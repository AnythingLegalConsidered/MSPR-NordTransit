# Structure du projet

> Guide rapide pour comprendre ce qu'il y a dans chaque dossier.

```
MSPR/
├── _specs/              # Export Notion (read-only)
├── docs/                # Documentation reproductible
│   ├── 01-analyse/
│   ├── 02-conception/
│   ├── 03-lab-poc/
│   ├── 04-livrables/
│   ├── 05-soutenance/
│   └── _templates/
├── configs/ansible/     # Automation lab Proxmox
├── scripts/             # Outils (export PDF, sync Notion)
└── output/              # Fichiers generes (gitignored)
```

---

## _specs/

Export Notion du projet. **Ne pas editer** — c'est un snapshot des specs initiales.

| Fichier | Contenu |
|---------|---------|
| `OVERVIEW.md` | Resume projet en 30 secondes |
| `PLAN.md` | Jalons et phases du projet |
| `comprendre/` | Analyse de l'existant (infra, sites, points de douleur) |
| `solution/` | Architecture cible, VLAN, budget, migration |
| `poc/` | Criteres de succes des tests POC |

---

## docs/

Documentation principale du projet. C'est ici qu'on travaille.

### docs/01-analyse/

Comprendre le client et son infrastructure actuelle.

| Fichier | Contenu |
|---------|---------|
| `01-contexte-client.md` | NordTransit : metier, sites, equipe DSI |
| `02-audit-infrastructure.md` | Etat des lieux technique (reseau, serveurs, securite) |
| `03-points-douleur.md` | SPOF WMS, securite faible, QoS absente |

### docs/02-conception/

Architecture cible et strategie.

| Fichier | Contenu |
|---------|---------|
| `01-architecture-cible.md` | Schema reseau APRES, choix techniques |
| `02-plan-adressage-vlan.md` | VLANs par site, plan IP complet |
| `03-strategie-securite.md` | FortiGate, segmentation, MFA |
| `04-strategie-migration.md` | 6 phases M1-M6, rollback prevu |

### docs/03-lab-poc/

Guides pas-a-pas pour reproduire le lab Proxmox. **Suivre dans l'ordre.**

| Fichier | Contenu |
|---------|---------|
| `00-prerequis-lab.md` | Ce qu'il faut avant de commencer (Proxmox, ISOs, bridges) |
| `01-reseau-lab.md` | Creer les bridges vmbr1/vmbr2, IPs |
| `02-pfsense-siege.md` | Deployer et configurer FW-SIEGE (pfSense) |
| `03-active-directory.md` | Installer AD : DC01 + DC02 + DC-AZURE |
| `04-ipbx-qos.md` | FreePBX + extensions SIP + QoS PRIQ |
| `05-azure-tunnel.md` | FW-AZURE + tunnel IPsec + routage inter-VLAN |
| `06-wms-simulation.md` | VM Ubuntu + MySQL + donnees test |
| `07-tests-validation.md` | 4 tests POC avec resultats (4/4 PASS) |
| `02-pfsense/` | Screenshots pfSense (captures de config) |

### docs/04-livrables/

Documents finaux remis au jury. Ce sont les **vrais livrables** de la MSPR.

| Fichier | Contenu |
|---------|---------|
| `architecture-technique.md` | DAT complet (33 Ko) : schemas, budget, specs |
| `strategie-migration.md` | 6 phases sur 6 semaines, planning, rollback |
| `guide-depannage-toip.md` | Guide N1/N2 pour la telephonie VoIP |
| `note-recommandation-wms.md` | Analyse SPOF WMS + recommandations HA |
| `configs/pare-feu.md` | Regles FortiGate + QoS (CLI production) |
| `configs/vpn-ipsec.md` | 5 tunnels IKEv2 site-to-site (CLI production) |

### docs/05-soutenance/

Preparation de la presentation orale.

| Fichier | Contenu |
|---------|---------|
| `plan-presentation.md` | Structure 30 min, script demo, questions types |

### docs/_templates/

Templates pour generer les documents.

| Fichier | Contenu |
|---------|---------|
| `guide-template.md` | Structure type d'un guide lab |
| `livrable-template.md` | Structure type d'un livrable |
| `metadata.yaml` | Metadonnees pandoc (titre, auteur, date) |
| `reference.docx` | Template Word pour l'export DOCX |

### Autres fichiers docs/

| Fichier | Contenu |
|---------|---------|
| `QUICKSTART.md` | Guide de demarrage rapide (par ou commencer) |
| `glossaire.md` | Definitions des termes techniques |

---

## configs/ansible/

Playbooks Ansible pour deployer le lab sur Proxmox automatiquement.

| Fichier | Contenu |
|---------|---------|
| `inventory/hosts.yml` | Inventaire Proxmox (IP, credentials) |
| `inventory/group_vars/all/main.yml` | Specs des 7 VMs (RAM, disque, reseau) |
| `playbooks/00-preflight.yml` | Verifications avant deploiement |
| `playbooks/01-create-vms.yml` | Creation des 7 VMs |
| `playbooks/02-start-vms.yml` | Demarrage ordonne |
| `playbooks/03-post-deploy-wms.yml` | Config automatique du WMS (MySQL + donnees) |
| `playbooks/99-teardown.yml` | Suppression complete du lab |
| `roles/wms_setup/` | Role Ansible pour le WMS (MySQL, schema, script check) |
| `files/cloud-init/` | Config cloud-init pour la VM Ubuntu |

---

## scripts/

| Fichier | Contenu |
|---------|---------|
| `build_docs.py` | Export Markdown vers DOCX/PDF via pandoc |
| `build_corporate.py` | Export DOCX avec style corporate (python-docx) |
| `notion_sync.py` | Sync Notion vers `_specs/` (API Notion) |

---

## output/

Fichiers generes par les scripts (DOCX, PDF, PPTX). **Gitignored** — ne pas commiter.

Regenerer avec :
```bash
python scripts/build_docs.py --all --format docx
```
