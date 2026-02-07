# MSPR - NordTransit Logistics

Projet de modernisation infrastructure SI pour NordTransit Logistics (PME logistique, 4 entrepots + 1 cross-dock).

> **En 30 secondes** : NordTransit = PME logistique, 4 entrepots, SI vieillissant.
> On modernise : FortiGate, cluster HA, AD multi-DC, PRA Azure, QoS VoIP.
> Budget : 137k EUR | Equipe : 5 personnes | Lab POC : 7 VMs Proxmox, 4/4 tests PASS.

## Par ou commencer ?

| Tu veux... | Va sur... |
|------------|-----------|
| Comprendre la structure du repo | [`STRUCTURE.md`](STRUCTURE.md) |
| Demarrer rapidement | [`docs/QUICKSTART.md`](docs/QUICKSTART.md) |
| Comprendre le contexte client | [`docs/01-analyse/`](docs/01-analyse/) |
| Voir l'architecture cible | [`docs/02-conception/`](docs/02-conception/) |
| Reproduire le lab Proxmox | [`docs/03-lab-poc/`](docs/03-lab-poc/) (guides 00 a 07) |
| Lire les livrables finaux | [`docs/04-livrables/`](docs/04-livrables/) |
| Preparer la soutenance | [`docs/05-soutenance/`](docs/05-soutenance/) |
| Deployer le lab automatiquement | [`configs/ansible/`](configs/ansible/) |

## Structure du projet

```
MSPR/
├── _specs/              # Export Notion (read-only, specs initiales)
├── docs/                # Documentation reproductible
│   ├── 01-analyse/      # Contexte, audit, points de douleur
│   ├── 02-conception/   # Architecture, VLAN, securite, migration
│   ├── 03-lab-poc/      # Guides pas-a-pas lab Proxmox (7 VMs)
│   ├── 04-livrables/    # Documents finaux pour le jury
│   ├── 05-soutenance/   # Plan de presentation orale
│   └── _templates/      # Templates pandoc
├── configs/ansible/     # Playbooks automation lab
├── scripts/             # Export PDF, sync Notion
└── output/              # Fichiers generes (gitignored)
```

Detail complet dans [`STRUCTURE.md`](STRUCTURE.md).

## Exporter en DOCX/PDF

Prerequis : [pandoc](https://pandoc.org/installing.html) (`choco install pandoc` sur Windows).

```bash
# Generer le template DOCX de reference (une seule fois)
python scripts/build_docs.py --init-template

# Exporter tous les livrables
python scripts/build_docs.py --all --format pdf

# Exporter un fichier specifique
python scripts/build_docs.py docs/04-livrables/architecture-technique.md --format docx
```

## Conventions Git

Commits conventionnels : `feat:` | `fix:` | `docs:` | `refactor:` | `test:` | `chore:`

## Equipe

5 personnes - pas de roles figes, on s'entraide !

## Liens

- [Notion projet](https://www.notion.so/MSPR-NordTransit-Logistics-2e095ddfecb18106aee6f23d0c83a063) (presentation visuelle)
- Lab Proxmox : VMID 32001-32030, reseau 172.16.132.0/24
