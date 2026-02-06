# Budget detaille

> Chiffrage complet de la modernisation

**Budget total alloue** : 100 000 EUR - 150 000 EUR

---

## Repartition budgetaire detaillee

> Calculs detailles et justifies -- Budget max 150 000 EUR

| Poste | Detail du calcul | Montant |
|---|---|---|
| **Securite** | | |
| FortiGate 100F (siege) | 1 x 2 800 EUR | 2 800 EUR |
| FortiGate 60F (entrepots) | 3 x 440 EUR | 1 320 EUR |
| FortiGate 40F (backup) | 1 x 400 EUR | 400 EUR |
| Licences FortiCare/FortiGuard 3 ans | 5 appareils x 2 600 EUR | 13 000 EUR |
| **Sous-total Securite** | | **17 520 EUR** |
| **Virtualisation** | | |
| Dell R650xs (siege) | 2 x 13 000 EUR | 26 000 EUR |
| ProSupport Dell 3 ans | 2 x 2 000 EUR | 4 000 EUR |
| **Sous-total Virtualisation** | | **30 000 EUR** |
| **Stockage** | | |
| Dell PowerVault ME5012 | 1 x 17 500 EUR | 17 500 EUR |
| Maintenance 3 ans | ~15% du prix | 2 500 EUR |
| **Sous-total Stockage** | | **20 000 EUR** |
| **Reseau** | | |
| Cisco Catalyst C9200 24P | 4 x 2 500 EUR | 10 000 EUR |
| SmartNet 3 ans | 4 x 500 EUR | 2 000 EUR |
| **Sous-total Reseau** | | **12 000 EUR** |
| **Azure PRA (3 ans)** | | |
| Azure Site Recovery | 20 VMs x 23 EUR/mois x 36 mois | 16 560 EUR |
| Stockage replica (Standard HDD) | 500 Go x 0.02 EUR/Go x 36 mois | 360 EUR |
| Snapshots + Egress | ~50 EUR/mois x 36 mois | 1 800 EUR |
| Reduction Reserved 3 ans (-40%) | | -7 488 EUR |
| **Sous-total Azure PRA** | | **11 232 EUR** |
| **Supervision (3 ans)** | | |
| PRTG 500 sensors | 1 500 EUR/an x 3 ans | 4 500 EUR |
| Veeam Backup Essentials | 1 000 EUR/an x 3 ans | 3 000 EUR |
| **Sous-total Supervision** | | **7 500 EUR** |
| **Connectivite Internet (1 an)** | | |
| Siege : Fibre 1 Gbps x 2 FAI | 2 x 200 EUR/mois x 12 | 4 800 EUR |
| Entrepots : Fibre 500 Mbps | 3 x 120 EUR/mois x 12 | 4 320 EUR |
| Backup 4G/5G (routeurs) | 3 x 400 EUR | 1 200 EUR |
| Forfaits 4G/5G | 3 x 70 EUR/mois x 12 | 2 520 EUR |
| **Sous-total Internet** | | **12 840 EUR** |
| **Main d'oeuvre** | | |
| Architecte/Lead | 1 x 20h x 115 EUR/h | 2 300 EUR |
| Experts Infra Confirmes | 4 x 20h x 75 EUR/h | 6 000 EUR |
| **Sous-total Main d'oeuvre** | | **8 300 EUR** |
| | | |
| **SOUS-TOTAL** | | **119 392 EUR** |
| **Marge imprevus (15%)** | | **17 909 EUR** |
| | | |
| **TOTAL PROJET** | | **137 301 EUR** |

> **Budget respecte** : 137 301 EUR < 150 000 EUR -- Marge de **12 699 EUR** disponible

---

## Couts recurrents annuels (OPEX)

> Apres l'investissement initial, voici les couts a prevoir chaque annee

| Poste | Detail | Cout/an |
|---|---|---|
| Azure Site Recovery | 20 VMs x 23 EUR/mois (apres Reserved) | ~4 000 EUR |
| Connectivite Internet | Siege 2x1Gbps + 3 entrepots + backup 4G | ~12 840 EUR |
| Supervision | PRTG 500 sensors + Veeam Essentials | ~2 500 EUR |
| **TOTAL OPEX** | | **~19 340 EUR/an** |

> **A prevoir apres 3 ans** : Renouvellement des contrats de maintenance (FortiCare, ProSupport Dell, SmartNet Cisco) -- estime ~15 000 EUR/3 ans

> **Resume financier**
> - **CAPEX (investissement initial)** : ~137 000 EUR
> - **OPEX (cout annuel)** : ~19 340 EUR/an
> - **TCO sur 3 ans** : 137 000 + (19 340 x 2) = **~175 680 EUR**
> *(La 1ere annee d'OPEX est incluse dans le CAPEX)*

---

## Configuration recommandee

> 2 serveurs on-premise + replication Azure (PRA cloud)

| Poste | Choix | Qte | Prix unitaire | Total |
|---|---|---|---|---|
| Pare-feu siege | FortiGate 100F | 1 | 2 800 EUR | 2 800 EUR |
| Pare-feu entrepots | FortiGate 60F | 3 | 440 EUR | 1 320 EUR |
| Pare-feu backup | FortiGate 40F | 1 | 400 EUR | 400 EUR |
| Serveurs | Dell R650xs | 2 | 13 000 EUR | 26 000 EUR |
| Stockage SAN | PowerVault ME5012 | 1 | 17 500 EUR | 17 500 EUR |
| Switchs | Cisco C9200-24P | 4 | 2 500 EUR | 10 000 EUR |
| PRA Cloud | Azure Site Recovery | 20 VMs | 23 EUR/mois | ~11 000 EUR/3ans |
| Supervision | PRTG + Veeam | 3 ans | 2 500 EUR/an | 7 500 EUR |
| **Sous-total hardware** | | | | **76 520 EUR** |
| Licences & maintenance 3 ans | | | | ~21 500 EUR |
| Internet 1ere annee | | | | 12 840 EUR |
| Main d'oeuvre | | | | 8 300 EUR |
| **Sous-total** | | | | **119 160 EUR** |
| Marge imprevus (15%) | | | | 17 874 EUR |
| **TOTAL** | | | | **137 034 EUR** |

> **Legende des prix**
> - **Prix Hardware** : Materiel seul (prix constates en ligne janvier 2026)
> - **Prix + Licences** : Inclut FortiCare/FortiGuard, ProSupport Dell, maintenance Cisco, abonnements logiciels sur 3 ans

---

## Justifications

| Choix | Raison |
|---|---|
| FortiGate | Interface connue, support FR, prix PME |
| Dell R650xs | Performance pour 20+ VMs, evolutif |
| SAN iSCSI | Separation compute/stockage |
| Cisco switchs | QoS native VoIP, support enterprise |
| Azure Reserved | Economies 3 ans pour PRA |
| Veeam | Backup eprouve, interface simple |

---

## Estimation Main d'oeuvre (Equipe projet)

> Chiffrage pour 5 experts infrastructure sur 20h de travail

### Tarifs journaliers moyens en France (2025-2026)

| Niveau | TJM (EUR/jour) | Taux horaire | 20h = |
|---|---|---|---|
| Expert Infra Junior (3-5 ans) | 400-500 EUR | ~55 EUR/h | 1 100 EUR |
| Expert Infra Confirme (5-8 ans) | 500-650 EUR | ~75 EUR/h | 1 500 EUR |
| Expert Infra Senior (8+ ans) | 650-850 EUR | ~95 EUR/h | 1 900 EUR |
| Architecte Infra | 800-1000 EUR | ~115 EUR/h | 2 300 EUR |

### Estimation recommandee

| Role | Nb | TJM | 20h | Total |
|---|---|---|---|---|
| Architecte/Lead | 1 | 800 EUR | 2 300 EUR | 2 300 EUR |
| Expert Infra Confirme | 4 | 550 EUR | 1 570 EUR | 6 280 EUR |
| **TOTAL** | **5** | - | - | **~8 600 EUR** |

> **Resume** : 5 experts infra x 20h = **entre 5 500 EUR et 9 500 EUR**
> Estimation realiste : **~8 000 EUR** (charges comprises en freelance)
> Ce montant represente environ **5-8%** du budget total du projet.

---

## Cette configuration

- Supprime tous les SPOF
- Reste exploitable par 4 personnes
- S'inscrit dans le budget
- Permet la croissance
- Prepare le PRA cloud
