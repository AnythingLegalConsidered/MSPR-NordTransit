---
title: "pfSense Azure et tunnel IPsec"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 02-pfsense-siege.md complete"
  - "VM FW-AZURE (32005) installee avec pfSense"
---

# pfSense Azure et tunnel IPsec

## Objectif

> Installer pfSense cote "Azure", configurer le tunnel IPsec entre les 2 pfSense,
> puis deployer DC-AZURE comme controleur de domaine replique.
> A la fin, le siege et Azure communiquent via VPN et AD est replique sur les 2 sites.

## Prerequis

- [ ] FW-SIEGE (32001) operationnel
- [ ] FW-AZURE (32005) cree avec pfSense
- [ ] DC-AZURE (32012) cree avec Windows Server 2022

## Etapes

### 1. Installer pfSense sur FW-AZURE

**Pourquoi** : FW-AZURE simule la VPN Gateway Azure.

Installation identique a FW-SIEGE (guide 02), mais avec :
- **LAN** : 10.100.0.1/24 (reseau Azure)
- **WAN** : interface sur vmbr2 pour le tunnel

> Note : Dans le lab, les 2 pfSense sont sur le meme bridge vmbr2 — ce bridge simule "Internet".

### 2. Configurer le tunnel IPsec cote SIEGE

**Pourquoi** : Le tunnel IPsec relie les 2 reseaux de maniere chiffree.

Sur FW-SIEGE → VPN → IPsec :

**Phase 1 :**
- Remote Gateway : 10.100.0.1 (FW-AZURE)
- Authentication : Mutual PSK
- Pre-Shared Key : `MSPR-VPN-2024!`
- Encryption : AES-256-GCM
- Hash : SHA-256
- DH Group : 14 (2048 bit)
- Lifetime : 28800

**Phase 2 :**
- Local Network : 172.16.132.0/24 (siege)
- Remote Network : 10.100.0.0/24 (Azure)
- Protocol : ESP
- Encryption : AES-256-GCM
- Hash : SHA-256
- PFS : Group 14
- Lifetime : 3600

### 3. Configurer le tunnel IPsec cote AZURE

**Pourquoi** : Les 2 cotes du tunnel doivent etre symetriques.

Sur FW-AZURE → VPN → IPsec :

Configuration miroir de l'etape 2 :
- Remote Gateway : cote siege du bridge (verifier l'IP WAN de FW-SIEGE)
- PSK : identique (`MSPR-VPN-2024!`)
- Local Network : 10.100.0.0/24
- Remote Network : 172.16.132.0/24

### 4. Activer et tester le tunnel

**Pourquoi** : Verifier que les 2 reseaux communiquent a travers le VPN.

Sur les 2 pfSense : Status → IPsec → Connect

```powershell
# Depuis DC01 (siege), pinger DC-AZURE
ping 10.100.0.10

# Depuis DC-AZURE, pinger DC01
ping 172.16.132.10
```

**Resultat attendu** : Ping OK dans les 2 sens.

### 5. Promouvoir DC-AZURE comme DC replique

**Pourquoi** : DC-AZURE = 3eme DC dans le cloud. Si le siege est detruit, AD survit.

Sur DC-AZURE (DNS pointe vers DC01 via le tunnel : 172.16.132.10) :

```powershell
# Installer AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promouvoir dans le domaine existant
Install-ADDSDomainController `
    -DomainName "lab.local" `
    -InstallDns:$true `
    -SiteName "Azure" `
    -Credential (Get-Credential) `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Force:$true
```

> Credentials : LAB\Administrator / P@ssw0rd!

### 6. Verifier la replication cross-site

```powershell
# Lister les 3 DC
Get-ADDomainController -Filter *

# Replication
repadmin /replsummary

# DNS cross-site
nslookup dc-azure.lab.local
```

**Resultat attendu** : 3 DC listes (DC01, DC02, DC-AZURE), replication OK.

## Verification

| Test | Commande | Resultat attendu |
|------|----------|-------------------|
| Tunnel UP | Status → IPsec sur pfSense | "Established" |
| Ping cross-site | `ping 10.100.0.10` depuis DC01 | Reponse OK |
| DNS cross-site | `nslookup dc-azure.lab.local` | Resolu |
| 3 DC actifs | `Get-ADDomainController -Filter *` | 3 DC |
| Replication OK | `repadmin /replsummary` | 0 failures |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Tunnel ne monte pas | PSK differentes | Verifier la cle des 2 cotes |
| Ping bloque malgre tunnel UP | Regles firewall IPsec | Ajouter "Allow all from IPsec" sur les 2 pfSense |
| DC-AZURE ne joint pas le domaine | DNS ne passe pas le tunnel | Verifier `nslookup lab.local 172.16.132.10` depuis DC-AZURE |
| Replication echoue | Ports AD bloques | Ouvrir ports 389, 636, 3268, 88, 53, 135, 49152-65535 |

## Liens

- Spec de reference : `_specs/poc/poc3-tunnel-azure.md`
- Guide precedent : `docs/03-lab-poc/04-ipbx-qos.md`
- Guide suivant : `docs/03-lab-poc/06-wms-simulation.md`
