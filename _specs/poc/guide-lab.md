# Guide Lab Proxmox

> Reference rapide pour l'equipe

> **CREDENTIALS DE LAB UNIQUEMENT** - Ces identifiants sont destines au lab de test. NE PAS utiliser en production !

---

## Acces au Lab

| Information | Valeur |
|---|---|
| Plateforme | Proxmox VE |
| VMID reserves | 32000-32100 |
| Reseau Siege | 172.16.132.0/24 (vmbr1) |
| Reseau Azure | 10.100.0.0/24 (vmbr2) |

---

## Inventaire VMs

| VMID | Nom | OS | IP | RAM | Role |
|---|---|---|---|---|---|
| 32001 | FW-SIEGE | pfSense | 172.16.132.1 | 2 Go | Firewall + QoS + VPN |
| 32005 | FW-AZURE | pfSense | 10.100.0.1 | 2 Go | Cote Azure du tunnel |
| 32010 | DC01 | Win Server 2022 | 172.16.132.10 | 4 Go | AD principal |
| 32011 | DC02 | Win Server 2022 | 172.16.132.11 | 4 Go | AD secondaire |
| 32012 | DC-AZURE | Win Server 2022 | 10.100.0.10 | 4 Go | DC cloud |
| 32020 | WMS | Ubuntu 22.04 | 172.16.132.20 | 2 Go | Simulation WMS |
| 32030 | IPBX | FreePBX | 172.16.132.30 | 2 Go | Telephonie VoIP |

**Total : 7 VMs, ~20 Go RAM**

---

## Credentials

| Systeme | Acces | Login | Password |
|---|---|---|---|
| Proxmox | https://proxmox.local:8006 | root | (votre mdp) |
| pfSense Siege | https://172.16.132.1 | admin | pfsense |
| pfSense Azure | https://10.100.0.1 | admin | pfsense |
| FreePBX | http://172.16.132.30 | admin | (a definir) |
| Windows AD | RDP | Administrator | P@ssw0rd! |
| Ubuntu WMS | SSH | wmsadmin | P@ssw0rd! |
| VPN IPsec | PSK | - | MSPR-VPN-2024! |

---

## Ce qu'on demontre

| POC | Ce qu'on prouve | Critere de succes |
|---|---|---|
| **QoS VoIP** | Voix prioritaire sous charge | Latence < 150ms, Gigue < 30ms, Perte < 1% |
| **Failover AD** | DC02 prend le relais | Bascule < 15 min, Auth OK |
| **Failover WMS** | VM redemarre automatiquement | Donnees MySQL intactes |
| **Tunnel Azure** | Connectivite siege <-> cloud | Ping + DNS cross-site OK |

---

## Commandes utiles

### pfSense (SSH)
```bash
# Verifier queues QoS
pfctl -s queue

# Verifier tunnel IPsec
ipsec statusall
```

### Windows AD (PowerShell)
```powershell
# Lister les DC
Get-ADDomainController -Filter *

# Etat replication
repadmin /replsummary

# Quel DC repond ?
nltest /dsgetdc:lab.local

# Sante AD
dcdiag /s:DC01
```

### Ubuntu WMS (SSH)
```bash
# Test MySQL
mysql -u root -e "SELECT * FROM wms_test.inventory;"

# Verifier services
systemctl status mysql
```

### Tests reseau
```powershell
# Ping cross-site
ping 10.100.0.10

# DNS cross-site
nslookup dc-azure.azure.local
```

---

## Repartition equipe

| Role | Responsabilites |
|---|---|
| **P1** | Setup reseau + pfSense siege + DC01 |
| **P2** | DC02 + replication + failover AD |
| **P3** | IPBX + QoS + test VoIP |
| **P4** | Azure (FW + DC) + tunnel IPsec |
| **P5** | WMS + documentation + captures |
