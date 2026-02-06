# Ansible — Lab Proxmox NordTransit

Playbooks pour provisionner le lab POC sur n'importe quel noeud Proxmox (pve02 perso, Proxmox ecole, etc.).

## Prerequis

### Sur le noeud Proxmox

```bash
# Installer les dependances Python (necessaires pour le module proxmox_kvm)
pip install proxmoxer requests

# Installer Ansible (si pas deja fait)
apt install ansible   # ou : pip install ansible

# Installer les collections Ansible
ansible-galaxy collection install community.general community.mysql
```

### ISOs a telecharger

Placer les ISOs dans `/var/lib/vz/template/iso/` sur le Proxmox :

| ISO | Usage | Lien |
|-----|-------|------|
| `pfSense-CE-2.7.2-RELEASE-amd64.iso` | FW-SIEGE + FW-AZURE | https://www.pfsense.org/download/ |
| `SERVER_EVAL_x64FRE_en-us.iso` | DC01, DC02, DC-AZURE | https://www.microsoft.com/evalcenter/evaluate-windows-server-2022 |
| `ubuntu-22.04.4-live-server-amd64.iso` | WMS | https://releases.ubuntu.com/22.04/ |
| `SNG7-PBX16-64bit-2302-1.iso` | IPBX | https://www.freepbx.org/downloads/ |

### Reseau Proxmox

Creer 2 bridges sur le noeud (Datacenter > Node > Network) :

| Bridge | Usage | Subnet |
|--------|-------|--------|
| `vmbr1` | LAN siege | 172.16.132.0/24 |
| `vmbr2` | WAN / lien Azure | 10.100.0.0/24 |

### Cle SSH

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "mspr-lab"
```

Copier la cle publique dans `group_vars/all.yml` (variable `ssh_public_key`).

### Vault (credentials Proxmox)

```bash
# Creer le fichier vault avec le mot de passe Proxmox
ansible-vault create vault.yml
# Contenu :
# vault_proxmox_password: "votre_mot_de_passe_root"

# Creer le fichier de deverrouillage automatique (ne PAS committer)
echo "votre_vault_password" > .vault_pass
chmod 600 .vault_pass
```

## Configuration

1. Editer `inventory/hosts.yml` : mettre l'IP de votre Proxmox
2. Editer `group_vars/all.yml` : ajuster `proxmox_node` et `ssh_public_key`
3. Verifier les noms d'ISOs si differents

## Utilisation

```bash
cd configs/ansible/

# 1. Verifier que le Proxmox est pret
ansible-playbook playbooks/00-preflight.yml

# 2. Creer les 7 VMs
ansible-playbook playbooks/01-create-vms.yml

# 3. Demarrer les VMs (ordre : firewalls → AD → services)
ansible-playbook playbooks/02-start-vms.yml

# 4. Apres installation manuelle d'Ubuntu sur WMS :
ansible-playbook playbooks/03-post-deploy-wms.yml

# Pour tout supprimer et recommencer :
ansible-playbook playbooks/99-teardown.yml
```

## VMs creees

| VMID | Nom | OS | IP | RAM | Config manuelle |
|------|-----|----|----|-----|-----------------|
| 32001 | FW-SIEGE | pfSense | 172.16.132.1 + 10.100.0.254 | 2 Go | docs/03-lab-poc/02-pfsense-siege.md |
| 32005 | FW-AZURE | pfSense | 10.100.0.1 | 2 Go | docs/03-lab-poc/05-azure-tunnel.md |
| 32010 | DC01 | Win Server 2022 | 172.16.132.10 | 4 Go | docs/03-lab-poc/03-active-directory.md |
| 32011 | DC02 | Win Server 2022 | 172.16.132.11 | 4 Go | docs/03-lab-poc/03-active-directory.md |
| 32012 | DC-AZURE | Win Server 2022 | 10.100.0.10 | 4 Go | docs/03-lab-poc/05-azure-tunnel.md |
| 32020 | WMS | Ubuntu 22.04 | 172.16.132.20 | 2 Go | Automatise (role wms_setup) |
| 32030 | IPBX | FreePBX | 172.16.132.30 | 2 Go | docs/03-lab-poc/04-ipbx-qos.md |

**Total** : 20 Go RAM, 176 Go disque

## Changer de Proxmox (ecole)

Pour deployer sur un autre noeud :

1. Decommenter `pve-ecole` dans `inventory/hosts.yml` et mettre l'IP
2. Ajuster `proxmox_node` dans `group_vars/all.yml`
3. Relancer les playbooks

## Structure

```
configs/ansible/
├── ansible.cfg                  # Config Ansible
├── inventory/hosts.yml          # Noeuds Proxmox (pve02 + ecole)
├── group_vars/all.yml           # Variables : specs VMs, reseaux, ISOs
├── playbooks/
│   ├── 00-preflight.yml         # Checks avant deploiement
│   ├── 01-create-vms.yml        # Creation des 7 VMs
│   ├── 02-start-vms.yml         # Demarrage ordonne
│   ├── 03-post-deploy-wms.yml   # Config WMS (MySQL, iperf3)
│   └── 99-teardown.yml          # Suppression complete
├── roles/wms_setup/             # Role Ansible pour le WMS
├── files/cloud-init/            # Cloud-init user-data WMS
└── README.md                    # Ce fichier
```
