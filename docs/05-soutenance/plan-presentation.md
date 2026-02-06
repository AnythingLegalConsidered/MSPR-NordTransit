---
title: "Plan de presentation - Soutenance MSPR"
phase: "05-soutenance"
author: "Equipe NordTransit"
date: 2026-XX-XX
---

# Plan de presentation - Soutenance MSPR

## Objectif

> Structurer la presentation de soutenance et repartir les parties entre les 5 membres.
> Timing : ~15-20 min presentation + ~5 min demo POC + ~10 min questions.

## Structure des slides

### Partie 1 - Contexte (3-4 min)
- Presenter NordTransit (metier, sites, equipe DSI)
- Problematique (SPOF, securite, pas de PRA)
- Budget et contraintes

**Responsable** : _a attribuer_

### Partie 2 - Architecture cible (5-6 min)
- Schema reseau AVANT → APRES
- Choix techniques et justifications
- Plan VLAN et QoS
- Strategy PRA Azure

**Responsable** : _a attribuer_

### Partie 3 - Demo POC (5 min)
- Montrer le lab Proxmox
- Demo live : tunnel VPN, failover AD, QoS VoIP
- Resultats des tests (captures)

**Responsable** : _a attribuer_

### Partie 4 - Migration et budget (3-4 min)
- Phases de migration
- Budget detaille
- Couts recurrents (OPEX)

**Responsable** : _a attribuer_

### Partie 5 - Conclusion (2 min)
- Recapitulatif des gains
- Prochaines etapes
- Questions

**Responsable** : _a attribuer_

## Questions types a preparer

| Question probable | Elements de reponse |
|-------------------|---------------------|
| Pourquoi 2 serveurs et pas 3 ? | Economie ~15k, Azure = PRA geo, Cloud Witness = quorum |
| Pourquoi FortiGate et pas un autre ? | Interface connue, support FR, prix PME, ecosystem |
| Quel est le RTO/RPO ? | AD < 15min/0, WMS < 1h/15min, VoIP < 30min |
| Risques de la migration ? | Phases avec rollback, fenetres nuit, ordre par criticite |
| Budget est-il realiste ? | 137k < 150k, marge 15% imprevus incluse |

## Checklist avant soutenance

- [ ] Slides finalisees et relues
- [ ] Demo POC testee sur le lab
- [ ] Chaque membre connait sa partie
- [ ] Repetition generale effectuee
- [ ] Backup des slides en PDF
- [ ] Timer prepare (respect du timing)
