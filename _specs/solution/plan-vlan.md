# Plan d'adressage VLAN

> Segmentation reseau cible -- harmonisee sur tous les sites

---

## Principe

> **Un numero de VLAN = Un type de trafic, partout**
> VLAN 10 = Admin | VLAN 20 = Serveurs | VLAN 30 = Users/Data | VLAN 40 = VoIP

---

## Tableau recapitulatif global

| Site | VLAN | Nom | Reseau | Gateway | Plage DHCP | DSCP |
|---|---|---|---|---|---|---|
| **Lille** | 10 | MGMT | 192.168.10.0/26 | .1 | Statique | - |
| | 20 | SERVEURS | 192.168.10.64/26 | .65 | Statique | AF31 |
| | 30 | DATA | 192.168.10.128/26 | .129 | .130-.190 | BE |
| | 40 | VOIP | 192.168.10.192/26 | .193 | .194-.250 | EF |
| **WH1 Lens** | 10 | MGMT | 192.168.20.0/27 | .1 | Statique | - |
| | 30 | DATA | 192.168.20.32/25 | .33 | .34-.150 | BE |
| | 40 | VOIP | 192.168.20.160/27 | .161 | .162-.190 | EF |
| **WH2 Valenciennes** | 10 | MGMT | 192.168.30.0/27 | .1 | Statique | - |
| | 30 | DATA | 192.168.30.32/25 | .33 | .34-.150 | BE |
| | 40 | VOIP | 192.168.30.160/27 | .161 | .162-.190 | EF |
| **WH3 Arras** | 10 | MGMT | 192.168.40.0/27 | .1 | Statique | - |
| | 30 | DATA | 192.168.40.32/25 | .33 | .34-.150 | BE |
| | 40 | VOIP | 192.168.40.160/27 | .161 | .162-.190 | EF |
| **Cross-dock** | 30 | DATA | 192.168.50.0/24 | .1 | .10-.240 | BE |
| **Azure Hub** | - | Hub | 10.100.0.0/24 | .1 | - | - |
| **Azure Backup** | - | Backup | 10.100.1.0/24 | .1 | - | - |

---

## Legende VLAN

| VLAN ID | Nom | Usage | Present sur |
|---|---|---|---|
| 10 | MGMT | Administration switches, AP, firewalls | Tous sauf CDK |
| 20 | SERVEURS | VMs, stockage SAN | Siege uniquement |
| 30 | DATA | Postes de travail, terminaux RF, imprimantes | Tous les sites |
| 40 | VOIP | Telephones IP Cisco | Tous sauf CDK |

---

## QoS par VLAN

| VLAN | Priorite | DSCP | Bande passante garantie | Remarque |
|---|---|---|---|---|
| VOIP (40) | **Haute** | EF (46) | 30% minimum | Priorite absolue pour la voix |
| SERVEURS (20) | Moyenne-Haute | AF31 (26) | 40% | WMS, AD, DNS critiques |
| DATA (30) | Normale | BE (0) | Best effort | Trafic utilisateur standard |
| MGMT (10) | Normale | CS2 (16) | 5% | Faible volume, acces admin |

---

## Validation anti-conflit

> **Aucun chevauchement IP detecte**
> - Siege : 192.168.10.0/24
> - WH1 : 192.168.20.0/24
> - WH2 : 192.168.30.0/24
> - WH3 : 192.168.40.0/24
> - CDK : 192.168.50.0/24
> - Azure : 10.100.0.0/23
