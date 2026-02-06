---
title: "Guide de Depannage ToIP - Niveaux N1 et N2"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Guide de Depannage ToIP - N1/N2

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

### 1.1 Objectif

Ce guide permet au support N1 (technicien) et N2 (admin) de diagnostiquer et resoudre
les problemes de telephonie VoIP chez NordTransit.

### 1.2 Architecture VoIP

- IPBX : FreePBX (siege)
- Protocole : SIP (PJSIP)
- Telephones : Cisco IP (~70 postes sur 4 sites)
- QoS : DSCP EF (46) via FortiGate, VLAN 40 dedie

---

## 2. Depannage N1 (Technicien)

### 2.1 Pas de tonalite

| Etape | Action | Resultat attendu |
|-------|--------|-------------------|
| 1 | Verifier le cable reseau du telephone | LED allumee |
| 2 | Verifier l'alimentation PoE du switch | Port actif |
| 3 | Redemarrer le telephone | Demarrage normal |
| 4 | Verifier l'IP du telephone (menu) | IP dans VLAN 40 |

### 2.2 Audio coupe / saccade

| Etape | Action | Resultat attendu |
|-------|--------|-------------------|
| 1 | Verifier la bande passante | `iperf3` ou speed test |
| 2 | Verifier la QoS | Trafic dans qVoIP |
| 3 | Verifier le VLAN | Telephone sur VLAN 40 |

### 2.3 Appel ne sonne pas

| Etape | Action | Resultat attendu |
|-------|--------|-------------------|
| 1 | Verifier l'extension SIP | Enregistre dans FreePBX |
| 2 | Verifier le firewall | Ports SIP (5060) et RTP (10000-20000) ouverts |

---

## 3. Depannage N2 (Admin)

### 3.1 Commandes de diagnostic

```bash
# pfSense - verifier les queues QoS
pfctl -s queue

# FreePBX - verifier les peers SIP
asterisk -rx "pjsip show endpoints"

# FreePBX - logs en temps reel
asterisk -rvvv

# Test de latence vers IPBX
ping -c 100 172.16.132.30
```

### 3.2 Problemes FreePBX

_A completer avec les cas rencontres en POC_

### 3.3 Problemes QoS

_A completer avec les metriques et seuils_

---

## 4. Arbre de decision

```
Probleme VoIP
├── Pas de tonalite
│   ├── Cable OK ? → Non → Remplacer cable
│   ├── PoE OK ? → Non → Verifier port switch
│   └── IP OK ? → Non → Verifier DHCP VLAN 40
├── Audio coupe
│   ├── QoS active ? → Non → Escalade N2
│   └── Bande passante OK ? → Non → Escalade N2
└── Appel ne sonne pas
    ├── Extension enregistree ? → Non → Re-provisionner
    └── Firewall OK ? → Non → Verifier regles SIP/RTP
```

---

## 5. Contacts escalade

| Niveau | Contact | Delai |
|--------|---------|-------|
| N1 | Technicien sur site | Immediat |
| N2 | Admin reseau | < 1h |
| N3 | Prestataire IPBX | < 4h |

---

## 6. Annexes

- Guide lab QoS : `docs/03-lab-poc/04-ipbx-qos.md`
- Specs VoIP : `_specs/poc/poc1-qos-voip.md`
