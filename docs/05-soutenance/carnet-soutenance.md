# CARNET SOUTENANCE — NordTransit Logistics

> **Navigation soutenance** : [**Revision express**](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · **Carnet** · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

> Condense complet a recopier sur carnet. Tout ce qu'il faut savoir.

---

## LE CLIENT

- PME logistique Hauts-de-France, 240 employes (300 haute saison)
- 5 sites : siege Lille + 3 entrepots (Lens, Valenciennes, Arras) + 1 cross-dock saisonnier
- 65 postes, 70 telephones IP, ~20 VMs
- DSI de 4 personnes
- WMS = coeur de metier, horaires 5h30-18h30

---

## PROBLEMES ACTUELS (pourquoi on modernise)

**4 SPOF critiques :**
1. Un seul serveur Dell R630 → panne = TOUT tombe (AD, WMS, VoIP)
2. NAS RAID5 unique → backups non testes, non externalises
3. Pas de PRA → sinistre siege = perte totale
4. Liens WAN sans redondance → 1 lien par site

**Securite :**
- FortiGate 80D en fin de vie (plus de patches)
- DrayTek 2860 en entrepots (VPN IKEv1 faible)
- MFA seulement pour l'IT, pas les utilisateurs

**Manques :**
- Pas de QoS → VoIP degradee sous charge
- Pas de VLAN → pas d'isolation reseau
- Pas de supervision unifiee
- Pas de documentation reseau

---

## ARCHITECTURE CIBLE

**Pare-feu :**
- Siege : FortiGate 100F (hub VPN, UTM, 1 Gbps)
- 3 entrepots : FortiGate 60F
- Cross-dock : FortiGate 40F

**VPN :** IKEv2 AES-256-GCM, DPD, PFS DH Group 14, hub-and-spoke

**4 VLANs :**
- VLAN 10 MGMT — admin (DSCP CS2, 5%)
- VLAN 20 SERVEURS — VMs, SAN (DSCP AF31, 40%)
- VLAN 30 DATA — postes (best effort)
- VLAN 40 VOIP — telephones (DSCP EF, 30% min)

**Haute dispo :**
- 2x Dell R650xs (256 Go RAM, cluster HA)
- SAN PowerVault ME5012 (8x SSD 1.92 To, iSCSI)
- Cloud Witness Azure (3eme vote quorum)
- Pourquoi 2 noeuds pas 3 : economie 15k, Azure = PRA geo

**AD multi-site :**
- DC01 siege : DC principal
- DC02 siege : DC secondaire, failover immediat
- DC-Azure : replique cloud, PRA geographique

**PRA Azure :**

| Service | RTO | RPO | Mecanisme |
|---------|-----|-----|-----------|
| AD | < 15 min | 0 | Replication temps reel |
| WMS | < 1h | < 15 min | Azure Site Recovery |
| VoIP | < 30 min | N/A | Redemarrage VM noeud sain |

---

## BUDGET — 137 301 EUR / 150k max

| Poste | Montant |
|-------|---------|
| 5x FortiGate + licences 3 ans | 17 520 |
| 2x Dell R650xs + ProSupport | 30 000 |
| SAN ME5012 | 20 000 |
| 4x Cisco C9200-24P | 12 000 |
| Azure PRA 3 ans (Reserved -40%) | 11 232 |
| PRTG + Veeam 3 ans | 7 500 |
| Internet 1ere annee | 12 840 |
| Main d'oeuvre | 8 300 |
| Imprevus 15% | 17 909 |

OPEX/an : ~19 340 | TCO 3 ans : ~175 680

---

## MIGRATION — 6 phases, 6 semaines

| Phase | Quoi | Duree | Rollback |
|-------|------|-------|----------|
| M1 | Pare-feu (DrayTek → FortiGate) | 5 nuits S1-S2 | Rebrancher DrayTek (15 min) |
| M2 | Cluster (2x R650xs + SAN) | 1 WE + 2j S2-S3 | Nouveau matos, pas d'impact |
| M3 | Migration VMs (~20 VMs du R630) | 2 nuits WE S3 | Snapshot + restore (30 min) |
| M4 | Azure (VPN + DC + Site Recovery) | 3 jours S4 | Nouveau, pas migration |
| M5 | QoS + VLAN (segmentation) | 3 nuits S5 | Desactiver VLAN (20 min) |
| M6 | Tests validation | 1 WE S6 | Validation, pas modification |

Logique : du moins critique au plus critique.
Cross-dock d'abord pour roder, siege en dernier.
Seuil d'abandon : 03h00 (marge 2h30 avant ouverture 5h30).

---

## POC — 4 tests, 4/4 PASS

**7 VMs sur Proxmox :**

| VM | OS | IP | Role |
|----|----|----|------|
| FW-SIEGE | pfSense | 172.16.132.1 | Firewall + QoS |
| FW-AZURE | pfSense | 10.100.0.1 | Cote Azure |
| DC01 | Win Server 2022 | 172.16.132.10 | AD principal |
| DC02 | Win Server 2022 | 172.16.132.11 | AD secondaire |
| DC-AZURE | Win Server 2022 | 10.100.0.10 | DC cloud |
| WMS | Ubuntu 22.04 | 172.16.132.20 | Simulation WMS |
| IPBX | FreePBX | 172.16.132.30 | Telephonie VoIP |

**Resultats :**

| Test | Ce qu'on prouve | Resultat |
|------|-----------------|----------|
| QoS VoIP | VoIP stable sous 500 Mbps | 0.1 ms latence, 0% perte |
| Failover AD | DC02 prend le relais | Bascule < 30s, DNS+Auth OK |
| Failover WMS | BDD survit crash | Reboot 20s, 5/5 records |
| Tunnel Azure | Siege ↔ Azure | Ping+DNS+Replication OK |

**Limites du POC (le jury va demander) :**
- QoS testee avec ping, pas un vrai appel VoIP
- Routes statiques, pas vrai IPsec (config documentee)
- Cluster physique non simulable sur 1 Proxmox
- BDD de test = 5 records (pas volume realiste)
- pfSense ≠ FortiGate (memes concepts, pas meme produit)

---

## REPONSES AUX PIEGES JURY

**"Routes statiques ≠ vrai IPsec"**
→ Valide la connectivite. Config IPsec documentee. Le tunnel ajouterait de l'encapsulation sans changer les resultats de routage.

**"0.1 ms c'est du LAN"**
→ Oui. En prod avec IPsec : 6-18 ms. Toujours << 150 ms (seuil ITU-T G.114).

**"5 records c'est rien"**
→ Valide le mecanisme crash+integrite. Load testing = recommandation moyen terme.

**"pfSense ≠ FortiGate"**
→ POC valide les concepts (routage, QoS, VPN), pas les produits.

**"Pourquoi 2 noeuds pas 3 ?"**
→ Economie 15k. Azure = PRA geo. Cloud Witness = 3eme vote quorum.

**"Si le siege brule ?"**
→ DC-Azure maintient AD. Site Recovery bascule VMs. Veeam sur Blob Storage.

**"Split-brain cluster ?"**
→ Cloud Witness Azure = 3eme vote, empeche le split-brain.

**"Point le plus faible ?"**
→ IPBX centralise au siege. Pas de survivability en entrepot. Solution future : SIP proxy local ou Teams Phone.

**"Si 300k de budget ?"**
→ Cluster 3 noeuds, FortiGate 100F partout, WAN redondant 2 FAI, PRA multi-region, SIEM.

**"Pourquoi Azure pas AWS/OVH ?"**
→ Client deja sur M365/Entra ID. Integration native AD Connect + Site Recovery.

**"DSI de 4, si l'admin est malade ?"**
→ Doc complete, FortiCare support inclus, flotte homogene = 1 competence a maitriser.

**"Ransomware chiffre DC01+DC02 ?"**
→ DC-Azure a copie complete. Seize FSMO, nettoyer metadata. Condition : Azure non compromis.

---

## PHRASES CLES

- "On passe de TOUT PEUT TOMBER a TOUT EST REDONDANT"
- "Chaque choix technique repond a un probleme concret identifie dans l'audit"
- "Le POC valide les CONCEPTS, pas les produits — les principes sont identiques en production"
- "Budget respecte : 137k sur 150k, avec 15% de marge imprevus"
- "Architecture pensee pour une DSI de 4 personnes — simple a exploiter"
