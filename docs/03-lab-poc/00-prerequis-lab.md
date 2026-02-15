---
title: "Prerequis du lab POC"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Phase 02-conception terminee"
---

# Prerequis du lab POC

## Objectif

> Lister tout ce qu'il faut avoir avant de commencer le lab :
> acces Proxmox, ISOs, ressources, et repartition des roles dans l'equipe.

## Prerequis

- [ ] Acces a Proxmox VE (https://proxmox.local:8006)
- [ ] Compte root ou acces admin sur le noeud Proxmox

## Etapes

### 1. Verifier les ressources Proxmox

**Pourquoi** : 7 VMs = ~20 Go RAM. Si la machine est sous-dimensionnee, les VMs seront instables.

Ressources necessaires :
- **RAM** : 20 Go minimum (idealement 24+ Go)
- **CPU** : 8+ vCPU disponibles
- **Stockage** : ~100 Go espace disque (OS + ISOs + VMs)
- **Reseau** : 2 bridges (vmbr1 pour siege, vmbr2 pour Azure)

Verifier sur Proxmox :
```bash
# RAM disponible
free -h

# Espace disque
df -h /var/lib/vz

# CPU
nproc
```

### 2. Telecharger les ISOs

**Pourquoi** : Toutes les VMs ont besoin d'un OS. Les telecharger en avance evite des pertes de temps.

| ISO | URL | Taille | Usage |
|-----|-----|--------|-------|
| pfSense CE 2.7.x | https://www.pfsense.org/download/ | ~900 Mo | FW-SIEGE + FW-AZURE |
| Windows Server 2022 Eval | https://www.microsoft.com/evalcenter/ | ~5 Go | DC01, DC02, DC-AZURE |
| Ubuntu 22.04 Server | https://ubuntu.com/download/server | ~1.5 Go | WMS |
| FreePBX ISO | https://www.freepbx.org/downloads/ | ~1 Go | IPBX |

Uploader sur Proxmox : Storage local → ISO Images → Upload

### 3. Configurer les bridges reseau

**Pourquoi** : Les 2 reseaux (siege + Azure) doivent etre isoles l'un de l'autre.

| Bridge | Reseau | Usage |
|--------|--------|-------|
| vmbr1 | 172.16.132.0/24 | Reseau "siege" |
| vmbr2 | 10.100.0.0/24 | Reseau "Azure" |

Sur Proxmox : Datacenter → Node → Network → Create → Linux Bridge
- **vmbr1** : pas d'IP (bridge interne), pas de gateway
- **vmbr2** : pas d'IP (bridge interne), pas de gateway

### 4. Repartir les roles equipe

**Pourquoi** : 5 personnes travaillent en parallele — chacun sait ce qu'il fait.

| Personne | Responsabilites | Guides concernes |
|----------|-----------------|------------------|
| P1 | Setup reseau + pfSense siege + DC01 | 01, 02, 03 |
| P2 | DC02 + replication + failover AD | 03, 07 |
| P3 | IPBX + QoS + test VoIP | 04, 07 |
| P4 | Azure (FW + DC) + tunnel IPsec | 05, 07 |
| P5 | WMS + documentation + captures | 06, 07 |

### 5. Inventaire des VMs a creer

| VMID | Nom | OS | IP | RAM | Role |
|------|-----|----|----|-----|------|
| 32001 | FW-SIEGE | pfSense | 172.16.132.1 | 2 Go | Firewall + QoS + VPN |
| 32005 | FW-AZURE | pfSense | 10.100.0.1 | 2 Go | Cote Azure du tunnel |
| 32010 | DC01 | Win Server 2022 | 172.16.132.10 | 4 Go | AD principal |
| 32011 | DC02 | Win Server 2022 | 172.16.132.11 | 4 Go | AD secondaire |
| 32012 | DC-AZURE | Win Server 2022 | 10.100.0.10 | 4 Go | DC cloud |
| 32020 | WMS | Ubuntu 22.04 | 172.16.132.20 | 2 Go | Simulation WMS |
| 32030 | IPBX | FreePBX | 172.16.132.30 | 2 Go | Telephonie VoIP |

**Total : 7 VMs, ~20 Go RAM**

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| RAM suffisante | `free -h` sur Proxmox | >= 20 Go dispo |
| ISOs presentes | Verifier local storage | 4 ISOs uploadees |
| Bridges crees | `ip link show` | vmbr1 + vmbr2 actifs |
| Equipe briefee | Chacun connait son role | 5 roles attribues |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| RAM insuffisante | Trop de VMs deja presentes | Eteindre les VMs non utilisees |
| ISO upload echoue | Taille > limite storage | Utiliser `wget` directement sur le node |
| Bridge non visible | Node pas reboot | `ifreload -a` ou reboot node |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide suivant : `docs/03-lab-poc/01-reseau-lab.md`
