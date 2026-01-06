# POC 3 - Tunnel Azure

> Établir une connexion sécurisée vers le cloud

---

## Objectif

Démontrer la connectivité site-à-site entre l'infrastructure on-premise et Azure (ou simulation).

---

## Critères de succès

| Métrique | Seuil acceptable |
| --- | --- |
| Tunnel | UP et stable |
| Ping bidirectionnel | OK |
| Routing | Fonctionnel |

---

## Options de simulation

| Option | Avantage | Inconvénient |
| --- | --- | --- |
| Azure Free Trial | Réel, 200$ crédits | Carte bancaire requise |
| VM "Azure" sur Proxmox | Gratuit, simple | Simulation |

---

## Procédure de test (simulation)

### Étape 1 : Préparer "Azure"
- Créer VM DC-AZURE (VMID 32012)
- Réseau : 172.16.132.12
- Simuler subnet Azure : 10.100.0.0/24

### Étape 2 : Configurer VPN
- pfSense siège : créer tunnel IPsec
- Phase 1 : IKEv2, AES-256, SHA256
- Phase 2 : ESP, AES-256-GCM

### Étape 3 : Configurer côté "Azure"
- pfSense ou OpenVPN sur VM Azure
- Mêmes paramètres Phase 1/2

### Étape 4 : Tester
- Vérifier tunnel UP
- Ping depuis siège vers Azure
- Ping depuis Azure vers siège
- Tester résolution DNS

---

## Résultats

| Test | Résultat | Statut |
| --- | --- | --- |
| Tunnel UP | ??? | ⬜ |
| Ping Siège → Azure | ??? ms | ⬜ |
| Ping Azure → Siège | ??? ms | ⬜ |
| DNS cross-site | ??? | ⬜ |

---

## Captures d'écran

*À ajouter pendant les tests*
