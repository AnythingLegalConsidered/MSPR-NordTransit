---
title: "Fichiers de Configuration Pare-feu"
subtitle: "MSPR - NordTransit Logistics"
author: "Groupe 2 - PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise"
date: 2026-02-06
version: "1.0"
toc: true
---

# Fichiers de Configuration Pare-feu

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-02-06 |
| Auteurs | Groupe 2 : PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise |
| Statut | Complet |

---

## 1. Inventaire pare-feu

### 1.1 Equipements cibles

| Site | Ancien equipement | Nouveau modele | IP Management | Firmware | Role |
|------|-------------------|----------------|---------------|----------|------|
| Siege Lille | FortiGate 80D (EOL) | FortiGate 100F | 192.168.10.1/26 | v7.4.x | Hub VPN, UTM complet, debit 1 Gbps |
| WH1 Lens | DrayTek 2860 | FortiGate 60F | 192.168.20.1/27 | v7.4.x | VPN IKEv2, QoS, spoke |
| WH2 Valenciennes | DrayTek 2860 | FortiGate 60F | 192.168.30.1/27 | v7.4.x | VPN IKEv2, QoS, spoke |
| WH3 Arras | DrayTek 2860 | FortiGate 60F | 192.168.40.1/27 | v7.4.x | VPN IKEv2, QoS, spoke |
| Cross-dock | Aucun | FortiGate 40F | 192.168.50.1/24 | v7.4.x | Protection minimale site saisonnier |

### 1.2 Equivalence POC

| Production (FortiGate) | POC (pfSense) | VM Proxmox | IP POC |
|-------------------------|---------------|------------|--------|
| FortiGate 100F (Siege) | pfSense FW-SIEGE | VM 32001 | LAN: 172.16.132.1/24, WAN: 10.100.0.254/24 |
| Azure VPN Gateway | pfSense FW-AZURE | VM 32005 | LAN: 10.100.0.1/24, WAN: sur vmbr2 |

---

## 2. Plan d'adressage VLAN par pare-feu

### 2.1 Principe

> **Un numero de VLAN = un type de trafic, partout.**
> VLAN 10 = Admin | VLAN 20 = Serveurs | VLAN 30 = Users/Data | VLAN 40 = VoIP

### 2.2 Siege Lille (FortiGate 100F)

| VLAN ID | Nom | Reseau | Gateway | Plage DHCP | DSCP |
|---------|-----|--------|---------|------------|------|
| 10 | MGMT | 192.168.10.0/26 | .1 | Statique | CS2 (16) |
| 20 | SERVEURS | 192.168.10.64/26 | .65 | Statique | AF31 (26) |
| 30 | DATA | 192.168.10.128/26 | .129 | .130-.190 | BE (0) |
| 40 | VOIP | 192.168.10.192/26 | .193 | .194-.250 | EF (46) |

### 2.3 Entrepots (FortiGate 60F)

| Site | VLAN 10 MGMT | VLAN 30 DATA | VLAN 40 VOIP |
|------|--------------|--------------|--------------|
| WH1 Lens | 192.168.20.0/27 (GW: .1) | 192.168.20.32/25 (GW: .33, DHCP: .34-.150) | 192.168.20.160/27 (GW: .161, DHCP: .162-.190) |
| WH2 Valenciennes | 192.168.30.0/27 (GW: .1) | 192.168.30.32/25 (GW: .33, DHCP: .34-.150) | 192.168.30.160/27 (GW: .161, DHCP: .162-.190) |
| WH3 Arras | 192.168.40.0/27 (GW: .1) | 192.168.40.32/25 (GW: .33, DHCP: .34-.150) | 192.168.40.160/27 (GW: .161, DHCP: .162-.190) |

### 2.4 Cross-dock et Azure

| Site | Reseau | Gateway | Remarque |
|------|--------|---------|----------|
| Cross-dock | 192.168.50.0/24 (DATA seul) | .1 | Site simple, pas de segmentation VLAN |
| Azure Hub | 10.100.0.0/24 | .1 | DC replique + VPN Gateway |
| Azure Backup | 10.100.1.0/24 | .1 | Stockage backup |

---

## 3. Regles de firewall

### 3.1 Regles inter-VLAN (appliquees sur tous les sites avec VLAN)

| # | Source | Destination | Service | Port(s) | Action | Justification |
|---|--------|-------------|---------|----------|--------|---------------|
| 1 | VLAN 10 (MGMT) | Toutes les zones | Tout | * | ACCEPT | Administration reseau |
| 2 | VLAN 40 (VOIP) | VLAN 20 (SERVEURS) | SIP, RTP | 5060, 10000-20000 | ACCEPT | Telephones IP vers IPBX |
| 3 | VLAN 30 (DATA) | VLAN 20 (SERVEURS) | HTTP, HTTPS, SMB, DNS, LDAP, LDAPS, Kerberos | 80, 443, 445, 53, 389, 636, 88 | ACCEPT | Postes vers WMS, AD, fichiers |
| 4 | VLAN 30 (DATA) | VLAN 40 (VOIP) | Tout | * | DENY | Isolation stricte VoIP |
| 5 | VLAN 40 (VOIP) | VLAN 30 (DATA) | Tout | * | DENY | Isolation stricte VoIP |
| 6 | VLAN 20 (SERVEURS) | VLAN 20 (SERVEURS) | Tout | * | ACCEPT | Communication inter-serveurs |
| 7 | Tout VLAN | Tout VLAN | Tout | * | DENY | Regle implicite de blocage |

### 3.2 Regles WAN (entree)

| # | Source | Destination | Service | Port(s) | Action | Justification |
|---|--------|-------------|---------|----------|--------|---------------|
| 1 | Peers VPN (sites NordTransit) | LAN interne | IPsec | UDP 500, 4500 | ACCEPT | Etablissement tunnels VPN |
| 2 | Peers VPN | LAN interne | ESP | Protocol 50 | ACCEPT | Trafic chiffre VPN |
| 3 | Azure VPN Gateway | LAN interne | IPsec | UDP 500, 4500 | ACCEPT | Tunnel PRA Azure |
| 4 | Tout | Tout | Tout | * | DENY | Regle par defaut |

### 3.3 Regles WAN (sortie)

| # | Source | Destination | Service | Port(s) | Action | Justification |
|---|--------|-------------|---------|----------|--------|---------------|
| 1 | LAN | Internet | HTTP/HTTPS | 80, 443 | ACCEPT | Navigation et mises a jour |
| 2 | LAN | Internet | DNS | 53 | ACCEPT | Resolution DNS externe |
| 3 | LAN | Internet | NTP | 123 | ACCEPT | Synchronisation horaire |
| 4 | SERVEURS | Azure Blob | HTTPS | 443 | ACCEPT | Backup externalise |
| 5 | LAN | Tout | Tout | * | DENY | Blocage par defaut |

### 3.4 Regles specifiques au cross-dock

| # | Source | Destination | Service | Action | Justification |
|---|--------|-------------|---------|--------|---------------|
| 1 | 192.168.50.0/24 | Siege via VPN | HTTPS, SMB | ACCEPT | Acces WMS et fichiers |
| 2 | 192.168.50.0/24 | Internet | HTTP, HTTPS, DNS | ACCEPT | Navigation minimale |
| 3 | Tout | Tout | Tout | DENY | Site saisonnier, surface minimale |

---

## 4. Configuration QoS

### 4.1 Politique QoS par VLAN

| VLAN | Priorite | Marquage DSCP | Valeur DSCP | Bande passante garantie | Remarque |
|------|----------|---------------|-------------|-------------------------|----------|
| VOIP (40) | Haute | EF | 46 | 30% minimum | Priorite absolue pour la voix |
| SERVEURS (20) | Moyenne-Haute | AF31 | 26 | 40% | WMS, AD, DNS critiques |
| DATA (30) | Normale | BE | 0 | Best effort | Trafic utilisateur standard |
| MGMT (10) | Normale | CS2 | 16 | 5% | Faible volume, acces admin |

### 4.2 Configuration FortiGate CLI -- QoS Siege

```
# --- Traffic Shapers ---

config firewall shaper traffic-shaper
    edit "SHAPER-VOIP"
        set guaranteed-bandwidth 300000
        set maximum-bandwidth 1000000
        set priority high
        set dscp-marking enable
        set dscp-marking-value 46
    next
    edit "SHAPER-SERVEURS"
        set guaranteed-bandwidth 400000
        set maximum-bandwidth 1000000
        set priority medium
        set dscp-marking enable
        set dscp-marking-value 26
    next
    edit "SHAPER-DATA"
        set guaranteed-bandwidth 0
        set maximum-bandwidth 1000000
        set priority low
        set dscp-marking enable
        set dscp-marking-value 0
    next
    edit "SHAPER-MGMT"
        set guaranteed-bandwidth 50000
        set maximum-bandwidth 1000000
        set priority low
        set dscp-marking enable
        set dscp-marking-value 16
    next
end

# --- Shaping Policy : appliquer les shapers par VLAN source ---

config firewall shaping-policy
    edit 1
        set name "QOS-VOIP-PRIORITAIRE"
        set srcintf "VLAN40-VOIP"
        set dstintf "any"
        set service "ALL"
        set traffic-shaper "SHAPER-VOIP"
        set traffic-shaper-reverse "SHAPER-VOIP"
    next
    edit 2
        set name "QOS-SERVEURS"
        set srcintf "VLAN20-SERVEURS"
        set dstintf "any"
        set service "ALL"
        set traffic-shaper "SHAPER-SERVEURS"
        set traffic-shaper-reverse "SHAPER-SERVEURS"
    next
    edit 3
        set name "QOS-DATA"
        set srcintf "VLAN30-DATA"
        set dstintf "any"
        set service "ALL"
        set traffic-shaper "SHAPER-DATA"
        set traffic-shaper-reverse "SHAPER-DATA"
    next
    edit 4
        set name "QOS-MGMT"
        set srcintf "VLAN10-MGMT"
        set dstintf "any"
        set service "ALL"
        set traffic-shaper "SHAPER-MGMT"
        set traffic-shaper-reverse "SHAPER-MGMT"
    next
end
```

### 4.3 Configuration QoS entrepots (FortiGate 60F)

La meme logique s'applique, avec les interfaces adaptees. Les entrepots n'ayant pas de VLAN 20 (SERVEURS), seuls les shapers VOIP, DATA et MGMT sont configures.

```
# Template entrepot (adapter le nom des interfaces)
config firewall shaper traffic-shaper
    edit "SHAPER-VOIP"
        set guaranteed-bandwidth 150000
        set maximum-bandwidth 500000
        set priority high
        set dscp-marking enable
        set dscp-marking-value 46
    next
    edit "SHAPER-DATA"
        set guaranteed-bandwidth 0
        set maximum-bandwidth 500000
        set priority low
        set dscp-marking enable
        set dscp-marking-value 0
    next
    edit "SHAPER-MGMT"
        set guaranteed-bandwidth 25000
        set maximum-bandwidth 500000
        set priority low
        set dscp-marking enable
        set dscp-marking-value 16
    next
end
```

---

## 5. Configuration POC (pfSense)

### 5.1 Architecture POC

Le POC utilise deux instances pfSense sur Proxmox pour simuler l'infrastructure FortiGate :

- **FW-SIEGE** (VM 32001) : simule le FortiGate 100F
  - LAN : `vtnet0` sur vmbr1 -- 172.16.132.1/24
  - WAN : `vtnet1` sur vmbr2 -- 10.100.0.254/24 (segment "Internet" simule)
- **FW-AZURE** (VM 32005) : simule la VPN Gateway Azure
  - LAN : 10.100.0.1/24 (reseau Azure)
  - WAN : interface sur vmbr2 (meme bridge que FW-SIEGE)

### 5.2 Installation pfSense

1. Demarrer la VM, booter sur l'ISO pfSense
2. Accept defaults, Install, Continue
3. Partition : Auto (ZFS), Stripe
4. Reboot apres installation

### 5.3 Assignation des interfaces (FW-SIEGE)

```
Should VLANs be set up now? n
Enter the WAN interface: vtnet1     (vmbr2 - liaison Azure)
Enter the LAN interface: vtnet0     (vmbr1 - reseau siege)
```

Configuration IP :
- **LAN** : 172.16.132.1/24 -- pas de DHCP (IPs statiques en lab)
- **WAN** : 10.100.0.254/24 -- cote siege du tunnel

### 5.4 Configuration de base pfSense

Dans **System > General Setup** :
- Hostname : `fw-siege`
- Domain : `lab.local`
- DNS Servers : `8.8.8.8` (temporaire, remplacer par `172.16.132.10` apres AD)

Dans **System > Advanced > Admin Access** :
- Desactiver le redirect HTTP vers HTTPS (environnement lab uniquement)

### 5.5 Regles firewall POC

**LAN** :
- Allow All (lab uniquement -- a restreindre en production)

**WAN/OPT1** :
- Allow IPsec : UDP 500, 4500
- Allow ICMP : pour les tests de connectivite
- Allow ESP : Protocol 50

### 5.6 Acces interface web

```
https://172.16.132.1
Login: admin / pfsense
```

---

## 6. Configuration production (FortiGate)

### 6.1 Configuration systeme (siege)

```
# --- Parametres systeme de base ---

config system global
    set hostname "FG-SIEGE-LILLE"
    set timezone 28
    set admin-sport 8443
    set admintimeout 30
end

config system dns
    set primary 192.168.10.66
    set secondary 192.168.10.67
    set domain "nordtransit.local"
end

config system ntp
    set ntpsync enable
    set server-mode enable
    config ntpserver
        edit 1
            set server "0.fr.pool.ntp.org"
        next
        edit 2
            set server "1.fr.pool.ntp.org"
        next
    end
end
```

### 6.2 Interfaces VLAN (siege)

```
# --- VLAN 10 : MGMT ---
config system interface
    edit "VLAN10-MGMT"
        set vdom "root"
        set ip 192.168.10.1 255.255.255.192
        set allowaccess ping https ssh snmp
        set interface "internal"
        set vlanid 10
        set description "Administration reseau"
        set role lan
    next
end

# --- VLAN 20 : SERVEURS ---
config system interface
    edit "VLAN20-SERVEURS"
        set vdom "root"
        set ip 192.168.10.65 255.255.255.192
        set allowaccess ping
        set interface "internal"
        set vlanid 20
        set description "VMs et stockage SAN"
        set role lan
    next
end

# --- VLAN 30 : DATA ---
config system interface
    edit "VLAN30-DATA"
        set vdom "root"
        set ip 192.168.10.129 255.255.255.192
        set allowaccess ping
        set interface "internal"
        set vlanid 30
        set description "Postes de travail et terminaux RF"
        set role lan
    next
end

# --- VLAN 40 : VOIP ---
config system interface
    edit "VLAN40-VOIP"
        set vdom "root"
        set ip 192.168.10.193 255.255.255.192
        set allowaccess ping
        set interface "internal"
        set vlanid 40
        set description "Telephones IP Cisco"
        set role lan
    next
end
```

### 6.3 Serveur DHCP (siege -- VLAN 30 et 40)

```
# --- DHCP VLAN 30 DATA ---
config system dhcp server
    edit 1
        set interface "VLAN30-DATA"
        set default-gateway 192.168.10.129
        set dns-server1 192.168.10.66
        set dns-server2 192.168.10.67
        config ip-range
            edit 1
                set start-ip 192.168.10.130
                set end-ip 192.168.10.190
            next
        end
        set lease-time 86400
    next
end

# --- DHCP VLAN 40 VOIP ---
config system dhcp server
    edit 2
        set interface "VLAN40-VOIP"
        set default-gateway 192.168.10.193
        set dns-server1 192.168.10.66
        config ip-range
            edit 1
                set start-ip 192.168.10.194
                set end-ip 192.168.10.250
            next
        end
        set lease-time 86400
        set ntp-server1 192.168.10.1
        set vci-match enable
        set vci-string "Cisco"
    next
end
```

### 6.4 Politiques de firewall (siege)

```
# --- Regle 1 : MGMT vers toutes les zones ---
config firewall policy
    edit 1
        set name "MGMT-TO-ALL"
        set srcintf "VLAN10-MGMT"
        set dstintf "any"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Administration reseau - acces total"
    next

    # --- Regle 2 : VOIP vers SERVEURS (SIP/RTP) ---
    edit 2
        set name "VOIP-TO-IPBX"
        set srcintf "VLAN40-VOIP"
        set dstintf "VLAN20-SERVEURS"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "SIP" "H323"
        set logtraffic all
        set comments "Telephones vers IPBX"
    next

    # --- Regle 3 : DATA vers SERVEURS (WMS, AD, fichiers) ---
    edit 3
        set name "DATA-TO-SERVEURS"
        set srcintf "VLAN30-DATA"
        set dstintf "VLAN20-SERVEURS"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS" "LDAP" "SMB" "CIFS"
        set logtraffic all
        set comments "Postes vers WMS, AD, partages fichiers"
    next

    # --- Regle 4 : Blocage DATA vers VOIP ---
    edit 4
        set name "DENY-DATA-TO-VOIP"
        set srcintf "VLAN30-DATA"
        set dstintf "VLAN40-VOIP"
        set srcaddr "all"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Isolation VoIP - securite"
    next

    # --- Regle 5 : LAN vers Internet (navigation) ---
    edit 5
        set name "LAN-TO-INTERNET"
        set srcintf "VLAN30-DATA" "VLAN20-SERVEURS"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS" "NTP"
        set nat enable
        set logtraffic all
        set comments "Acces Internet sortant"
    next

    # --- Regle 6 : VPN entrant ---
    edit 6
        set name "VPN-INBOUND"
        set srcintf "VPN-WH1" "VPN-WH2" "VPN-WH3" "VPN-AZURE"
        set dstintf "VLAN20-SERVEURS" "VLAN30-DATA"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Trafic VPN inter-sites"
    next

    # --- Regle implicite : Deny All ---
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
        set comments "Blocage par defaut - tout ce qui n'est pas explicitement autorise"
    next
end
```

### 6.5 Template entrepot (FortiGate 60F -- exemple WH1 Lens)

```
# --- Interfaces VLAN (adapter IP par site) ---
config system interface
    edit "VLAN10-MGMT"
        set vdom "root"
        set ip 192.168.20.1 255.255.255.224
        set allowaccess ping https ssh snmp
        set interface "internal"
        set vlanid 10
        set description "Administration WH1"
        set role lan
    next
    edit "VLAN30-DATA"
        set vdom "root"
        set ip 192.168.20.33 255.255.255.128
        set allowaccess ping
        set interface "internal"
        set vlanid 30
        set description "Postes et terminaux RF WH1"
        set role lan
    next
    edit "VLAN40-VOIP"
        set vdom "root"
        set ip 192.168.20.161 255.255.255.224
        set allowaccess ping
        set interface "internal"
        set vlanid 40
        set description "Telephones IP WH1"
        set role lan
    next
end

# --- Politiques firewall entrepot ---
config firewall policy
    edit 1
        set name "MGMT-TO-ALL"
        set srcintf "VLAN10-MGMT"
        set dstintf "any"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
    edit 2
        set name "DATA-TO-SIEGE-VPN"
        set srcintf "VLAN30-DATA"
        set dstintf "VPN-SIEGE"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "SMB" "DNS" "LDAP"
        set logtraffic all
        set comments "Acces WMS et AD au siege"
    next
    edit 3
        set name "VOIP-TO-SIEGE-VPN"
        set srcintf "VLAN40-VOIP"
        set dstintf "VPN-SIEGE"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "SIP" "H323"
        set logtraffic all
        set comments "VoIP vers IPBX siege"
    next
    edit 4
        set name "DENY-DATA-TO-VOIP"
        set srcintf "VLAN30-DATA"
        set dstintf "VLAN40-VOIP"
        set srcaddr "all"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
    edit 5
        set name "LAN-TO-INTERNET"
        set srcintf "VLAN30-DATA"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS" "NTP"
        set nat enable
        set logtraffic all
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

### 6.6 Logging et supervision

```
# --- Logging vers FortiAnalyzer ou syslog ---
config log syslogd setting
    set status enable
    set server "192.168.10.70"
    set port 514
    set facility local7
end

# --- Alertes email ---
config alertemail setting
    set username "alerts@nordtransit.local"
    set mailto1 "admin@nordtransit.local"
    set filter-mode threshold
end

# --- SNMP pour supervision ---
config system snmp community
    edit 1
        set name "nordtransit-ro"
        set query-v2c-status enable
        config hosts
            edit 1
                set ip 192.168.10.0 255.255.255.192
            next
        end
    next
end
```

---

## 7. Securisation des acces administration

### 7.1 MFA sur les acces FortiGate

| Acces | MFA cible | Methode |
|-------|-----------|---------|
| Console admin FortiGate | FortiToken (TOTP) | FortiToken Mobile |
| VPN distant | FortiToken (TOTP) | FortiToken Mobile |
| RDP serveurs | Azure MFA | Conditional Access |
| Console Proxmox | TOTP | PAM + Google Authenticator |

### 7.2 Comptes administrateur

```
config system admin
    edit "admin-ntl"
        set accprofile "super_admin"
        set two-factor fortitoken
        set fortitoken "<SERIAL_FORTITOKEN>"
        set trusthost1 192.168.10.0 255.255.255.192
        set password "<MOT_DE_PASSE_FORT>"
    next
end
```

---

## 8. Verification et validation

| Test | Methode | Resultat attendu |
|------|---------|-------------------|
| VLAN segmentes | Depuis VLAN 30, ping vers VLAN 40 | Timeout (DENY) |
| VOIP vers IPBX | Depuis VLAN 40, SIP vers VLAN 20 | Connexion OK |
| DATA vers WMS | Depuis VLAN 30, HTTPS vers VLAN 20 | Acces WMS OK |
| Acces Internet | Depuis VLAN 30, curl https://google.com | Reponse 200 |
| Deny par defaut | Depuis VLAN 30, telnet vers port non autorise | Connexion refusee |
| QoS VoIP | Test iperf avec marquage EF | Bande passante garantie 30% |
| Logs actifs | Generer du trafic, verifier les logs | Entrees visibles dans le syslog |

---

## 9. Annexes

### 9.1 Correspondance ports/services

| Service | Port(s) | Protocole |
|---------|---------|-----------|
| SIP | 5060 | UDP/TCP |
| RTP | 10000-20000 | UDP |
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| DNS | 53 | UDP/TCP |
| LDAP | 389 | TCP |
| SMB/CIFS | 445 | TCP |
| IPsec IKE | 500 | UDP |
| IPsec NAT-T | 4500 | UDP |
| ESP | Protocol 50 | IP |
| NTP | 123 | UDP |
| SNMP | 161/162 | UDP |
| Syslog | 514 | UDP |

### 9.2 Liens de reference

- Guide lab pfSense : `docs/03-lab-poc/02-pfsense-siege.md`
- Plan VLAN : `docs/02-conception/02-plan-adressage-vlan.md`
- Strategie securite : `docs/02-conception/03-strategie-securite.md`
- Architecture cible : `_specs/solution/architecture-cible.md`
- Fichiers bruts pfSense : `configs/pfsense/` (a exporter apres le lab)
- Configuration VPN : `docs/04-livrables/configs/vpn-ipsec.md`
