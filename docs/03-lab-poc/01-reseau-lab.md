---
title: "Creation du reseau lab"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 00-prerequis-lab.md complete"
  - "Bridges vmbr1 et vmbr2 crees"
---

# Creation du reseau lab

## Objectif

> Creer les 7 VMs sur Proxmox, installer les OS, et configurer les IPs statiques.
> A la fin de ce guide, toutes les VMs sont creees, installees et joignables sur leur reseau respectif.

## Prerequis

- [ ] Proxmox accessible + 4 ISOs uploadees
- [ ] Bridges vmbr0 + vmbr1 + vmbr2 crees
- [ ] Guide prerequis complete (credentials notes)

## Etapes

### 1. Creer les VMs

**Pourquoi** : Chaque VM simule un composant de l'architecture cible.

Pour chaque VM, sur Proxmox : Create VM → parametres ci-dessous.

> **Alternative Ansible** : Si vous preferez automatiser, les playbooks dans `configs/ansible/`
> creent les 7 VMs automatiquement. Voir `configs/ansible/README.md`.

#### FW-SIEGE (VMID 32001)
- OS : pfSense ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 8 Go (SCSI, VirtIO SCSI controller)
- Reseau : **3 NICs** :
  - net0 → vmbr1 (LAN siege) — type virtio
  - net1 → vmbr2 (liaison Azure) — type virtio
  - net2 → vmbr0 (internet reel, NAT) — type virtio

> **Attention** : FW-SIEGE a 3 NICs, pas 2. Le 3eme (vmbr0) fournit l'acces internet au lab.

#### FW-AZURE (VMID 32005)
- OS : pfSense ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 8 Go
- Reseau : **1 NIC** sur vmbr2 (reseau Azure) — type virtio

#### DC01 (VMID 32010)
- OS : Windows Server 2022 ISO
- CPU : 2 cores
- RAM : 4 Go
- Disque : 40 Go (**SATA**, pas SCSI — Windows n'a pas les drivers VirtIO)
- Reseau : 1 NIC sur vmbr1 — **type e1000** (pas virtio — pas de drivers)

> **Important Windows** : Toujours utiliser disque **SATA** et NIC **e1000** pour Windows Server
> sans drivers VirtIO. Sinon, Windows ne detecte ni le disque ni le reseau pendant l'installation.

#### DC02 (VMID 32011)
- Identique a DC01, VMID 32011
- Reseau : 1 NIC sur vmbr1 (e1000)

#### DC-AZURE (VMID 32012)
- Identique a DC01, VMID 32012
- Reseau : 1 NIC sur **vmbr2** (e1000) — cote Azure

#### WMS (VMID 32020)
- OS : Ubuntu 22.04 Server ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 20 Go (SCSI, VirtIO SCSI controller)
- Reseau : 1 NIC sur vmbr1 — type virtio

#### IPBX (VMID 32030)
- OS : FreePBX/SangomaOS ISO
- CPU : 1 core
- RAM : 2 Go
- Disque : 20 Go (SCSI, VirtIO SCSI controller)
- Reseau : 1 NIC sur vmbr1 — type virtio

---

### 2. Installer les systemes d'exploitation

**Pourquoi** : Chaque VM doit avoir son OS installe avant de pouvoir etre configuree.

#### 2a. pfSense (FW-SIEGE et FW-AZURE)

L'installation pfSense est detaillee dans le **guide 02** (FW-SIEGE) et le **guide 05** (FW-AZURE).
Passer a l'etape 2b pour les autres VMs.

#### 2b. Windows Server 2022 (DC01, DC02, DC-AZURE)

Demarrer la VM → la console Proxmox affiche l'installeur Windows.

1. Langue : **English** (ou votre choix), clavier : **French** si AZERTY
2. Cliquer **Install now**
3. Selectionner **Windows Server 2022 Standard Evaluation (Desktop Experience)**
4. Accepter la licence
5. Choisir **Custom: Install Windows only**
6. Selectionner le disque → **Next** → attendre l'installation (~10-15 min)
7. Definir le mot de passe Administrator : `P@ssw0rd!`
8. Se connecter (Ctrl+Alt+Del via la console Proxmox : bouton "Send Key" en haut)

> **Clavier AZERTY** : La console Proxmox envoie les touches en QWERTY. Pour taper `P@ssw0rd!`
> sur un clavier AZERTY, il faut taper `P0ssw0rd!` (le `@` est a un emplacement different).
> Alternative : utiliser le clavier visuel Windows ou coller via le clipboard Proxmox.

**Repeter pour les 3 VMs Windows** (DC01, DC02, DC-AZURE).

> **Apres l'installation** : Retirer l'ISO dans Proxmox (Hardware → CD/DVD → Do not use any media)
> pour eviter de rebooter sur l'installeur.

#### 2c. Ubuntu 22.04 (WMS)

Demarrer la VM → l'installeur Ubuntu demarre.

1. Langue : English
2. Keyboard : French (ou votre choix)
3. Type d'installation : **Ubuntu Server**
4. Network : DHCP pour le moment (on configure l'IP statique apres)
5. Proxy : *(laisser vide)*
6. Mirror : *(defaut)*
7. Storage : **Use an entire disk** → confirmer
8. Profil :
   - Your name : `wmsadmin`
   - Server name : `wms`
   - Username : `wmsadmin`
   - Password : `P@ssw0rd!`
9. **Install OpenSSH server** : cocher
10. Featured snaps : ne rien cocher → **Done**
11. Attendre l'installation → **Reboot Now**

Retirer l'ISO apres le reboot.

#### 2d. FreePBX / SangomaOS (IPBX)

Demarrer la VM → l'installeur SangomaOS demarre.

1. Selectionner **FreePBX 16 Installation — Asterisk 18 — Recommended**
2. Choisir **Graphical Installation — Output to VGA**
3. L'installation est **entierement automatique** (partitionnement, packages, etc.)
4. Attendre ~10-15 min — la VM reboot automatiquement
5. Le mot de passe root par defaut est : `SangomaDefaultPassword`

> **Important** : SangomaOS n'utilise PAS `nmcli` pour le reseau. La configuration se fait via
> `/etc/sysconfig/network-scripts/ifcfg-eth0` (voir etape 3).

Retirer l'ISO apres le reboot.

---

### 3. Configurer les IP statiques

**Pourquoi** : En lab, le DHCP complique le diagnostic. IPs statiques = reproductibilite.

> **pfSense** : Les IPs sont configurees pendant l'installation (guides 02 et 05). Ne pas configurer ici.

#### 3a. Windows Server (DC01, DC02, DC-AZURE)

Ouvrir PowerShell en administrateur sur chaque VM :

**DC01 :**
```powershell
# Trouver le nom de l'interface (generalement "Ethernet" ou "Ethernet Instance 0")
Get-NetAdapter

# Configurer IP statique
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.132.10 -PrefixLength 24 -DefaultGateway 172.16.132.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8

# Note : DNS pointe vers 8.8.8.8 temporairement. Il sera change vers 127.0.0.1 apres la promotion AD (guide 03).
```

**DC02 :**
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.132.11 -PrefixLength 24 -DefaultGateway 172.16.132.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8
```

**DC-AZURE :**
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.100.0.10 -PrefixLength 24 -DefaultGateway 10.100.0.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8
```

> **DNS temporaire 8.8.8.8** : Avant que AD soit installe, les DCs n'ont pas de DNS local.
> On utilise 8.8.8.8 pour pouvoir telecharger des mises a jour si besoin.
> Le DNS sera reconfigure au guide 03 (Active Directory).

**Activer le ping (ICMP) — necessaire pour les tests :**
```powershell
# Sur chaque VM Windows
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True
```

**Activer SSH (optionnel mais recommande pour l'administration a distance) :**
```powershell
# Telecharger OpenSSH (si pas d'internet, voir la methode manuelle dans le depannage)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

#### 3b. Ubuntu WMS

Se connecter en console (user : wmsadmin / P@ssw0rd!) :

```bash
# Configurer l'IP statique via netplan
sudo tee /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 172.16.132.20/24
      routes:
        - to: default
          via: 172.16.132.1
      nameservers:
        addresses:
          - 172.16.132.10
          - 172.16.132.11
        search:
          - lab.local
EOF

sudo netplan apply
```

> **Note** : L'interface s'appelle generalement `ens18` sur Proxmox (VirtIO). Verifier avec `ip a`.
> Le DNS pointe vers DC01/DC02 — si AD n'est pas encore installe, utiliser temporairement `8.8.8.8`.

#### 3c. FreePBX (IPBX)

Se connecter en SSH ou console (root / SangomaDefaultPassword) :

```bash
# Editer la configuration reseau
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << 'EOF'
TYPE=Ethernet
BOOTPROTO=static
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=172.16.132.30
NETMASK=255.255.255.0
GATEWAY=172.16.132.1
DNS1=172.16.132.10
DNS2=172.16.132.11
EOF

# Appliquer
systemctl restart network
```

> **Important** : SangomaOS est base sur CentOS 7. Pas de `nmcli`, pas de `netplan`.
> Toujours utiliser `/etc/sysconfig/network-scripts/ifcfg-eth0`.

---

### 4. Tester la connectivite

**Pourquoi** : Valider que le reseau fonctionne avant de configurer les services.

```bash
# Depuis DC01 (PowerShell), pinger les VMs du siege
ping 172.16.132.1    # FW-SIEGE
ping 172.16.132.11   # DC02
ping 172.16.132.20   # WMS
ping 172.16.132.30   # IPBX
```

**Resultat attendu** : Toutes les VMs du meme bridge (vmbr1) se pinguent entre elles.

> **Note** : Le reseau Azure (10.100.0.x) n'est PAS joignable depuis le siege a ce stade.
> Il le sera apres la configuration du tunnel IPsec (guide 05).

## Verification

| Test | Commande | Resultat attendu |
|------|----------|-------------------|
| 7 VMs creees | `qm list` sur Proxmox | 7 VMs listees |
| OS installes | Console de chaque VM | Login prompt visible |
| IPs correctes | `ping` depuis chaque VM siege | Reponse OK sur 172.16.132.x |
| Bridges fonctionnels | `ip link show vmbr1 vmbr2` sur Proxmox | UP |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| VM ne demarre pas | ISO non trouvee | Verifier le path de l'ISO dans Hardware → CD/DVD |
| Windows ne voit pas le disque | Disque SCSI au lieu de SATA | Recreer la VM avec un disque SATA |
| Windows pas de reseau | NIC virtio au lieu de e1000 | Changer le type NIC dans Hardware → Network Device |
| Pas de reseau sur une VM | Mauvais bridge | Verifier NIC → bridge dans Proxmox |
| Ping echoue entre VMs | Firewall Windows | `netsh advfirewall set allprofiles state off` (lab uniquement) |
| Ubuntu interface pas `ens18` | Nom different selon le driver | Verifier avec `ip a`, adapter le netplan |
| FreePBX IP pas appliquee | Service `network` pas redemarre | `systemctl restart network` |
| OpenSSH install echoue (Windows) | Pas d'internet | Telecharger OpenSSH-Win64.zip depuis GitHub, extraire dans `C:\Program Files\OpenSSH`, puis `.\install-sshd.ps1` |
| Clavier AZERTY dans console | Proxmox envoie en QWERTY | Utiliser le clavier visuel Windows ou le clipboard Proxmox |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/00-prerequis-lab.md`
- Guide suivant : `docs/03-lab-poc/02-pfsense-siege.md`
