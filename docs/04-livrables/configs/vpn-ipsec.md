---
title: "Fichiers de Configuration VPN IPsec"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Fichiers de Configuration VPN IPsec

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Brouillon |

---

## 1. Vue d'ensemble VPN

| Tunnel | Source | Destination | Protocole |
|--------|--------|-------------|-----------|
| Siege ↔ Azure | 172.16.132.0/24 | 10.100.0.0/24 | IKEv2/IPsec |
| Siege ↔ WH1 | 192.168.10.0/24 | 192.168.20.0/24 | IKEv2/IPsec |
| Siege ↔ WH2 | 192.168.10.0/24 | 192.168.30.0/24 | IKEv2/IPsec |
| Siege ↔ WH3 | 192.168.10.0/24 | 192.168.40.0/24 | IKEv2/IPsec |

---

## 2. Parametres IPsec communs

### Phase 1 (IKE)

| Parametre | Valeur | Justification |
|-----------|--------|---------------|
| Version | IKEv2 | Plus rapide et stable que v1 |
| Chiffrement | AES-256-GCM | Chiffrement fort + authentification integree |
| Hash | SHA-256 | Standard securise |
| DH Group | 14 (2048-bit) | Compromis securite/performance |
| Lifetime | 28800 s (8h) | Renouvellement regulier |
| DPD | Active (10s interval) | Detection de perte de tunnel |

### Phase 2 (ESP)

| Parametre | Valeur |
|-----------|--------|
| Protocol | ESP |
| Chiffrement | AES-256-GCM |
| Hash | SHA-256 |
| PFS | Group 14 |
| Lifetime | 3600 s (1h) |

---

## 3. Configuration POC (pfSense)

### 3.1 Tunnel Siege ↔ Azure

_Reprendre la config exacte de `docs/03-lab-poc/05-azure-tunnel.md`_

### 3.2 Exports pfSense

_A completer : exporter les configs XML de pfSense_

---

## 4. Configuration production (FortiGate)

### 4.1 Template FortiGate CLI

```
# A adapter pour chaque tunnel
config vpn ipsec phase1-interface
    edit "VPN-AZURE"
        set interface "wan1"
        set ike-version 2
        set peertype any
        set proposal aes256gcm-sha256
        set dhgrp 14
        set remote-gw <IP_AZURE>
        set psksecret <PSK>
        set dpd on-idle
        set dpd-retryinterval 10
    next
end

config vpn ipsec phase2-interface
    edit "VPN-AZURE-P2"
        set phase1name "VPN-AZURE"
        set proposal aes256gcm-sha256
        set pfs enable
        set dhgrp 14
        set src-subnet 192.168.10.0/24
        set dst-subnet 10.100.0.0/24
    next
end
```

---

## 5. Annexes

- Guide lab tunnel : `docs/03-lab-poc/05-azure-tunnel.md`
- Fichiers bruts pfSense : `configs/pfsense/` (quand exportes)
