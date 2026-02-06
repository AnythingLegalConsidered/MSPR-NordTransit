---
title: "Creation du reseau lab"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Guide 00-prerequis-lab.md complete"
  - "Bridges vmbr1 et vmbr2 crees"
---

# Creation du reseau lab

## Objectif

> Creer les 7 VMs sur Proxmox et configurer le reseau de base (IP statiques, connectivity).
> A la fin de ce guide, toutes les VMs sont creees et joignables sur leur reseau respectif.

## Prerequis

- [ ] Proxmox accessible + ISOs uploadees
- [ ] Bridges vmbr1 + vmbr2 crees
- [ ] Guide prerequis complete

## Etapes

### 1. Creer les VMs

**Pourquoi** : Chaque VM simule un composant de l'architecture cible.

Pour chaque VM, sur Proxmox : Create VM → parametres ci-dessous.

#### FW-SIEGE (VMID 32001)
- OS : pfSense ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 8 Go
- Reseau : **2 NICs** — NIC1 sur vmbr1 (LAN siege), NIC2 sur vmbr2 (WAN vers Azure)

#### FW-AZURE (VMID 32005)
- OS : pfSense ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 8 Go
- Reseau : **1 NIC** sur vmbr2 (reseau Azure)

#### DC01 (VMID 32010)
- OS : Windows Server 2022 ISO
- CPU : 2 cores
- RAM : 4 Go
- Disque : 40 Go
- Reseau : 1 NIC sur vmbr1

#### DC02 (VMID 32011)
- Idem DC01, VMID 32011

#### DC-AZURE (VMID 32012)
- OS : Windows Server 2022 ISO
- CPU : 2 cores
- RAM : 4 Go
- Disque : 40 Go
- Reseau : 1 NIC sur vmbr2

#### WMS (VMID 32020)
- OS : Ubuntu 22.04 Server ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 20 Go
- Reseau : 1 NIC sur vmbr1

#### IPBX (VMID 32030)
- OS : FreePBX ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 20 Go
- Reseau : 1 NIC sur vmbr1

### 2. Configurer les IP statiques

**Pourquoi** : En lab, le DHCP complique le diagnostic. IPs statiques = reproductibilite.

Configurer apres installation de chaque OS :

| VM | IP | Masque | Gateway | DNS |
|----|----|--------|---------|-----|
| FW-SIEGE (LAN) | 172.16.132.1 | /24 | - | - |
| FW-AZURE | 10.100.0.1 | /24 | - | - |
| DC01 | 172.16.132.10 | /24 | 172.16.132.1 | 127.0.0.1 |
| DC02 | 172.16.132.11 | /24 | 172.16.132.1 | 172.16.132.10 |
| DC-AZURE | 10.100.0.10 | /24 | 10.100.0.1 | 127.0.0.1 |
| WMS | 172.16.132.20 | /24 | 172.16.132.1 | 172.16.132.10 |
| IPBX | 172.16.132.30 | /24 | 172.16.132.1 | 172.16.132.10 |

### 3. Tester la connectivite

**Pourquoi** : Valider que le reseau fonctionne avant de configurer les services.

```bash
# Depuis DC01, pinger les autres VMs du siege
ping 172.16.132.1    # FW-SIEGE
ping 172.16.132.11   # DC02
ping 172.16.132.20   # WMS
ping 172.16.132.30   # IPBX
```

**Resultat attendu** : Toutes les VMs du meme bridge se pinguent entre elles.

> Note : Le reseau Azure (10.100.0.x) ne sera joignable depuis le siege qu'apres la configuration du tunnel IPsec (guide 05).

## Verification

| Test | Commande | Resultat attendu |
|------|----------|-------------------|
| 7 VMs creees | `qm list` sur Proxmox | 7 VMs listees |
| IPs correctes | `ping` depuis chaque VM | Reponse OK |
| Bridges fonctionnels | `ip link show vmbr1 vmbr2` | UP |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| VM ne demarre pas | ISO non trouvee | Verifier le path de l'ISO dans les settings |
| Pas de reseau | Mauvais bridge | Verifier NIC → bridge dans Proxmox |
| Ping echoue | Firewall Windows | `netsh advfirewall set allprofiles state off` (lab uniquement) |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/00-prerequis-lab.md`
- Guide suivant : `docs/03-lab-poc/02-pfsense-siege.md`
