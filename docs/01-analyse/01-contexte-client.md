---
title: "Contexte client - NordTransit Logistics"
phase: "01-analyse"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Acces au sujet MSPR (PDF)"
  - "Acces Notion projet"
---

# Contexte client - NordTransit Logistics

## Objectif

> Synthetiser le contexte NordTransit pour que chaque membre de l'equipe comprenne le client,
> son metier et ses contraintes avant de toucher a la technique.

## Prerequis

- [ ] Lire le sujet MSPR (`2025-2026 ASRBD - Sujet MSPR TPRE512.pdf`)
- [ ] Acces a la page Notion du projet

## Etapes

### 1. Identifier le client

**Pourquoi** : Comprendre le metier permet de dimensionner correctement les solutions.

NordTransit Logistics est une PME de logistique basee dans les Hauts-de-France :
- **4 entrepots permanents** : Lille (siege), Lens, Valenciennes, Arras
- **1 cross-dock saisonnier** : active pendant les pics e-commerce/soldes
- **~240 employes** dont ~100 postes informatiques
- **Equipe DSI** : 4 personnes (1 responsable + 1 admin itinerant + 1 technicien + 1 alternant)

### 2. Comprendre le coeur de metier

**Pourquoi** : Le WMS est LE systeme critique — toute l'architecture tourne autour de sa disponibilite.

| Systeme | Criticite | Impact si panne |
|---------|-----------|-----------------|
| WMS (Warehouse Management) | CRITIQUE | Arret immediat reception/expedition sur les 4 sites |
| Active Directory | Haute | Plus d'authentification, plus d'acces |
| VoIP (IPBX) | Moyenne | Communication perturbee mais operations manuelles possibles |

**Horaires critiques** : 5h30 - 18h30 (operations entrepot)
**Fenetres maintenance** : nuit (apres 18h30), samedi matin en haute saison

### 3. Cartographier les sites

**Pourquoi** : Chaque site a des contraintes differentes.

| Site | Reseau actuel | Pare-feu | Specificite |
|------|---------------|----------|-------------|
| Siege Lille | 192.168.10.0/24 | FortiGate 80D (EOL) | Heberge toutes les VMs critiques |
| WH1 Lens | 192.168.20.0/24 | DrayTek 2860 | Pas de lien de secours |
| WH2 Valenciennes | 192.168.30.0/24 | DrayTek 2860 | QoS/VLAN non documentes |
| WH3 Arras | 192.168.40.0/24 | DrayTek 2860 | Impression/etiquettes critique |
| Cross-dock | 192.168.50.0/24 | Switch basique | Saisonnier, moyens reduits |

### 4. Budget et contraintes

**Pourquoi** : Cadrer les solutions dans le budget disponible.

- **Budget** : 100 000 - 150 000 EUR
- **Equipe DSI reduite** : solutions simples a exploiter obligatoires
- **Pas de downtime WMS** pendant les heures d'operations

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Comprehension | Chaque membre peut expliquer le metier NordTransit | Oui/Non |
| Sites | Tous les sites sont identifies avec leurs contraintes | 5 sites documentes |
| Budget | Le budget est connu de tous | 100-150k EUR |

## Liens

- Spec de reference : `_specs/OVERVIEW.md`, `_specs/comprendre/sites-nordtransit.md`
- Guide suivant : `docs/01-analyse/02-audit-infrastructure.md`
