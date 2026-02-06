---
title: "Strategie de migration"
phase: "02-conception"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Architecture cible validee"
  - "Plan VLAN valide"
  - "Strategie securite definie"
---

# Strategie de migration

## Objectif

> Definir le plan de migration de l'infrastructure existante vers la cible,
> en minimisant les interruptions de service (WMS = 0 downtime pendant les heures d'operations).

## Prerequis

- [ ] Architecture cible, plan VLAN et strategie securite valides
- [ ] Fenetres de maintenance identifiees : nuit (apres 18h30), samedi matin

## Etapes

### 1. Definir les phases de migration

**Pourquoi** : Migrer tout d'un coup est risque. On decoupe en phases avec validation apres chaque etape.

| Phase | Quoi | Quand | Risque | Rollback |
|-------|------|-------|--------|----------|
| M1 | Deployer FortiGate (siege + entrepots) | Nuit, 1 site/nuit | Moyen | Rebrancher DrayTek |
| M2 | Installer cluster serveurs + SAN | Nuit/WE | Faible (nouveau materiel) | Garder R630 actif |
| M3 | Migrer VMs vers le cluster | Nuit | Haut (WMS) | Snapshot avant migration |
| M4 | Configurer Azure (VPN + DC + PRA) | Journee (sans impact) | Faible | Supprimer ressources Azure |
| M5 | Activer QoS et VLAN | Nuit | Moyen | Desactiver VLAN |
| M6 | Tests de validation + PRA | WE | Faible | N/A |

### 2. Definir l'ordre de migration des sites

**Pourquoi** : Commencer par le site le moins critique pour roder le processus.

1. **Cross-dock** (si actif) — site le plus simple, validation du processus
2. **WH3 Arras** — entrepot standard
3. **WH2 Valenciennes** — entrepot standard
4. **WH1 Lens** — entrepot standard
5. **Siege Lille** — en dernier car heberge tout (migration la plus critique)

### 3. Planifier les fenetres de maintenance

**Pourquoi** : Le WMS ne peut pas etre arrete entre 5h30 et 18h30.

| Fenetre | Horaire | Duree max | Usage |
|---------|---------|-----------|-------|
| Nuit semaine | 19h00 - 04h00 | 9h | Migrations reseau, firewall |
| Nuit WE | 18h30 sam - 05h00 lun | 34h | Migrations serveurs, WMS |
| Journee | 09h00 - 17h00 | 8h | Installations sans impact (Azure, cablage) |

### 4. Definir les procedures de rollback

**Pourquoi** : Chaque migration doit pouvoir etre annulee si quelque chose tourne mal.

| Migration | Rollback | Delai | Responsable |
|-----------|----------|-------|-------------|
| FortiGate | Rebrancher DrayTek | 15 min | Admin reseau |
| Cluster serveurs | R630 reste actif en parallele | Immediat | Admin systeme |
| Migration WMS | Restaurer snapshot | 30 min | Admin systeme |
| Azure VPN | Couper le tunnel | 5 min | Admin reseau |

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Phases definies | 6 phases documentees | Ordre et timing clairs |
| Rollback prevu | Chaque phase a un rollback | Tableau complet |
| Fenetres OK | Pas de migration pendant heures WMS | Aucune entre 5h30-18h30 |

## Liens

- Spec de reference : `_specs/solution/architecture-cible.md`
- Guide precedent : `docs/02-conception/03-strategie-securite.md`
- Guide suivant : `docs/03-lab-poc/00-prerequis-lab.md`
