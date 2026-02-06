# Architecture cible

> Notre proposition de modernisation

---

## Objectifs de l'architecture

| Objectif | Solution |
|---|---|
| Supprimer les SPOF | Cluster 2 noeuds + SAN HA + PRA Azure |
| Securiser le perimetre | Pare-feu homogenes + VPN renforces |
| Garantir la VoIP | QoS configuree et documentee |
| Preparer le PRA | Landing Zone Azure + DC cloud |
| Simplifier l'exploitation | Gestion centralisee, supervision unifiee |

---

## Securite & Reseau

### Pare-feu homogenes

| Site | Equipement actuel | Equipement cible |
|---|---|---|
| Siege Lille | FortiGate 80D (EOL) | FortiGate 100F |
| WH1 Lens | DrayTek 2860 | FortiGate 60F |
| WH2 Valenciennes | DrayTek 2860 | FortiGate 60F |
| WH3 Arras | DrayTek 2860 | FortiGate 60F |
| Cross-dock | - | FortiGate 40F |

### VPN renforces
- IKEv2 avec AES-256
- Dead Peer Detection (DPD)
- Failover automatique

---

## Virtualisation & HA

### Cluster 2 noeuds + PRA Azure

| Noeud | Role | Specs |
|---|---|---|
| Node 1 | Compute + Quorum | Dell R650xs, 256 Go RAM |
| Node 2 | Compute + Quorum | Dell R650xs, 256 Go RAM |
| Azure (PRA) | Replication Site Recovery | 20 VMs repliquees, failover cloud |

> **Pourquoi 2 serveurs au lieu de 3 ?**
> - Economie de ~15 000 EUR sur le hardware
> - Azure Site Recovery assure le PRA geographique
> - RTO ~30 min / RPO ~15 min (acceptable pour PME)
> - Le 3eme noeud "quorum" est remplace par un temoin cloud (Azure Cloud Witness)

### Stockage partage
- SAN iSCSI Dell PowerVault ME5012
- 8x SSD 1.92 To Enterprise
- Replication vers Azure Blob Storage

---

## Cloud & PRA

### Landing Zone Azure

| Composant | Role |
|---|---|
| VPN Gateway | Tunnel site-a-site |
| DC-Azure | Controleur domaine replique |
| Blob Storage | Backup externalise |
| Recovery Services | PRA automatise |

### RTO/RPO cibles

| Service | RTO | RPO |
|---|---|---|
| Active Directory | < 15 min | 0 (replication) |
| WMS | < 1h | < 15 min |
| Telephonie | < 30 min | N/A |
