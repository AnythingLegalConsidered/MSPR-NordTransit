---
title: "Strategie de Migration"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Strategie de Migration

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Brouillon |

---

## 1. Introduction

### 1.1 Contexte

Migration de l'infrastructure NordTransit de l'existant vers l'architecture cible,
en minimisant les interruptions de service.

### 1.2 Contrainte principale

Le WMS ne doit JAMAIS etre arrete entre 5h30 et 18h30 (heures d'operations).

---

## 2. Phases de migration

_Reprendre et detailler `docs/02-conception/04-strategie-migration.md`_

### 2.1 Phase M1 - Pare-feu
### 2.2 Phase M2 - Cluster serveurs
### 2.3 Phase M3 - Migration VMs
### 2.4 Phase M4 - Azure
### 2.5 Phase M5 - QoS et VLAN
### 2.6 Phase M6 - Validation

---

## 3. Planning

_Diagramme de Gantt ou tableau temporel_

---

## 4. Plan de rollback

_Procedures de retour arriere par phase_

---

## 5. Matrice des risques

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| _a completer_ | | | |

---

## 6. Annexes

- Guides lab associes : `docs/03-lab-poc/`
- Specs migration : `_specs/solution/architecture-cible.md`
