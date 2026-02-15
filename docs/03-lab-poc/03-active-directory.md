---
title: "Active Directory - DC01 et DC02"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 02-pfsense-siege.md complete"
  - "VMs DC01 (32010) et DC02 (32011) installees avec Windows Server 2022"
---

# Active Directory - DC01 et DC02

## Objectif

> Deployer Active Directory avec un DC principal (DC01) et un DC secondaire (DC02).
> Cela demontre la haute disponibilite AD : si DC01 tombe, DC02 prend le relais.

## Prerequis

- [ ] DC01 et DC02 installes avec Windows Server 2022 (guide 01, etape 2b)
- [ ] IP statiques configurees (guide 01, etape 3a) : DC01 = .10, DC02 = .11
- [ ] pfSense siege operationnel (guide 02) — gateway .1 repond au ping
- [ ] DNS temporaire sur DC01 et DC02 = `8.8.8.8` (configure au guide 01)

## Etapes

### 1. Configurer DC01 comme premier controleur de domaine

**Pourquoi** : DC01 est le premier DC — il cree la foret AD et le domaine `lab.local`.

Sur DC01, ouvrir PowerShell en admin :

```powershell
# Installer le role AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promouvoir en DC (cree le domaine lab.local)
Install-ADDSForest `
    -DomainName "lab.local" `
    -DomainNetBIOSName "LAB" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Force:$true
```

**Resultat attendu** : Le serveur reboot automatiquement. Se reconnecter via la console Proxmox
en tant que `LAB\Administrator` / `P@ssw0rd!`.

> **Apres promotion** : Changer le DNS de DC01 vers lui-meme :
> ```powershell
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1,172.16.132.11
> ```

### 2. Verifier DC01

**Pourquoi** : S'assurer que AD et DNS fonctionnent avant d'ajouter DC02.

```powershell
# Verifier le domaine
Get-ADDomain

# Verifier DNS
Resolve-DnsName lab.local

# Sante AD
dcdiag /s:DC01
```

### 3. Promouvoir DC02 comme DC secondaire

**Pourquoi** : DC02 = replique de DC01. Si DC01 tombe, DC02 repond aux requetes d'authentification.

Sur DC02, d'abord changer le DNS pour pointer vers DC01 :
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.132.10
```

Puis installer et promouvoir :

```powershell
# Installer le role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Joindre le domaine et promouvoir
Install-ADDSDomainController `
    -DomainName "lab.local" `
    -InstallDns:$true `
    -Credential (Get-Credential) `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Force:$true
```

> Quand "Get-Credential" apparait, entrer : LAB\Administrator / P@ssw0rd!

**Resultat attendu** : DC02 reboot, se reconnecte en tant que LAB\Administrator.

### 4. Verifier la replication

**Pourquoi** : Si la replication ne fonctionne pas, le failover AD ne marchera pas.

```powershell
# Lister les DC
Get-ADDomainController -Filter *

# Etat de la replication
repadmin /replsummary

# Forcer une replication
repadmin /syncall /AdeP
```

**Resultat attendu** : 2 DC listes, replication "0 failures".

### 5. Configurer le DNS des autres VMs

**Pourquoi** : Toutes les VMs du siege doivent utiliser DC01 (et DC02 en secondaire) comme DNS.

| VM | DNS primaire | DNS secondaire |
|----|-------------|----------------|
| DC01 | 127.0.0.1 | 172.16.132.11 |
| DC02 | 172.16.132.10 | 127.0.0.1 |
| WMS | 172.16.132.10 | 172.16.132.11 |
| IPBX | 172.16.132.10 | 172.16.132.11 |

## Verification

| Test | Commande | Resultat attendu |
|------|----------|-------------------|
| DC01 est DC | `Get-ADDomainController -Filter *` | DC01 liste |
| DC02 est DC | Meme commande | DC02 liste |
| Replication OK | `repadmin /replsummary` | 0 failures |
| DNS fonctionne | `nslookup lab.local` depuis WMS | Repond avec DC01 |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Promotion DC02 echoue | DNS de DC02 ne pointe pas vers DC01 | Verifier IP DNS dans la config reseau |
| Replication en erreur | Firewall bloque | Verifier regles pfSense, ports AD (389, 636, 3268, 88, 53) |
| nslookup echoue | DNS mal configure | Verifier que le service DNS est actif : `Get-Service DNS` |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/02-pfsense-siege.md`
- Guide suivant : `docs/03-lab-poc/04-ipbx-qos.md`
