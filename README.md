# MSPR - NordTransit Logistics

Projet de modernisation infrastructure SI pour NordTransit Logistics (PME logistique, 4 entrepôts + 1 cross-dock).

## Structure du projet

```
MSPR/
├── _specs/                 # Export Notion (READ-ONLY - ne pas editer)
│   ├── OVERVIEW.md         # Vue d'ensemble projet
│   ├── PLAN.md             # Jalons et planning
│   ├── comprendre/         # Analyse de l'existant
│   ├── solution/           # Architecture cible
│   └── poc/                # Tests de validation
│
├── docs/                   # Documentation reproductible (EDITABLE)
│   ├── _templates/         # Templates guides + livrables + metadata pandoc
│   ├── 01-analyse/         # Phase 1 : Contexte, audit, points de douleur
│   ├── 02-conception/      # Phase 2 : Architecture, VLAN, securite, migration
│   ├── 03-lab-poc/         # Phase 3 : Guides pas-a-pas pour le lab Proxmox
│   ├── 04-livrables/       # Phase 4 : Documents finaux (archi, migration, ToIP...)
│   ├── 05-soutenance/      # Phase 5 : Plan de presentation
│   └── glossaire.md        # Termes techniques
│
├── configs/                # Fichiers techniques (EDITABLE)
│   ├── pfsense/            # Configs firewall
│   ├── ansible/            # Playbooks automation
│   └── azure/              # Templates ARM/Bicep
│
├── scripts/
│   ├── build_docs.py       # Export Markdown → DOCX/PDF via pandoc
│   └── notion_sync.py      # Sync Notion → local
│
└── output/                 # Fichiers generes (DOCX/PDF) - gitignore
```

## Workflow équipe

### Regle d'or

| Dossier | Usage | Editable ? |
|---------|-------|------------|
| `_specs/` | Miroir Notion | NON - sync automatique |
| `docs/` | Guides reproductibles + livrables | OUI - commit normalement |
| `configs/` | Fichiers techniques | OUI - commit normalement |
| `output/` | Fichiers generes (PDF/DOCX) | NON - genere par script |

### Actions courantes

| Je veux... | Où ? | Comment ? |
|------------|------|-----------|
| Modifier une spec/doc | **Notion** | Éditer sur notion.so |
| Synchroniser les specs | **Terminal** | `python scripts/notion_sync.py` |
| Modifier une config | **Git** | Éditer + commit |
| Voir les tâches | **Notion** | Kanban "📝 Tâches" |
| Créer une tâche | **Notion** | Ajouter dans "📝 Tâches" |

### Sync Notion → Local

```bash
# Sync complète
python scripts/notion_sync.py

# Dry-run (voir sans écrire)
python scripts/notion_sync.py --dry-run

# Sync une seule section
python scripts/notion_sync.py --page "POC"
```

## Documentation et export PDF

### Guides reproductibles

Chaque guide dans `docs/` suit un template uniforme : objectif, prerequis, etapes avec justifications, verification, depannage.

### Exporter en DOCX/PDF

Prerequis : [pandoc](https://pandoc.org/installing.html) installe (`choco install pandoc` sur Windows).

```bash
# Generer le template DOCX de reference (une seule fois)
python scripts/build_docs.py --init-template

# Exporter un fichier
python scripts/build_docs.py docs/04-livrables/architecture-technique.md --format pdf

# Exporter tous les livrables
python scripts/build_docs.py --all --format pdf

# Exporter en DOCX (pour retouches Word)
python scripts/build_docs.py --all --format docx
```

Les fichiers generes sont dans `output/`.

## Conventions Git

### Commits

```
feat: nouvelle fonctionnalité
fix: correction bug
docs: sync notion / documentation
refactor: refactoring code
test: ajout/modif tests
chore: maintenance
```

### Branches

- `main` - Production stable
- `feature/xxx` - Nouvelles features
- `fix/xxx` - Corrections

## Liens utiles

- [Notion projet](https://www.notion.so/MSPR-NordTransit-Logistics-2e095ddfecb18106aee6f23d0c83a063)
- Lab Proxmox : VMID 32000-32100, réseau 172.16.132.0/24

## Équipe

5 personnes - pas de rôles figés, on s'entraide !
