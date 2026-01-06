# MSPR - NordTransit Logistics

Projet de modernisation infrastructure SI pour NordTransit Logistics (PME logistique, 4 entrepôts + 1 cross-dock).

## Structure du projet

```
MSPR/
├── _specs/                 # Export Notion (READ-ONLY - ne pas éditer)
│   ├── OVERVIEW.md         # Vue d'ensemble projet
│   ├── PLAN.md             # Jalons et planning
│   ├── comprendre/         # Analyse de l'existant
│   ├── solution/           # Architecture cible
│   └── poc/                # Tests de validation
│
├── configs/                # Fichiers techniques (EDITABLE)
│   ├── pfsense/            # Configs firewall
│   ├── ansible/            # Playbooks automation
│   └── azure/              # Templates ARM/Bicep
│
└── scripts/
    └── notion_sync.py      # Sync Notion → local
```

## Workflow équipe

### Règle d'or

| Dossier | Usage | Éditable ? |
|---------|-------|------------|
| `_specs/` | Miroir Notion | NON - sync automatique |
| `configs/` | Fichiers techniques | OUI - commit normalement |

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
