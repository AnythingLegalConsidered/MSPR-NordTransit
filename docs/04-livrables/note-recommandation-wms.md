---
title: "Note de Recommandation WMS"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Note de Recommandation WMS

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Brouillon |

---

## 1. Contexte

Le WMS (Warehouse Management System) est le systeme le plus critique de NordTransit.
Son arret provoque l'arret immediat des operations sur les 4 sites.

---

## 2. Situation actuelle

| Aspect | Etat actuel | Risque |
|--------|-------------|--------|
| Hebergement | VM unique sur Dell R630 | SPOF — arret total si panne |
| Sauvegarde | _A documenter_ | Perte de donnees possible |
| Haute disponibilite | Aucune | Pas de failover |
| Performance | _A evaluer_ | Degradation possible en haute saison |

---

## 3. Recommandations

### 3.1 Court terme (dans le cadre du projet)

_A completer : migration vers le cluster, snapshots, backup_

### 3.2 Moyen terme

_A completer : replication BDD, monitoring, alerting_

### 3.3 Long terme

_A completer : migration cloud, conteneurisation, modernisation applicative_

---

## 4. Impact sur l'architecture

_Comment les recommandations WMS s'integrent dans l'architecture cible_

---

## 5. Annexes

- Guide lab WMS : `docs/03-lab-poc/06-wms-simulation.md`
- Tests failover : `docs/03-lab-poc/07-tests-validation.md`
