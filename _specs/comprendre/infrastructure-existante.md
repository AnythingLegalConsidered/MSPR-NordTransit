# Infrastructure existante

> État des lieux complet AVANT modernisation

---

## Vue d'ensemble

| Métrique | Valeur |
| --- | --- |
| Effectif normal | ~240 personnes |
| Effectif haute saison | ~300 personnes |
| Postes de travail | ~65 |
| Téléphones IP | ~70 |
| VMs hébergées | ~20 |
| Sites interconnectés | 5 |
| Équipe DSI | 4 personnes |

---

## Siège Social - Lille (192.168.10.0/24)

### Virtualisation

> **ALERTE CRITIQUE : Hyperviseur unique = Point de défaillance majeur**

| Équipement | Modèle | Spécifications | Problème |
| --- | --- | --- | --- |
| Hyperviseur | Dell PowerEdge R630 | 2× Xeon E5-2630 v3, 128 Go RAM | **SPOF** - Hyperviseur unique |
| Stockage | NAS 6 To RAID5 | Disques SAS 10K | Backups non testés, pas d'externalisation |

### Machines Virtuelles

| VM | OS | Rôle | IP | Criticité |
| --- | --- | --- | --- | --- |
| DC01 | Windows Server | Contrôleur domaine principal | 192.168.10.10 | Critique |
| DC02 | Windows Server | Contrôleur domaine secondaire | 192.168.10.11 | Haute |
| WMS-APP | Ubuntu 20.04 | Application WMS | 192.168.10.22 | **CRITIQUE** |
| WMS-DB | Ubuntu 20.04 | Base MySQL WMS | 192.168.10.21 | **CRITIQUE** |
| IPBX-VM | CentOS | Serveur téléphonie | 192.168.10.40 | Critique |
| SUPER-01 | Windows Server | Supervision | 192.168.10.50 | Moyenne |

### Sécurité périmètre

| Équipement | Modèle | Problème |
| --- | --- | --- |
| Pare-feu | FortiGate 80D | EOL proche, pas de maintenance |

---

## Entrepôts distants

### WH1 - Lens (192.168.20.0/24)

| Élément | Valeur |
| --- | --- |
| Pare-feu | DrayTek Vigor 2860 |
| Lien opérateur | ~200 Mbps managé |
| VPN | Site-à-site vers siège |
| Problème | **Pas de lien secours** |

### WH2 - Valenciennes (192.168.30.0/24)

| Élément | Valeur |
| --- | --- |
| Pare-feu | DrayTek Vigor 2860 |
| Lien opérateur | ~200 Mbps managé |
| Problème | **QoS/VLAN non documentés** |

### WH3 - Arras (192.168.40.0/24)

| Élément | Valeur |
| --- | --- |
| Pare-feu | DrayTek Vigor 2860 |
| Lien opérateur | ~200 Mbps managé |
| Note | Impression/étiquettes particulièrement critique |

### Cross-dock (192.168.50.0/24)

| Élément | Valeur |
| --- | --- |
| Équipement | Switch 24 ports basique |
| Activation | Saisonnière (pics e-commerce, soldes) |
| Note | Moyens IT volontairement réduits |

---

## Services Cloud actuels

| Service | Fournisseur | Statut | Problème |
| --- | --- | --- | --- |
| Microsoft 365 | Microsoft | Actif | Adoption inégale selon sites |
| Microsoft Entra ID | Microsoft | Actif | **MFA uniquement pour IT** |
| OneDrive/SharePoint | Microsoft | Actif | Droits hérités par défaut |
| Application RH (SaaS) | Éditeur externe | Actif | Comptes spécifiques |
