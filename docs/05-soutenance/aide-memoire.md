---
title: "Aide-memoire Soutenance"
subtitle: "MSPR - NordTransit Logistics"
date: 2026-02-18
---

# Aide-memoire Soutenance — 23/02

> A imprimer ou garder sous la main. Chaque section pointe vers le document detaille.

---

## Chiffres cles

| Quoi | Valeur | Detail dans |
|------|--------|-------------|
| Employes | 240 (300 haute saison) | `docs/01-analyse/01-contexte-client.md` |
| Sites | 4 entrepots + 1 cross-dock | `docs/01-analyse/01-contexte-client.md` |
| Postes | 65 PC, 70 telephones IP, ~20 VMs | `docs/04-livrables/architecture-technique.md` §2.1 |
| DSI | 4 personnes | `docs/01-analyse/01-contexte-client.md` |
| Budget | **137 301 EUR** / 150k max | `docs/04-livrables/architecture-technique.md` §4 |
| Marge | 12 699 EUR (+ 17 909 imprevus) | `docs/04-livrables/architecture-technique.md` §4.2 |
| OPEX/an | ~19 340 EUR | `docs/04-livrables/architecture-technique.md` §4.3 |
| TCO 3 ans | ~175 680 EUR | `docs/04-livrables/architecture-technique.md` §4.4 |
| Migration | 6 phases, 6 semaines | `docs/04-livrables/strategie-migration.md` |
| POC | 7 VMs, 4 tests, **4/4 PASS** | `docs/03-lab-poc/07-tests-validation.md` |

---

## Budget express

| Poste | Montant |
|-------|---------|
| Securite (5x FortiGate + 3 ans) | 17 520 |
| Virtualisation (2x R650xs) | 30 000 |
| Stockage (SAN ME5012) | 20 000 |
| Reseau (4x Cisco C9200) | 12 000 |
| Azure PRA (3 ans Reserved) | 11 232 |
| Supervision (PRTG + Veeam) | 7 500 |
| Internet (1ere annee) | 12 840 |
| Main d'oeuvre | 8 300 |
| Imprevus 15% | 17 909 |
| **TOTAL** | **137 301 EUR** |

> Detail complet : `docs/04-livrables/architecture-technique.md` §4.1

---

## RTO/RPO

| Service | RTO | RPO | Comment |
|---------|-----|-----|---------|
| AD | < 15 min | 0 | DC replique Azure, temps reel |
| WMS | < 1h | < 15 min | Azure Site Recovery |
| VoIP | < 30 min | N/A | Redemarrage VM noeud sain |

> Detail : `docs/04-livrables/architecture-technique.md` §3.6.2

---

## Resultats POC

| Test | Resultat cle | Seuil ITU-T |
|------|-------------|-------------|
| QoS VoIP | 0.1ms / 0.04ms / 0% perte | < 150ms / < 30ms / < 1% |
| Failover AD | Bascule < 30s | < 15 min |
| Failover WMS | Reboot 20s, 5/5 records | < 1h |
| Tunnel Azure | Ping + DNS + Replication OK | Fonctionnel |

> Detail : `docs/03-lab-poc/07-tests-validation.md`

---

## Reponses aux pieges

**"Routes statiques ≠ vrai IPsec"** → Valide la connectivite, config IPsec prete dans `docs/04-livrables/configs/vpn-ipsec.md`

**"0.1ms c'est du LAN"** → Oui, en prod 6-18ms avec IPsec, toujours << 150ms

**"5 records c'est rien"** → Valide le mecanisme crash+integrite, load testing = moyen terme

**"pfSense ≠ FortiGate"** → POC valide concepts, pas produits. Memes fonctions testees

**"Siege brule ?"** → DC-Azure maintient AD, Site Recovery bascule VMs, Veeam sur Blob

**"Split-brain cluster ?"** → Cloud Witness Azure = 3eme vote

**"Point le plus faible ?"** → IPBX centralise, pas de survivability entrepot

**"Si 300k ?"** → Cluster 3 noeuds, 100F partout, WAN redondant, PRA multi-region, SIEM

> 100 questions completes : `docs/05-soutenance/questions-jury.md`

---

## Commandes demo (copier-coller)

```bash
# QoS — Terminal 1 : serveur iperf3
iperf3 -s -B 172.16.132.254 -p 5201

# QoS — Terminal 2 : saturation 500M
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M"

# QoS — Terminal 3 : ping IPBX pendant charge
ssh wmsadmin@172.16.132.20 "ping -c 50 -i 0.2 172.16.132.30"

# Failover AD — couper DC01
qm stop 32010
# Attendre 30s puis tester
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"

# Remettre DC01
qm start 32010
```

> Script demo complet : `docs/05-soutenance/plan-presentation.md` §Partie 3

---

## Liens rapides vers les livrables

| Document | Chemin |
|----------|--------|
| Architecture technique (DAT) | `docs/04-livrables/architecture-technique.md` |
| Strategie migration | `docs/04-livrables/strategie-migration.md` |
| Config pare-feu | `docs/04-livrables/configs/pare-feu.md` |
| Config VPN IPsec | `docs/04-livrables/configs/vpn-ipsec.md` |
| Note WMS | `docs/04-livrables/note-recommandation-wms.md` |
| Guide depannage ToIP | `docs/04-livrables/guide-depannage-toip.md` |
| Plan presentation | `docs/05-soutenance/plan-presentation.md` |
| 100 questions jury | `docs/05-soutenance/questions-jury.md` |
| Tests POC | `docs/03-lab-poc/07-tests-validation.md` |
