#!/usr/bin/env bash
# preflight-demo.sh — Verification pre-soutenance NordTransit
# Usage: bash preflight-demo.sh [--quick]
# Run on: pve02 as root, 30 min avant la soutenance
#
# Verifie en ~30s que le lab est pret : VMs, SSH, services, reseau, QoS

set -uo pipefail

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Mode ---
QUICK="${1:-}"
TIMEOUT=5
[ "$QUICK" = "--quick" ] && TIMEOUT=3

# --- Infrastructure ---
declare -A VM_NAMES
VM_NAMES=([32001]="FW-SIEGE" [32005]="FW-AZURE" [32010]="DC01"
          [32011]="DC02" [32012]="DC-AZURE" [32020]="WMS" [32030]="IPBX")
VMIDS=(32001 32005 32010 32011 32012 32020 32030)

IP_FW_SIEGE="172.16.132.1"
IP_FW_AZURE="10.100.0.1"
IP_DC01="172.16.132.10"
IP_DC02="172.16.132.11"
IP_DC_AZURE="10.100.0.10"
IP_WMS="172.16.132.20"
IP_IPBX="172.16.132.30"
IP_PVE02="172.16.132.254"

PASS_PF="pfsense"
PASS_WIN='az4826QS6284**'
PASS_IPBX="SangomaDefaultPassword"

# --- Compteurs ---
TOTAL=0
PASSED=0
FAILED=0

# --- Tableaux resultats (ordre d'insertion) ---
declare -a CHECK_NAMES=()
declare -A RESULTS=()

# ============================================================
# Fonctions utilitaires
# ============================================================

record() {
    local label="$1" status="$2"
    TOTAL=$((TOTAL + 1))
    CHECK_NAMES+=("$label")
    if [ "$status" = "PASS" ]; then
        PASSED=$((PASSED + 1))
        RESULTS["$label"]="PASS"
        printf "  ${GREEN}[✓]${NC} %s\n" "$label"
    else
        FAILED=$((FAILED + 1))
        RESULTS["$label"]="FAIL"
        printf "  ${RED}[✗]${NC} %s\n" "$label"
    fi
}

print_section() {
    printf "\n${BOLD}${YELLOW}=== %s ===${NC}\n" "$1"
}

# SSH password-based (pfSense, Windows, IPBX)
ssh_run() {
    local user="$1" pass="$2" ip="$3" cmd="$4"
    sshpass -p "$pass" ssh \
        -o ConnectTimeout="$TIMEOUT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$user@$ip" "$cmd" 2>/dev/null
}

# SSH key-based (WMS)
ssh_key_run() {
    local user="$1" ip="$2" cmd="$3"
    ssh -o ConnectTimeout="$TIMEOUT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$user@$ip" "$cmd" 2>/dev/null
}

# ============================================================
# Phase 1 — Statut VMs
# ============================================================

check_vms() {
    print_section "1/5 STATUT VMs"
    for vmid in "${VMIDS[@]}"; do
        local name="${VM_NAMES[$vmid]}"
        local status
        status=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')
        if [ "$status" = "running" ]; then
            record "VM $vmid ($name) running" "PASS"
        else
            record "VM $vmid ($name) running [got: ${status:-unknown}]" "FAIL"
        fi
    done
}

# ============================================================
# Phase 2 — Connectivite SSH
# ============================================================

check_ssh() {
    print_section "2/5 CONNECTIVITE SSH"

    # pfSense
    ssh_run admin "$PASS_PF" "$IP_FW_SIEGE" "echo ok" >/dev/null 2>&1 \
        && record "SSH FW-SIEGE ($IP_FW_SIEGE)" "PASS" \
        || record "SSH FW-SIEGE ($IP_FW_SIEGE)" "FAIL"

    ssh_run admin "$PASS_PF" "$IP_FW_AZURE" "echo ok" >/dev/null 2>&1 \
        && record "SSH FW-AZURE ($IP_FW_AZURE)" "PASS" \
        || record "SSH FW-AZURE ($IP_FW_AZURE)" "FAIL"

    # Windows DCs
    for entry in "$IP_DC01:DC01" "$IP_DC02:DC02" "$IP_DC_AZURE:DC-AZURE"; do
        local ip="${entry%%:*}" label="${entry##*:}"
        ssh_run Administrator "$PASS_WIN" "$ip" "echo ok" >/dev/null 2>&1 \
            && record "SSH $label ($ip)" "PASS" \
            || record "SSH $label ($ip)" "FAIL"
    done

    # WMS (key-based)
    ssh_key_run wmsadmin "$IP_WMS" "echo ok" >/dev/null 2>&1 \
        && record "SSH WMS ($IP_WMS)" "PASS" \
        || record "SSH WMS ($IP_WMS)" "FAIL"

    # IPBX
    ssh_run root "$PASS_IPBX" "$IP_IPBX" "echo ok" >/dev/null 2>&1 \
        && record "SSH IPBX ($IP_IPBX)" "PASS" \
        || record "SSH IPBX ($IP_IPBX)" "FAIL"
}

# ============================================================
# Phase 3 — Services
# ============================================================

check_services() {
    print_section "3/5 SERVICES"

    # AD — nltest sur DC01
    local out
    out=$(ssh_run Administrator "$PASS_WIN" "$IP_DC01" "nltest /dsgetdc:lab.local" 2>/dev/null)
    echo "$out" | grep -qi "DC:" \
        && record "AD nltest DC01" "PASS" \
        || record "AD nltest DC01" "FAIL"

    # AD — nltest sur DC02
    out=$(ssh_run Administrator "$PASS_WIN" "$IP_DC02" "nltest /dsgetdc:lab.local" 2>/dev/null)
    echo "$out" | grep -qi "DC:" \
        && record "AD nltest DC02" "PASS" \
        || record "AD nltest DC02" "FAIL"

    # AD — replication
    out=$(ssh_run Administrator "$PASS_WIN" "$IP_DC01" "repadmin /replsummary" 2>/dev/null)
    if echo "$out" | grep -qi "0 fail"; then
        record "AD replication (0 failures)" "PASS"
    elif echo "$out" | grep -qi "replsummary"; then
        # repadmin a repondu mais avec des erreurs
        record "AD replication (errors detected)" "FAIL"
    else
        record "AD replication (no response)" "FAIL"
    fi

    # MySQL sur WMS
    out=$(ssh_key_run wmsadmin "$IP_WMS" "systemctl is-active mysql" 2>/dev/null)
    [ "$out" = "active" ] \
        && record "MySQL WMS" "PASS" \
        || record "MySQL WMS [got: ${out:-no response}]" "FAIL"

    # Asterisk sur IPBX
    out=$(ssh_run root "$PASS_IPBX" "$IP_IPBX" "asterisk -rx 'core show channels'" 2>/dev/null)
    echo "$out" | grep -qi "active channel" \
        && record "Asterisk IPBX" "PASS" \
        || record "Asterisk IPBX" "FAIL"

    # DNS — dig depuis pve02
    out=$(dig @"$IP_DC01" lab.local +short +timeout=3 2>/dev/null)
    [ -n "$out" ] \
        && record "DNS lab.local (@DC01)" "PASS" \
        || record "DNS lab.local (@DC01)" "FAIL"
}

# ============================================================
# Phase 4 — Reseau
# ============================================================

check_network() {
    print_section "4/5 RESEAU"

    # Cross-VLAN
    ping -c 3 -W 2 "$IP_DC_AZURE" >/dev/null 2>&1 \
        && record "Cross-VLAN pve02 -> DC-AZURE ($IP_DC_AZURE)" "PASS" \
        || record "Cross-VLAN pve02 -> DC-AZURE ($IP_DC_AZURE)" "FAIL"

    # iperf3 sur WMS
    ssh_key_run wmsadmin "$IP_WMS" "which iperf3" >/dev/null 2>&1 \
        && record "iperf3 disponible sur WMS" "PASS" \
        || record "iperf3 disponible sur WMS" "FAIL"
}

# ============================================================
# Phase 5 — QoS pfSense
# ============================================================

check_qos() {
    print_section "5/5 QoS pfSense"

    local out
    out=$(ssh_run admin "$PASS_PF" "$IP_FW_SIEGE" "pfctl -s queue" 2>/dev/null)

    echo "$out" | grep -q "qVoIP" \
        && record "QoS queue qVoIP (FW-SIEGE)" "PASS" \
        || record "QoS queue qVoIP (FW-SIEGE)" "FAIL"

    echo "$out" | grep -q "qDefault" \
        && record "QoS queue qDefault (FW-SIEGE)" "PASS" \
        || record "QoS queue qDefault (FW-SIEGE)" "FAIL"
}

# ============================================================
# Resume final
# ============================================================

show_summary() {
    print_section "RESUME"

    printf "\n  %-48s %s\n" "CHECK" "STATUT"
    printf "  %-48s %s\n" "$(printf '%0.s-' {1..48})" "------"

    for label in "${CHECK_NAMES[@]}"; do
        local status="${RESULTS[$label]}"
        if [ "$status" = "PASS" ]; then
            printf "  %-48s ${GREEN}PASS${NC}\n" "$label"
        else
            printf "  %-48s ${RED}FAIL${NC}\n" "$label"
        fi
    done

    printf "\n  ${BOLD}TOTAL: %d/%d PASS${NC}\n" "$PASSED" "$TOTAL"

    if [ "$FAILED" -eq 0 ]; then
        printf "\n${GREEN}${BOLD}  >>> LAB PRET POUR LA SOUTENANCE <<<${NC}\n\n"
        exit 0
    else
        printf "\n${RED}${BOLD}  >>> %d CHECK(S) EN ECHEC — INVESTIGUER AVANT DEMO <<<${NC}\n\n" "$FAILED"
        exit 1
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    printf "\n${BOLD}${CYAN}NordTransit Logistics — Preflight Soutenance${NC}\n"
    printf "Date : $(date '+%d/%m/%Y %H:%M')\n"
    printf "Mode : %s\n" "$([ "$QUICK" = '--quick' ] && echo 'RAPIDE (timeout 3s)' || echo 'STANDARD (timeout 5s)')"

    check_vms
    check_ssh
    check_services
    check_network
    check_qos
    show_summary
}

main
