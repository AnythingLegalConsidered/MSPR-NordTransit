---
title: "Quick Start - Guide de demarrage rapide"
author: "Equipe NordTransit"
date: 2026-02-06
---

# Quick Start - MSPR NordTransit Logistics

> **Tu viens d'arriver sur le projet ?** Ce guide te dit exactement par ou commencer.

## C'est quoi ce projet ?

On modernise l'infra SI de NordTransit Logistics (PME logistique, 4 entrepots).
Leur SI actuel est fragile (pas de redondance, pas de PRA, securite faible).
On propose une architecture avec FortiGate, cluster serveurs, AD multi-DC et PRA Azure.

**On a construit un lab Proxmox (7 VMs) qui prouve que ca marche.**

## Structure du repo

```
Tu es ici
|
├── _specs/                 ← Specs Notion (READ-ONLY, ne pas editer)
|
├── docs/                   ← TOUT EST LA
│   ├── 01-analyse/         ← Comprendre le client et ses problemes
│   ├── 02-conception/      ← Architecture cible (VLAN, securite, cloud)
│   ├── 03-lab-poc/         ← Guides pas-a-pas pour REFAIRE le lab
│   │   ├── 00-prerequis    ← Ce qu'il faut avant de commencer
│   │   ├── 01-reseau       ← Creer les bridges + VMs Proxmox
│   │   ├── 02-pfsense      ← Configurer le firewall siege
│   │   ├── 03-active-dir   ← Installer AD (3 DCs)
│   │   ├── 04-ipbx-qos     ← FreePBX + QoS VoIP
│   │   ├── 05-azure-tunnel ← Site Azure + routage inter-sites
│   │   ├── 06-wms          ← WMS + MySQL + donnees test
│   │   └── 07-tests        ← 4 tests de validation (tous PASS)
│   ├── 04-livrables/       ← Documents finaux (archi, migration, ToIP...)
│   ├── 05-soutenance/      ← Plan de presentation
│   └── QUICKSTART.md       ← Tu es ici !
|
├── configs/
│   └── ansible/            ← Playbooks pour deployer automatiquement
|
└── scripts/
    └── build_docs.py       ← Generer les PDF/DOCX
```

## Par ou commencer selon ton role

### "Je dois comprendre le projet"
1. Lis `_specs/OVERVIEW.md` — vue d'ensemble en 5 min
2. Lis `docs/04-livrables/architecture-technique.md` — le DAT complet
3. Lis `docs/04-livrables/strategie-migration.md` — comment on migre

### "Je dois refaire le lab"
1. Lis `docs/03-lab-poc/00-prerequis-lab.md` — verifier les ressources
2. Suis les guides **dans l'ordre** : 01 → 02 → 03 → 04 → 05 → 06
3. Valide avec `docs/03-lab-poc/07-tests-validation.md`

**Raccourci** : si tu as Ansible, les playbooks dans `configs/ansible/` automatisent la creation des VMs.

### "Je dois preparer la soutenance"

**Ordre de lecture recommande :**

1. `docs/05-soutenance/briefing-soutenance.md` — comprendre la structure, qui dit quoi
2. `docs/05-soutenance/plan-presentation.md` — timing et contenu par slide
3. `docs/05-soutenance/carnet-soutenance.md` — notebook condense pour le jour J
4. `docs/05-soutenance/aide-memoire.md` — fiches memo chiffres cles
5. `docs/05-soutenance/cheatsheet-demo.md` — commandes copy-paste pour la demo live
6. `docs/05-soutenance/guide-captures-plan-b.md` — plan B si la demo plante
7. `docs/05-soutenance/questions-jury.md` — 100 Q&A pour se preparer au jury

Les livrables dans `docs/04-livrables/` sont tes sources pour les slides.

### "Je dois generer les PDF"
```bash
# Installer pandoc si pas fait
choco install pandoc    # Windows
# ou
sudo apt install pandoc # Linux

# Generer tous les livrables
python scripts/build_docs.py --all --format pdf
```

## Les 7 VMs du lab

| VM | OS | IP | Role |
|----|----|----|------|
| FW-SIEGE | pfSense | 172.16.132.1 | Firewall + QoS |
| FW-AZURE | pfSense | 10.100.0.1 | Cote Azure |
| DC01 | Win Server 2022 | 172.16.132.10 | AD principal |
| DC02 | Win Server 2022 | 172.16.132.11 | AD secondaire |
| DC-AZURE | Win Server 2022 | 10.100.0.10 | DC cloud |
| WMS | Ubuntu 22.04 | 172.16.132.20 | Gestion entrepot |
| IPBX | FreePBX | 172.16.132.30 | Telephonie VoIP |

**Ressources necessaires** : ~20 Go RAM, ~100 Go disque, Proxmox VE

## Les 6 livrables

| Livrable | Fichier | Statut |
|----------|---------|--------|
| Architecture technique (DAT) | `docs/04-livrables/architecture-technique.md` | Complet |
| Strategie de migration | `docs/04-livrables/strategie-migration.md` | Complet |
| Config pare-feu | `docs/04-livrables/configs/pare-feu.md` | Complet |
| Config VPN IPsec | `docs/04-livrables/configs/vpn-ipsec.md` | Complet |
| Note recommandation WMS | `docs/04-livrables/note-recommandation-wms.md` | Complet |
| Guide depannage ToIP | `docs/04-livrables/guide-depannage-toip.md` | Complet |

## Resultats POC (deja valides)

| Test | Resultat | Critere |
|------|----------|---------|
| QoS VoIP | **PASS** | Latence 0.1ms < 150ms, 0% perte |
| Failover AD | **PASS** | DC02 repond en < 30s |
| Failover WMS | **PASS** | Reboot 20s, donnees intactes |
| Tunnel Azure | **PASS** | Ping + DNS + replication OK |

## Questions ?

- Le plan de soutenance est dans `docs/05-soutenance/plan-presentation.md`
- Les specs Notion sont dans `_specs/` (read-only)
- Le glossaire est dans `docs/glossaire.md`
