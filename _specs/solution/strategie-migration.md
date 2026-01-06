# Stratégie de migration

> Plan de déploiement sans interruption de service

---

## Principes

> **Contrainte absolue** : Pas d'interruption pendant les heures ouvrées (5h30 - 18h30)

- Migration site par site
- Coexistence ancien/nouveau pendant la transition
- Rollback possible à chaque étape
- Tests de validation avant passage au site suivant

---

## Planning de migration

### Phase 1 : Préparation (Semaine 1-2)

| Action | Durée |
| --- | --- |
| Installation cluster serveurs | 2 jours |
| Configuration stockage SAN | 1 jour |
| Setup Azure Landing Zone | 1 jour |
| Tests internes | 2 jours |

### Phase 2 : Siège (Semaine 3)

| Action | Créneau | Durée |
| --- | --- | --- |
| Installation FortiGate 100F | Nuit (19h-23h) | 4h |
| Migration VMs vers cluster | Nuit suivante | 4h |
| Validation services | Matinée | 2h |

### Phase 3 : Sites distants (Semaine 4-5)

| Site | Créneau | Durée |
| --- | --- | --- |
| WH1 Lens | Nuit | 3h |
| WH2 Valenciennes | Nuit +1 | 3h |
| WH3 Arras | Nuit +2 | 3h |
| Cross-dock | Journée (site fermé) | 2h |

### Phase 4 : Finalisation (Semaine 6)

| Action | Durée |
| --- | --- |
| Tests bout en bout | 1 jour |
| Documentation finale | 1 jour |
| Formation équipe DSI | 1 jour |
| Mise en supervision | 1 jour |

---

## Plan de rollback

| Situation | Action |
| --- | --- |
| Problème pare-feu | Rebrancher ancien équipement |
| Problème VMs | Restaurer depuis backup |
| Problème VPN | Tunnels de secours préconfigurés |
