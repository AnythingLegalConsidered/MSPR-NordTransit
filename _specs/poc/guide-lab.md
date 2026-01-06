# Guide Lab Proxmox

> Comment utiliser l'environnement de test

---

## Accès au Lab

| Information | Valeur |
| --- | --- |
| Plateforme | Proxmox VE |
| VMID réservés | 32000-32100 |
| Réseau Lab | 172.16.132.0/24 |

---

## Mapping Lab ↔ Production

| VM Lab | IP Lab | Équipement Prod | IP Prod |
| --- | --- | --- | --- |
| FW-SIEGE | 172.16.132.1 | FortiGate 80D | 192.168.10.254 |
| FW-WH1 | 172.16.132.2 | DrayTek Vigor | 192.168.20.254 |
| FW-WH2 | 172.16.132.3 | DrayTek Vigor | 192.168.30.254 |
| FW-WH3 | 172.16.132.4 | DrayTek Vigor | 192.168.40.254 |
| FW-CDK | 172.16.132.5 | Cross-dock | 192.168.50.254 |
| DC01 | 172.16.132.10 | DC01 | 192.168.10.10 |
| DC02 | 172.16.132.11 | DC02 | 192.168.10.11 |
| DC-AZURE | 172.16.132.12 | DC Azure | 10.x.x.x |
| WMS-APP | 172.16.132.20 | WMS-APP | 192.168.10.22 |
| WMS-DB | 172.16.132.21 | WMS-DB | 192.168.10.21 |
| IPBX | 172.16.132.30 | IPBX-VM | 192.168.10.40 |
| SUPERVISION | 172.16.132.40 | SUPER-01 | 192.168.10.50 |

---

## Quick Start

### Étape 1 : Créer la VM pfSense (30 min)
1. Nouvelle VM, VMID 32001
2. ISO pfSense
3. 2 Go RAM, 2 vCPU
4. 2 interfaces réseau (WAN + LAN)

### Étape 2 : Créer DC01 (45 min)
1. Nouvelle VM, VMID 32010
2. ISO Windows Server 2022
3. 4 Go RAM, 2 vCPU
4. Installer AD DS, DNS

### Étape 3 : Configurer le réseau (30 min)
1. Configurer pfSense (IP, DHCP)
2. Joindre DC01 au domaine
3. Tester la connectivité
