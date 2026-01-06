# Plan d'adressage VLAN

> Segmentation réseau cible

---

## Siège Lille (192.168.10.0/24 → segmenté)

| VLAN | Nom | Réseau | Passerelle | Usage |
| --- | --- | --- | --- | --- |
| 10 | MGMT | 192.168.10.0/26 | .1 | Administration |
| 20 | SERVEURS | 192.168.10.64/26 | .65 | VMs, stockage |
| 30 | USERS | 192.168.10.128/26 | .129 | Postes de travail |
| 40 | VOIP | 192.168.10.192/26 | .193 | Téléphonie IP |

---

## Sites distants

### WH1 - Lens (192.168.20.0/24)

| VLAN | Nom | Réseau | Usage |
| --- | --- | --- | --- |
| 20 | DATA | 192.168.20.0/25 | Postes + terminaux RF |
| 40 | VOIP | 192.168.20.128/25 | Téléphonie |

### WH2 - Valenciennes (192.168.30.0/24)

| VLAN | Nom | Réseau | Usage |
| --- | --- | --- | --- |
| 20 | DATA | 192.168.30.0/25 | Postes + terminaux RF |
| 40 | VOIP | 192.168.30.128/25 | Téléphonie |

### WH3 - Arras (192.168.40.0/24)

| VLAN | Nom | Réseau | Usage |
| --- | --- | --- | --- |
| 20 | DATA | 192.168.40.0/25 | Postes + terminaux RF |
| 40 | VOIP | 192.168.40.128/25 | Téléphonie |

### Cross-dock (192.168.50.0/24)

| VLAN | Nom | Réseau | Usage |
| --- | --- | --- | --- |
| 20 | DATA | 192.168.50.0/24 | Tout le trafic |

---

## Azure

| VNet | Réseau | Usage |
| --- | --- | --- |
| Hub | 10.100.0.0/24 | VPN Gateway, DC-Azure |
| Backup | 10.100.1.0/24 | Blob Storage, Recovery |

---

## QoS par VLAN

| VLAN | Priorité | DSCP | Bande passante garantie |
| --- | --- | --- | --- |
| VOIP | Haute | EF (46) | 30% minimum |
| SERVEURS | Moyenne-Haute | AF31 (26) | 40% |
| DATA | Normale | BE (0) | Best effort |
