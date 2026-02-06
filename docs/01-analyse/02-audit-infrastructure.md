---
title: "Audit de l'infrastructure existante"
phase: "01-analyse"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 01-contexte-client.md lu"
---

# Audit de l'infrastructure existante

## Objectif

> Documenter l'etat actuel de l'infrastructure NordTransit site par site,
> identifier les equipements, services et failles pour justifier la modernisation.

## Prerequis

- [ ] Contexte client maitrise (guide precedent)
- [ ] Acces aux specs Notion (`_specs/comprendre/`)

## Etapes

### 1. Inventorier les equipements par site

**Pourquoi** : Savoir ce qu'on remplace permet de dimensionner et budgeter.

#### Siege Lille
- Hyperviseur : Dell R630 (toutes les VMs critiques — SPOF)
- Stockage : NAS 6 To RAID5
- Telephonie : Passerelle SIP + ~25 telephones Cisco IP
- Pare-feu : FortiGate 80D (fin de vie)

#### Entrepots (Lens, Valenciennes, Arras) — par site
- ~15 PC / terminaux legers
- ~15 telephones IP
- ~10 terminaux RF Wi-Fi
- ~3 imprimantes etiquettes
- Pare-feu : DrayTek Vigor 2860

#### Cross-dock
- Switch 24 ports basique
- Equipement minimal (saisonnier)

### 2. Lister les services heberges

**Pourquoi** : Identifier les dependances entre services.

| Service | Hebergement | Dependances |
|---------|-------------|-------------|
| Active Directory (DC01, DC02) | Siege Lille | DNS, DHCP, authentification |
| WMS (App + BDD) | Siege Lille | AD, reseau |
| IPBX | Siege Lille | SIP, reseau, QoS |
| Supervision | Siege Lille | Reseau |

### 3. Documenter les liens WAN

**Pourquoi** : Les liens inter-sites sont le nerf de la guerre pour une entreprise multi-sites.

| Liaison | Debit | Redondance | VPN |
|---------|-------|------------|-----|
| Siege <-> WH1 | ~200 Mbps | NON | DrayTek |
| Siege <-> WH2 | ~200 Mbps | NON | DrayTek |
| Siege <-> WH3 | ~200 Mbps | NON | DrayTek |
| Siege <-> Cross-dock | Variable | NON | Aucun |

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Inventaire complet | Tous les equipements documentes | 5 sites couverts |
| Services mappes | Chaque service a un hebergeur identifie | Tableau complet |
| Liens documentes | Chaque liaison WAN documentee | 4 liaisons |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Info manquante dans le sujet | Le sujet ne detaille pas tout | Faire des hypotheses raisonnables et les documenter |

## Liens

- Spec de reference : `_specs/comprendre/infrastructure-existante.md`, `_specs/comprendre/sites-nordtransit.md`
- Guide precedent : `docs/01-analyse/01-contexte-client.md`
- Guide suivant : `docs/01-analyse/03-points-douleur.md`
