# Architecture cible

> Notre proposition de modernisation

---

## Objectifs de l'architecture

| Objectif | Solution |
| --- | --- |
| Supprimer les SPOF | Cluster 3 noeuds + NAS HA |
| Sécuriser le périmètre | Pare-feu homogènes + VPN renforcés |
| Garantir la VoIP | QoS configurée et documentée |
| Préparer le PRA | Landing Zone Azure + DC cloud |
| Simplifier l'exploitation | Gestion centralisée, supervision unifiée |

---

## Sécurité & Réseau

### Pare-feu homogènes

| Site | Équipement actuel | Équipement cible |
| --- | --- | --- |
| Siège Lille | FortiGate 80D (EOL) | FortiGate 100F |
| WH1 Lens | DrayTek 2860 | FortiGate 60F |
| WH2 Valenciennes | DrayTek 2860 | FortiGate 60F |
| WH3 Arras | DrayTek 2860 | FortiGate 60F |
| Cross-dock | - | FortiGate 40F |

### VPN renforcés
- IKEv2 avec AES-256
- Dead Peer Detection (DPD)
- Failover automatique

---

## Virtualisation & HA

### Cluster 3 noeuds

| Noeud | Rôle | Specs |
| --- | --- | --- |
| Node 1 | Compute + Quorum | Dell R650xs, 256 Go RAM |
| Node 2 | Compute + Quorum | Dell R650xs, 256 Go RAM |
| Node 3 | Compute + Quorum | Dell R650xs, 256 Go RAM |

### Stockage partagé
- SAN iSCSI Dell PowerVault ME5024
- 8x SSD 1.92 To Enterprise
- Réplication vers Azure

---

## Cloud & PRA

### Landing Zone Azure

| Composant | Rôle |
| --- | --- |
| VPN Gateway | Tunnel site-à-site |
| DC-Azure | Contrôleur domaine répliqué |
| Blob Storage | Backup externalisé |
| Recovery Services | PRA automatisé |

### RTO/RPO cibles

| Service | RTO | RPO |
| --- | --- | --- |
| Active Directory | < 15 min | 0 (réplication) |
| WMS | < 1h | < 15 min |
| Téléphonie | < 30 min | N/A |
