---
title: "pfSense siege - Installation et configuration"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 01-reseau-lab.md complete"
  - "VM FW-SIEGE (32001) creee avec 2 NICs"
---

# pfSense siege - Installation et configuration

## Objectif

> Installer pfSense sur FW-SIEGE et configurer le firewall comme point central du reseau siege.
> Ce pfSense simule le FortiGate 100F de l'architecture cible.

## Prerequis

- [ ] VM 32001 creee avec 2 NICs (vmbr1 + vmbr2)
- [ ] pfSense ISO uploade sur Proxmox
- [ ] Guide reseau lab termine

## Etapes

### 1. Installer pfSense

**Pourquoi** : pfSense est le firewall open-source le plus proche de FortiGate en termes de fonctionnalites (VPN, QoS, VLAN).

1. Demarrer la VM 32001
2. Booter sur l'ISO pfSense
3. Accept defaults → Install → Continue
4. Partition : Auto (ZFS) → Stripe
5. Reboot apres installation

### 2. Configurer les interfaces

**Pourquoi** : LAN = reseau siege, OPT1 = liaison vers "Azure".

Au premier boot, pfSense demande l'assignation des interfaces :

```
Should VLANs be set up now? n
Enter the WAN interface: vtnet1     (vmbr2 — liaison Azure)
Enter the LAN interface: vtnet0     (vmbr1 — reseau siege)
```

Puis configurer les IPs :
- **LAN** : 172.16.132.1/24 — pas de DHCP (IPs statiques en lab)
- **WAN/OPT1** : 10.100.0.254/24 — cote siege du tunnel (FW-AZURE sera en 10.100.0.1 sur le meme bridge vmbr2, les deux se voient via ce segment)

### 3. Acceder a l'interface web

**Pourquoi** : La configuration avancee se fait via l'interface web.

Depuis une VM du siege (ex: DC01) :
```
https://172.16.132.1
Login: admin / pfsense
```

### 4. Configuration de base

**Pourquoi** : Securiser le firewall et configurer DNS.

Dans System → General Setup :
- Hostname : `fw-siege`
- Domain : `lab.local`
- DNS Servers : `8.8.8.8` temporairement (remplacer par `172.16.132.10` apres le guide 03-active-directory.md)

Dans System → Advanced → Admin Access :
- Desactiver le redirect HTTP → HTTPS (lab)

### 5. Regles de firewall basiques

**Pourquoi** : Par defaut, pfSense bloque tout sur WAN. En lab, on ouvre pour le tunnel.

LAN → rules :
- Allow All (lab) — a restreindre en production

OPT1/WAN → rules :
- Allow IPsec (UDP 500, 4500)
- Allow ICMP (pour les tests ping)

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| Interface web accessible | https://172.16.132.1 depuis DC01 | Page login pfSense |
| LAN fonctionne | Ping 172.16.132.1 depuis DC01 | Reponse OK |
| 2 interfaces visibles | Status → Interfaces | LAN + WAN/OPT1 |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Interface web inaccessible | IP mal configuree | Reconfigurer via console pfSense (option 2) |
| Pas de reponse ping | Regles firewall | Ajouter Allow ICMP sur LAN |
| Interface WAN en DHCP | Auto-detect | Reconfigurer en statique via console |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/01-reseau-lab.md`
- Guide suivant : `docs/03-lab-poc/03-active-directory.md`
