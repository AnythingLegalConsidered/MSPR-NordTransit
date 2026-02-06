---
title: "Document d'Architecture Technique"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Document d'Architecture Technique

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Brouillon |

## Historique des modifications

| Version | Date | Auteur | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-XX-XX | Equipe | Version initiale |

---

## 1. Introduction

### 1.1 Contexte

NordTransit Logistics est une PME logistique avec 4 entrepots et 1 cross-dock saisonnier.
L'infrastructure SI actuelle presente des failles critiques : SPOF, securite insuffisante,
pas de PRA.

### 1.2 Objectif

Ce document decrit l'architecture cible qui remplace l'infrastructure existante,
en repondant aux problemes de disponibilite, securite et performance.

### 1.3 Perimetre

- Reseau et securite (pare-feu, VPN, VLAN, QoS)
- Virtualisation et haute disponibilite (cluster, SAN)
- Cloud et PRA (Azure)
- Telephonie (VoIP/QoS)

---

## 2. Architecture existante

_Reprendre le contenu de `docs/01-analyse/02-audit-infrastructure.md`_

### 2.1 Topologie reseau actuelle

_Schema reseau AVANT — a inserer_

### 2.2 Equipements par site

_Tableaux de l'audit_

### 2.3 Points de douleur

_Reprendre `docs/01-analyse/03-points-douleur.md`_

---

## 3. Architecture cible

_Reprendre le contenu de `docs/02-conception/01-architecture-cible.md`_

### 3.1 Topologie reseau cible

_Schema reseau APRES — a inserer_

### 3.2 Securite et reseau

_Contenu de `docs/02-conception/03-strategie-securite.md`_

### 3.3 Plan d'adressage VLAN

_Contenu de `docs/02-conception/02-plan-adressage-vlan.md`_

### 3.4 Virtualisation et haute disponibilite

_Details cluster 2 noeuds + SAN_

### 3.5 Cloud et PRA

_Landing Zone Azure, Site Recovery, RTO/RPO_

---

## 4. Budget

_Reprendre `_specs/solution/budget.md`_

---

## 5. Preuves de concept (POC)

_Resultats des tests de `docs/03-lab-poc/07-tests-validation.md`_

### 5.1 QoS VoIP
### 5.2 Failover AD
### 5.3 Failover WMS
### 5.4 Tunnel Azure

---

## 6. Annexes

### 6.1 Glossaire

Voir `docs/glossaire.md`

### 6.2 References

- Specs projet : `_specs/`
- Guides lab : `docs/03-lab-poc/`
