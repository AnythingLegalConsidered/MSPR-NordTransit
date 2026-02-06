---
title: "pfSense siege - Installation et configuration"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 01-reseau-lab.md complete"
  - "VM FW-SIEGE (32001) creee avec 3 NICs (vmbr0 + vmbr1 + vmbr2)"
---

# pfSense siege - Installation et configuration

## Objectif

> Installer pfSense sur FW-SIEGE et configurer le firewall comme point central du reseau siege.
> Ce pfSense simule le FortiGate 100F de l'architecture cible.

## Prerequis

- [ ] VM 32001 creee avec 3 NICs :
  - net0 → vmbr1 (LAN siege)
  - net1 → vmbr2 (liaison Azure)
  - net2 → vmbr0 (internet reel, NAT)
- [ ] pfSense ISO uploade sur Proxmox
- [ ] Guide reseau lab termine

## Mapping interfaces

La VM a 3 NICs dans Proxmox. L'ordre des `vtnetX` dans pfSense correspond a l'ordre des `netX` :

| vtnet (pfSense) | net (Proxmox) | Bridge | Role |
|-----------------|---------------|--------|------|
| vtnet0 | net0 | vmbr1 | LAN siege |
| vtnet1 | net1 | vmbr2 | Liaison Azure (OPT1) |
| vtnet2 | net2 | vmbr0 | Internet reel (WAN) |

## Etapes

### 1. Installer pfSense

**Pourquoi** : pfSense est le firewall open-source le plus proche de FortiGate en termes de fonctionnalites (VPN, QoS, VLAN).

1. Demarrer la VM 32001 depuis la console Proxmox
2. La VM boot sur l'ISO pfSense automatiquement
3. Accepter les conditions (Accept)
4. Selectionner **Install** → **Continue**

<!-- Screenshot: ecran d'accueil installer pfSense -->

#### Partitionnement ZFS

5. Selectionner **Auto (ZFS)**
6. Sur l'ecran ZFS Configuration :
   - Aller sur **T Pool Type/Disks** → Entree
   - Selectionner **stripe** (Stripe - No Redundancy) → OK

<!-- Screenshot: selection stripe -->

7. **Cocher le disque** `da0` (QEMU HARDDISK) avec la touche **Espace** → OK

<!-- Screenshot: selection disque da0 -->

8. Verifier que l'ecran affiche **"stripe: 1 disk"** → selectionner **>>> Install**

<!-- Screenshot: ZFS config avec 1 disk -->

9. Confirmer avec **YES** (destruction des donnees du disque)
10. Attendre la copie des fichiers
11. **Reboot**

> **Important** : Apres le reboot, retirer l'ISO dans Proxmox (Hardware → CD/DVD → Do not use any media) pour eviter de rebooter sur l'installer.

### 2. Assigner les interfaces

**Pourquoi** : pfSense doit savoir quel NIC correspond a quel role (WAN, LAN, OPT1).

Au premier boot post-installation, pfSense affiche les interfaces detectees et pose des questions :

```
Valid interfaces are:
vtnet0  bc:24:11:xx:xx:xx VirtIO Networking Adapter
vtnet1  bc:24:11:xx:xx:xx VirtIO Networking Adapter
vtnet2  bc:24:11:xx:xx:xx VirtIO Networking Adapter

Should VLANs be set up now [y|n]? n

Enter the WAN interface name:  vtnet2
Enter the LAN interface name:  vtnet0
Enter the OPT1 interface name: vtnet1

Do you want to proceed [y|n]? y
```

<!-- Screenshot: assignation des interfaces -->

> **Attention** : Les logs php-fpm peuvent s'afficher par-dessus les prompts. C'est normal, tapez la reponse quand meme.

### 3. Configurer les IPs (option 2)

**Pourquoi** : Les IPs par defaut ne correspondent pas a notre plan d'adressage.

Depuis le menu principal, taper **`2`** (Set interface(s) IP address).

#### 3a. LAN (interface 2 — vtnet0)

| Question | Reponse |
|----------|---------|
| Interface number | `2` |
| Configure IPv4 via DHCP? | `n` |
| Enter new IPv4 address | `172.16.132.1` |
| Enter subnet bit count | `24` |
| Enter IPv4 gateway | *(Entree — pas de gateway)* |
| Configure IPv6 via DHCP6? | `n` |
| Enter new IPv6 address | *(Entree — aucune)* |
| Enable DHCP server on LAN? | `n` |
| Revert to HTTP? | `n` |

#### 3b. OPT1 (interface 3 — vtnet1)

Refaire option **`2`** puis :

| Question | Reponse |
|----------|---------|
| Interface number | `3` |
| Configure IPv4 via DHCP? | `n` |
| Enter new IPv4 address | `10.100.0.254` |
| Enter subnet bit count | `24` |
| Enter IPv4 gateway | *(Entree — pas de gateway)* |
| Configure IPv6 via DHCP6? | `n` |
| Enter new IPv6 address | *(Entree — aucune)* |
| Enable DHCP server on OPT1? | `n` |
| Revert to HTTP? | `n` |

#### 3c. WAN (interface 1 — vtnet2)

Le WAN obtient son IP automatiquement en DHCP sur vmbr0 (reseau reel). **Rien a configurer**.

### 4. Verification console

Le menu principal doit afficher :

```
WAN (wan)   -> vtnet2  -> v4/DHCP4: 192.168.2.x/24
LAN (lan)   -> vtnet0  -> v4: 172.16.132.1/24
OPT1 (opt1) -> vtnet1  -> v4: 10.100.0.254/24
```

<!-- Screenshot: menu principal avec les 3 IPs configurees -->

> **FW-SIEGE est operationnel cote console.** La suite (web UI) se fait apres configuration d'une VM sur le LAN siege.

### 5. Acceder a l'interface web

**Pourquoi** : La configuration avancee (rules, VPN, QoS) se fait via l'interface web.

Depuis une VM du siege (DC01 ou WMS) :
```
https://172.16.132.1
Login: admin / pfsense
```

### 6. Configuration de base (web UI)

**Pourquoi** : Securiser le firewall et configurer DNS.

Dans System → General Setup :
- Hostname : `fw-siege`
- Domain : `lab.local`
- DNS Servers : `8.8.8.8` temporairement (remplacer par `172.16.132.10` apres le guide 03-active-directory.md)

Dans System → Advanced → Admin Access :
- Desactiver le redirect HTTP → HTTPS (lab)

### 7. Regles de firewall basiques

**Pourquoi** : Par defaut, pfSense bloque tout sur WAN. En lab, on ouvre pour le tunnel.

LAN → rules :
- Allow All (lab) — a restreindre en production

OPT1 → rules :
- Allow IPsec (UDP 500, 4500)
- Allow ICMP (pour les tests ping)

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| IPs console correctes | Menu principal pfSense | WAN DHCP, LAN .132.1, OPT1 .0.254 |
| Interface web accessible | https://172.16.132.1 depuis DC01/WMS | Page login pfSense |
| LAN fonctionne | Ping 172.16.132.1 depuis DC01 | Reponse OK |
| 3 interfaces visibles | Status → Interfaces | WAN + LAN + OPT1 |
| Internet depuis pfSense | Option 7 → ping 8.8.8.8 | Reponse OK |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Interface web inaccessible | IP mal configuree | Reconfigurer via console (option 2) |
| Pas de reponse ping | Regles firewall | Ajouter Allow ICMP sur LAN |
| IP LAN en DHCP au lieu de statique | Repondu `y` au lieu de `n` a "DHCP?" | Refaire option 2, repondre `n` |
| Logs php-fpm par-dessus les prompts | Normal au boot | Ignorer, taper la reponse quand meme |
| Config freeze apres erreur | Mauvaise saisie | Option 4 (factory defaults) puis reconfigurer |
| Reboot sur l'installer | ISO encore montee | Proxmox → Hardware → CD/DVD → Do not use any media |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/01-reseau-lab.md`
- Guide suivant : `docs/03-lab-poc/03-active-directory.md`
