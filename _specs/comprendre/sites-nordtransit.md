# Sites NordTransit

> Detail de chaque site et ses specificites

---

## Siege Social - Lille

| Information | Valeur |
|---|---|
| Reseau | 192.168.10.0/24 |
| Passerelle | 192.168.10.1 |
| Pare-feu | FortiGate 80D |
| Role | Services centraux, hebergement VMs |

### Equipements cles
- Hyperviseur Dell R630 (toutes les VMs critiques)
- NAS 6 To RAID5
- Passerelle SIP
- ~25 telephones Cisco IP

### Services heberges
- Active Directory (DC01, DC02)
- WMS (Application + Base de donnees)
- IPBX (telephonie)
- Supervision

---

## WH1 - Entrepot Lens

| Information | Valeur |
|---|---|
| Reseau | 192.168.20.0/24 |
| Passerelle | 192.168.20.1 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps manage |

### Equipements
- ~15 PC / Terminaux legers
- ~15 telephones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes etiquettes

> **Probleme identifie : Pas de lien de secours**

---

## WH2 - Entrepot Valenciennes

| Information | Valeur |
|---|---|
| Reseau | 192.168.30.0/24 |
| Passerelle | 192.168.30.1 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps manage |

### Equipements
- ~15 PC / Terminaux legers
- ~15 telephones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes etiquettes

> **Probleme identifie : QoS/VLAN non documentes**

---

## WH3 - Entrepot Arras

| Information | Valeur |
|---|---|
| Reseau | 192.168.40.0/24 |
| Passerelle | 192.168.40.1 |
| Pare-feu | DrayTek Vigor 2860 |
| Lien | ~200 Mbps manage |

### Equipements
- ~15 PC / Terminaux legers
- ~15 telephones IP
- ~10 terminaux RF (Wi-Fi)
- ~3 imprimantes etiquettes

> **Specificite : Impression/etiquettes particulierement critique sur ce site**

---

## Cross-dock (Saisonnier)

| Information | Valeur |
|---|---|
| Reseau | 192.168.50.0/24 |
| Passerelle | 192.168.50.1 |
| Equipement | Switch 24 ports basique |
| Activation | Pics e-commerce, soldes |

> **Site saisonnier** - Moyens IT volontairement reduits
> Active uniquement pendant les periodes de forte activite
