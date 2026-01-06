# Budget détaillé

> Chiffrage complet de la modernisation

**Budget total alloué** : 100 000€ - 150 000€

---

## Répartition budgétaire

| Poste | Budget min | Budget max | % |
| --- | --- | --- | --- |
| Sécurité (Pare-feu, VPN) | 25 000 € | 35 000 € | 25% |
| Virtualisation (Serveurs) | 35 000 € | 50 000 € | 35% |
| Stockage | 15 000 € | 25 000 € | 17% |
| Réseau (Switchs) | 10 000 € | 15 000 € | 10% |
| Cloud Azure (1 an) | 8 000 € | 12 000 € | 8% |
| Supervision & Licences | 5 000 € | 8 000 € | 5% |

---

## Configuration recommandée

| Poste | Choix | Prix Hardware | Prix + Licences 3 ans |
| --- | --- | --- | --- |
| Pare-feu | FortiGate (100F + 60F ×3 + 40F) | 4 520 € | ~18 000 € |
| Serveurs | Dell R650xs × 3 | 39 000 € | ~45 000 € |
| Stockage | SAN PowerVault ME5 | 17 500 € | ~20 000 € |
| Switchs | Cisco C9200 (×4) | 10 000 € | ~12 000 € |
| Azure 3 ans | Reserved | - | 10 000 € |
| Supervision | PRTG + Veeam (3 ans) | - | ~5 000 € |
| **Sous-total** | | **71 020 €** | **110 000 €** |
| Marge imprévus (15%) | | 10 653 € | 16 500 € |
| **TOTAL** | | **81 673 €** | **126 500 €** |

> **Légende des prix**
> - **Prix Hardware** : Matériel seul (prix constatés en ligne janvier 2026)
> - **Prix + Licences** : Inclut FortiCare/FortiGuard, ProSupport Dell, maintenance Cisco, abonnements logiciels sur 3 ans

---

## Justifications

| Choix | Raison |
| --- | --- |
| FortiGate | Interface connue, support FR, prix PME |
| Dell R650xs | Performance pour 20+ VMs, évolutif |
| SAN iSCSI | Séparation compute/stockage |
| Cisco switchs | QoS native VoIP, support enterprise |
| Azure Reserved | Économies 3 ans pour PRA |
| Veeam | Backup éprouvé, interface simple |

---

## Amélioration connectivité

### Option A : Upgrade fibre uniquement

| Site | Débit actuel | Débit cible | Coût annuel |
| --- | --- | --- | --- |
| Siège Lille | 200 Mbps | 1 Gbps | +600-960 € |
| Entrepôt 1 | 200 Mbps | 500 Mbps | +360-600 € |
| Entrepôt 2 | 200 Mbps | 500 Mbps | +360-600 € |
| Entrepôt 3 | 200 Mbps | 500 Mbps | +360-600 € |
| **Total Option A** | | | **1 680 - 2 760 €/an** |

### Option B : Fibre + Backup 4G/5G

| Site | Upgrade fibre | Routeur 4G/5G | Total annuel |
| --- | --- | --- | --- |
| Siège Lille | +80 €/mois | ~300-500 € | ~2 060 € |
| Entrepôts (×3) | +50 €/mois | ~300-500 € | ~1 700 € chacun |
| **Total Option B** | | **1 200-2 000 €** (one-time) | **~7 160 €/an** |

### Comparatif

| Option | Investissement initial | Coût récurrent/an | Redondance |
| --- | --- | --- | --- |
| A - Fibre seule | 0 € | ~2 200 € | Non |
| B - Fibre + 4G/5G | ~1 600 € | ~7 200 € | Oui |

> **Recommandation** : Option B pour le siège (criticité WMS) + Option A pour les entrepôts
> → Budget estimé : ~1 600 € (init) + ~4 500 €/an

---

## Cette configuration

- Supprime tous les SPOF
- Reste exploitable par 4 personnes
- S'inscrit dans le budget
- Permet la croissance
- Prépare le PRA cloud
