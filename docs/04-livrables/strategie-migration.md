---
title: "Strategie de Migration"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-XX-XX
version: "1.0"
toc: true
---

# Strategie de Migration

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-XX-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | Valide |

---

## 1. Introduction

### 1.1 Contexte

NordTransit Logistics est une PME de logistique operant 4 entrepots (Lens, Valenciennes, Arras, cross-dock) et un siege social a Lille, pour un effectif de 240 a 300 personnes selon la saison. L'infrastructure actuelle presente des points uniques de defaillance critiques (hyperviseur unique Dell R630, NAS sans externalisation, pare-feu heterogenes) qui menacent la continuite d'activite.

Ce document definit la strategie de migration de l'infrastructure existante vers l'architecture cible (cluster 2 noeuds Dell R650xs, SAN PowerVault ME5012, pare-feu FortiGate homogenes, PRA Azure), en minimisant les interruptions de service et en garantissant un rollback a chaque etape.

### 1.2 Contraintes absolues

| Contrainte | Detail |
|------------|--------|
| Disponibilite WMS | Le WMS ne doit JAMAIS etre arrete entre 5h30 et 18h30 (heures d'operations logistiques) |
| Coexistence | L'ancien et le nouveau systeme doivent coexister pendant la transition |
| Rollback | Chaque phase doit pouvoir etre annulee en moins de 30 minutes |
| Budget | Enveloppe totale de 137 301 EUR (plafond 150 000 EUR) |
| Equipe DSI | 4 personnes en interne, interventions nocturnes ou week-end |

### 1.3 Principes directeurs

1. **Migration site par site** : commencer par le site le moins critique pour roder le processus
2. **Validation avant progression** : chaque phase est validee avant passage a la suivante
3. **Zero impact en heures ouvrees** : toutes les migrations impactantes se font hors 5h30-18h30
4. **Documentation systematique** : chaque intervention est tracee pour reproductibilite

---

## 2. Fenetres de maintenance

Le planning de migration s'appuie sur trois types de creneaux, definis pour respecter la contrainte WMS.

| Fenetre | Horaire | Duree max | Usage type |
|---------|---------|-----------|------------|
| Nuit semaine | 19h00 - 04h00 | 9h | Migrations reseau, deploiement pare-feu |
| Nuit week-end | 18h30 sam - 05h00 lun | 34h | Migrations serveurs, migration WMS, tests PRA |
| Journee (sans impact) | 09h00 - 17h00 | 8h | Installations physiques, configuration Azure, cablage |

> **Regle** : aucune migration impactant un service de production ne doit demarrer apres 01h00 en nuit de semaine (4h de marge pour rollback avant 5h30).

---

## 3. Ordre de migration des sites

La migration des sites distants suit un ordre du moins critique au plus critique, afin de valider les procedures sur des environnements simples avant d'attaquer le siege.

| Ordre | Site | Justification |
|-------|------|---------------|
| 1 | Cross-dock | Site le plus simple (switch basique, activation saisonniere), valide le processus |
| 2 | WH3 Arras | Entrepot standard, premiere validation sur site permanent |
| 3 | WH2 Valenciennes | Entrepot standard, confirme la reproductibilite |
| 4 | WH1 Lens | Entrepot standard, derniere validation avant siege |
| 5 | Siege Lille | Site le plus critique (heberge toutes les VMs, DC, WMS, IPBX), migre en dernier |

---

## 4. Phases de migration

### 4.1 Phase M1 -- Deploiement des pare-feu FortiGate

| Element | Detail |
|---------|--------|
| **Objectif** | Remplacer les DrayTek 2860 et le FortiGate 80D (EOL) par une gamme homogene FortiGate (100F/60F/40F) |
| **Duree** | 5 nuits (1 site par nuit) |
| **Creneau** | Nuit semaine, 19h00 - 04h00 |
| **Prerequis** | Materiel recu et pre-configure en atelier, VPN IKEv2 pre-testes en lab |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Pre-configurer le FortiGate en atelier (interfaces, VPN IKEv2, regles firewall, DPD) | 2h (journee) | Admin reseau |
| 2 | Nuit J : couper le lien WAN du site cible | 5 min | Admin reseau |
| 3 | Debrancher l'ancien equipement (DrayTek ou 80D), brancher le FortiGate | 15 min | Admin reseau |
| 4 | Activer le FortiGate, verifier la connectivite WAN | 10 min | Admin reseau |
| 5 | Monter le tunnel VPN IKEv2 vers le siege (ou vers le nouveau FG100F si siege deja migre) | 20 min | Admin reseau |
| 6 | Tester : ping inter-sites, acces WMS, telephonie VoIP, acces internet | 30 min | Equipe |
| 7 | Valider et documenter | 15 min | Admin reseau |

**Ordre de deploiement :**

| Nuit | Site | Equipement | Remarque |
|------|------|------------|----------|
| N1 | Cross-dock | FortiGate 40F | Site saisonnier, risque minimal |
| N2 | WH3 Arras | FortiGate 60F | Premier entrepot permanent |
| N3 | WH2 Valenciennes | FortiGate 60F | Confirmation processus |
| N4 | WH1 Lens | FortiGate 60F | Dernier entrepot |
| N5 | Siege Lille | FortiGate 100F | Hub VPN central, migration la plus sensible |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Tunnel VPN ne monte pas | Moyenne | Haut (perte acces WMS distant) | Config de secours DrayTek prete, basculer en 15 min |
| Regles firewall trop restrictives | Moyenne | Moyen (services bloques) | Jeu de regles teste en lab, mode permissif temporaire si necessaire |
| Incompatibilite IKEv2 avec ancien FG80D (pendant transition) | Faible | Moyen | Garder un tunnel IKEv1 de secours jusqu'a migration du siege |

**Procedure de rollback :**

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Debrancher le nouveau FortiGate | 2 min |
| 2 | Rebrancher l'ancien DrayTek / FortiGate 80D | 5 min |
| 3 | Verifier le retablissement de la connectivite | 5 min |
| **Total** | | **~15 min** |

---

### 4.2 Phase M2 -- Installation cluster serveurs + SAN

| Element | Detail |
|---------|--------|
| **Objectif** | Installer les 2 Dell R650xs en cluster (Hyper-V / VMware) avec le SAN PowerVault ME5012, sans impacter le R630 existant |
| **Duree** | 1 week-end (installation physique) + 2 jours (configuration) |
| **Creneau** | Journee (sans impact, nouveau materiel) + nuit pour le cablage reseau |
| **Prerequis** | Baie serveur avec espace, alimentation electrique, cablage iSCSI prepare |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Installation physique des 2 R650xs dans la baie | 2h | Admin systeme |
| 2 | Installation physique du SAN PowerVault ME5012 | 1h | Admin systeme |
| 3 | Cablage reseau (iSCSI dedie, management, production) | 2h | Admin reseau |
| 4 | Configuration RAID/LUN sur le SAN (8x SSD 1.92 To) | 2h | Admin systeme |
| 5 | Installation de l'hyperviseur sur les 2 noeuds | 2h | Admin systeme |
| 6 | Configuration du cluster (quorum Azure Cloud Witness) | 1h | Admin systeme |
| 7 | Tests de bascule cluster (failover/failback a vide) | 2h | Equipe |
| 8 | Validation et documentation | 1h | Admin systeme |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Materiel defectueux a la livraison | Faible | Haut (retard projet) | Commander avec delai de marge, verifier a reception |
| Probleme de connectivite iSCSI | Faible | Moyen (pas de stockage partage) | Tester le cablage et les MTU avant configuration cluster |
| Cluster ne forme pas le quorum | Faible | Moyen | Azure Cloud Witness pre-configure, documentation Microsoft suivie |

**Procedure de rollback :**

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Le R630 existant reste actif en parallele pendant toute la phase | Immediat |
| 2 | Si probleme cluster : corriger sans urgence (aucun service de production impacte) | N/A |
| **Total** | Pas de rollback necessaire (nouveau materiel, pas d'impact production) | **Immediat** |

---

### 4.3 Phase M3 -- Migration des VMs vers le cluster

| Element | Detail |
|---------|--------|
| **Objectif** | Migrer les ~20 VMs du R630 (hyperviseur unique SPOF) vers le nouveau cluster HA |
| **Duree** | 2 nuits de week-end (migration par lots) |
| **Creneau** | Nuit week-end, 18h30 sam - 05h00 dim (10h30 disponibles) |
| **Prerequis** | Cluster M2 valide, snapshots de toutes les VMs, backups Veeam verifies |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Realiser un snapshot de chaque VM sur le R630 | 1h | Admin systeme |
| 2 | Verifier les backups Veeam de toutes les VMs | 30 min | Admin systeme |
| 3 | **Lot 1 (nuit 1) -- VMs non critiques** : SUPER-01 (supervision), serveurs secondaires | 3h | Admin systeme |
| 4 | Valider le fonctionnement des VMs migrees | 1h | Equipe |
| 5 | **Lot 2 (nuit 2) -- VMs critiques** : DC01, DC02, WMS-APP, WMS-DB, IPBX-VM | 4h | Admin systeme |
| 6 | Tests complets : AD, authentification, WMS (lecture/ecriture), telephonie | 2h | Equipe |
| 7 | Validation finale, mise hors tension du R630 (garde en standby 72h) | 30 min | Admin systeme |

**Ordre de migration des VMs critiques (Lot 2) :**

| Ordre | VM | IP | Criticite | Justification de l'ordre |
|-------|----|----|-----------|--------------------------|
| 1 | DC02 | 192.168.10.11 | Haute | DC secondaire, test de replication |
| 2 | DC01 | 192.168.10.10 | Critique | DC principal, valide apres DC02 |
| 3 | IPBX-VM | 192.168.10.40 | Critique | Telephonie, pas d'impact nuit |
| 4 | WMS-DB | 192.168.10.21 | Critique | Base de donnees, snapshot avant |
| 5 | WMS-APP | 192.168.10.22 | Critique | Application, dernier pour minimiser downtime |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Echec migration WMS | Moyenne | Critique (arret operations) | Snapshot pre-migration, rollback en 30 min, R630 en standby |
| Corruption donnees pendant transfert | Faible | Critique | Verification checksums, backup Veeam independant |
| Migration depasse la fenetre | Moyenne | Haut (WMS indisponible a 5h30) | Commencer par les VMs les plus rapides, seuil d'abandon a 03h00 |
| Probleme reseau post-migration (IP, DNS) | Moyenne | Moyen | Memes IP conservees, cache DNS purge, tests DNS pre-valides |

**Procedure de rollback :**

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Arreter la VM migree sur le nouveau cluster | 2 min |
| 2 | Restaurer le snapshot sur le R630 | 20 min |
| 3 | Demarrer la VM originale sur le R630 | 5 min |
| 4 | Verifier le service (WMS, AD, telephonie) | 5 min |
| **Total** | | **~30 min** |

> **Seuil d'abandon** : si la migration du Lot 2 n'est pas terminee a 03h00, rollback immediat et report au week-end suivant.

---

### 4.4 Phase M4 -- Configuration Azure (VPN + DC + PRA)

| Element | Detail |
|---------|--------|
| **Objectif** | Deployer la Landing Zone Azure : VPN site-a-site, DC replique cloud, Azure Site Recovery pour le PRA |
| **Duree** | 3 jours (configuration sans impact production) |
| **Creneau** | Journee, 09h00 - 17h00 (aucun impact sur la production) |
| **Prerequis** | FortiGate 100F en place (M1), cluster operationnel (M2), abonnement Azure active |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Creer la Landing Zone Azure (Resource Group, VNet 10.100.0.0/24, subnets) | 2h | Admin systeme |
| 2 | Deployer la VPN Gateway Azure et configurer le tunnel site-a-site vers FortiGate 100F | 3h | Admin reseau |
| 3 | Verifier la connectivite VPN (ping, traceroute, tests de debit) | 1h | Equipe |
| 4 | Deployer DC-Azure (VM Windows Server) et configurer la replication AD | 3h | Admin systeme |
| 5 | Valider la replication AD (forcer une synchro, verifier les objets) | 1h | Admin systeme |
| 6 | Configurer Azure Site Recovery (vault, politique de replication, VMs cibles) | 4h | Admin systeme |
| 7 | Lancer la replication initiale des 20 VMs vers Azure | Variable (bande passante) | Admin systeme |
| 8 | Configurer Azure Blob Storage pour les backups externalises | 1h | Admin systeme |
| 9 | Test de failover PRA sur une VM non critique | 2h | Equipe |
| 10 | Documentation et validation | 1h | Admin systeme |

**Composants Azure deployes :**

| Composant | Role | Reseau |
|-----------|------|--------|
| VPN Gateway | Tunnel site-a-site vers FortiGate 100F | 10.100.0.0/24 |
| DC-Azure | Controleur domaine replique (PRA AD) | 10.100.0.0/24 |
| Recovery Services Vault | PRA automatise (20 VMs) | - |
| Blob Storage | Backup externalise | 10.100.1.0/24 |

**Objectifs RTO/RPO :**

| Service | RTO | RPO |
|---------|-----|-----|
| Active Directory | < 15 min | 0 (replication temps reel) |
| WMS | < 1h | < 15 min |
| Telephonie | < 30 min | N/A |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Tunnel VPN instable | Faible | Moyen (replication lente) | DPD configure, failover 4G en secours |
| Replication initiale trop longue | Moyenne | Faible (pas d'impact production) | Planifier en heures creuses, limiter la bande passante |
| Cout Azure depasse le budget | Faible | Faible | Reserved Instances 3 ans (-40%), monitoring des couts |

**Procedure de rollback :**

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Couper le tunnel VPN sur le FortiGate | 5 min |
| 2 | Supprimer les ressources Azure (ou les arreter) | 15 min |
| **Total** | Aucun impact sur la production (resources cloud independantes) | **~5 min** |

---

### 4.5 Phase M5 -- Activation QoS et VLAN

| Element | Detail |
|---------|--------|
| **Objectif** | Segmenter le reseau en VLAN (MGMT, SERVEURS, DATA, VOIP) et activer la QoS pour garantir la VoIP |
| **Duree** | 3 nuits (1 nuit par lot de sites) |
| **Creneau** | Nuit semaine, 19h00 - 04h00 |
| **Prerequis** | FortiGate en place (M1), switches Cisco C9200 deployes, plan VLAN valide |

**Plan VLAN standardise :**

| VLAN ID | Nom | Usage | DSCP | Bande passante |
|---------|-----|-------|------|----------------|
| 10 | MGMT | Administration switches, AP, firewalls | CS2 (16) | 5% garanti |
| 20 | SERVEURS | VMs, stockage SAN | AF31 (26) | 40% garanti |
| 30 | DATA | Postes, terminaux RF, imprimantes | BE (0) | Best effort |
| 40 | VOIP | Telephones IP Cisco | EF (46) | 30% garanti |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Pre-configurer les VLAN sur les switches Cisco C9200 en journee (sans les activer) | 2h | Admin reseau |
| 2 | Nuit 1 : activer les VLAN au siege (switch par switch, validation incrementale) | 4h | Admin reseau |
| 3 | Configurer les regles inter-VLAN sur le FortiGate 100F | 1h | Admin reseau |
| 4 | Configurer la QoS (DSCP EF pour VOIP, AF31 pour SERVEURS) | 1h | Admin reseau |
| 5 | Tester : telephonie VoIP (qualite d'appel), acces WMS, administration | 1h | Equipe |
| 6 | Nuit 2 : activer les VLAN sur les entrepots WH1-WH3 | 3h | Admin reseau |
| 7 | Nuit 3 : ajustements, tests bout en bout, documentation | 2h | Equipe |

**Regles inter-VLAN (FortiGate) :**

| Source | Destination | Action | Justification |
|--------|-------------|--------|---------------|
| VOIP (40) | SERVEURS (20) | Autorise | SIP vers IPBX |
| DATA (30) | SERVEURS (20) | Autorise | Acces WMS, AD, fichiers |
| DATA (30) | VOIP (40) | Refuse | Isolation telephonie |
| MGMT (10) | Tous | Autorise | Administration |
| Tous | Internet | Autorise (via NAT) | Acces web filtre |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Terminaux RF non detectes dans le bon VLAN | Moyenne | Haut (arret picking entrepot) | Tester les terminaux RF en premier, port d'acces dedie |
| QoS trop restrictive (voix OK mais data lente) | Moyenne | Moyen | Ajuster les pourcentages apres tests de charge |
| Imprimantes/etiqueteuses inaccessibles | Moyenne | Haut (arret expedition) | Verifier les IP et VLAN de chaque peripherique avant |

**Procedure de rollback :**

| Etape | Action | Delai |
|-------|--------|-------|
| 1 | Desactiver les VLAN sur les switches (retour en access port unique) | 10 min |
| 2 | Retirer les regles inter-VLAN sur le FortiGate | 5 min |
| 3 | Verifier la connectivite | 5 min |
| **Total** | | **~20 min** |

---

### 4.6 Phase M6 -- Tests de validation et PRA

| Element | Detail |
|---------|--------|
| **Objectif** | Valider l'ensemble de l'infrastructure migree : tests fonctionnels, tests de charge, test PRA reel |
| **Duree** | 1 week-end complet |
| **Creneau** | Nuit week-end, 18h30 sam - 05h00 lun |
| **Prerequis** | Phases M1 a M5 terminees et validees |

**Etapes detaillees :**

| # | Action | Duree estimee | Responsable |
|---|--------|---------------|-------------|
| 1 | Tests fonctionnels : WMS (saisie, lecture, impression etiquettes), AD (authentification, GPO), telephonie (appels internes/externes) | 3h | Equipe |
| 2 | Tests de connectivite inter-sites : VPN, latence, debit | 1h | Admin reseau |
| 3 | Test de bascule cluster (arreter un noeud, verifier la continuite) | 2h | Admin systeme |
| 4 | Test PRA Azure : failover complet d'une VM critique vers Azure | 3h | Admin systeme |
| 5 | Test de restauration Veeam : restaurer une VM depuis le backup | 2h | Admin systeme |
| 6 | Test QoS : charge reseau simulee + appel VoIP simultane | 1h | Admin reseau |
| 7 | Validation des metriques PRTG (tous les capteurs au vert) | 1h | Equipe |
| 8 | Redaction du PV de validation | 2h | Chef de projet |
| 9 | Formation equipe DSI (4 personnes) sur les nouvelles procedures | 4h | Equipe |

**Criteres de validation :**

| Test | Critere de succes | Resultat |
|------|-------------------|----------|
| WMS operationnel | Saisie + lecture + etiquettes OK sur les 4 sites | [ ] OK / [ ] KO |
| AD fonctionnel | Authentification, GPO, replication DC01-DC02-DC-Azure | [ ] OK / [ ] KO |
| Telephonie | Appels internes et externes sans coupure ni echo | [ ] OK / [ ] KO |
| Cluster HA | Failover automatique en < 2 min | [ ] OK / [ ] KO |
| PRA Azure | Failover VM en < 1h (RTO cible) | [ ] OK / [ ] KO |
| QoS VoIP | MOS > 4.0 sous charge reseau | [ ] OK / [ ] KO |
| Backup Veeam | Restauration complete d'une VM en < 30 min | [ ] OK / [ ] KO |
| VPN inter-sites | Latence < 30 ms, debit > 100 Mbps | [ ] OK / [ ] KO |

**Risques specifiques :**

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Tests revelent un probleme non detecte | Moyenne | Variable | Prevoir 1 semaine de marge avant la mise en production definitive |
| PRA Azure echoue | Faible | Haut | Tester sur VM non critique d'abord, documenter chaque erreur |

**Procedure de rollback :** Non applicable (phase de tests uniquement, pas de modification de production).

---

## 5. Planning general

### 5.1 Vue d'ensemble (6 semaines)

| Semaine | Phase | Actions principales | Creneau |
|---------|-------|---------------------|---------|
| S1 | **Preparation** | Reception materiel, pre-configuration FortiGate en atelier, preparation cablage | Journee |
| S1-S2 | **M1 -- Pare-feu** | Deploiement FortiGate sur 5 sites (1 site/nuit) | 5 nuits |
| S2-S3 | **M2 -- Cluster + SAN** | Installation physique R650xs + ME5012, configuration cluster | Journee + 1 nuit |
| S3 | **M3 -- Migration VMs** | Lot 1 (non critiques) + Lot 2 (critiques) | 2 nuits WE |
| S4 | **M4 -- Azure** | Landing Zone, VPN, DC replique, Site Recovery | Journee |
| S5 | **M5 -- QoS & VLAN** | Segmentation reseau, activation QoS | 3 nuits |
| S6 | **M6 -- Validation** | Tests bout en bout, PRA, formation DSI | 1 WE |

### 5.2 Diagramme temporel

```
Semaine    S1         S2         S3         S4         S5         S6
           |----------|----------|----------|----------|----------|
PREP       [========]
M1 Pare-feu     [==========]
M2 Cluster           [==========]
M3 VMs                     [=====]
M4 Azure                            [========]
M5 VLAN/QoS                                  [==========]
M6 Valid.                                                [=======]
```

### 5.3 Jalons cles

| Jalon | Semaine | Critere de passage |
|-------|---------|-------------------|
| J1 -- Pare-feu operationnels | Fin S2 | 5 FortiGate deployes, VPN IKEv2 fonctionnels entre tous les sites |
| J2 -- Cluster pret | Fin S3 | Cluster 2 noeuds + SAN fonctionnels, failover teste a vide |
| J3 -- VMs migrees | Fin S3 | Toutes les VMs sur le cluster, R630 eteint (en standby) |
| J4 -- Azure operationnel | Fin S4 | VPN Azure, DC replique, replication ASR en cours |
| J5 -- Reseau segmente | Fin S5 | VLAN actifs, QoS configuree, VoIP validee |
| J6 -- Go/No-Go production | Fin S6 | Tous les tests de validation passes, PV signe |

---

## 6. Budget migration

Le budget de migration s'inscrit dans l'enveloppe globale du projet.

| Poste | Montant |
|-------|---------|
| Securite (FortiGate + licences 3 ans) | 17 520 EUR |
| Virtualisation (2x Dell R650xs + ProSupport) | 30 000 EUR |
| Stockage (PowerVault ME5012 + maintenance) | 20 000 EUR |
| Reseau (4x Cisco C9200 + SmartNet) | 12 000 EUR |
| Azure PRA (3 ans, Reserved) | 11 232 EUR |
| Supervision (PRTG + Veeam, 3 ans) | 7 500 EUR |
| Connectivite Internet (1 an) | 12 840 EUR |
| Main d'oeuvre (1 architecte + 4 experts, 20h chacun) | 8 300 EUR |
| Marge imprevus (15%) | 17 909 EUR |
| **TOTAL** | **137 301 EUR** |

> Budget respecte : 137 301 EUR < 150 000 EUR. Marge restante de 12 699 EUR.

---

## 7. Plan de rollback consolide

Chaque phase dispose d'une procedure de retour arriere testee.

| Phase | Action de rollback | Delai max | Responsable | Impact production |
|-------|-------------------|-----------|-------------|-------------------|
| M1 -- Pare-feu | Rebrancher l'ancien DrayTek / FortiGate 80D | 15 min | Admin reseau | Faible (nuit) |
| M2 -- Cluster | R630 reste actif en parallele (pas de rollback necessaire) | Immediat | Admin systeme | Aucun |
| M3 -- Migration VMs | Restaurer les snapshots sur le R630 | 30 min | Admin systeme | Nul si avant 5h30 |
| M4 -- Azure | Couper le tunnel VPN, supprimer les ressources Azure | 5 min | Admin reseau | Aucun |
| M5 -- QoS/VLAN | Desactiver les VLAN, retour en flat network | 20 min | Admin reseau | Faible (nuit) |
| M6 -- Validation | Non applicable (tests uniquement) | - | - | Aucun |

### Regles de declenchement du rollback

1. **Service critique indisponible** (WMS, AD, telephonie) et non retabli en 15 min
2. **Depassement du seuil horaire** : 03h00 en nuit de semaine, 03h00 dimanche en nuit de WE
3. **Decision du chef de projet** : en cas de doute, on rollback et on replanifie

---

## 8. Matrice des risques

### 8.1 Echelle d'evaluation

| Niveau | Probabilite | Impact |
|--------|-------------|--------|
| 1 - Faible | < 10% de chance | Perturbation mineure, pas d'arret de service |
| 2 - Moyen | 10-40% | Degradation de service, correction en < 1h |
| 3 - Haut | 40-70% | Arret d'un service critique, rollback necessaire |
| 4 - Critique | > 70% | Arret total de production, perte de donnees potentielle |

### 8.2 Matrice complete

| # | Risque | Phase | Probabilite | Impact | Score | Mitigation | Responsable |
|---|--------|-------|-------------|--------|-------|------------|-------------|
| R1 | Echec migration WMS (corruption ou timeout) | M3 | 2 - Moyen | 4 - Critique | **8** | Snapshot pre-migration, backup Veeam, seuil d'abandon a 03h00, R630 en standby 72h | Admin systeme |
| R2 | Tunnel VPN IKEv2 ne monte pas | M1 | 2 - Moyen | 3 - Haut | **6** | Config testee en lab, ancien equipement pret a rebrancher en 15 min | Admin reseau |
| R3 | Migration depasse la fenetre de maintenance | M3 | 2 - Moyen | 3 - Haut | **6** | Planifier large, lots separes, seuil d'abandon strict | Chef de projet |
| R4 | Terminaux RF/imprimantes non fonctionnels apres VLAN | M5 | 2 - Moyen | 3 - Haut | **6** | Inventaire complet des peripheriques, test individuel, VLAN DATA par defaut | Admin reseau |
| R5 | Probleme replication AD vers DC-Azure | M4 | 1 - Faible | 3 - Haut | **3** | Synchro forcee, verification des ports, test de failover pre-production | Admin systeme |
| R6 | Materiel defectueux a reception | M2 | 1 - Faible | 3 - Haut | **3** | Commander avec delai de marge, verifier a reception, contrat ProSupport Dell | Chef de projet |
| R7 | QoS VoIP degrade la data (config trop agressive) | M5 | 2 - Moyen | 2 - Moyen | **4** | Tests de charge, ajustement progressif des pourcentages | Admin reseau |
| R8 | Cout Azure depasse le previsionnel | M4 | 1 - Faible | 1 - Faible | **1** | Reserved Instances 3 ans, alertes budgetaires Azure, monitoring mensuel | Chef de projet |
| R9 | Perte de connectivite internet pendant migration | M1/M5 | 1 - Faible | 3 - Haut | **3** | Lien 4G/5G de secours sur chaque site, basculement automatique | Admin reseau |
| R10 | Indisponibilite d'un membre de l'equipe pendant une nuit critique | M3 | 2 - Moyen | 2 - Moyen | **4** | Procedures documentees, 2 personnes formees sur chaque phase | Chef de projet |

### 8.3 Risques prioritaires (score >= 6)

| # | Risque | Score | Action prioritaire |
|---|--------|-------|--------------------|
| R1 | Echec migration WMS | **8** | Lab POC prealable obligatoire, procedure testee 2 fois avant la nuit reelle |
| R2 | Tunnel VPN IKEv2 | **6** | Validation lab complete avec les modeles exacts de FortiGate |
| R3 | Depassement fenetre | **6** | Chronometrer chaque etape en lab, ajouter 30% de marge |
| R4 | Peripheriques post-VLAN | **6** | Inventaire detaille avec MAC/IP/VLAN de chaque equipement |

---

## 9. Communication et gouvernance

### 9.1 Parties prenantes

| Partie prenante | Role | Information attendue |
|-----------------|------|---------------------|
| Direction NordTransit | Sponsor | Go/No-Go avant chaque phase critique (M3, M5) |
| DSI (4 personnes) | Execution | Planning detaille, procedures, escalade |
| Responsables entrepots | Utilisateurs | Horaires de coupure, contact en cas de probleme |
| Equipe projet (5 experts) | Migration | Affectation par phase, checklist |

### 9.2 Points de controle

| Moment | Action | Participants |
|--------|--------|--------------|
| Avant chaque phase | Reunion Go/No-Go (15 min) | Chef de projet + admin concerne |
| Pendant chaque migration | Point de contact telephonique | Admin sur site + backup |
| Apres chaque phase | Compte-rendu ecrit (email + ticket) | Equipe projet |
| Fin de migration (S6) | PV de validation signe | Direction + DSI + equipe projet |

---

## 10. Annexes

### 10.1 Documents de reference

| Document | Chemin |
|----------|--------|
| Architecture cible detaillee | `_specs/solution/architecture-cible.md` |
| Plan d'adressage VLAN | `docs/02-conception/02-plan-adressage-vlan.md` |
| Strategie de securite | `docs/02-conception/03-strategie-securite.md` |
| Budget detaille | `_specs/solution/budget.md` |
| Guide de migration (conception) | `docs/02-conception/04-strategie-migration.md` |

### 10.2 Guides de lab associes

| Guide | Phase concernee |
|-------|-----------------|
| `docs/03-lab-poc/00-prerequis-lab.md` | Toutes |
| `docs/03-lab-poc/01-reseau-base.md` | M1, M5 |
| `docs/03-lab-poc/02-firewall-vpn.md` | M1 |
| `docs/03-lab-poc/03-hyperviseur-cluster.md` | M2 |
| `docs/03-lab-poc/04-ad-dns.md` | M3, M4 |
| `docs/03-lab-poc/05-wms-applicatif.md` | M3 |
| `docs/03-lab-poc/06-azure-pra.md` | M4 |
| `docs/03-lab-poc/07-tests-validation.md` | M6 |

### 10.3 Contacts d'escalade

| Niveau | Contact | Delai de reaction |
|--------|---------|-------------------|
| N1 | Admin sur site | Immediat |
| N2 | Chef de projet | 15 min |
| N3 | Direction NordTransit | 30 min (si arret production > 1h) |
| Support Dell ProSupport | Hotline 24/7 | 4h (NBD pour non critique) |
| Support Fortinet | FortiCare | NBD |
