# Sites NordTransit

> Détail de chaque site et ses spécificités

---

## Siège Social - Lille

| Information | Valeur |
| --- | --- |
| Réseau | 192.168.10.0/24 |
| Passerelle | 192.168.10.254 |
| Pare-feu | FortiGate 80D |
| Rôle | Services centraux, hébergement VMs |

### Équipements clés
- Hyperviseur Dell R630 (toutes les VMs critiques)
- NAS 6 To RAID5
- Passerelle SIP
- ~25 téléphones Cisco IP

### Services hébergés
- Active Directory (DC01, DC02)
- WMS (Application + Base de données)
- IPBX (téléphonie)
- Supervision

---

## WH1 - Entrepôt Lens

| Information | Valeur |
| --- | --- |
| Réseau | 192.168.20.0/24 |
| Passerelle | 192.168.20.254 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps managé |

### Équipements
- ~15 PC / Terminaux légers
- ~15 téléphones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes étiquettes

> **Problème identifié : Pas de lien de secours**

---

## WH2 - Entrepôt Valenciennes

| Information | Valeur |
| --- | --- |
| Réseau | 192.168.30.0/24 |
| Passerelle | 192.168.30.254 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps managé |

### Équipements
- ~15 PC / Terminaux légers
- ~15 téléphones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes étiquettes

> **Problème identifié : QoS/VLAN non documentés**

---

## WH3 - Entrepôt Arras

| Information | Valeur |
| --- | --- |
| Réseau | 192.168.40.0/24 |
| Passerelle | 192.168.40.254 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps managé |

### Équipements
- ~15 PC / Terminaux légers
- ~15 téléphones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes étiquettes

> **Spécificité : Impression/étiquettes particulièrement critique sur ce site**

---

## Cross-dock (Saisonnier)

| Information | Valeur |
| --- | --- |
| Réseau | 192.168.50.0/24 |
| Passerelle | 192.168.50.254 |
| Équipement | Switch 24 ports basique |
| Activation | Pics e-commerce, soldes |

> **Site saisonnier** - Moyens IT volontairement réduits
> Activé uniquement pendant les périodes de forte activité
