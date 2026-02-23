---
title: "Briefing Soutenance MSPR"
subtitle: "MSPR - NordTransit Logistics"
author: "Groupe 2 - PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise"
date: 2026-02-18
version: "1.0"
---

# BRIEFING SOUTENANCE MSPR — 23/02/2026

> **Navigation soutenance** : [**Revision express**](revision-express.md) · **Briefing** · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

## Format de l'epreuve

| Bloc | Duree | Contenu |
|------|-------|---------|
| Presentation | ~15-20 min | Contexte → Architecture → Demo → Migration → Conclusion |
| Demo POC | ~5 min | Lab Proxmox live (ou captures en plan B) |
| Questions jury | ~10 min | Justification des choix, technique, budget |

---

## 1. LE CLIENT — NordTransit Logistics

**Pitch 30 secondes** : PME logistique Hauts-de-France, 240 employes (300 en haute saison), 4 entrepots permanents (Lille siege, Lens, Valenciennes, Arras) + 1 cross-dock saisonnier. 65 postes, 70 telephones IP, ~20 VMs. DSI de 4 personnes.

**3 enjeux critiques a marteler** :
1. **WMS = coeur de metier** — indisponibilite = arret immediat de la reception/expedition sur les 4 sites entre 5h30-18h30
2. **Fenetres de maintenance tres reduites** — uniquement la nuit apres 18h30
3. **DSI de 4 personnes** — les solutions DOIVENT etre simples a exploiter

**Equipe projet** : PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise — 19h de preparation, budget 100-150k EUR.

---

## 2. L'EXISTANT — Pourquoi moderniser

### SPOF identifies (priorite P0)

| SPOF | Impact |
|------|--------|
| Dell R630 unique | TOUTES les VMs dessus (AD, WMS, VoIP) — panne = arret TOTAL |
| NAS RAID5 unique | Backups non testes, non externalises |
| Pas de PRA | Sinistre siege = arret total, perte donnees |
| Liens WAN sans redondance | 1 lien par site, pas de backup |

### Securite (P1)

| Faille | Detail |
|--------|--------|
| FortiGate 80D EOL | Plus de patches securite → CVE non corrigees |
| DrayTek 2860 | Pare-feu basiques, VPN IKEv1 faible |
| MFA partiel | Seulement pour l'IT, pas les utilisateurs |
| VPN config minimale | IKEv1, pas de DPD |

### Manques operationnels (P2-P3)
- QoS non documentee → VoIP degradee sous charge
- Pas de VLAN → broadcast storms, pas d'isolation
- Pas de supervision unifiee
- Pas de documentation reseau

---

## 3. ARCHITECTURE CIBLE — Notre solution

### Reseau & Securite

| Site | Actuel | Cible | Pourquoi |
|------|--------|-------|----------|
| Siege | FortiGate 80D (EOL) | **FortiGate 100F** | Hub VPN, 1 Gbps, UTM complet |
| 3 entrepots | DrayTek 2860 | **FortiGate 60F** | VPN IKEv2, QoS native, FortiGuard |
| Cross-dock | Rien | **FortiGate 40F** | Protection minimale site saisonnier |

**VPN** : IKEv1 → **IKEv2 AES-256-GCM**, DPD, PFS DH Group 14. Topologie hub-and-spoke.

**4 VLANs harmonises** :

| VLAN | Usage | DSCP | Bande passante |
|------|-------|------|----------------|
| 10 MGMT | Admin switches/AP/FW | CS2 | 5% |
| 20 SERVEURS | VMs, SAN | AF31 | 40% |
| 30 DATA | Postes, terminaux RF | BE | Best effort |
| 40 VOIP | Telephones IP | **EF (46)** | 30% min |

### Haute Disponibilite

| Composant | Specs |
|-----------|-------|
| 2x Dell R650xs | 256 Go RAM chacun, cluster HA |
| SAN PowerVault ME5012 | 8x SSD 1.92 To, iSCSI |
| Cloud Witness Azure | 3eme vote quorum (remplace 3eme noeud physique) |

**Pourquoi 2 noeuds pas 3** : economie ~15k EUR, Azure = PRA geo, Cloud Witness = quorum suffisant.

### AD multi-site
- **DC01** (siege) : DC principal, DNS principal
- **DC02** (siege) : DC secondaire, failover immediat
- **DC-Azure** : replique cloud, PRA geographique

### PRA Azure

| Service | RTO | RPO | Mecanisme |
|---------|-----|-----|-----------|
| AD | < 15 min | 0 | Replication temps reel DC-Azure |
| WMS | < 1h | < 15 min | Azure Site Recovery |
| VoIP | < 30 min | N/A | Redemarrage VM sur noeud sain |

---

## 4. BUDGET — 137 301 EUR

| Poste | Montant |
|-------|---------|
| Securite (5x FortiGate + licences 3 ans) | 17 520 EUR |
| Virtualisation (2x R650xs + ProSupport) | 30 000 EUR |
| Stockage (SAN ME5012) | 20 000 EUR |
| Reseau (4x Cisco C9200-24P) | 12 000 EUR |
| Azure PRA (3 ans, Reserved -40%) | 11 232 EUR |
| Supervision (PRTG + Veeam, 3 ans) | 7 500 EUR |
| Connectivite Internet (1ere annee) | 12 840 EUR |
| Main d'oeuvre | 8 300 EUR |
| Marge imprevus (15%) | 17 909 EUR |
| **TOTAL** | **137 301 EUR** (< 150k) |

**OPEX annuel** : ~19 340 EUR/an | **TCO 3 ans** : ~175 680 EUR

---

## 5. MIGRATION — 6 phases, 6 semaines

| Phase | Contenu | Duree | Risque | Rollback |
|-------|---------|-------|--------|----------|
| M1 | Pare-feu (DrayTek → FortiGate) | 5 nuits (S1-S2) | Moyen | Rebrancher DrayTek (15 min) |
| M2 | Cluster (install 2x R650xs + SAN) | 1 WE + 2j (S2-S3) | Faible | Nouveau matos, pas d'impact prod |
| M3 | Migration VMs (~20 VMs du R630) | 2 nuits WE (S3) | **Eleve** | Snapshot + restaurer sur R630 (30 min) |
| M4 | Azure (VPN + DC replique + Site Recovery) | 3 jours (S4) | Moyen | Nouveau, pas migration |
| M5 | QoS + VLAN (segmentation 4 VLAN) | 3 nuits (S5) | Moyen | Desactiver VLAN (20 min) |
| M6 | Tests validation bout en bout | 1 WE (S6) | Faible | Validation, pas modification |

**Logique** : du moins critique au plus critique. Cross-dock d'abord pour roder, siege en dernier.
**Seuil d'abandon** : 03h00 pour garder 2h30 de marge avant ouverture 5h30.

---

## 6. LE POC — 4 tests, 4 PASS

### Environnement
7 VMs sur Proxmox VE 9.1.4, min 32 Go RAM, 2 bridges (LAN siege + WAN Azure). Valide sur cluster ecole et homelab perso.

| VMID | Nom | OS | IP | Role |
|------|-----|----|----|------|
| 32001 | FW-SIEGE | pfSense | 172.16.132.1 | Firewall + QoS |
| 32005 | FW-AZURE | pfSense | 10.100.0.1 | Cote Azure |
| 32010 | DC01 | Win Server 2022 | 172.16.132.10 | AD principal |
| 32011 | DC02 | Win Server 2022 | 172.16.132.11 | AD secondaire |
| 32012 | DC-AZURE | Win Server 2022 | 10.100.0.10 | DC cloud |
| 32020 | WMS | Ubuntu 22.04 | 172.16.132.20 | Simulation WMS |
| 32030 | IPBX | FreePBX | 172.16.132.30 | Telephonie VoIP |

### Resultats

| Test | Ce qu'on prouve | Resultat |
|------|-----------------|----------|
| **QoS VoIP** | VoIP stable sous charge 500 Mbps | Latence **0.1ms**, gigue **0.04ms**, **0% perte** |
| **Failover AD** | DC02 prend le relais si DC01 tombe | Bascule **immediate** (< 30s), DNS+Auth OK |
| **Failover WMS** | BDD survit a un reboot brutal | **20s** reboot, MySQL OK, **5/5 records intacts** |
| **Tunnel Azure** | Siege communique avec Azure | Ping+DNS+Replication AD **OK** (0 erreurs) |

### Limites a connaitre (le jury va demander)
- QoS testee avec ICMP ping, pas un vrai appel VoIP avec softphones
- Routes statiques au lieu de vrai IPsec (config IPsec documentee)
- Cluster physique non simulable sur 1 seul Proxmox
- BDD de test = 5 records (pas un volume realiste)
- pfSense ≠ FortiGate (pas d'UTM, interface differente)

---

## 7. DEMO LIVE (5 min)

> Toutes les commandes depuis **pve02** (`ssh pve02`).
> Procedure complete : `docs/05-soutenance/procedure-demo-live.md`

| Etape | Action | Ce qu'on montre | Duree |
|-------|--------|-----------------|-------|
| 1 | `qm list` sur pve02 | "On a reproduit l'archi en lab — 7 VMs" | 30s |
| 2 | iperf3 500M + ping IPBX | QoS : latence 0.16ms, 0% perte sous charge | 90s |
| 3 | `qm stop 32010` → nltest sur DC02 | Failover AD : DC02 prend le relais | 90s |
| 4 | crash WMS → mysql SELECT | 5/5 records identiques apres crash | 60s |
| 5 | ping cross-VLAN + repadmin | Tunnel Azure + replication AD OK | 30s |

**Plan B** : captures du 22/02 dans `docs/05-soutenance/images/captures-poc-2026-02-22.txt`

---

## 8. TOP 20 QUESTIONS JURY (les plus dangereuses)

| # | Question | Reponse cle |
|---|----------|-------------|
| 1 | **Pourquoi 2 noeuds pas 3 ?** | Economie 15k, Azure = PRA geo, Cloud Witness = quorum |
| 2 | **Pourquoi FortiGate ?** | Prix PME, support FR, gestion centralisee, VPN IKEv2 natif |
| 3 | **RTO/RPO ?** | AD < 15min/0, WMS < 1h/15min, VoIP < 30min |
| 4 | **Budget realiste ?** | 137k < 150k, marge 15%, prix revendeurs entreprise |
| 5 | **Routes statiques = pas un vrai POC ?** | Valide la connectivite, config IPsec documentee, tunnel ajouterait encapsulation sans changer les resultats |
| 6 | **0.1ms en lab mais en prod ?** | LAN local, en prod avec IPsec : 6-18ms, toujours < 150ms ITU-T |
| 7 | **5 records WMS c'est pas realiste** | Valide le mecanisme (crash + integrite), recommandation moyen terme = load testing |
| 8 | **pfSense ≠ FortiGate** | Memes fonctions testees (routage, QoS, VPN), POC valide concepts pas produits |
| 9 | **Si le siege brule ?** | DC-Azure maintient AD, Site Recovery bascule VMs, Veeam sur Blob |
| 10 | **DSI de 4, l'admin est malade ?** | Doc complete, FortiCare support inclus, flotte homogene = 1 competence |
| 11 | **Split-brain cluster ?** | Cloud Witness Azure = 3eme vote, evite le split-brain |
| 12 | **IPBX centralise, WAN tombe ?** | Pas de VoIP en entrepot, limite assumee, solution future = SIP proxy local ou Teams Phone |
| 13 | **Pourquoi Azure pas AWS/OVH ?** | NordTransit deja sur M365/Entra ID, integration native AD Connect, Site Recovery |
| 14 | **MDP en clair dans le lab ?** | Lab = reproductibilite, prod = coffre-fort (KeePass/vault), rotation, certificats X.509 |
| 15 | **Ansible mais pas pour pfSense/Windows ?** | pfSense = XML (pas de module mature), Windows AD = PowerShell encode b64, rapport effort/benefice |
| 16 | **Ransomware chiffre DC01+DC02 ?** | DC-Azure a copie complete, seize FSMO, nettoyer metadata, condition = Azure non compromis |
| 17 | **VLAN VoIP /27 = 30 hotes, assez ?** | 70 tel / 4 sites = ~17/site, siege en /26 = 62, marge OK |
| 18 | **Point le plus faible ?** | Telephonie centralisee sans survivability en entrepot |
| 19 | **Si 300k ?** | Cluster 3 noeuds, FortiGate 100F partout, WAN redondant 2 FAI, PRA multi-region, SIEM |
| 20 | **Qu'est-ce que ce projet vous a apporte ?** | Reponse PERSONNELLE — conception multi-site, VPN, AD, QoS, budget IT, approche POC |

Le document complet des 100 questions est dans `docs/05-soutenance/questions-jury.md`.

---

## 9. CHECKLIST AVANT SOUTENANCE

### J-5 (18/02)
- [ ] Lire ce briefing a fond
- [ ] Relire les 100 questions du `questions-jury.md`
- [ ] Attribuer les parties aux 5 membres (P1-P5)
- [ ] S'assurer que chaque membre connait sa partie

### J-2 (21/02)
- [ ] Repetition generale avec timer (~30 min total)
- [ ] Verifier que le lab est UP (7 VMs demarrees)
- [ ] Tester les commandes demo (iperf3, qm stop/start, nltest)
- [ ] Backup slides en PDF

### J-1 (22/02)
- [ ] 2eme repetition si possible
- [ ] Preparer les commandes demo en copier-coller
- [ ] Captures d'ecran plan B dans les slides

### Jour J (23/02)
- [ ] VMs demarrees 30 min avant
- [ ] Tester SSH vers toutes les VMs
- [ ] Ouvrir les terminaux a l'avance
- [ ] Verifier iperf3 fonctionne

---

## 10. LIVRABLES RENDUS

| Livrable | Fichier | Format |
|----------|---------|--------|
| Architecture Technique (DAT) | `docs/04-livrables/architecture-technique.md` | MD + DOCX |
| Strategie de Migration | `docs/04-livrables/strategie-migration.md` | MD + DOCX |
| Config Pare-feu | `docs/04-livrables/configs/pare-feu.md` | MD |
| Config VPN IPsec | `docs/04-livrables/configs/vpn-ipsec.md` | MD |
| Note Recommandation WMS | `docs/04-livrables/note-recommandation-wms.md` | MD + DOCX |
| Guide Depannage ToIP | `docs/04-livrables/guide-depannage-toip.md` | MD + DOCX |
| Presentation | `docs/05-soutenance/MSPR_NordTransit_Presentation.pptx` | PPTX |

---

## PHRASES CLES A RETENIR

- "On passe de **tout peut tomber** a **tout est redondant**"
- "Chaque choix technique repond a un **probleme concret** identifie dans l'audit"
- "Le POC valide les **concepts**, pas les produits — les principes sont identiques en production"
- "Budget respecte : **137k sur 150k**, avec 15% de marge imprevus"
- "Architecture pensee pour une **DSI de 4 personnes** — simple a exploiter, interface unifiee"
