---
title: "Titre du guide"
phase: "XX-phase"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Prerequis 1"
  - "Prerequis 2"
---

# Titre du guide

## Objectif

> Quoi et pourquoi — en 2-3 phrases max.
> Expliquer ce que ce guide permet d'accomplir et dans quel contexte du projet il s'inscrit.

## Prerequis

- [ ] Prerequis 1 (ex: guide precedent termine)
- [ ] Prerequis 2 (ex: ISO/logiciel telecharge)
- [ ] Prerequis 3 (ex: acces reseau/Proxmox confirme)

## Etapes

### 1. Premiere etape

**Pourquoi** : Explication du choix technique ou de la raison de cette etape.

```bash
# Commande exacte a executer
commande ici
```

**Resultat attendu** : Decrire ce qu'on doit voir a l'ecran ou dans les logs.

### 2. Deuxieme etape

**Pourquoi** : Justification.

```bash
commande ici
```

**Resultat attendu** : Description.

## Verification

| Test | Commande/Action | Resultat attendu |
|------|-----------------|-------------------|
| Test 1 | `commande` | Description du succes |
| Test 2 | Action manuelle | Ce qu'on doit observer |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| Erreur X | Mauvaise config Y | Verifier Z puis relancer |
| Service ne demarre pas | Port occupe | `netstat -tlnp` puis killer le process |

## Liens

- Spec de reference : `_specs/xxx.md`
- Guide precedent : `docs/XX-phase/XX-guide.md`
- Guide suivant : `docs/XX-phase/XX-guide.md`
