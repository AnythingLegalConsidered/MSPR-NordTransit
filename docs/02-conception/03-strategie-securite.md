---
title: "Strategie de securite"
phase: "02-conception"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 02-plan-adressage-vlan.md complete"
---

# Strategie de securite

## Objectif

> Definir la politique de securite reseau : pare-feu, VPN, segmentation, MFA.
> Ce guide documente les choix et leur justification pour l'equipe.

## Prerequis

- [ ] Plan VLAN valide (guide precedent)
- [ ] Connaissance des specs : `_specs/comprendre/points-douleur.md`

## Etapes

### 1. Homogeneiser les pare-feu

**Pourquoi** : Des pare-feu differents (DrayTek vs FortiGate) = double competence, double maintenance.
Passer a 100% FortiGate permet une gestion centralisee via FortiManager.

| Site | Ancien | Nouveau | Raison du modele |
|------|--------|---------|------------------|
| Siege | FortiGate 80D | FortiGate 100F | Hub VPN, debit 1Gbps, UTM complet |
| WH1-3 | DrayTek 2860 | FortiGate 60F | VPN IKEv2, QoS, prix PME |
| Cross-dock | Rien | FortiGate 40F | Protection minimale site saisonnier |

### 2. Renforcer les VPN

**Pourquoi** : Les VPN DrayTek actuels sont basiques et ne supportent pas IKEv2.

Configuration cible :
- **Protocole** : IKEv2 (plus rapide, plus stable que IKEv1)
- **Chiffrement** : AES-256-GCM
- **Authentification** : PSK (lab) → certificats (production)
- **DPD** : Dead Peer Detection active (detection de perte de tunnel)
- **Failover** : Bascule automatique sur lien 4G/5G

### 3. Segmenter par VLAN

**Pourquoi** : Sans VLAN, tout le trafic est dans le meme broadcast domain. Un terminal compromis peut scanner tout le reseau.

Regles inter-VLAN sur le FortiGate :
- VOIP → SERVEURS : **Autorise** (SIP vers IPBX)
- DATA → SERVEURS : **Autorise** (acces WMS, AD)
- DATA → VOIP : **Refuse** (pas d'acces direct)
- MGMT → Tout : **Autorise** (administration)

### 4. Deployer le MFA

**Pourquoi** : Le MFA est partiellement deploye — il faut le generaliser.

| Acces | MFA actuel | MFA cible |
|-------|------------|-----------|
| VPN distant | Non | FortiToken (TOTP) |
| Admin FortiGate | Non | FortiToken |
| RDP serveurs | Partiel | Azure MFA |
| Console Proxmox | Non | TOTP |

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Pare-feu homogenes | Tous FortiGate | 5 FortiGate, 0 DrayTek |
| VPN IKEv2 | Config VPN verifiee | AES-256, DPD actif |
| VLAN segmentes | Regles inter-VLAN | DATA ne peut pas joindre VOIP |
| MFA deploye | Chaque acces critique | MFA sur tous les acces admin |

## Liens

- Spec de reference : `_specs/solution/architecture-cible.md`
- Guide precedent : `docs/02-conception/02-plan-adressage-vlan.md`
- Guide suivant : `docs/02-conception/04-strategie-migration.md`
