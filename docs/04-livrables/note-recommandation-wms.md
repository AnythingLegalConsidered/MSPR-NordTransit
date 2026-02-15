---
title: "Note de Recommandation WMS"
subtitle: "MSPR - NordTransit Logistics"
author: "Groupe 2 - PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise"
date: 2026-02-06
version: "1.0"
toc: true
---

# Note de Recommandation WMS

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-02-06 |
| Auteurs | Groupe 2 : PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise |
| Statut | Complet |

---

## 1. Contexte

Le WMS (Warehouse Management System) est le systeme le plus critique de NordTransit Logistics.
Il gere en temps reel l'inventaire, les expeditions et la tracabilite des colis sur les 4 entrepots
(Lens, Valenciennes, Arras, Cross-dock) et le siege de Lille.

**Impact d'un arret WMS** : arret immediat de toutes les operations logistiques. Aucun colis ne peut
etre recu, traite ou expedie. Cout estime : plusieurs milliers d'euros par heure d'indisponibilite
(penalites contractuelles + perte de chiffre d'affaires).

---

## 2. Situation actuelle

### 2.1 Hebergement

| Aspect | Etat actuel | Risque |
|--------|-------------|--------|
| Hebergement | VM unique sur Dell R630 (siege) | **SPOF critique** — arret total si panne serveur |
| Sauvegarde | Sauvegarde locale sur le meme serveur | Perte de donnees en cas de sinistre (incendie, vol) |
| Haute disponibilite | Aucune | Aucun failover, pas de redondance |
| Performance | Serveur de 2016, charge croissante | Degradation possible en haute saison (Q4) |
| Reseau | Acces via DrayTek 2860 (VPN faible) | Coupure VPN = entrepots isoles du WMS |

### 2.2 Risques identifies

1. **SPOF serveur** : Le Dell R630 heberge le WMS ET d'autres VMs. Une panne hardware = arret WMS.
2. **Pas de PRA** : Aucun site de reprise. Un sinistre au siege = perte complete.
3. **Backup non externalise** : Les sauvegardes sont sur le meme serveur physique.
4. **VPN instable** : Les DrayTek n'assurent pas un VPN fiable vers les entrepots.

---

## 3. Recommandations

### 3.1 Court terme (dans le cadre du projet MSPR)

**Objectif** : Supprimer le SPOF et assurer la disponibilite immediate.

| Action | Detail | Benefice |
|--------|--------|----------|
| Migration cluster | Migrer la VM WMS vers le cluster Dell R650xs (2 noeuds + SAN ME5012) | Failover automatique, RTO < 1h |
| Snapshots quotidiens | Configurer des snapshots VM quotidiens sur le SAN | RPO < 24h, restauration rapide |
| Backup Veeam | Sauvegarde Veeam vers stockage externe (Azure Blob) | Protection contre sinistre local |
| VLAN dedie | Placer le WMS dans le VLAN 20 (Serveurs) avec acces restreint | Isolation reseau, securite |

**RTO cible** : < 1h (failover cluster)
**RPO cible** : < 15 min (replication SAN + snapshots)

### 3.2 Moyen terme (6-12 mois apres le projet)

| Action | Detail | Benefice |
|--------|--------|----------|
| Replication BDD | MySQL replication vers un serveur secondaire (ou Azure Database) | RPO ~0, haute disponibilite applicative |
| Monitoring PRTG | Sonde dediee WMS : etat MySQL, temps de reponse, espace disque | Detection proactive des problemes |
| Alerting | Alertes par email/SMS si le WMS ne repond pas dans les 30 secondes | Intervention rapide |
| Load testing | Tester les performances WMS sous charge simulee (haute saison) | Identifier les goulots AVANT la crise |

### 3.3 Long terme (12-24 mois)

| Action | Detail | Benefice |
|--------|--------|----------|
| Migration Azure | Migrer le WMS vers Azure via Site Recovery (deja prevu dans l'architecture) | PRA geographique complet |
| Conteneurisation | Dockeriser le WMS pour faciliter le deploiement et les mises a jour | Deploiement reproductible, rollback facile |
| API REST | Exposer le WMS via API pour integration avec d'autres systemes | Interoperabilite, mobilite |
| WMS SaaS | Evaluer une migration vers un WMS SaaS (type Odoo, SAP B1) | Externaliser la maintenance, focus metier |

---

## 4. Impact sur l'architecture

Les recommandations WMS s'integrent dans l'architecture cible comme suit :

| Composant architecture | Impact WMS |
|------------------------|------------|
| Cluster Dell R650xs | WMS migre en priorite (VM critique) |
| SAN PowerVault ME5012 | Stockage WMS sur SSD pour performances |
| FortiGate 100F (siege) | Regles VLAN 20, acces WMS securise |
| FortiGate 60F (entrepots) | VPN IKEv2 stable vers le WMS |
| Azure Site Recovery | WMS replique vers Azure (20 VMs dont WMS) |
| Veeam Backup | WMS dans le plan de sauvegarde prioritaire |
| PRTG | Sonde WMS = premiere sonde configuree |

### Schema d'integration

```
Entrepots (WH1-3)                    Siege Lille
  [WMS Client]                    [Cluster R650xs]
       |                               |
  FortiGate 60F ──── VPN IKEv2 ──── FortiGate 100F
                                       |
                                  VLAN 20 Serveurs
                                       |
                                   [VM WMS]
                                       |
                              SAN ME5012 (stockage)
                                       |
                              Azure Site Recovery
                                       |
                                  [VM WMS Azure]
                                  (mode standby)
```

---

## 5. Validation POC

Le POC valide les recommandations court terme via le test 3 (failover WMS) :

| Test | Protocole | Critere |
|------|-----------|---------|
| Arret brutal VM WMS | Stop VM depuis Proxmox, redemarrer | VM redemarre, MySQL actif |
| Integrite donnees | check_wms.sh avant/apres | 5 records intacts |
| Temps de reprise | Mesurer duree entre stop et service OK | < 1h (RTO cible) |

Resultats : voir `docs/03-lab-poc/07-tests-validation.md` (Test 3)

---

## 6. Annexes

- Guide lab WMS : `docs/03-lab-poc/06-wms-simulation.md`
- Tests failover : `docs/03-lab-poc/07-tests-validation.md`
- Architecture cible : `docs/02-conception/01-architecture-cible.md`
- Budget : `_specs/solution/budget.md`
