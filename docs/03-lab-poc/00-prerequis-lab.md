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

- [ ] Acces a Proxmox VE 8.x ou 9.x (interface web : https://IP:8006)
- [ ] Compte root ou acces admin sur le noeud Proxmox
- [ ] Connexion internet sur le noeud (pour telecharger les ISOs)

## Credentials du lab

> **IMPORTANT** : Tous les guides font reference a ces credentials. Les garder sous la main.

| Service | Utilisateur | Mot de passe | Acces |
|---------|-------------|-------------|-------|
| Proxmox | root | *(votre mot de passe)* | https://IP:8006 |
| pfSense (x2) | admin | pfsense | Console + https://IP |
| Windows Server (x3) | Administrator | P@ssw0rd! | Console + RDP |
| Active Directory | LAB\Administrator | P@ssw0rd! | Apres promotion AD |
| AD SafeMode | - | P@ssw0rd! | Mode restauration AD |
| Ubuntu WMS | wmsadmin | P@ssw0rd! | SSH (cle ou mot de passe) |
| FreePBX SSH | root | SangomaDefaultPassword | SSH |
| FreePBX web | admin | admin | http://172.16.132.30 |
| VPN IPsec PSK | - | MSPR-VPN-2024! | Config tunnel |

> **Rappel** : Ces credentials sont acceptables pour un lab. En production, utiliser des secrets forts
> et un gestionnaire de mots de passe.

## Etapes

### 1. Verifier les ressources Proxmox

**Pourquoi** : 7 VMs = ~20 Go RAM. Si la machine est sous-dimensionnee, les VMs seront instables.

Ressources necessaires :
- **RAM** : 20 Go minimum (idealement 24+ Go)
- **CPU** : 8+ vCPU disponibles
- **Stockage** : ~200 Go espace disque (176 Go VMs + ISOs)
- **Reseau** : bridge vmbr0 existant (reseau physique)

Verifier sur le noeud Proxmox (SSH ou Shell via l'interface web) :
```bash
# RAM disponible
free -h

# Espace disque sur le stockage
pvesm status

# CPU
nproc
```

### 2. Telecharger les ISOs

**Pourquoi** : Toutes les VMs ont besoin d'un OS. Les telecharger en avance evite des pertes de temps.

| ISO | Nom du fichier | Taille | Usage |
|-----|----------------|--------|-------|
| pfSense CE 2.7.2 | `pfSense-CE-2.7.2-RELEASE-amd64.iso` | ~900 Mo | FW-SIEGE + FW-AZURE |
| Windows Server 2022 Eval | `SERVER_EVAL_x64FRE_en-us.iso` | ~5 Go | DC01, DC02, DC-AZURE |
| Ubuntu 22.04 Server | `ubuntu-22.04.4-live-server-amd64.iso` | ~1.5 Go | WMS |
| FreePBX (SangomaOS) | `SNG7-PBX16-64bit-2302-1.iso` | ~1 Go | IPBX |

**Upload via l'interface web Proxmox :**
1. Aller dans Datacenter → Node → local → ISO Images
2. Cliquer **Upload** → selectionner l'ISO depuis votre poste

**Ou via wget directement sur le noeud** (plus rapide pour les grosses ISOs) :
```bash
cd /var/lib/vz/template/iso/
# Exemple pour pfSense :
wget https://atxfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz
gunzip pfSense-CE-2.7.2-RELEASE-amd64.iso.gz
```

> **Verification** : Dans Proxmox → local → ISO Images, les 4 ISOs doivent apparaitre.

### 3. Configurer les bridges reseau

**Pourquoi** : Les 2 reseaux (siege + Azure) doivent etre isoles. Le bridge vmbr0 existe deja (reseau physique).

| Bridge | Reseau | Usage | IP sur le host |
|--------|--------|-------|----------------|
| vmbr0 | *(existant)* | Internet reel (NAT via FW-SIEGE) | *(deja configuree)* |
| vmbr1 | 172.16.132.0/24 | LAN siege | Optionnel (voir note) |
| vmbr2 | 10.100.0.0/24 | WAN Azure simule | Optionnel |

**Creer vmbr1 et vmbr2 :**

Sur Proxmox : Node → Network → Create → Linux Bridge

Pour **vmbr1** :
- Name : `vmbr1`
- IPv4/CIDR : *(laisser vide — bridge interne)*
- Bridge ports : *(laisser vide — pas de NIC physique)*
- Autostart : cocher
- Comment : `LAN siege 172.16.132.0/24`

Repeter pour **vmbr2** (comment : `WAN Azure 10.100.0.0/24`).

Cliquer **Apply Configuration** en haut de la page.

> **Optionnel — IP du host sur les bridges** : Pour pouvoir acceder aux VMs depuis le host
> Proxmox (utile pour les tests iperf3 au guide 07), ajouter une IP :
> ```bash
> # Temporaire (perdu au reboot)
> ip addr add 172.16.132.254/24 dev vmbr1
> ip addr add 10.100.0.253/24 dev vmbr2
> ```
> Pour rendre persistant, editer `/etc/network/interfaces` et ajouter `address` sous chaque bridge.

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

| VMID | Nom | OS | IP | RAM | Disque | Role |
|------|-----|----|----|-----|--------|------|
| 32001 | FW-SIEGE | pfSense | 172.16.132.1 + 10.100.0.254 | 2 Go | 8 Go | Firewall 3 NICs + QoS + VPN |
| 32005 | FW-AZURE | pfSense | 10.100.0.1 | 2 Go | 8 Go | Cote Azure du tunnel |
| 32010 | DC01 | Win Server 2022 | 172.16.132.10 | 4 Go | 40 Go | AD principal + DNS |
| 32011 | DC02 | Win Server 2022 | 172.16.132.11 | 4 Go | 40 Go | AD secondaire |
| 32012 | DC-AZURE | Win Server 2022 | 10.100.0.10 | 4 Go | 40 Go | DC cloud |
| 32020 | WMS | Ubuntu 22.04 | 172.16.132.20 | 2 Go | 20 Go | Simulation WMS |
| 32030 | IPBX | SangomaOS/FreePBX | 172.16.132.30 | 2 Go | 20 Go | Telephonie VoIP |

**Total : 7 VMs, ~20 Go RAM, ~176 Go disque**

## Verification

| Test | Action | Resultat attendu |
|------|--------|-------------------|
| RAM suffisante | `free -h` sur Proxmox | >= 20 Go dispo |
| Stockage suffisant | `pvesm status` | >= 200 Go dispo |
| ISOs presentes | local → ISO Images | 4 ISOs uploadees |
| Bridges crees | `ip link show vmbr1` et `vmbr2` | UP |
| Equipe briefee | Chacun connait son role | 5 roles attribues |
| Credentials notes | Tableau ci-dessus accessible | Oui |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| RAM insuffisante | Trop de VMs/LXC deja presentes | Eteindre les VMs non utilisees |
| ISO upload echoue | Taille > limite storage | Utiliser `wget` directement sur le noeud |
| Bridge non visible | Config pas appliquee | `ifreload -a` ou reboot noeud |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide suivant : `docs/03-lab-poc/01-reseau-lab.md`
