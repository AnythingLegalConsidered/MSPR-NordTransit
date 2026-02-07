---
title: "Plan de presentation - Soutenance MSPR"
phase: "05-soutenance"
author: "Equipe NordTransit"
date: 2026-02-07
---

# Plan de presentation - Soutenance MSPR

## Objectif

> Structurer la presentation de soutenance et repartir les parties entre les 5 membres.
> Timing : ~15-20 min presentation + ~5 min demo POC + ~10 min questions.

## Timing global

| Partie | Duree | Contenu |
|--------|-------|---------|
| 1 - Contexte | 3-4 min | Client, problematique, enjeux |
| 2 - Architecture cible | 5-6 min | Reseau, serveurs, cloud, securite |
| 3 - Demo POC | 5 min | Lab Proxmox, tests live |
| 4 - Migration et budget | 3-4 min | Phases, planning, couts |
| 5 - Conclusion + Q&A | 2 min + 10 min | Gains, questions |
| **Total** | **~30 min** | |

---

## Structure des slides

### Partie 1 - Contexte (3-4 min)

**Messages cles :**
- NordTransit = PME logistique, 4 entrepots + 1 cross-dock, ~240 employes, ~100 postes
- DSI reduite : 4 personnes (1 responsable + 1 admin itinerant + 1 tech + 1 alternant)
- WMS = coeur de metier, indisponibilite = arret des operations sur 4 sites

**Slides suggerees :**

| Slide | Contenu | Support visuel |
|-------|---------|----------------|
| 1.1 | Presentation NordTransit : metier, sites, chiffres | Carte des 5 sites (Lille, Lens, Valenciennes, Arras, cross-dock) |
| 1.2 | Infrastructure existante : DrayTek, AD mono-DC, pas de PRA | Schema reseau AVANT (mermaid dans `architecture-technique.md`) |
| 1.3 | Points de douleur : SPOF, securite, QoS absente | Liste des 3 enjeux critiques |
| 1.4 | Cadrage : budget 100-150k, equipe 5 pers, 19h | Tableau budget/contraintes |

**Points a insister :**
- Le WMS tourne sur UN serveur sans redondance → panne = arret total
- MFA partiel seulement, pas de segmentation reseau
- Fenetres de maintenance tres reduites (nuit uniquement)

**Responsable** : _a attribuer_

---

### Partie 2 - Architecture cible (5-6 min)

**Messages cles :**
- FortiGate remplace les DrayTek (securite + QoS + VPN integre)
- Cluster 2 serveurs + SAN = plus de SPOF
- AD 3 DCs (2 on-prem + 1 Azure) = PRA geographique
- VPN IPsec IKEv2 entre tous les sites

**Slides suggerees :**

| Slide | Contenu | Support visuel |
|-------|---------|----------------|
| 2.1 | Architecture reseau APRES | Schema mermaid (cf. `architecture-technique.md` section 4) |
| 2.2 | Plan VLAN et QoS | Tableau VLANs + regles QoS (priorites VoIP/Serveurs/Data) |
| 2.3 | Haute disponibilite : cluster + AD multi-DC | Schema cluster + replication AD |
| 2.4 | PRA Azure : Site Recovery + DC cloud | Schema landing zone Azure |
| 2.5 | Securite : FortiGate, VPN, segmentation | Regles pare-feu principales (cf. `configs/pare-feu.md`) |

**Points a insister :**
- Chaque choix a une justification (FortiGate = prix PME + support FR + ecosystem)
- QoS garantit la VoIP meme sous charge (prouve par le POC)
- Azure = PRA geo, pas migration full-cloud (budget maitrise)

**Responsable** : _a attribuer_

---

### Partie 3 - Demo POC (5 min)

**Objectif** : Montrer que l'architecture fonctionne, pas juste sur papier.

**Script demo :**

| Etape | Action | Ce qu'on montre | Duree |
|-------|--------|-----------------|-------|
| 1 | Ouvrir Proxmox, montrer les 7 VMs | "On a reproduit l'archi cible en lab" | 30s |
| 2 | `iperf3` saturation + `ping IPBX` | QoS : VoIP stable meme sous 500Mbps de charge | 90s |
| 3 | `qm stop 32010` (DC01) → `nltest` sur DC02 | Failover AD : bascule immediate | 90s |
| 4 | `qm start 32010` → montrer replication OK | AD se resynchronise automatiquement | 30s |
| 5 | Montrer resultats consolides (tableau 4/4 PASS) | Synthese : tous les criteres valides | 30s |

**Commandes preparees (copier-coller) :**

```bash
# Test QoS - Terminal 1 (sur pve02)
iperf3 -s -B 172.16.132.254 -p 5201

# Test QoS - Terminal 2 (sur WMS via SSH)
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M"

# Test QoS - Terminal 3 (ping IPBX pendant charge)
ssh wmsadmin@172.16.132.20 "ping -c 50 -i 0.2 172.16.132.30"

# Failover AD
qm stop 32010
# Attendre 30s...
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"

# Remettre DC01
qm start 32010
```

**Plan B (si demo plante) :**
- Avoir les captures d'ecran des resultats dans les slides
- Les resultats sont documentes dans `docs/03-lab-poc/07-tests-validation.md`
- Dire : "On a les preuves documentees, voici les captures"

**Responsable** : _a attribuer_

---

### Partie 4 - Migration et budget (3-4 min)

**Messages cles :**
- Migration en 6 phases sur 6 semaines (nuit uniquement)
- Chaque phase a un rollback prevu
- Budget total : 137k EUR (marge 15% incluse, sous le plafond de 150k)

**Slides suggerees :**

| Slide | Contenu | Support visuel |
|-------|---------|----------------|
| 4.1 | Les 6 phases de migration | Timeline visuelle M1→M6 |
| 4.2 | Phase M1 : reseau (FortiGate) | Detail + fenetres de maintenance |
| 4.3 | Phases M2-M4 : serveurs, AD, WMS | Points critiques + rollback |
| 4.4 | Budget detaille | Tableau CAPEX/OPEX |

**Phases de migration (resume) :**

| Phase | Contenu | Duree | Risque |
|-------|---------|-------|--------|
| M1 | Reseau : FortiGate + VLAN + QoS | Semaine 1 | Moyen (rollback = remettre DrayTek) |
| M2 | Serveurs : cluster + SAN + migration VMs | Semaine 2 | Eleve (backup complet avant) |
| M3 | AD : DC02 + replication | Semaine 3 | Faible (ajout, pas remplacement) |
| M4 | WMS : migration vers cluster | Semaine 4 | Eleve (fenetre nuit, rollback prevu) |
| M5 | Azure : landing zone + DC-AZURE + PRA | Semaine 5 | Moyen (nouveau, pas migration) |
| M6 | VoIP : migration IPBX + QoS fine | Semaine 6 | Faible (parallele possible) |

**Budget :**

| Poste | Montant |
|-------|---------|
| Reseau (FortiGate x5 + AP + switches) | ~45k EUR |
| Serveurs (2x R650xs + SAN) | ~55k EUR |
| Azure (12 mois) | ~15k EUR |
| Services (installation + formation) | ~12k EUR |
| Marge imprevus (15%) | ~10k EUR |
| **Total** | **~137k EUR** |

**Responsable** : _a attribuer_

---

### Partie 5 - Conclusion (2 min)

**Messages cles :**
- On passe de "tout peut tomber" a "tout est redondant"
- Budget respecte (137k < 150k)
- Solutions simples a exploiter (DSI de 4 personnes)

**Slides suggerees :**

| Slide | Contenu |
|-------|---------|
| 5.1 | AVANT vs APRES en 3 points : SPOF→HA, pas de PRA→Azure, QoS absente→garantie |
| 5.2 | Prochaines etapes : formation equipe DSI, monitoring, audit securite 6 mois |
| 5.3 | Merci + Questions |

**Responsable** : _a attribuer_

---

## Questions types a preparer

| Question probable | Elements de reponse | Livrable de reference |
|-------------------|---------------------|-----------------------|
| Pourquoi 2 serveurs et pas 3 ? | Economie ~15k, Azure = PRA geo, Cloud Witness = quorum | `architecture-technique.md` section 5 |
| Pourquoi FortiGate et pas un autre ? | Interface connue, support FR, prix PME, ecosystem unifie | `architecture-technique.md` section 4.2 |
| Quel est le RTO/RPO ? | AD < 15min/0, WMS < 1h/15min, VoIP < 30min | `strategie-migration.md` section 3 |
| Risques de la migration ? | 6 phases avec rollback, fenetres nuit, ordre par criticite | `strategie-migration.md` section 2 |
| Budget est-il realiste ? | 137k < 150k, marge 15% imprevus incluse, devis constructeurs | `architecture-technique.md` section 8 |
| Comment vous avez teste ? | Lab Proxmox 7 VMs, 4 tests mesurables, tous PASS | `07-tests-validation.md` |
| Et si Azure tombe ? | DC on-prem autonomes, Azure = PRA pas dependance | `architecture-technique.md` section 6 |
| QoS sur tous les sites ? | Oui, FortiGate gere QoS nativement, meme config sur 5 sites | `configs/pare-feu.md` section QoS |

---

## Repartition equipe (a completer)

| Personne | Partie presentation | Partie POC lab |
|----------|--------------------|-----------------------|
| P1 | Partie 1 - Contexte | Setup reseau + pfSense |
| P2 | Partie 2 - Architecture | AD + replication |
| P3 | Partie 3 - Demo POC | IPBX + QoS |
| P4 | Partie 4 - Migration/budget | Azure + tunnel |
| P5 | Partie 5 - Conclusion | WMS + documentation |

> **Note** : Remplacer P1-P5 par les vrais noms une fois decides.

---

## Checklist avant soutenance

### J-7

- [ ] Slides finalisees (PowerPoint ou Google Slides)
- [ ] Chaque membre connait sa partie
- [ ] Demo POC testee sur le lab (toutes VMs demarrees)

### J-1

- [ ] Repetition generale complete (timer)
- [ ] Backup des slides en PDF
- [ ] Commandes demo preparees (copier-coller pret)
- [ ] Plan B demo pret (captures d'ecran dans slides)

### Jour J

- [ ] VMs demarrees 30 min avant
- [ ] Tester SSH vers toutes les VMs
- [ ] Verifier que iperf3 fonctionne
- [ ] Ouvrir les terminaux necessaires a l'avance
