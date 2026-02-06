---
title: "Points de douleur identifies"
phase: "01-analyse"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 02-audit-infrastructure.md complete"
---

# Points de douleur identifies

## Objectif

> Lister et categoriser tous les problemes de l'infrastructure actuelle.
> Ces points de douleur justifient chaque choix de l'architecture cible.

## Prerequis

- [ ] Audit infrastructure complete (guide precedent)
- [ ] Specs lues : `_specs/comprendre/points-douleur.md`

## Etapes

### 1. Identifier les SPOF (Single Points of Failure)

**Pourquoi** : Un SPOF = un arret potentiel de production. C'est le probleme n°1 de NordTransit.

| SPOF | Impact | Criticite |
|------|--------|-----------|
| Serveur unique Dell R630 | Panne = arret total de tous les services | CRITIQUE |
| NAS unique RAID5 | Perte de donnees si 2 disques tombent | Haute |
| Pas de PRA | Sinistre siege = arret total, perte donnees | CRITIQUE |
| Liens WAN sans redondance | Perte de lien = site isole | Haute |

### 2. Auditer la securite

**Pourquoi** : La securite est insuffisante sur plusieurs axes.

| Faille | Detail | Risque |
|--------|--------|--------|
| FortiGate 80D en EOL | Plus de mises a jour securite | Vulnerabilites non patchees |
| DrayTek 2860 | Pare-feu basiques, capacites limitees | Filtrage insuffisant |
| MFA partiel | Pas deploye partout | Acces compromis possibles |
| VPN faible | Configuration DrayTek basique | Interception possible |

### 3. Lister les manques operationnels

**Pourquoi** : Ces manques compliquent le travail de la DSI au quotidien.

| Manque | Consequence |
|--------|-------------|
| QoS non documentee | VoIP degradee sous charge |
| VLAN non segmentes | Broadcast storms, pas d'isolation |
| Pas de supervision unifiee | Pannes detectees tardivement |
| Pas de documentation reseau | Interventions plus longues |

### 4. Prioriser les problemes

**Pourquoi** : On ne peut pas tout traiter en meme temps — prioriser guide l'architecture cible.

| Priorite | Probleme | Solution proposee |
|----------|----------|-------------------|
| P0 | SPOF serveur + pas de PRA | Cluster 2 noeuds + PRA Azure |
| P1 | Securite reseau | FortiGate homogenes + VPN IKEv2 |
| P2 | QoS VoIP | Configuration QoS sur FortiGate |
| P3 | Segmentation | Plan VLAN par site |

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| SPOF listes | Chaque SPOF identifie et documente | >= 4 SPOF |
| Failles securite | Audit securite complet | Tableau rempli |
| Priorisation | Chaque probleme a une priorite | P0 a P3 definis |

## Liens

- Spec de reference : `_specs/comprendre/points-douleur.md`
- Guide precedent : `docs/01-analyse/02-audit-infrastructure.md`
- Guide suivant : `docs/02-conception/01-architecture-cible.md`
