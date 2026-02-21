#!/usr/bin/env bash
# demo-soutenance.sh — Demo interactive soutenance MSPR NordTransit
# Usage: bash demo-soutenance.sh [--quick]
#   --quick : timeouts courts, avance automatique (repetition solo)
#   (defaut) : pauses manuelles, timeouts complets (mode live jury)
#
# Run on: pve02 as root

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

if [ "$QUICK" = "--quick" ]; then
    IPERF_DURATION=8
    PING_COUNT=20
    PING_INTERVAL=0.2
    AD_WAIT=20
    WMS_WAIT=25
    AUTO_ADVANCE=true
else
    IPERF_DURATION=20
    PING_COUNT=100
    PING_INTERVAL=0.1
    AD_WAIT=35
    WMS_WAIT=45
    AUTO_ADVANCE=false
fi

# --- Infrastructure ---
IP_FW_SIEGE="172.16.132.1"
IP_DC01="172.16.132.10"
IP_DC02="172.16.132.11"
IP_DC_AZURE="10.100.0.10"
IP_WMS="172.16.132.20"
IP_IPBX="172.16.132.30"
IP_PVE02="172.16.132.254"

PASS_PF="pfsense"
PASS_WIN='az4826QS6284**'

SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# --- Resultats ---
declare -A TEST_RESULTS=()
declare -A TEST_DURATIONS=()

# ============================================================
# Fonctions utilitaires
# ============================================================

ssh_run() {
    local user="$1" pass="$2" ip="$3" cmd="$4"
    sshpass -p "$pass" ssh $SSH_OPTS "$user@$ip" "$cmd" 2>/dev/null
}

ssh_key_run() {
    local user="$1" ip="$2" cmd="$3"
    ssh $SSH_OPTS "$user@$ip" "$cmd" 2>/dev/null
}

header_test() {
    local num="$1" total="$2" name="$3"
    printf "\n"
    printf "${BOLD}${YELLOW}+================================================+${NC}\n"
    printf "${BOLD}${YELLOW}|  TEST %s/%s : %-37s|${NC}\n" "$num" "$total" "$name"
    printf "${BOLD}${YELLOW}+================================================+${NC}\n"
}

explain() {
    printf "${CYAN}  [CONTEXTE] %s${NC}\n" "$1"
}

expected() {
    printf "${CYAN}  [ATTENDU]  %s${NC}\n\n" "$1"
}

step() {
    printf "\n${BOLD}  [%s] %s${NC}\n" "$1" "$2"
}

wait_enter() {
    if [ "$AUTO_ADVANCE" = "true" ]; then
        sleep 1
    else
        printf "\n${BOLD}  >>> Appuyer sur ENTREE pour continuer...${NC}"
        read -r
    fi
}

countdown() {
    local secs="$1"
    while [ "$secs" -gt 0 ]; do
        printf "\r  Attente... %ds   " "$secs"
        sleep 5
        secs=$((secs - 5))
        [ "$secs" -lt 0 ] && secs=0
    done
    printf "\r  Attente... terminee.       \n"
}

# ============================================================
# TEST 1 — QoS VoIP
# ============================================================

test_qos() {
    header_test 1 4 "QoS VoIP"
    echo
    explain "On sature le reseau a 500 Mbps avec iperf3."
    explain "En parallele, on mesure la latence vers l'IPBX (VoIP)."
    explain "Sans QoS, la latence exploserait. Avec PRIQ, le trafic"
    explain "VoIP reste prioritaire (queue qVoIP, priority 7)."
    echo
    expected "Latence < 150 ms, gigue < 30 ms, 0% perte paquets"

    wait_enter

    # Cleanup iperf3 residuel
    pkill iperf3 2>/dev/null || true
    sleep 1

    step "1/4" "Lancement serveur iperf3 sur pve02 (background)..."
    iperf3 -s -B "$IP_PVE02" -p 5201 &>/dev/null &
    IPERF_SERVER_PID=$!
    sleep 2

    step "2/4" "Saturation 500 Mbps depuis WMS (${IPERF_DURATION}s)..."
    local t_start
    t_start=$(date +%s)

    ssh_key_run wmsadmin "$IP_WMS" \
        "iperf3 -c $IP_PVE02 -p 5201 -t $IPERF_DURATION -b 500M" &
    local IPERF_CLIENT_PID=$!

    # Petit delai pour que la saturation demarre
    sleep 2

    step "3/4" "Ping IPBX pendant saturation (${PING_COUNT} paquets)..."
    echo
    local PING_OUT
    PING_OUT=$(ssh_key_run wmsadmin "$IP_WMS" \
        "ping -c $PING_COUNT -i $PING_INTERVAL $IP_IPBX")
    echo "$PING_OUT" | tail -3

    wait $IPERF_CLIENT_PID 2>/dev/null || true

    local t_end
    t_end=$(date +%s)
    TEST_DURATIONS["QoS VoIP"]=$((t_end - t_start))

    step "4/4" "Stats queues QoS sur FW-SIEGE :"
    echo
    ssh_run admin "$PASS_PF" "$IP_FW_SIEGE" "pfctl -s queue" 2>/dev/null || true

    # Cleanup
    kill $IPERF_SERVER_PID 2>/dev/null || true
    pkill iperf3 2>/dev/null || true

    # Analyse resultats
    local pkt_loss avg_ms
    pkt_loss=$(echo "$PING_OUT" | grep -o '[0-9]*% packet loss' | grep -o '[0-9]*' || echo "100")
    avg_ms=$(echo "$PING_OUT" | grep 'rtt min/avg/max' | awk -F'/' '{print $5}' || echo "999")

    echo
    if [ "${pkt_loss:-100}" -lt 2 ] && awk "BEGIN{exit !(${avg_ms:-999} < 150)}" 2>/dev/null; then
        TEST_RESULTS["QoS VoIP"]="PASS"
        printf "  ${GREEN}${BOLD}RESULTAT : PASS${NC} — latence ${avg_ms}ms, perte ${pkt_loss}%%\n"
    else
        TEST_RESULTS["QoS VoIP"]="FAIL"
        printf "  ${RED}${BOLD}RESULTAT : FAIL${NC} — latence ${avg_ms}ms, perte ${pkt_loss}%%\n"
    fi

    wait_enter
}

# ============================================================
# TEST 2 — Failover AD
# ============================================================

test_failover_ad() {
    header_test 2 4 "Failover Active Directory"
    echo
    explain "On eteint brutalement DC01 (controleur principal)."
    explain "DC02 doit prendre le relais automatiquement."
    explain "En production, les 240 employes ne voient aucune coupure."
    echo
    expected "nltest /dsgetdc:lab.local repond DC02.lab.local"

    wait_enter

    step "1/4" "Etat initial — nltest sur DC02 :"
    echo
    ssh_run Administrator "$PASS_WIN" "$IP_DC02" "nltest /dsgetdc:lab.local" || true

    wait_enter

    step "2/4" "Arret brutal de DC01 (qm stop 32010)..."
    local t_start
    t_start=$(date +%s)
    qm stop 32010 2>/dev/null
    printf "  DC01 arrete. Convergence AD en cours...\n"
    countdown "$AD_WAIT"

    step "3/4" "Test DNS via DC02 :"
    echo
    ssh_run Administrator "$PASS_WIN" "$IP_DC02" \
        "nslookup lab.local 172.16.132.11" || true

    step "4/4" "Verification nltest sur DC02 :"
    echo
    local NLTEST_OUT
    NLTEST_OUT=$(ssh_run Administrator "$PASS_WIN" "$IP_DC02" \
        "nltest /dsgetdc:lab.local" || true)
    echo "$NLTEST_OUT"

    local t_end
    t_end=$(date +%s)
    TEST_DURATIONS["Failover AD"]=$((t_end - t_start))

    echo
    if echo "$NLTEST_OUT" | grep -qi "DC02"; then
        TEST_RESULTS["Failover AD"]="PASS"
        printf "  ${GREEN}${BOLD}RESULTAT : PASS${NC} — DC02 repond en ${TEST_DURATIONS[Failover AD]}s\n"
    else
        TEST_RESULTS["Failover AD"]="FAIL"
        printf "  ${RED}${BOLD}RESULTAT : FAIL${NC} — DC02 ne repond pas\n"
    fi

    wait_enter

    step "+" "Redemarrage DC01 (qm start 32010)..."
    qm start 32010 2>/dev/null
    printf "  DC01 en cours de reboot — resynchronisation AD en arriere-plan.\n"

    wait_enter
}

# ============================================================
# TEST 3 — Failover WMS
# ============================================================

test_failover_wms() {
    header_test 3 4 "Failover WMS"
    echo
    explain "On arrete brutalement la VM WMS (simule coupure courant)."
    explain "Apres reboot, MySQL doit etre operationnel et les donnees"
    explain "intactes : 5 articles d'inventaire dans la base."
    echo
    expected "MySQL active, 5/5 records identiques avant/apres"

    wait_enter

    step "1/4" "Etat AVANT — check_wms.sh :"
    echo
    ssh_key_run wmsadmin "$IP_WMS" "/usr/local/bin/check_wms.sh" || true

    wait_enter

    step "2/4" "Arret brutal + redemarrage WMS..."
    local t_start
    t_start=$(date +%s)
    qm stop 32020 2>/dev/null
    printf "  VM arretee. Redemarrage...\n"
    sleep 2
    qm start 32020 2>/dev/null
    printf "  VM en cours de boot...\n"
    countdown "$WMS_WAIT"

    # Boucle retry SSH
    step "3/4" "Attente SSH WMS..."
    local attempt
    for attempt in $(seq 1 12); do
        if ssh_key_run wmsadmin "$IP_WMS" "echo ok" >/dev/null 2>&1; then
            printf "  SSH OK apres tentative %d\n" "$attempt"
            break
        fi
        printf "  Tentative %d/12...\n" "$attempt"
        sleep 5
    done

    local t_end
    t_end=$(date +%s)
    TEST_DURATIONS["Failover WMS"]=$((t_end - t_start))

    step "4/4" "Etat APRES — check_wms.sh :"
    echo
    local AFTER
    AFTER=$(ssh_key_run wmsadmin "$IP_WMS" "/usr/local/bin/check_wms.sh" || true)
    echo "$AFTER"

    echo
    if echo "$AFTER" | grep -q "5 records" && echo "$AFTER" | grep -q "MySQL service running"; then
        TEST_RESULTS["Failover WMS"]="PASS"
        printf "  ${GREEN}${BOLD}RESULTAT : PASS${NC} — reboot ${TEST_DURATIONS[Failover WMS]}s, 5/5 records intacts\n"
    else
        TEST_RESULTS["Failover WMS"]="FAIL"
        printf "  ${RED}${BOLD}RESULTAT : FAIL${NC} — MySQL ou donnees KO\n"
    fi

    wait_enter
}

# ============================================================
# TEST 4 — Tunnel Azure
# ============================================================

test_tunnel_azure() {
    header_test 4 4 "Tunnel Inter-sites (Azure)"
    echo
    explain "On verifie la communication siege <-> Azure."
    explain "En prod : tunnel IPsec IKEv2. En lab : routes statiques"
    explain "(meme principe de routage inter-VLAN via pfSense)."
    echo
    expected "Ping bidirectionnel OK, DNS cross-site, replication 0 erreurs"

    wait_enter

    local t_start
    t_start=$(date +%s)

    step "1/4" "Ping siege -> Azure (DC01 -> DC-AZURE) :"
    echo
    ssh_run Administrator "$PASS_WIN" "$IP_DC01" \
        "ping -n 4 $IP_DC_AZURE" || true

    wait_enter

    step "2/4" "Ping Azure -> siege (DC-AZURE -> DC01) :"
    echo
    local PING2
    PING2=$(ssh_run Administrator "$PASS_WIN" "$IP_DC_AZURE" \
        "ping -n 4 $IP_DC01" || true)
    echo "$PING2"

    wait_enter

    step "3/4" "DNS cross-site (nslookup dc-azure.lab.local depuis DC01) :"
    echo
    ssh_run Administrator "$PASS_WIN" "$IP_DC01" \
        "nslookup dc-azure.lab.local" || true

    wait_enter

    step "4/4" "Replication AD cross-site (depuis DC-AZURE) :"
    echo
    local REPL_OUT
    REPL_OUT=$(ssh_run Administrator "$PASS_WIN" "$IP_DC_AZURE" \
        "repadmin /syncall /APed" || true)
    echo "$REPL_OUT"

    local t_end
    t_end=$(date +%s)
    TEST_DURATIONS["Tunnel Azure"]=$((t_end - t_start))

    # Verification
    local ping_ok=false repl_ok=false
    echo "$PING2" | grep -qi "reply from" && ping_ok=true
    echo "$REPL_OUT" | grep -qi "no errors" && repl_ok=true

    echo
    if $ping_ok && $repl_ok; then
        TEST_RESULTS["Tunnel Azure"]="PASS"
        printf "  ${GREEN}${BOLD}RESULTAT : PASS${NC} — inter-sites OK en ${TEST_DURATIONS[Tunnel Azure]}s\n"
    else
        TEST_RESULTS["Tunnel Azure"]="FAIL"
        printf "  ${RED}${BOLD}RESULTAT : FAIL${NC} — verifier routage pfSense / AD replication\n"
    fi

    wait_enter
}

# ============================================================
# Resume final
# ============================================================

show_summary() {
    printf "\n"
    printf "${BOLD}${YELLOW}+================================================+${NC}\n"
    printf "${BOLD}${YELLOW}|     RESULTATS SOUTENANCE — NordTransit          |${NC}\n"
    printf "${BOLD}${YELLOW}+================================================+${NC}\n\n"

    local all_pass=true
    for test in "QoS VoIP" "Failover AD" "Failover WMS" "Tunnel Azure"; do
        local status="${TEST_RESULTS[$test]:-SKIP}"
        local duration="${TEST_DURATIONS[$test]:-?}"
        if [ "$status" = "PASS" ]; then
            printf "  ${GREEN}[PASS]${NC}  %-22s  (%ss)\n" "$test" "$duration"
        else
            printf "  ${RED}[FAIL]${NC}  %-22s  (%ss)\n" "$test" "$duration"
            all_pass=false
        fi
    done

    echo
    if $all_pass; then
        printf "  ${GREEN}${BOLD}4/4 PASS — POC VALIDE${NC}\n\n"
    else
        printf "  ${RED}${BOLD}DES TESTS ONT ECHOUE — voir details ci-dessus${NC}\n\n"
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    printf "\n${BOLD}${CYAN}=== NordTransit Logistics — Demo Soutenance MSPR ===${NC}\n\n"
    printf "  Date  : $(date '+%d/%m/%Y %H:%M')\n"
    printf "  Mode  : %s\n" "$([ "$QUICK" = '--quick' ] && echo 'REPETITION (timeouts courts)' || echo 'LIVE (pauses manuelles)')"
    printf "  Tests : 4 (QoS, Failover AD, Failover WMS, Tunnel Azure)\n"

    wait_enter

    test_qos
    test_failover_ad
    test_failover_wms
    test_tunnel_azure
    show_summary
}

main
