---
title: "Fiche Reference Jour J"
subtitle: "MSPR - NordTransit Logistics"
date: 2026-02-23
---

# Fiche Reference Jour J

> **Navigation soutenance** : [Revision express](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · **Fiche Ref**

> **Document a garder ouvert sur le PC pendant la soutenance.**
> Ctrl+F pour trouver n'importe quel detail en 2 secondes.

---

## 1. Justifications techniques

### Pourquoi FortiGate (vs Palo Alto, Sophos, pfSense)

| Critere | FortiGate | Palo Alto | Sophos | pfSense |
|---------|-----------|-----------|--------|---------|
| Prix 60F/equiv. | ~440 EUR | ~2 500 EUR | ~800 EUR | Gratuit |
| Gestion centralisee | FortiManager | Panorama | Central | Non |
| VPN IKEv2 natif | Oui | Oui | Limite | Oui |
| QoS integree | Oui (DSCP) | Oui | Basique | Oui (PRIQ) |
| Support entreprise FR | Oui (FortiCare) | Oui mais cher | Oui | Non |
| UTM complet | IPS+AV+WebFilter | Oui | Oui | Non |

**Argument cle** : meilleur rapport qualite/prix PME. Le 100F au siege (2 800 EUR) gere 5 tunnels VPN + UTM + QoS. Palo Alto equivalent = 2-3x plus cher. pfSense n'a pas de support entreprise ni de gestion centralisee multi-sites.

### Pourquoi 2 noeuds (vs 3 noeuds)

| | 2 noeuds + Cloud Witness | 3 noeuds |
|---|---|---|
| Cout | 30 000 EUR | ~45 000 EUR (+15k) |
| Quorum | Cloud Witness Azure (3eme vote) | 3eme noeud physique |
| Split-brain | Resolu par le witness cloud | Resolu nativement |
| PRA geo | Azure Site Recovery quand meme | Idem |

**Argument** : un 3eme noeud depasserait le plafond de 150k. Pour ~20 VMs et 240 employes, 2 noeuds suffisent. Le Cloud Witness Azure coute < 1 EUR/mois.

### Pourquoi Azure (vs AWS, OVH)

- NordTransit utilise **deja M365 + Entra ID** → synergie ecosysteme Microsoft
- **AD Connect** : sync on-prem ↔ cloud natif
- **Azure Site Recovery** : replication Hyper-V/VMware native, pas d'agent tiers
- **Blob Storage** : destination Veeam native
- AWS n'a pas d'equivalent natif pour AD on-prem. OVH n'a pas de service PRA automatise comparable.

### Pourquoi SAN iSCSI (vs NAS)

- SAN = stockage **bloc** (iSCSI/FC), requis pour le **failover cluster** (les 2 noeuds accedent au meme stockage)
- NAS = stockage **fichier** (NFS/SMB), ne supporte pas le live migration de VMs
- PowerVault ME5012 : 8x SSD 1.92 To, RAID 10 recommande, capacite brute 15.36 To

### Pourquoi IKEv2 (vs IKEv1)

| | IKEv2 | IKEv1 |
|---|---|---|
| Echanges pour etablir | 4 messages | 9 messages (Main Mode) |
| DPD | Integre nativement | Extension optionnelle |
| MOBIKE | Oui (changement IP sans coupure) | Non |
| NAT Traversal | Natif | Extension |
| Chiffrement | AES-256-GCM (AEAD) | AES-256-CBC + HMAC |

**GCM** = Galois/Counter Mode = chiffre ET authentifie en une seule operation, parallelisable, hardware-accelerated, pas de padding oracle attack.

---

## 2. Budget detaille

### CAPEX ligne par ligne

| Poste | Unite | Qte | PU | Total |
|-------|-------|-----|-----|-------|
| FortiGate 100F (siege) | 1 | 1 | 2 800 | 2 800 |
| FortiGate 60F (entrepots) | 1 | 3 | 440 | 1 320 |
| FortiGate 40F (cross-dock) | 1 | 1 | 400 | 400 |
| FortiCare/FortiGuard 3 ans | 1 | 5 | 2 600 | 13 000 |
| **Sous-total Securite** | | | | **17 520** |
| Dell R650xs 256 Go RAM | 1 | 2 | 13 000 | 26 000 |
| ProSupport Dell 3 ans | 1 | 2 | 2 000 | 4 000 |
| **Sous-total Virtualisation** | | | | **30 000** |
| PowerVault ME5012 8x SSD | 1 | 1 | 17 500 | 17 500 |
| Maintenance SAN 3 ans | 1 | 1 | 2 500 | 2 500 |
| **Sous-total Stockage** | | | | **20 000** |
| Cisco C9200-24P PoE | 1 | 4 | 2 500 | 10 000 |
| SmartNet Cisco 3 ans | 1 | 4 | 500 | 2 000 |
| **Sous-total Reseau** | | | | **12 000** |
| Azure Site Recovery 20 VMs | mois | 36 | 460 | 16 560 |
| Stockage replica HDD | Go/mois | 36 | 10 | 360 |
| Snapshots + Egress | mois | 36 | 50 | 1 800 |
| Reduction Reserved 3 ans | | | | -7 488 |
| **Sous-total Azure PRA** | | | | **11 232** |
| PRTG 500 sensors | an | 3 | 1 500 | 4 500 |
| Veeam Backup Essentials | an | 3 | 1 000 | 3 000 |
| **Sous-total Supervision** | | | | **7 500** |
| Fibre 1 Gbps siege (2 FAI) | mois | 12 | 400 | 4 800 |
| Fibre 500 Mbps entrepots | mois | 12 | 360 | 4 320 |
| Routeurs 4G/5G backup | 1 | 3 | 400 | 1 200 |
| Forfaits 4G/5G | mois | 12 | 210 | 2 520 |
| **Sous-total Internet** | | | | **12 840** |
| Architecte/Lead (20h) | h | 20 | 115 | 2 300 |
| Experts Infra (4 x 20h) | h | 80 | 75 | 6 000 |
| **Sous-total Main d'oeuvre** | | | | **8 300** |

### Synthese

| | Montant |
|---|---------|
| Sous-total CAPEX | 119 392 EUR |
| Imprevus 15% | 17 909 EUR |
| **TOTAL PROJET** | **137 301 EUR** |
| Plafond budget | 150 000 EUR |
| **Marge disponible** | **12 699 EUR** |

### OPEX annuel

| Poste | Cout/an |
|-------|---------|
| Azure Site Recovery (20 VMs) | ~4 000 |
| Connectivite Internet (siege + 3 entrepots + 4G) | ~12 840 |
| Supervision (PRTG + Veeam) | ~2 500 |
| **TOTAL OPEX** | **~19 340 EUR/an** |

### TCO 3 ans

| Element | Montant |
|---------|---------|
| CAPEX initial | ~137 000 |
| OPEX annee 2 | ~19 340 |
| OPEX annee 3 | ~19 340 |
| **TCO 3 ans** | **~175 680 EUR** |

> La 1ere annee d'OPEX est incluse dans le CAPEX (connectivite, licences).

---

## 3. Reseau et securite

### Adressage VLAN complet

**Siege Lille (192.168.10.0/24)** :

| VLAN | Reseau | Gateway | DHCP | DSCP | Hotes |
|------|--------|---------|------|------|-------|
| 10 MGMT | 192.168.10.0/26 | .1 | Statique | CS2 (16) | 62 |
| 20 SERVEURS | 192.168.10.64/26 | .65 | Statique | AF31 (26) | 62 |
| 30 DATA | 192.168.10.128/26 | .129 | .130-.190 | BE (0) | 62 |
| 40 VOIP | 192.168.10.192/26 | .193 | .194-.250 | EF (46) | 62 |

**Entrepots** :

| Site | MGMT | DATA | VOIP |
|------|------|------|------|
| WH1 Lens | 192.168.20.0/27 (30h) | 192.168.20.32/25 (126h) | 192.168.20.160/27 (30h) |
| WH2 Valenciennes | 192.168.30.0/27 | 192.168.30.32/25 | 192.168.30.160/27 |
| WH3 Arras | 192.168.40.0/27 | 192.168.40.32/25 | 192.168.40.160/27 |

**Autres** : Cross-dock = 192.168.50.0/24 (flat). Azure Hub = 10.100.0.0/24. Azure Backup = 10.100.1.0/24.

Schema adressage : **3eme octet = identifiant site** (.10 siege, .20 WH1, .30 WH2, .40 WH3, .50 CDK). Aucun chevauchement.

### QoS — Configuration PRIQ

| Queue | Priorite | DSCP | BP garantie | Trafic |
|-------|----------|------|-------------|--------|
| qVoIP | 7 (max) | EF (46) | 30% | SIP 5060 + RTP 10000-20000 |
| qServers | 5 | AF31 (26) | 40% | Trafic serveurs |
| qDefault | 1 (min) | BE (0) | Best effort | Tout le reste |

7 floating rules sur pfSense/FortiGate : matchent sur ports SIP/RTP + IP serveurs. PRIQ = Priority Queuing (la queue la plus haute passe en premier, toujours).

### Regles firewall inter-VLAN

| Source | Destination | Action | Pourquoi |
|--------|-------------|--------|----------|
| VOIP (40) | SERVEURS (20) | Autorise | SIP vers IPBX |
| DATA (30) | SERVEURS (20) | Autorise | Acces WMS, AD, fichiers |
| DATA (30) | VOIP (40) | **Refuse** | Isolation telephonie |
| MGMT (10) | Tout | Autorise | Administration |
| Tout | MGMT (10) | **Refuse** | Protection plan de gestion |
| Tout | Internet | Autorise (NAT) | Acces web filtre UTM |

Routage inter-VLAN = **router-on-a-stick** via le FortiGate (gateway de chaque VLAN). Le 100F supporte largement le debit.

### MFA — Plan de deploiement

| Phase | Acces | Solution | Etat actuel |
|-------|-------|----------|-------------|
| 1 | VPN distant + Admin FortiGate | FortiToken (TOTP) | Non → Oui |
| 2 | RDP serveurs | Azure MFA (Entra ID) | Partiel → Complet |
| 3 | Console Proxmox | TOTP | Non → Oui |

MFA bloque **99.9%** des attaques par vol de credentials (source Microsoft). FIDO2 envisageable en phase 2 (plus cher).

### VPN IKEv2 — Specs detaillees

| Parametre | Valeur |
|-----------|--------|
| Phase 1 | IKEv2, AES-256-GCM, DH Group 14 (2048-bit) |
| Phase 2 | ESP, AES-256-GCM, PFS DH Group 14 |
| DPD | Keepalive 10s, 3 retries, timeout 30s |
| Authentification | PSK (lab) → Certificats X.509 (prod) |
| Topology | Hub-and-spoke (siege = hub, 5 tunnels) |
| Failover WAN | 4G/5G automatique sur entrepots |

PFS (Perfect Forward Secrecy) : meme si la PSK est compromise, les sessions passees restent protegees (clef de session ephemere).

---

## 4. Haute disponibilite

### Sequence de failover cluster

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Heartbeat perdu entre les 2 noeuds | 0s |
| 2 | Noeud survivant interroge le Cloud Witness Azure | ~5s |
| 3 | Quorum confirme (2/3 votes : noeud + witness) | ~10s |
| 4 | VMs du noeud tombe sont redemarrees sur le survivant | 1-3 min |
| 5 | Clients reconnectent (AD, WMS) | ~30s |
| 6 | Alerte PRTG envoyee a l'equipe DSI | ~1 min |
| 7 | Noeud repare, VMs re-equilibrees (live migration) | Manuel |

**RTO total** : < 5 min pour une panne noeud.

### RTO / RPO avec justifications

| Service | RTO | RPO | Mecanisme | Pourquoi ce chiffre |
|---------|-----|-----|-----------|---------------------|
| AD | < 15 min | 0 | DC replique Azure, temps reel | Replication AD = temps reel, DC-Azure = Global Catalog |
| WMS | < 1h | < 15 min | Azure Site Recovery | ASR replique toutes les 15 min. 1h = temps de boot VMs dans Azure |
| VoIP | < 30 min | N/A | Redemarrage VM noeud sain | IPBX = VM, pas d'etat persistant a sauvegarder |

### Azure Site Recovery — Mecanisme

1. Agent ASR installe sur chaque VM (20 VMs)
2. Replication incrementale toutes les 15 min vers Azure
3. En cas de sinistre : **failover** = les VMs demarrent dans Azure (meme IPs, reconfiguration DNS automatique)
4. Les entrepots se reconnectent via le VPN Gateway Azure (tunnel deja en place)
5. **Failback** quand le siege est repare : replication inverse, basculement retour

### Scenario "Siege brule" — Recovery complet

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | DC-Azure maintient l'AD (deja actif, replication temps reel) | Immediat |
| 2 | Declenchement ASR : 20 VMs demarrent dans Azure | < 1h |
| 3 | Entrepots basculent automatiquement sur le VPN Gateway Azure | ~5 min |
| 4 | WMS operationnel depuis Azure | < 1h |
| 5 | Backups Veeam sur Blob Storage = restauration complete si besoin | Variable |
| 6 | Reconstitution siege physique (nouveau materiel) | Semaines |

**Sans l'architecture cible** (etat actuel) : perte totale, pas de PRA, delai indefini.

---

## 5. Migration — Risques et rollback

### 6 phases en 6 semaines

| Phase | Quoi | Duree | Creneau | Rollback |
|-------|------|-------|---------|----------|
| M1 | Pare-feu FortiGate (5 sites, 1/nuit) | 5 nuits | 19h-04h | Rebrancher ancien DrayTek (15 min) |
| M2 | Cluster 2 noeuds + SAN | 1 WE + 2j | Journee | R630 reste actif (immediat) |
| M3 | Migration ~20 VMs du R630 → cluster | 2 nuits WE | 18h30-05h | Restaurer snapshot R630 (30 min) |
| M4 | Azure (VPN + DC + Site Recovery) | 3 jours | Journee | Couper tunnel VPN (5 min) |
| M5 | VLAN + QoS sur tous les sites | 3 nuits | 19h-04h | Desactiver VLANs (20 min) |
| M6 | Tests validation + PRA + formation | 1 WE | 18h30-05h | N/A (tests uniquement) |

### Matrice de risques critiques

| Risque | Phase | Prob. | Impact | Mitigation |
|--------|-------|-------|--------|------------|
| Tunnel VPN ne monte pas | M1 | Moyenne | Haut | Config DrayTek de secours prete, basculer en 15 min |
| Echec migration WMS | M3 | Moyenne | Critique | Snapshot pre-migration, R630 en standby 72h |
| Migration depasse la fenetre | M3 | Moyenne | Haut | Seuil d'abandon 03h00, 2h30 de marge avant 5h30 |
| Terminaux RF hors VLAN | M5 | Moyenne | Haut | Tester terminaux RF en premier, port dedie |
| PRA Azure echoue | M6 | Faible | Haut | Tester sur VM non critique d'abord |

### Seuil d'abandon : pourquoi 03h00

- Operations logistiques reprennent a **5h30**
- Rollback le plus long = **30 min** (restaurer snapshot VM sur R630)
- Marge de securite = **2h** (tests + verification + imprevus)
- 5h30 - 30 min - 2h = **03h00** → dernier moment pour decider

### Ordre de migration des sites

Du moins critique au plus critique : **Cross-dock** (saisonnier) → **WH3 Arras** → **WH2 Valenciennes** → **WH1 Lens** → **Siege** (hub VPN, toutes les VMs). Si on rate le cross-dock = zero impact. Si on rate le siege = arret total.

---

## 6. VoIP technique

### Seuils ITU-T G.114

| Metrique | Seuil acceptable | Seuil critique | Resultat POC | Marge |
|----------|-------------------|----------------|--------------|-------|
| Latence (one-way) | < 150 ms | > 300 ms | **0.1 ms** | x1500 |
| Gigue (jitter) | < 30 ms | > 50 ms | **0.04 ms** | x750 |
| Perte de paquets | < 1% | > 3% | **0%** | OK |
| MOS (qualite voix) | > 4.0 | < 3.5 | Non mesure | - |

### Inference production (avec IPsec)

| Composant | Latence ajoutee |
|-----------|-----------------|
| Fibre regionale Hauts-de-France | 5-15 ms |
| Overhead IPsec AES-256-GCM | 1-3 ms |
| **Total estime** | **6-18 ms** |
| Seuil ITU-T | 150 ms |
| **Marge** | **8x-25x sous le seuil** |

Gigue estimee en production : 5-10 ms (toujours << 30 ms).

### Codecs VoIP

| Codec | Debit | Qualite | Usage |
|-------|-------|---------|-------|
| G.711 (alaw/ulaw) | 64 kbps/appel | Excellente | LAN, bande passante suffisante |
| G.729 | 8 kbps/appel | Bonne | WAN, bande passante limitee |

### Commandes diagnostic N2

```bash
# Etat des extensions SIP (FreePBX)
asterisk -rx "pjsip show endpoints"

# Appels en cours
asterisk -rx "core show channels"

# Statistique QoS (pfSense/FortiGate)
pfctl -s queue

# Test saturation + latence
iperf3 -c <IP_GW> -t 15 -b 500M    # saturer
ping -c 50 -i 0.2 <IP_IPBX>        # mesurer

# SIP debug
asterisk -rx "pjsip set logger on"
```

### Architecture VoIP

| Composant | Detail |
|-----------|--------|
| IPBX | FreePBX 16 / Asterisk 18 (siege Lille, IP 172.16.132.30) |
| Protocole | PJSIP (remplace chan_sip deprecie depuis Asterisk 17) |
| Telephones | ~70 Cisco IP sur 4 sites |
| VLAN | VLAN 40 dedie, DSCP EF (46), priorite 7 |
| Ports | SIP 5060/UDP, RTP 10000-20000/UDP |
| Provisioning | CDP/LLDP-MED : switch annonce VLAN voix au telephone |
| Config Cisco | `switchport voice vlan 40` |

**Limite connue** : IPBX centralise, pas de survivability entrepot. Si WAN tombe = plus de telephonie. Solution future : SBC/proxy SIP local ou Teams Phone.

---

## 7. Top 20 questions — Reponses developpees

### Q1 : "Routes statiques dans le lab, c'est pas du vrai IPsec"

**Bonne reponse** : Le POC valide la **connectivite cross-site** (ping, DNS, replication AD entre DC01 et DC-AZURE). L'IPsec ajoute une couche de chiffrement mais ne change pas les resultats fonctionnels. La configuration IPsec pfSense est documentee et prete dans `vpn-ipsec.md`. C'est un choix **pragmatique** : automatiser ce qui est rentable, documenter le reste.

**Reponse faible a eviter** : "On n'a pas eu le temps."

### Q2 : "0.1ms de latence, c'est du LAN, pas representatif"

**Bonne reponse** : Exact, c'est du LAN local (meme bridge Proxmox). En production avec fibre regionale + IPsec : 6-18 ms. C'est **8 a 25 fois** sous le seuil ITU-T de 150 ms. La gigue passera de 0.04 ms a 5-10 ms, toujours sous les 30 ms. Le test prouve que la **priorisation QoS fonctionne** (0% perte sous 500 Mbps de charge), pas la latence absolue.

**Reponse faible** : "Mais ca marche quand meme."

### Q3 : "5 records dans le WMS, c'est rien"

**Bonne reponse** : Le test valide le **mecanisme** : arret brutal (kill -9) + verification integrite MySQL apres reboot. Que ce soit 5 ou 500 000 records, le mecanisme est le meme (WAL, InnoDB crash recovery). Un load testing avec dump anonymise = recommandation moyen terme. Les 5 records prouvent que MySQL survit a un crash sans perte.

**Reponse faible** : "On a manque de temps pour mettre plus de donnees."

### Q4 : "pfSense != FortiGate, votre POC ne prouve rien"

**Bonne reponse** : Le POC valide les **concepts**, pas les produits. Les fonctions testees (routage, firewall, QoS PRIQ/DSCP, VPN) sont **equivalentes** entre pfSense et FortiGate. La difference est dans l'UTM (IPS, antivirus, web filter) et l'interface — ce qu'on ne teste pas dans le POC. Le passage en production = memes regles, interface differente.

**Reponse faible** : "pfSense fait pareil."

### Q5 : "Si le siege brule ?"

**Bonne reponse** : DC-Azure maintient l'AD (deja actif, replication temps reel, RPO = 0). Azure Site Recovery bascule les 20 VMs (RTO < 1h). Les entrepots se reconnectent via le VPN Gateway Azure. Veeam sur Blob Storage = restauration complete si besoin. **Sans notre architecture** = perte totale, pas de PRA, delai indefini.

### Q6 : "Split-brain cluster ?"

**Bonne reponse** : Cloud Witness Azure = 3eme vote dans un 3eme "site" (Azure). Si un noeud perd la connectivite avec l'autre ET le witness, il s'arrete (1/3 vote). Le split-brain est **impossible** car le witness est geographiquement separe. Cout : < 1 EUR/mois.

### Q7 : "Point le plus faible de l'architecture ?"

**Bonne reponse** : La **telephonie VoIP**. L'IPBX est centralise au siege sans survivability entrepot. Si le WAN tombe, les entrepots n'ont plus de telephonie. Solutions futures : SBC/proxy SIP local par site, ou migration vers Teams Phone. En attendant : portables + Teams via 4G backup.

### Q8 : "Si 300k EUR de budget ?"

**Bonne reponse** : Cluster **3 noeuds** (+15k), FortiGate **100F sur tous les sites** (UTM complet partout), liens WAN **redondants** (2 FAI par entrepot), PRA Azure **multi-region**, SIEM (FortiSIEM), 2eme SAN pour replication locale, **formation certifiante** DSI (NSE Fortinet, AZ-800).

### Q9 : "DSI de 4 personnes, c'est gerable ?"

**Bonne reponse** : C'est tendu mais l'architecture est pensee pour ca. **Flotte homogene** FortiGate = une seule competence a maitriser. **FortiManager** = gestion centralisee des 5 sites. **PRTG** = supervision unifiee. **Documentation complete** = ce projet. En cas d'absence : support FortiCare (contrat inclus) + procedures step-by-step.

### Q10 : "Ubuntu 20.04 du WMS est en EOL"

**Bonne reponse** : Oui, EOL avril 2025. La migration OS vers 22.04/24.04 pourrait casser des dependances (librairies, version MySQL du WMS). Ce n'est **pas dans le scope** du projet (infra, pas applicatif). Recommandation moyen terme : planifier avec l'editeur du WMS. En attendant : **ESM** (Extended Security Maintenance Ubuntu) = 5 ans de patches supplementaires.

### Q11 : "Pourquoi PRTG et pas Zabbix/Grafana ?"

**Bonne reponse** : PRTG = interface graphique intuitive, capteurs preconfigures, ideal pour une DSI de 4 personnes sans expertise Linux avancee. Zabbix = puissant mais complexe a configurer/maintenir. Grafana = dashboard de visualisation, pas un outil de supervision natif (besoin de Prometheus en backend). 500 capteurs suffisent pour 5 sites.

### Q12 : "Ransomware chiffre DC01+DC02. On fait quoi ?"

**Bonne reponse** : DC-Azure a une copie complete de l'AD (Global Catalog). Procedure : **seize** les roles FSMO sur DC-Azure (ntdsutil), nettoyer les metadata des anciens DCs. L'AD est fonctionnel. Puis reinstaller 2 DCs on-prem. **Condition critique** : DC-Azure isole par NSG Azure (pas infecte). C'est pourquoi l'isolation reseau cloud est essentielle.

### Q13 : "Entra ID suffit, pourquoi garder l'AD on-prem ?"

**Bonne reponse** : L'AD on-prem est necessaire pour : **auth locale** (pas de dependance internet), **GPO** sur les postes, **Kerberos** pour les apps internes (WMS, partages), gestion imprimantes. Entra ID seul ne supporte pas tout ca. L'**hybride** (AD on-prem + Entra ID sync) est le standard PME.

### Q14 : "Ansible automatise les VMs mais pas pfSense/Windows. Incoherent ?"

**Bonne reponse** : Choix **pragmatique**. Ansible automatise la creation des 7 VMs et le post-deploy WMS (reproductible en 1 commande). pfSense se configure via XML (pas d'API REST simple, module Ansible instable). Windows AD = promotion via PowerShell encode en base64 (complexe a industrialiser). On automatise ce qui est **rentable**, on documente le reste en guides pas-a-pas.

### Q15 : "Un camarade peut refaire le lab ? En combien de temps ?"

**Bonne reponse** : Oui, c'est l'**objectif du projet**. 8 guides numerotes (00-07), step-by-step, avec prerequis listes. Ansible automatise la creation des VMs. Compter **4-6 heures** si Proxmox est deja installe. ISOs a telecharger listees dans le guide 00. L'ordre est obligatoire et documente.

### Q16 : "Panne regionale Azure ?"

**Bonne reponse** : Le PRA est dans une seule region Azure. Si panne regionale : DC-Azure indisponible, mais les **2 DCs on-prem continuent**. ASR inoperant mais les VMs tournent au siege sur le cluster. Pour un PRA multi-region = budget plus eleve. **Risque accepte** pour une PME de cette taille.

### Q17 : "QoS : la queue qVoIP ne montre qu'1 paquet"

**Bonne reponse** : Le test utilise un **ping ICMP** vers l'IPBX (marque EF). Un vrai appel VoIP genererait des centaines de paquets RTP par seconde. Le test prouve que la **priorisation fonctionne** (0% perte, 0.1ms latence sous 500Mbps de charge). Un test avec softphones = recommandation moyen terme.

### Q18 : "Global Catalog : pourquoi tous les DCs ?"

**Bonne reponse** : Le GC contient un sous-ensemble d'attributs de TOUS les objets AD. Il est necessaire pour le **login** (groupes universels) et les recherches cross-domaine. Tous les DCs en GC = **chaque DC peut traiter les authentifications seul**, sans dependre d'un autre. Essentiel pour le failover et le PRA.

### Q19 : "Seuil d'abandon 03h00 : et si on est presque fini a 03h05 ?"

**Bonne reponse** : La regle est **stricte** : si la migration n'est pas terminee a 03h00, rollback immediat. "Presque fini" = source de depassement en cascade. Il vaut mieux **perdre 1 nuit de travail** que risquer un WMS indisponible a 5h30. On replanifie au week-end suivant avec les lecons apprises.

### Q20 : "Cle PSK VPN compromise ?"

**Bonne reponse** : Un attaquant pourrait dechiffrer le trafic VPN ou monter un faux tunnel (MITM). Mais **PFS** (Perfect Forward Secrecy) avec DH Group 14 protege les sessions passees (clef ephemere par session). Action immediate : changer la PSK sur les 2 endpoints. Solution definitive : migration vers **certificats X.509** (prevue en production).
