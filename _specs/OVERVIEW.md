# MSPR - NordTransit Logistics

> **En 30 secondes**
> NordTransit Logistics = PME logistique, 4 entrepots + 1 cross-dock saisonnier
> Leur SI est vieillissant -> on modernise infrastructure, reseau, cloud
> Ressource : 100-150k EUR | Equipe : 5 personnes | Duree : 19h de prepa

---

## Vue d'ensemble

| Information | Detail |
|---|---|
| Equipe | 5 personnes |
| Duree | 19 heures de preparation |
| Budget | 100 000 EUR - 150 000 EUR |
| Lab POC | Proxmox (VMID 32000-32100) |
| Reseau Lab | 172.16.132.0/24 |

---

## Les 3 enjeux critiques

### WMS - Warehouse Management System = COEUR DE METIER
Son indisponibilite provoque l'arret immediat des operations de reception et d'expedition sur les 4 sites entre 5h30 et 18h30

### Fenetres de maintenance tres reduites
Uniquement la nuit (apres 18h30) - Ouvertures possibles le samedi matin en haute saison

### Equipe DSI reduite : 4 personnes
1 responsable + 1 admin itinerant + 1 technicien + 1 alternant
-> Solutions simples a exploiter obligatoires

---

## Par ou commencer ?

| Tu veux... | Va sur... |
|---|---|
| Comprendre le contexte client | COMPRENDRE (analyse existant) |
| Voir ce qu'on propose | SOLUTION (architecture cible) |
| Suivre l'avancement | PROJET (jalons, taches, livrables) |
| Tester sur le lab | POC (lab Proxmox 7 VMs) |
| Conseils et astuces | RESSOURCES |

---

## Structure Notion

```
MSPR - NordTransit Logistics
|-- COMPRENDRE (analyse existant)
|   |-- Infrastructure existante
|   |-- Sites NordTransit (Lille, Lens, Valenciennes, Arras + cross-dock)
|   |-- Points de douleur (SPOF, securite, manques)
|   |-- Schemas reseau AVANT
|
|-- SOLUTION (architecture cible)
|   |-- Architecture cible (schemas APRES)
|   |-- Plan d'adressage VLAN
|   |-- Budget detaille (100-150k EUR)
|   |-- Strategie de migration
|
|-- PROJET (suivi)
|   |-- Jalons cles
|   |-- DB Livrables (Nom, Type, Statut, Date livraison)
|   |-- DB Taches (Nom, Phase, Priorite, Assigne, Statut, Duree)
|
|-- POC (lab Proxmox)
|   |-- Guide Lab Proxmox
|   |-- 7 VMs (~20 Go RAM)
|   |-- Tests : QoS VoIP, Failover AD, Failover WMS, Tunnel Azure
|
|-- RESSOURCES
```

---

## Le client : NordTransit Logistics

PME specialisee dans la logistique :
- 4 entrepots permanents (Lille, Lens, Valenciennes, Arras)
- 1 cross-dock saisonnier
- ~100 postes informatiques (sur ~240 employes)

### Problematique
Infrastructure SI vieillissante :
- Pas de redondance (materiel et internet)
- Securite insuffisante (MFA partiel)
- Pas de PRA (plan reprise activite)
- QoS non documentee pour la VoIP

---

## Architecture proposee

### Securite & Reseau
- Remplacement des DrayTek par **FortiGate** (60F/100F)
- VPN site-a-site entre tous les sites
- QoS pour priorisation VoIP
- Segmentation VLAN

### Haute disponibilite
- **Cluster 2 serveurs** Dell R650xs + SAN PowerVault ME5012
- Cluster AD (2 DC on-prem + 1 Azure)
- **PRA Azure** : replication 20 VMs via Site Recovery

### Cloud & PRA
- Landing Zone Azure
- Backup externalise
- Plan de reprise d'activite

---

## Lab POC - Architecture

```
SIEGE (172.16.132.0/24)          AZURE (10.100.0.0/24)
+---------------------+          +---------------------+
| DC01, DC02, IPBX,   |<--IPsec->| DC-AZURE            |
| WMS, FW-SIEGE       |          | FW-AZURE            |
+---------------------+          +---------------------+
```

### Inventaire VMs

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

### Criteres de succes POC

| Test | Critere |
|---|---|
| QoS VoIP | Latence < 150ms, Gigue < 30ms |
| Failover AD | DC02 repond quand DC01 tombe |
| Failover WMS | VM redemarre, donnees intactes |
| Tunnel Azure | Ping + DNS cross-site OK |

---

## Equipe

**Equipe projet MSPR** : 5 personnes (pas de roles figes -> on s'entraide sur tout !)

*Note : L'equipe DSI client NordTransit compte 4 personnes (1 responsable + 1 admin + 1 technicien + 1 alternant)*

### Repartition POC

| Personne | Responsabilites |
|---|---|
| P1 | Setup reseau + pfSense siege + DC01 |
| P2 | DC02 + replication + test failover AD |
| P3 | IPBX + QoS + test VoIP |
| P4 | Azure (FW + DC) + tunnel IPsec |
| P5 | WMS + documentation + captures |

---

## Livrables attendus

| Livrable | Type | Statut |
|---|---|---|
| Document d'architecture technique | Document | - |
| Strategie de migration | Document | - |
| Guide depannage ToIP N1/N2 | Document | - |
| Fichiers configuration VPN | Configuration | - |
| Fichiers configuration pare-feu | Configuration | - |
| Note recommandation WMS | Document | - |
| Support de presentation | Presentation | - |

**Format : Tous les livrables en PDF pour la soutenance**

---

## Phases du projet

### Phase 1 - Analyse (Priorite: Haute)
- [ ] Lire et synthetiser le sujet MSPR
- [ ] Analyser l'infrastructure existante (5 sites)
- [ ] Identifier les equipements reseau par site
- [ ] Documenter les services critiques (WMS, AD, VoIP)
- [ ] Lister les failles securite actuelles
- [ ] Creer schema reseau AVANT

### Phase 2 - Conception (Priorite: Haute)
- [ ] Definir plan d'adressage VLAN (tous sites)
- [ ] Concevoir architecture serveurs (cluster Proxmox)
- [ ] Concevoir architecture cloud (Landing Zone Azure)
- [ ] Definir politique QoS VoIP
- [ ] Concevoir tunnel VPN site-to-site
- [ ] Creer schema reseau APRES
- [ ] Estimer budget detaille

### Phase 3 - Lab/POC (Priorite: Haute)
**A - Construire le lab (2h30)**
- [ ] Deployer les 7 VMs sur Proxmox
- [ ] Configurer le reseau de base

**B - Configurer (2h)**
- [ ] Tunnel IPsec siege <-> Azure
- [ ] QoS VoIP sur pfSense
- [ ] DNS et AD (DC01, DC02, DC-AZURE)

**C - Tests de validation (1h30)**
- [ ] Test QoS VoIP (latence < 150ms, gigue < 30ms)
- [ ] Test failover AD (DC01 down -> DC02 repond)
- [ ] Test failover WMS (VM redemarre, donnees intactes)
- [ ] Test tunnel Azure (ping + DNS cross-site)

**D - Documentation (30min)**
- [ ] Captures d'ecran des tests
- [ ] Consolidation des preuves

### Phase 4 - Documentation (Priorite: Moyenne)
- [ ] Document d'architecture technique
- [ ] Strategie de migration
- [ ] Guide depannage ToIP (N1/N2)
- [ ] Fichiers de configuration reseau
- [ ] Note recommandation WMS
- [ ] Consolider les preuves POC

### Phase 5 - Soutenance (Priorite: Moyenne)
- [ ] Creer support de presentation (slides)
- [ ] Preparer demo live du POC
- [ ] Repartir les parties entre l'equipe
- [ ] Repetition generale
- [ ] Preparer reponses aux questions types

**Timing soutenance :** Presentation ~15-20 min | Demo POC ~5 min | Questions ~10 min

---

## Jalons cles

- [ ] Kick-off projet
- [ ] Architecture validee
- [ ] Lab POC operationnel
- [ ] Tests POC termines
- [ ] Documentation finale
- [ ] Repetition soutenance
- [ ] **SOUTENANCE**
