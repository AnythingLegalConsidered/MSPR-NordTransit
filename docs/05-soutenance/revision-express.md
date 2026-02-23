---
title: "Revision Express — Soutenance MSPR"
subtitle: "NordTransit Logistics — Tout en un document"
author: "Groupe 2"
date: 2026-02-22
---

# REVISION EXPRESS — Soutenance 23/02/2026

> **Navigation soutenance** : **Revision express** · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

> Un seul document. Tout ce qu'il faut savoir pour presenter et repondre au jury.

---

## FORMAT

| Bloc | Duree | Contenu |
|------|-------|---------|
| Presentation | 15-20 min | Contexte → Archi → Demo → Migration → Conclusion |
| Demo POC | 5 min | 4 tests live sur Proxmox |
| Questions jury | 10 min | Justification des choix |

---

## 1. LE CLIENT (30 sec)

PME logistique **Hauts-de-France**, 240 employes (300 en haute saison).
5 sites : siege **Lille** + 3 entrepots (Lens, Valenciennes, Arras) + 1 cross-dock saisonnier.
65 postes, 70 telephones IP, ~20 VMs. **DSI de 4 personnes**.

WMS = coeur de metier. Si le WMS tombe, les 4 sites s'arretent (reception/expedition 5h30-18h30).

---

## 2. LES PROBLEMES — Pourquoi on modernise (2-3 min)

### 4 SPOF critiques

| SPOF | Impact |
|------|--------|
| Dell R630 **unique** | AD + WMS + VoIP dessus → panne = arret TOTAL |
| NAS RAID5 unique | Backups non testes, non externalises |
| Pas de PRA | Sinistre siege = perte totale des donnees |
| 1 lien WAN par site | Pas de backup, pas de failover |

### Securite

- FortiGate 80D **fin de vie** (plus de patches)
- DrayTek 2860 en entrepots (VPN IKEv1 faible)
- MFA seulement pour l'IT

### Manques

- Pas de QoS → VoIP degradee sous charge
- Pas de VLAN → pas d'isolation reseau
- Pas de supervision unifiee, pas de doc reseau

**3 enjeux a marteler** :
1. WMS = coeur de metier, indisponibilite = arret immediat
2. Fenetres de maintenance reduites (apres 18h30 uniquement)
3. DSI de 4 → les solutions DOIVENT etre simples

---

## 3. ARCHITECTURE CIBLE (5-6 min)

### Avant → Apres

| Element | Avant | Apres |
|---------|-------|-------|
| Firewall siege | FortiGate 80D (EOL) | **FortiGate 100F** (1 Gbps, UTM) |
| Firewall entrepots | DrayTek 2860 | **FortiGate 60F** (x3) |
| Cross-dock | Rien | **FortiGate 40F** |
| VPN | IKEv1 minimal | **IKEv2 AES-256-GCM**, hub-and-spoke |
| Serveurs | Dell R630 unique | **2x Dell R650xs** (cluster HA) |
| Stockage | NAS RAID5 | **SAN ME5012** (8x SSD, iSCSI) |
| AD | 1 DC au siege | **3 DCs** (siege x2 + Azure) |
| PRA | Aucun | **Azure** (Site Recovery + DC replique) |
| QoS | Aucune | **4 VLANs** avec priorites |

### 4 VLANs

| VLAN | Usage | DSCP | BP |
|------|-------|------|----|
| 10 MGMT | Admin | CS2 | 5% |
| 20 SERVEURS | VMs, SAN | AF31 | 40% |
| 30 DATA | Postes | BE | Best effort |
| **40 VOIP** | **Telephones** | **EF (46)** | **30% min** |

### Haute Disponibilite

- 2 noeuds R650xs (256 Go RAM chacun, cluster HA)
- SAN ME5012 (8x SSD 1.92 To, iSCSI)
- **Cloud Witness Azure** = 3eme vote quorum (remplace un 3eme noeud physique, economie 15k)

### RTO / RPO

| Service | RTO | RPO | Mecanisme |
|---------|-----|-----|-----------|
| AD | < 15 min | 0 | Replication temps reel DC-Azure |
| WMS | < 1h | < 15 min | Azure Site Recovery |
| VoIP | < 30 min | N/A | Redemarrage VM noeud sain |

---

## 4. BUDGET — 137 301 EUR / 150k max (1-2 min)

| Poste | Montant |
|-------|---------|
| Securite (5x FortiGate + licences 3 ans) | 17 520 |
| Virtualisation (2x R650xs + ProSupport) | 30 000 |
| Stockage (SAN ME5012) | 20 000 |
| Reseau (4x Cisco C9200-24P) | 12 000 |
| Azure PRA (3 ans, Reserved -40%) | 11 232 |
| Supervision (PRTG + Veeam, 3 ans) | 7 500 |
| Internet (1ere annee) | 12 840 |
| Main d'oeuvre | 8 300 |
| Imprevus 15% | 17 909 |
| **TOTAL** | **137 301 EUR** |

OPEX/an : ~19 340 EUR | TCO 3 ans : ~175 680 EUR | Marge restante : 12 699 EUR

---

## 5. MIGRATION — 6 phases, 6 semaines (1 min)

| Phase | Quoi | Duree | Rollback |
|-------|------|-------|----------|
| M1 | Pare-feu (DrayTek → FortiGate) | 5 nuits S1-S2 | Rebrancher DrayTek (15 min) |
| M2 | Cluster (2x R650xs + SAN) | 1 WE + 2j S2-S3 | Nouveau matos, pas d'impact |
| M3 | Migration VMs (~20 du R630) | 2 nuits WE S3 | Snapshot + restore (30 min) |
| M4 | Azure (VPN + DC + Site Recovery) | 3 jours S4 | Nouveau, pas migration |
| M5 | QoS + VLAN (segmentation) | 3 nuits S5 | Desactiver VLAN (20 min) |
| M6 | Tests validation | 1 WE S6 | Validation, pas modification |

**Logique** : du moins critique au plus critique. Cross-dock d'abord, siege en dernier.
**Seuil d'abandon** : 03h00 (marge 2h30 avant ouverture 5h30).

---

## 6. DEMO LIVE — 4 tests (5 min)

> Toutes les commandes ci-dessous sont depuis **pve02** (`ssh pve02`).

### Connexion

```bash
ssh pve02
for vmid in 32001 32005 32010 32011 32012 32020 32030; do qm start $vmid 2>/dev/null; done
```
Attendre 3-5 min. Pret quand ca repond :
```bash
sshpass -p 'az4826QS6284**' ssh -o StrictHostKeyChecking=no Administrator@172.16.132.10 "echo ok"
```

### Test 1 — QoS VoIP (90s)

**Terminal 1** (reste ouvert) :
```bash
iperf3 -s -B 172.16.132.254 -p 5201
```
**Terminal 2** :
```bash
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M" &
ssh wmsadmin@172.16.132.20 "ping -c 30 -i 0.2 172.16.132.30"
```

**Dire** : "On sature le reseau a 500 Mbps. La latence VoIP reste a 0.1 ms grace a la QoS — priorite 7."
**Resultat attendu** : latence ~0.16ms, 0% perte. Ctrl+C dans le terminal 1 quand fini.

### Test 2 — Failover AD (90s)

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
qm stop 32010
```
Attendre 30s. **Dire** : "DC01 vient de tomber. DC02 doit prendre le relais automatiquement."
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
qm start 32010
```

### Test 3 — Failover WMS (60s)

```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
qm stop 32020 && sleep 2 && qm start 32020
```
Attendre 45s. **Dire** : "Coupure de courant simulee. MySQL doit survivre sans perte."
```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
```
Memes 5 lignes, memes timestamps.

### Test 4 — Tunnel Azure (30s)

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "ping -n 4 10.100.0.10"
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "ping -n 4 172.16.132.10"
```
**Dire** : "Communication bidirectionnelle siege-Azure. En prod, c'est du IPsec IKEv2."

### Si ca plante

| Probleme | Fix |
|----------|-----|
| SSH refuse | Attendre 2 min (Windows est lent) |
| iperf3 "address in use" | `pkill iperf3` sur pve02 |
| nltest toujours DC01 | Attendre 30s de plus |
| Rien ne marche | Montrer `docs/05-soutenance/images/captures-poc-2026-02-22.txt` |

---

## 7. TOP 20 QUESTIONS JURY

| # | Question | Reponse |
|---|----------|---------|
| 1 | **Pourquoi 2 noeuds pas 3 ?** | Economie 15k, Azure = PRA geo, Cloud Witness = quorum |
| 2 | **Pourquoi FortiGate ?** | Prix PME, support FR, gestion centralisee, IKEv2 natif |
| 3 | **RTO/RPO ?** | AD < 15min/0, WMS < 1h/15min, VoIP < 30min |
| 4 | **Budget realiste ?** | 137k < 150k, marge 15%, prix revendeurs entreprise |
| 5 | **Routes statiques ≠ vrai IPsec ?** | Valide la connectivite, config IPsec documentee, tunnel = encapsulation sans changer le routage |
| 6 | **0.1ms c'est du LAN** | Oui, en prod avec IPsec : 6-18ms, toujours << 150ms ITU-T G.114 |
| 7 | **5 records c'est rien** | Valide le mecanisme crash+integrite, load testing = moyen terme |
| 8 | **pfSense ≠ FortiGate** | POC valide concepts, pas produits. Memes fonctions testees |
| 9 | **Si le siege brule ?** | DC-Azure maintient AD, Site Recovery bascule VMs, Veeam sur Blob |
| 10 | **DSI de 4, admin malade ?** | Doc complete, FortiCare support inclus, flotte homogene = 1 competence |
| 11 | **Split-brain cluster ?** | Cloud Witness Azure = 3eme vote, evite le split-brain |
| 12 | **IPBX centralise, WAN tombe ?** | Pas de VoIP en entrepot = limite assumee. Future : SIP proxy local ou Teams Phone |
| 13 | **Pourquoi Azure pas AWS ?** | Client deja sur M365/Entra ID, integration native AD Connect + Site Recovery |
| 14 | **MDP en clair dans le lab ?** | Lab = reproductibilite, prod = vault (KeePass), rotation, certificats X.509 |
| 15 | **Ansible pas pour pfSense/Windows ?** | pfSense = XML (pas de module), Windows AD = PowerShell b64, rapport effort/benefice |
| 16 | **Ransomware chiffre DC01+DC02 ?** | DC-Azure a copie complete, seize FSMO, condition : Azure non compromis |
| 17 | **VLAN VoIP assez large ?** | 70 tel / 4 sites ≈ 17/site, siege en /26 = 62 hotes, marge OK |
| 18 | **Point le plus faible ?** | Telephonie centralisee sans survivability en entrepot |
| 19 | **Si 300k de budget ?** | Cluster 3 noeuds, 100F partout, WAN 2 FAI, PRA multi-region, SIEM |
| 20 | **Ce que le projet vous a apporte ?** | Reponse PERSONNELLE : conception multi-site, VPN, AD, QoS, budget, approche POC |

---

## PHRASES CLES

- "On passe de **tout peut tomber** a **tout est redondant**"
- "Chaque choix technique repond a un **probleme concret** de l'audit"
- "Le POC valide les **concepts**, pas les produits — principes identiques en production"
- "Budget respecte : **137k sur 150k**, avec 15% de marge"
- "Architecture pensee pour une **DSI de 4** — simple a exploiter"

---

## LIMITES DU POC (anticiper le jury)

- QoS testee avec ICMP, pas un vrai appel VoIP
- Routes statiques au lieu de vrai IPsec (config IPsec documentee)
- Cluster physique non simulable sur 1 Proxmox
- BDD 5 records (pas volume realiste)
- pfSense ≠ FortiGate (memes concepts, interface differente)
