---
title: "Fichiers de Configuration Pare-feu"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Fichiers de Configuration Pare-feu

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Brouillon |

---

## 1. Inventaire pare-feu

| Site | Modele | IP Management | Firmware |
|------|--------|---------------|----------|
| Siege Lille | FortiGate 100F | 192.168.10.1 | v7.4.x |
| WH1 Lens | FortiGate 60F | 192.168.20.1 | v7.4.x |
| WH2 Valenciennes | FortiGate 60F | 192.168.30.1 | v7.4.x |
| WH3 Arras | FortiGate 60F | 192.168.40.1 | v7.4.x |
| Cross-dock | FortiGate 40F | 192.168.50.1 | v7.4.x |

---

## 2. Regles de firewall communes

### 2.1 Regles inter-VLAN

| Source | Destination | Service | Action | Justification |
|--------|-------------|---------|--------|---------------|
| VLAN 40 (VOIP) | VLAN 20 (SERVEURS) | SIP, RTP | Allow | Telephones → IPBX |
| VLAN 30 (DATA) | VLAN 20 (SERVEURS) | HTTP, HTTPS, SMB | Allow | Postes → WMS, fichiers |
| VLAN 30 (DATA) | VLAN 40 (VOIP) | Tout | Deny | Isolation VoIP |
| VLAN 10 (MGMT) | Tout | Tout | Allow | Administration |

### 2.2 Regles WAN

| Source | Destination | Service | Action |
|--------|-------------|---------|--------|
| Internet | Siege | IPsec (UDP 500, 4500) | Allow |
| VPN peers | LAN | Tout | Allow |
| LAN | Internet | HTTP, HTTPS, DNS | Allow |
| Tout | Tout | Tout | Deny (default) |

---

## 3. Configuration QoS

_Reprendre les regles de QoS de `docs/02-conception/02-plan-adressage-vlan.md`_

---

## 4. Configuration POC (pfSense)

_A completer avec les exports pfSense_

---

## 5. Configuration production (FortiGate)

### 5.1 Template CLI siege

```
# A adapter
config system interface
    edit "VLAN10-MGMT"
        set vdom "root"
        set ip 192.168.10.1 255.255.255.192
        set allowaccess ping https ssh
        set interface "internal"
        set vlanid 10
    next
    # Repeter pour VLAN 20, 30, 40
end

config firewall policy
    # A completer avec les regles du tableau ci-dessus
end
```

---

## 6. Annexes

- Guide lab pfSense : `docs/03-lab-poc/02-pfsense-siege.md`
- Plan VLAN : `docs/02-conception/02-plan-adressage-vlan.md`
- Fichiers bruts : `configs/pfsense/` (quand exportes)
