---
title: "Architecture cible"
phase: "02-conception"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Phase 01-analyse terminee"
---

# Architecture cible

## Objectif

> Definir et justifier l'architecture cible qui repond a chaque point de douleur identifie.
> Ce document sert de base au livrable "Document d'architecture technique".

## Prerequis

- [ ] Phase analyse complete (3 guides)
- [ ] Specs lues : `_specs/solution/architecture-cible.md`

## Etapes

### 1. Definir les objectifs de l'architecture

**Pourquoi** : Chaque choix technique doit repondre a un probleme concret.

| Objectif | Probleme resolu | Solution |
|----------|-----------------|----------|
| Supprimer les SPOF | Serveur unique, pas de PRA | Cluster 2 noeuds + SAN + PRA Azure |
| Securiser le perimetre | DrayTek obsoletes, VPN faible | FortiGate homogenes + IKEv2 AES-256 |
| Garantir la VoIP | QoS inexistante | QoS DSCP sur FortiGate + VLAN dedie |
| Preparer le PRA | Aucun plan de reprise | Landing Zone Azure + Site Recovery |
| Simplifier l'exploitation | DSI 4 personnes | Gestion centralisee, interface unique |

### 2. Concevoir le socle reseau/securite

**Pourquoi** : Les FortiGate remplacent les DrayTek et le FortiGate 80D EOL, avec une gestion homogene.

| Site | Equipement actuel | Equipement cible | Justification |
|------|-------------------|------------------|---------------|
| Siege | FortiGate 80D (EOL) | FortiGate 100F | Debit suffisant pour siege + VPN concentrateur |
| WH1-3 | DrayTek 2860 | FortiGate 60F | VPN IKEv2, QoS native, FortiGuard |
| Cross-dock | Rien | FortiGate 40F | Securisation minimale site saisonnier |

VPN site-a-site : IKEv2 avec AES-256, Dead Peer Detection, failover automatique.

### 3. Concevoir la virtualisation HA

**Pourquoi** : 2 serveurs + SAN = suppression du SPOF serveur unique.

| Composant | Specs | Role |
|-----------|-------|------|
| Node 1 | Dell R650xs, 256 Go RAM | Compute + Quorum |
| Node 2 | Dell R650xs, 256 Go RAM | Compute + Quorum |
| SAN | PowerVault ME5012, 8x SSD 1.92 To | Stockage partage iSCSI |
| Temoin | Azure Cloud Witness | 3eme vote quorum (remplace un 3eme noeud) |

> **Choix 2 noeuds vs 3** : Economie ~15k EUR, Azure assure le PRA geographique.
> RTO ~30 min / RPO ~15 min — acceptable pour une PME.

### 4. Concevoir le PRA Azure

**Pourquoi** : En cas de sinistre sur le siege, l'activite doit pouvoir reprendre.

| Composant Azure | Role |
|-----------------|------|
| VPN Gateway | Tunnel site-a-site permanent |
| DC-Azure | Controleur AD replique (zero RPO) |
| Site Recovery | Replication 20 VMs, failover automatise |
| Blob Storage | Backup externalise |

| Service | RTO cible | RPO cible |
|---------|-----------|-----------|
| Active Directory | < 15 min | 0 (replication temps reel) |
| WMS | < 1h | < 15 min |
| Telephonie | < 30 min | N/A |

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Chaque SPOF traite | Verifier que chaque SPOF P0 a une solution | Tableau complet |
| Budget respecte | Verifier que les choix rentrent dans 150k EUR | < 150k EUR |
| Exploitable par 4 | Aucune solution necessitant une expertise rare | Gestion centralisee |

## Liens

- Spec de reference : `_specs/solution/architecture-cible.md`
- Guide precedent : `docs/01-analyse/03-points-douleur.md`
- Guide suivant : `docs/02-conception/02-plan-adressage-vlan.md`
