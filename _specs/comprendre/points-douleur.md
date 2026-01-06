# Points de douleur

> Tous les problèmes identifiés qui justifient la modernisation

---

## Points uniques de défaillance (SPOF)

> **Ces éléments peuvent provoquer un arrêt total de l'activité**

| SPOF | Impact | Criticité |
| --- | --- | --- |
| Hyperviseur unique (R630) | Arrêt toutes les VMs | Critique |
| NAS unique | Perte données/VMs | Critique |
| WMS (App + DB) | Arrêt des 4 sites | Critique |
| IPBX unique | Plus de téléphonie | Critique |

---

## Risques sécurité

| Risque | Description | Gravité |
| --- | --- | --- |
| Pare-feu hétérogènes | FortiGate (siège) + DrayTek (sites) | Moyenne |
| Pas de gestion centralisée | Configuration manuelle site par site | Moyenne |
| **MFA limité** | Uniquement activé pour l'équipe IT | Critique |
| Sauvegardes non testées | Pas de test de restauration | Critique |
| Pas d'externalisation backup | Risque ransomware/sinistre | Critique |

---

## Problèmes opérationnels

| Problème | Conséquence |
| --- | --- |
| Supervision technique uniquement | Pas de vision "service" |
| Documentation dispersée | Difficulté de maintenance |
| Fenêtres maintenance courtes | Interventions nocturnes obligatoires |
| QoS/VLAN non documentés | Impossible de garantir qualité VoIP |
| FortiGate EOL proche | Plus de mises à jour sécurité |

---

## Problèmes VoIP spécifiques

| Problème | Impact |
| --- | --- |
| QoS non configurée | Qualité d'appel dégradée en cas de charge |
| IPBX unique | Pas de redondance téléphonie |
| Pas de priorisation | La voix en concurrence avec les données |

---

## Limitations connectivité

| Problème | Impact | Criticité |
| --- | --- | --- |
| Bande passante limitée (200 Mbps) | Congestion possible avec VPN + VoIP + services cloud simultanés | Moyenne |

---

## Contraintes opérationnelles

> **Horaires d'activité : 5h30 - 18h30**
> Toute intervention doit se faire APRÈS 18h30

| Amplitude | Horaire | Activité |
| --- | --- | --- |
| Matin | 5h30 - 12h | Arrivages et réceptions |
| Après-midi | 12h - 18h30 | Préparations et expéditions |
| Weekend | Samedi matin | Possible en pic d'activité |
| **Maintenance** | **Après 18h30** | **Seule fenêtre sûre** |
