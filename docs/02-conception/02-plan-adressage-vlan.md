---
title: "Plan d'adressage VLAN"
phase: "02-conception"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 01-architecture-cible.md lu"
---

# Plan d'adressage VLAN

## Objectif

> Definir la segmentation reseau harmonisee sur tous les sites.
> Un numero de VLAN = un type de trafic, partout. Cela simplifie l'exploitation et le depannage.

## Prerequis

- [ ] Architecture cible validee (guide precedent)
- [ ] Specs lues : `_specs/solution/plan-vlan.md`

## Etapes

### 1. Definir les VLAN standards

**Pourquoi** : Harmoniser les VLAN sur tous les sites permet a la DSI de diagnostiquer et intervenir de maniere identique partout.

| VLAN ID | Nom | Usage | Sites concernes |
|---------|-----|-------|-----------------|
| 10 | MGMT | Administration switches, AP, firewalls | Tous sauf cross-dock |
| 20 | SERVEURS | VMs, stockage SAN | Siege uniquement |
| 30 | DATA | Postes, terminaux RF, imprimantes | Tous les sites |
| 40 | VOIP | Telephones IP Cisco | Tous sauf cross-dock |

### 2. Attribuer les plages IP par site

**Pourquoi** : Eviter tout chevauchement et permettre le routage inter-sites.

#### Siege Lille (192.168.10.0/24)

| VLAN | Reseau | Gateway | Plage DHCP | DSCP |
|------|--------|---------|------------|------|
| 10 MGMT | 192.168.10.0/26 | .1 | Statique | CS2 |
| 20 SERVEURS | 192.168.10.64/26 | .65 | Statique | AF31 |
| 30 DATA | 192.168.10.128/26 | .129 | .130-.190 | BE |
| 40 VOIP | 192.168.10.192/26 | .193 | .194-.250 | EF |

#### Entrepots (meme schema, reseau different)

| Site | VLAN 10 MGMT | VLAN 30 DATA | VLAN 40 VOIP |
|------|--------------|--------------|--------------|
| WH1 Lens | 192.168.20.0/27 | 192.168.20.32/25 | 192.168.20.160/27 |
| WH2 Valenciennes | 192.168.30.0/27 | 192.168.30.32/25 | 192.168.30.160/27 |
| WH3 Arras | 192.168.40.0/27 | 192.168.40.32/25 | 192.168.40.160/27 |

#### Cross-dock & Azure

| Site | Reseau | Remarque |
|------|--------|----------|
| Cross-dock | 192.168.50.0/24 (DATA seul) | Site simple, pas de VLAN |
| Azure Hub | 10.100.0.0/24 | DC replique + VPN Gateway |
| Azure Backup | 10.100.1.0/24 | Stockage backup |

### 3. Definir la QoS par VLAN

**Pourquoi** : La VoIP ne tolere pas la latence — elle doit etre prioritaire.

| VLAN | Priorite | DSCP | Bande passante garantie |
|------|----------|------|-------------------------|
| VOIP (40) | Haute | EF (46) | 30% minimum |
| SERVEURS (20) | Moyenne-Haute | AF31 (26) | 40% |
| DATA (30) | Normale | BE (0) | Best effort |
| MGMT (10) | Normale | CS2 (16) | 5% |

### 4. Valider l'absence de conflits

**Pourquoi** : Un chevauchement IP = problemes de routage impossibles a diagnostiquer.

Verification :
- Siege : 192.168.10.0/24
- WH1 : 192.168.20.0/24
- WH2 : 192.168.30.0/24
- WH3 : 192.168.40.0/24
- CDK : 192.168.50.0/24
- Azure : 10.100.0.0/23

**Aucun chevauchement.**

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Pas de chevauchement | Verifier les plages IP | Aucun overlap |
| VLAN coherents | Meme VLAN = meme trafic partout | VLAN 10/20/30/40 uniformes |
| QoS definie | DSCP attribue par VLAN | EF, AF31, BE, CS2 |

## Liens

- Spec de reference : `_specs/solution/plan-vlan.md`
- Guide precedent : `docs/02-conception/01-architecture-cible.md`
- Guide suivant : `docs/02-conception/03-strategie-securite.md`
