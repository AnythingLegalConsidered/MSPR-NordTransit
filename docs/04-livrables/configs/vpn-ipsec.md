---
title: "Fichiers de Configuration VPN IPsec"
subtitle: "MSPR - NordTransit Logistics"
author: "Groupe 2 - PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise"
date: 2026-02-06
version: "1.0"
toc: true
---

# Fichiers de Configuration VPN IPsec

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-02-06 |
| Auteurs | Groupe 2 : PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise |
| Statut | Complet |

---

## 1. Vue d'ensemble VPN

### 1.1 Topologie

Le siege de Lille est le **hub VPN central** (FortiGate 100F). Tous les sites distants et Azure s'y connectent en etoile (hub-and-spoke).

```
                    +-----------------+
                    |   Azure Hub     |
                    | 10.100.0.0/24   |
                    | VPN Gateway /   |
                    | pfSense POC     |
                    +--------+--------+
                             |
                        IKEv2/IPsec
                             |
   +-------------+-----------+-----------+-------------+
   |             |                       |             |
+--+---+    +----+-----+           +----+-----+   +---+----+
| WH1  |    |  SIEGE   |           |   WH2    |   |  WH3   |
| Lens |----| Lille    |----+------| Valenc.  |   | Arras  |
| 60F  |    | 100F     |    |      | 60F      |   | 60F    |
+------+    +----------+    |      +----------+   +--------+
                            |
                       +----+-----+
                       | Cross-   |
                       | dock 40F |
                       +----------+
```

### 1.2 Inventaire des tunnels

| Tunnel | Source (LAN) | Destination (LAN) | Equipement source | Equipement dest. | Protocole |
|--------|--------------|--------------------|--------------------|-------------------|-----------|
| Siege - Azure | 192.168.10.0/24 | 10.100.0.0/24 | FortiGate 100F | Azure VPN Gateway | IKEv2/IPsec |
| Siege - WH1 | 192.168.10.0/24 | 192.168.20.0/24 | FortiGate 100F | FortiGate 60F | IKEv2/IPsec |
| Siege - WH2 | 192.168.10.0/24 | 192.168.30.0/24 | FortiGate 100F | FortiGate 60F | IKEv2/IPsec |
| Siege - WH3 | 192.168.10.0/24 | 192.168.40.0/24 | FortiGate 100F | FortiGate 60F | IKEv2/IPsec |
| Siege - CDK | 192.168.10.0/24 | 192.168.50.0/24 | FortiGate 100F | FortiGate 40F | IKEv2/IPsec |

### 1.3 Equivalence POC

| Tunnel production | Tunnel POC | Equipements POC |
|-------------------|------------|-----------------|
| Siege - Azure | FW-SIEGE - FW-AZURE | pfSense VM 32001 (172.16.132.0/24) vers pfSense VM 32005 (10.100.0.0/24) |

---

## 2. Parametres IPsec communs

### 2.1 Phase 1 (IKE)

| Parametre | Valeur | Justification |
|-----------|--------|---------------|
| Version | IKEv2 | Plus rapide, plus stable que IKEv1, supporte MOBIKE |
| Chiffrement | AES-256-GCM | Chiffrement fort avec authentification integree (AEAD) |
| Hash | SHA-256 | Standard securise, compatible tous equipements |
| Groupe DH | 14 (2048-bit MODP) | Compromis securite/performance adapte a une PME |
| Lifetime | 28800 s (8h) | Renouvellement regulier des cles |
| DPD | Active, 10s intervalle, 3 retries | Detection rapide de perte de tunnel |
| Authentification | PSK (lab) / Certificats (production) | PSK pour simplifier le POC, certificats pour la production |

### 2.2 Phase 2 (ESP)

| Parametre | Valeur | Justification |
|-----------|--------|---------------|
| Protocole | ESP | Chiffrement + authentification du trafic |
| Chiffrement | AES-256-GCM | Coherent avec Phase 1 |
| Hash | SHA-256 | Coherent avec Phase 1 |
| PFS | Group 14 | Perfect Forward Secrecy pour chaque session |
| Lifetime | 3600 s (1h) | Rotation frequente des cles de session |
| Replay detection | Activee | Protection contre les attaques par rejeu |

### 2.3 Failover

- Bascule automatique sur lien 4G/5G en cas de perte du lien principal
- DPD detecte la perte du tunnel en 30 secondes maximum (3 x 10s)
- Reestablissement automatique du tunnel apres retour du lien

---

## 3. Configuration POC (pfSense)

### 3.1 Architecture POC du tunnel

```
  FW-SIEGE (VM 32001)              FW-AZURE (VM 32005)
  +-----------------+              +-----------------+
  | LAN: vtnet0     |              | LAN: vtnet0     |
  | 172.16.132.1/24 |              | 10.100.0.1/24   |
  |                 |   vmbr2      |                 |
  | WAN: vtnet1     |==============| WAN: vtnet1     |
  | 10.100.0.254/24 |  ("Internet")| (sur vmbr2)     |
  +-----------------+              +-----------------+
```

> Note : Les deux pfSense partagent le bridge vmbr2 qui simule le lien Internet.

### 3.2 Tunnel IPsec cote SIEGE (FW-SIEGE)

Configuration via **VPN > IPsec** dans l'interface web pfSense.

**Phase 1 :**

| Parametre pfSense | Valeur |
|--------------------|--------|
| Key Exchange version | IKEv2 |
| Remote Gateway | 10.100.0.1 |
| Authentication Method | Mutual PSK |
| Pre-Shared Key | `MSPR-VPN-2024!` |
| Encryption Algorithm | AES 256-GCM, 128 bits |
| Hash Algorithm | SHA256 |
| DH Group | 14 (2048 bit) |
| Lifetime | 28800 |
| Dead Peer Detection | Enable, 10s interval |

**Phase 2 :**

| Parametre pfSense | Valeur |
|--------------------|--------|
| Local Network | LAN subnet (172.16.132.0/24) |
| Remote Network | 10.100.0.0/24 |
| Protocol | ESP |
| Encryption Algorithms | AES 256-GCM, 128 bits |
| Hash Algorithms | SHA256 |
| PFS Key Group | 14 (2048 bit) |
| Lifetime | 3600 |

### 3.3 Tunnel IPsec cote AZURE (FW-AZURE)

Configuration miroir symetrique :

**Phase 1 :**

| Parametre pfSense | Valeur |
|--------------------|--------|
| Key Exchange version | IKEv2 |
| Remote Gateway | IP WAN de FW-SIEGE (verifier sur vmbr2) |
| Authentication Method | Mutual PSK |
| Pre-Shared Key | `MSPR-VPN-2024!` |
| Encryption Algorithm | AES 256-GCM, 128 bits |
| Hash Algorithm | SHA256 |
| DH Group | 14 (2048 bit) |
| Lifetime | 28800 |
| Dead Peer Detection | Enable, 10s interval |

**Phase 2 :**

| Parametre pfSense | Valeur |
|--------------------|--------|
| Local Network | LAN subnet (10.100.0.0/24) |
| Remote Network | 172.16.132.0/24 |
| Protocol | ESP |
| Encryption Algorithms | AES 256-GCM, 128 bits |
| Hash Algorithms | SHA256 |
| PFS Key Group | 14 (2048 bit) |
| Lifetime | 3600 |

### 3.4 Regles firewall pfSense pour IPsec

Sur les **deux** pfSense, ajouter les regles suivantes :

**Onglet IPsec :**
- Allow All from IPsec (pour le lab, autoriser tout le trafic transitant par le tunnel)

**Onglet WAN/OPT1 :**
- Allow UDP 500 (IKE)
- Allow UDP 4500 (NAT-T)
- Allow ESP (Protocol 50)
- Allow ICMP (pour les tests)

### 3.5 Activation et test du tunnel

Sur les deux pfSense : **Status > IPsec > Connect**

```powershell
# Depuis DC01 (siege, 172.16.132.10), pinger DC-AZURE
ping 10.100.0.10

# Depuis DC-AZURE (10.100.0.10), pinger DC01
ping 172.16.132.10
```

Resultat attendu : reponse ping OK dans les deux sens.

---

## 4. Configuration production (FortiGate)

### 4.1 Tunnel Siege - Azure (FortiGate 100F)

```
# ============================================
# TUNNEL VPN SIEGE <-> AZURE
# FortiGate 100F (Siege Lille)
# ============================================

# --- Phase 1 : IKE ---
config vpn ipsec phase1-interface
    edit "VPN-AZURE"
        set interface "wan1"
        set ike-version 2
        set peertype any
        set net-device disable
        set proposal aes256gcm-sha256
        set dhgrp 14
        set remote-gw <IP_PUBLIQUE_AZURE_VPN_GATEWAY>
        set psksecret <CLE_PRE_PARTAGEE>
        set dpd on-idle
        set dpd-retryinterval 10
        set dpd-retrycount 3
        set comments "Tunnel vers Azure PRA"
    next
end

# --- Phase 2 : ESP ---
config vpn ipsec phase2-interface
    edit "VPN-AZURE-P2"
        set phase1name "VPN-AZURE"
        set proposal aes256gcm-sha256
        set pfs enable
        set dhgrp 14
        set replay enable
        set src-subnet 192.168.10.0 255.255.255.0
        set dst-subnet 10.100.0.0 255.255.255.0
        set comments "Siege LAN vers Azure Hub"
    next
end

# --- Route statique vers Azure via le tunnel ---
config router static
    edit 10
        set dst 10.100.0.0 255.255.255.0
        set device "VPN-AZURE"
        set comment "Route vers Azure Hub via VPN"
    next
    edit 11
        set dst 10.100.1.0 255.255.255.0
        set device "VPN-AZURE"
        set comment "Route vers Azure Backup via VPN"
    next
end

# --- Politique firewall pour le tunnel Azure ---
config firewall policy
    edit 20
        set name "SIEGE-TO-AZURE"
        set srcintf "VLAN20-SERVEURS" "VLAN10-MGMT"
        set dstintf "VPN-AZURE"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic siege vers Azure (replication AD, backup)"
    next
    edit 21
        set name "AZURE-TO-SIEGE"
        set srcintf "VPN-AZURE"
        set dstintf "VLAN20-SERVEURS" "VLAN10-MGMT"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic Azure vers siege (replication AD, recovery)"
    next
end
```

### 4.2 Tunnel Siege - Entrepot WH1 Lens (FortiGate 100F cote siege)

```
# ============================================
# TUNNEL VPN SIEGE <-> WH1 LENS
# FortiGate 100F (Siege Lille) — cote Hub
# ============================================

# --- Phase 1 ---
config vpn ipsec phase1-interface
    edit "VPN-WH1-LENS"
        set interface "wan1"
        set ike-version 2
        set peertype any
        set net-device disable
        set proposal aes256gcm-sha256
        set dhgrp 14
        set remote-gw <IP_PUBLIQUE_WH1>
        set psksecret <CLE_PRE_PARTAGEE_WH1>
        set dpd on-idle
        set dpd-retryinterval 10
        set dpd-retrycount 3
        set comments "Tunnel vers WH1 Lens"
    next
end

# --- Phase 2 ---
config vpn ipsec phase2-interface
    edit "VPN-WH1-LENS-P2"
        set phase1name "VPN-WH1-LENS"
        set proposal aes256gcm-sha256
        set pfs enable
        set dhgrp 14
        set replay enable
        set src-subnet 192.168.10.0 255.255.255.0
        set dst-subnet 192.168.20.0 255.255.255.0
        set comments "Siege LAN vers WH1 LAN"
    next
end

# --- Route statique ---
config router static
    edit 20
        set dst 192.168.20.0 255.255.255.0
        set device "VPN-WH1-LENS"
        set comment "Route vers WH1 Lens via VPN"
    next
end

# --- Politique firewall ---
config firewall policy
    edit 30
        set name "SIEGE-TO-WH1"
        set srcintf "VLAN20-SERVEURS" "VLAN30-DATA"
        set dstintf "VPN-WH1-LENS"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic siege vers WH1"
    next
    edit 31
        set name "WH1-TO-SIEGE"
        set srcintf "VPN-WH1-LENS"
        set dstintf "VLAN20-SERVEURS" "VLAN30-DATA"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic WH1 vers siege (WMS, AD, VoIP)"
    next
end
```

### 4.3 Template Siege vers WH2/WH3/Cross-dock

Reproduire la configuration de la section 4.2 en adaptant les valeurs suivantes :

| Tunnel | Nom Phase1 | Remote GW | Subnet distant | Route ID | Policy ID |
|--------|------------|-----------|----------------|----------|-----------|
| WH2 Valenciennes | VPN-WH2-VALENC | `<IP_PUBLIQUE_WH2>` | 192.168.30.0/24 | 30 | 40/41 |
| WH3 Arras | VPN-WH3-ARRAS | `<IP_PUBLIQUE_WH3>` | 192.168.40.0/24 | 40 | 50/51 |
| Cross-dock | VPN-CDK | `<IP_PUBLIQUE_CDK>` | 192.168.50.0/24 | 50 | 60/61 |

### 4.4 Configuration cote entrepot (FortiGate 60F -- exemple WH1 Lens)

```
# ============================================
# TUNNEL VPN WH1 LENS <-> SIEGE
# FortiGate 60F (WH1 Lens) — cote Spoke
# ============================================

# --- Phase 1 ---
config vpn ipsec phase1-interface
    edit "VPN-SIEGE"
        set interface "wan1"
        set ike-version 2
        set peertype any
        set net-device disable
        set proposal aes256gcm-sha256
        set dhgrp 14
        set remote-gw <IP_PUBLIQUE_SIEGE>
        set psksecret <CLE_PRE_PARTAGEE_WH1>
        set dpd on-idle
        set dpd-retryinterval 10
        set dpd-retrycount 3
        set comments "Tunnel vers Siege Lille"
    next
end

# --- Phase 2 ---
config vpn ipsec phase2-interface
    edit "VPN-SIEGE-P2"
        set phase1name "VPN-SIEGE"
        set proposal aes256gcm-sha256
        set pfs enable
        set dhgrp 14
        set replay enable
        set src-subnet 192.168.20.0 255.255.255.0
        set dst-subnet 192.168.10.0 255.255.255.0
        set comments "WH1 LAN vers Siege LAN"
    next
end

# --- Route statique vers le siege ---
config router static
    edit 10
        set dst 192.168.10.0 255.255.255.0
        set device "VPN-SIEGE"
        set comment "Route vers Siege Lille via VPN"
    next
end

# --- Route vers Azure via le siege (transit) ---
config router static
    edit 11
        set dst 10.100.0.0 255.255.255.0
        set device "VPN-SIEGE"
        set comment "Route vers Azure Hub via Siege"
    next
end

# --- Politique firewall ---
config firewall policy
    edit 10
        set name "WH1-TO-SIEGE"
        set srcintf "VLAN30-DATA" "VLAN40-VOIP"
        set dstintf "VPN-SIEGE"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic WH1 vers siege (WMS, AD, VoIP)"
    next
    edit 11
        set name "SIEGE-TO-WH1"
        set srcintf "VPN-SIEGE"
        set dstintf "VLAN30-DATA" "VLAN40-VOIP" "VLAN10-MGMT"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic siege vers WH1"
    next
end
```

### 4.5 Configuration cote Cross-dock (FortiGate 40F)

```
# ============================================
# TUNNEL VPN CROSS-DOCK <-> SIEGE
# FortiGate 40F — site saisonnier simplifie
# ============================================

# --- Phase 1 ---
config vpn ipsec phase1-interface
    edit "VPN-SIEGE"
        set interface "wan1"
        set ike-version 2
        set peertype any
        set net-device disable
        set proposal aes256gcm-sha256
        set dhgrp 14
        set remote-gw <IP_PUBLIQUE_SIEGE>
        set psksecret <CLE_PRE_PARTAGEE_CDK>
        set dpd on-idle
        set dpd-retryinterval 10
        set dpd-retrycount 3
        set comments "Tunnel vers Siege Lille"
    next
end

# --- Phase 2 ---
config vpn ipsec phase2-interface
    edit "VPN-SIEGE-P2"
        set phase1name "VPN-SIEGE"
        set proposal aes256gcm-sha256
        set pfs enable
        set dhgrp 14
        set replay enable
        set src-subnet 192.168.50.0 255.255.255.0
        set dst-subnet 192.168.10.0 255.255.255.0
        set comments "Cross-dock vers Siege"
    next
end

# --- Route statique ---
config router static
    edit 10
        set dst 192.168.10.0 255.255.255.0
        set device "VPN-SIEGE"
        set comment "Route vers Siege via VPN"
    next
end

# --- Politique firewall minimale ---
config firewall policy
    edit 1
        set name "CDK-TO-SIEGE"
        set srcintf "internal"
        set dstintf "VPN-SIEGE"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTPS" "SMB" "DNS"
        set logtraffic all
        set comments "Acces WMS et fichiers au siege"
    next
    edit 2
        set name "SIEGE-TO-CDK"
        set srcintf "VPN-SIEGE"
        set dstintf "internal"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Administration depuis siege"
    next
    edit 100
        set name "DENY-ALL"
        set srcintf "any"
        set dstintf "any"
        set srcaddr "all"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
end
```

---

## 5. Supervision et depannage VPN

### 5.1 Commandes de diagnostic FortiGate

```
# Verifier l'etat de tous les tunnels
get vpn ipsec tunnel summary

# Details d'un tunnel specifique
diagnose vpn ike gateway list name VPN-AZURE
diagnose vpn tunnel list name VPN-AZURE-P2

# Statistiques de trafic par tunnel
diagnose vpn ipsec status

# Debug IKE en temps reel (Phase 1)
diagnose debug application ike -1
diagnose debug enable

# Debug ESP en temps reel (Phase 2)
diagnose debug application ipsec -1
diagnose debug enable

# Arreter le debug
diagnose debug disable
diagnose debug reset

# Forcer la reenegociation d'un tunnel
diagnose vpn ike gateway flush name VPN-AZURE
```

### 5.2 Commandes de diagnostic pfSense (POC)

```
# Verifier l'etat du tunnel
Status > IPsec > Overview

# Logs IPsec
Status > System Logs > IPsec

# Forcer la reconnexion
Status > IPsec > Disconnect puis Connect

# Test de connectivite via le tunnel
Diagnostics > Ping (source: LAN address, destination: remote LAN)
```

### 5.3 Guide de depannage

| Probleme | Cause probable | Diagnostic | Solution |
|----------|----------------|------------|----------|
| Tunnel ne monte pas | PSK differente des 2 cotes | `diagnose vpn ike gateway list` | Verifier la cle sur les 2 equipements |
| Phase 1 OK, Phase 2 echoue | Subnets ne matchent pas | `diagnose vpn tunnel list` | Verifier src-subnet et dst-subnet |
| Tunnel UP, pas de trafic | Regles firewall manquantes | `diagnose firewall policy list` | Ajouter les politiques VPN |
| Tunnel UP, ping bloque | Route statique manquante | `get router info routing-table all` | Ajouter la route vers le subnet distant |
| Tunnel tombe frequemment | DPD trop agressif ou lien instable | Logs IKE | Augmenter dpd-retryinterval ou verifier le lien |
| Lenteurs sur le tunnel | MTU/MSS trop eleve | `ping -f -l 1400 <remote>` | Ajuster MTU a 1400 sur l'interface tunnel |
| Replication AD echoue via VPN | Ports AD bloques | `nslookup`, `repadmin /replsummary` | Ouvrir ports 389, 636, 3268, 88, 53, 135, 49152-65535 |

### 5.4 Ports requis pour les services transitant par VPN

| Service | Ports | Direction | Remarque |
|---------|-------|-----------|----------|
| Active Directory | 389 (LDAP), 636 (LDAPS), 3268 (GC), 88 (Kerberos), 53 (DNS), 135 (RPC), 49152-65535 (RPC dynamique) | Bidirectionnel | Replication AD entre siege et Azure |
| WMS | 443 (HTTPS) | Entrepots vers siege | Acces application metier |
| Partages fichiers | 445 (SMB) | Entrepots vers siege | Documents partages |
| VoIP | 5060 (SIP), 10000-20000 (RTP) | Entrepots vers siege | Telephonie IP centralisee |
| Backup | 443 (HTTPS) | Siege vers Azure | Sauvegarde vers Azure Blob |
| DNS | 53 | Bidirectionnel | Resolution inter-sites |

---

## 6. Securisation des tunnels VPN

### 6.1 Bonnes pratiques appliquees

| Pratique | Implementation | Statut |
|----------|----------------|--------|
| Chiffrement fort | AES-256-GCM (AEAD) | Applique |
| PFS (Perfect Forward Secrecy) | Group 14 en Phase 2 | Applique |
| DPD (Dead Peer Detection) | Actif, 10s intervalle | Applique |
| Rotation des cles | Phase 1: 8h, Phase 2: 1h | Applique |
| Protection anti-rejeu | Replay detection activee | Applique |
| Authentification renforcee | PSK en lab, certificats en production | A migrer |
| Logging complet | logtraffic all sur chaque policy | Applique |

### 6.2 Migration PSK vers certificats (production)

En production, remplacer l'authentification PSK par des certificats X.509 :

```
# Importer le certificat CA
config vpn certificate ca
    edit "NordTransit-CA"
        set ca "<CONTENU_CERTIFICAT_CA>"
    next
end

# Importer le certificat local
config vpn certificate local
    edit "FG-SIEGE-CERT"
        set private-key "<CLE_PRIVEE>"
        set certificate "<CERTIFICAT>"
    next
end

# Modifier le tunnel pour utiliser les certificats
config vpn ipsec phase1-interface
    edit "VPN-AZURE"
        set authmethod signature
        set certificate "FG-SIEGE-CERT"
        set peer "NordTransit-CA"
    next
end
```

---

## 7. Verification et validation

| Test | Commande / Action | Resultat attendu |
|------|-------------------|-------------------|
| Tunnel UP | `get vpn ipsec tunnel summary` | Tous les tunnels en "up" |
| Ping cross-site (POC) | `ping 10.100.0.10` depuis 172.16.132.10 | Reponse OK |
| Ping retour (POC) | `ping 172.16.132.10` depuis 10.100.0.10 | Reponse OK |
| DNS cross-site | `nslookup dc-azure.lab.local` | Resolu via le tunnel |
| Replication AD | `repadmin /replsummary` | 0 failures |
| Trafic chiffre | `diagnose vpn tunnel list` | Compteurs TX/RX en augmentation |
| DPD fonctionnel | Couper un lien, attendre 30s | Tunnel detecte comme down |
| Failover | Couper lien principal | Bascule sur lien backup |

---

## 8. Annexes

### 8.1 Recapitulatif des adresses IP des tunnels

| Site | Reseau LAN | IP publique WAN | Equipement |
|------|------------|-----------------|------------|
| Siege Lille | 192.168.10.0/24 | `<IP_PUBLIQUE_SIEGE>` | FortiGate 100F |
| WH1 Lens | 192.168.20.0/24 | `<IP_PUBLIQUE_WH1>` | FortiGate 60F |
| WH2 Valenciennes | 192.168.30.0/24 | `<IP_PUBLIQUE_WH2>` | FortiGate 60F |
| WH3 Arras | 192.168.40.0/24 | `<IP_PUBLIQUE_WH3>` | FortiGate 60F |
| Cross-dock | 192.168.50.0/24 | `<IP_PUBLIQUE_CDK>` | FortiGate 40F |
| Azure Hub | 10.100.0.0/24 | `<IP_AZURE_VPN_GW>` | Azure VPN Gateway |
| Azure Backup | 10.100.1.0/24 | (via Azure Hub) | Azure Storage |

### 8.2 Adresses POC

| Equipement | Interface | IP | Role |
|------------|-----------|-----|------|
| FW-SIEGE (VM 32001) | LAN (vtnet0) | 172.16.132.1/24 | Gateway siege POC |
| FW-SIEGE (VM 32001) | WAN (vtnet1) | 10.100.0.254/24 | Endpoint tunnel cote siege |
| FW-AZURE (VM 32005) | LAN (vtnet0) | 10.100.0.1/24 | Gateway Azure POC |
| FW-AZURE (VM 32005) | WAN (vtnet1) | Sur vmbr2 | Endpoint tunnel cote Azure |
| DC01 | LAN | 172.16.132.10 | DC siege |
| DC-AZURE (VM 32012) | LAN | 10.100.0.10 | DC replique Azure |

### 8.3 Liens de reference

- Guide lab tunnel IPsec : `docs/03-lab-poc/05-azure-tunnel.md`
- Guide pfSense siege : `docs/03-lab-poc/02-pfsense-siege.md`
- Strategie securite : `docs/02-conception/03-strategie-securite.md`
- Plan VLAN : `docs/02-conception/02-plan-adressage-vlan.md`
- Architecture cible : `_specs/solution/architecture-cible.md`
- Configuration pare-feu : `docs/04-livrables/configs/pare-feu.md`
- Fichiers bruts pfSense : `configs/pfsense/` (a exporter apres le lab)
