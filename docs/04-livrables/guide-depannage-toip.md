---
title: "Guide de Depannage ToIP - Niveaux N1 et N2"
subtitle: "MSPR - NordTransit Logistics"
author: "Equipe NordTransit"
date: 2026-02-XX
version: "1.0"
toc: true
---

# Guide de Depannage ToIP - N1/N2

## Informations document

| Champ | Valeur |
|-------|--------|
| Projet | MSPR - NordTransit Logistics |
| Version | 1.0 |
| Date | 2026-02-XX |
| Auteurs | Equipe NordTransit (5 personnes) |
| Statut | En cours |

---

## 1. Introduction

### 1.1 Objectif

Ce guide permet au support N1 (technicien sur site) et N2 (administrateur reseau) de diagnostiquer
et resoudre les problemes de telephonie VoIP chez NordTransit.

### 1.2 Architecture VoIP

| Composant | Detail |
|-----------|--------|
| IPBX | FreePBX (siege Lille) — IP : 172.16.132.30 |
| Protocole | SIP (PJSIP) |
| Telephones | Cisco IP (~70 postes sur 4 sites) |
| QoS | DSCP EF (46) via FortiGate, priorite 7 |
| VLAN | VLAN 40 dedie VoIP sur chaque site |
| Ports | SIP : 5060/UDP, RTP : 10000-20000/UDP |

### 1.3 Seuils de qualite

| Metrique | Seuil acceptable | Seuil critique |
|----------|-------------------|----------------|
| Latence | < 150 ms | > 300 ms |
| Gigue (jitter) | < 30 ms | > 50 ms |
| Perte de paquets | < 1% | > 3% |

---

## 2. Depannage N1 (Technicien sur site)

### 2.1 Pas de tonalite

| Etape | Action | Resultat attendu | Si KO |
|-------|--------|-------------------|-------|
| 1 | Verifier le cable reseau du telephone | LED reseau allumee | Remplacer le cable |
| 2 | Verifier l'alimentation PoE du switch | Port actif, LED ON | Tester sur un autre port |
| 3 | Redemarrer le telephone (debrancher 10s) | Boot normal | Escalade N2 |
| 4 | Verifier l'IP du telephone (Settings > Network) | IP dans 192.168.x.192/26 (VLAN 40) | Escalade N2 — probleme DHCP/VLAN |

### 2.2 Audio coupe / saccade

| Etape | Action | Resultat attendu | Si KO |
|-------|--------|-------------------|-------|
| 1 | Verifier si le probleme touche un seul poste ou tout le site | Identifier le perimetre | |
| 2 | Tester un appel depuis un autre poste | Audio correct | Probleme isole au poste → remplacer |
| 3 | Verifier la charge reseau (beaucoup de transferts en cours ?) | Charge normale | Attendre ou escalade N2 (QoS) |
| 4 | Verifier que le telephone est bien sur VLAN 40 | VLAN correct | Reconfigurer le port switch |

### 2.3 Appel ne sonne pas

| Etape | Action | Resultat attendu | Si KO |
|-------|--------|-------------------|-------|
| 1 | Verifier le numero compose (bon format ?) | Numero correct | Corriger le numero |
| 2 | Tester un appel interne (meme site) | Sonnerie OK | Escalade N2 — probleme SIP |
| 3 | Tester un appel inter-site (via VPN) | Sonnerie OK | Escalade N2 — VPN ou firewall |
| 4 | Verifier le renvoi d'appel (desactive ?) | Pas de renvoi actif | Desactiver le renvoi |

### 2.4 Echo ou bruit de fond

| Etape | Action | Resultat attendu | Si KO |
|-------|--------|-------------------|-------|
| 1 | Baisser le volume du haut-parleur | Echo reduit | |
| 2 | Tester avec le combine (pas le haut-parleur) | Audio propre | Defaut telephone |
| 3 | Tester avec un casque | Audio propre | Remplacer le telephone |

---

## 3. Depannage N2 (Administrateur)

### 3.1 Commandes de diagnostic

**Sur pfSense (SSH ou console) :**
```bash
# Verifier les queues QoS — le trafic VoIP doit etre dans qVoIP
pfctl -s queue

# Verifier les regles de firewall actives
pfctl -s rules

# Voir les etats NAT (sessions SIP actives)
pfctl -s state | grep 5060
```

**Sur FreePBX (SSH) :**
```bash
# Verifier les endpoints SIP enregistres
asterisk -rx "pjsip show endpoints"

# Verifier l'etat d'un endpoint specifique
asterisk -rx "pjsip show endpoint 1001"

# Voir les canaux actifs (appels en cours)
asterisk -rx "core show channels"

# Logs en temps reel (niveau verbose)
asterisk -rvvv

# Recharger la config SIP sans redemarrage
asterisk -rx "pjsip reload"
```

**Tests reseau :**
```bash
# Latence vers IPBX (depuis n'importe quel poste Linux)
ping -c 100 172.16.132.30

# Test de bande passante (depuis WMS — iperf3 installe)
iperf3 -c 172.16.132.30 -u -b 1M -t 30    # UDP pour simuler VoIP

# Trace route pour identifier les sauts
traceroute 172.16.132.30
```

### 3.2 Problemes FreePBX courants

| Probleme | Diagnostic | Solution |
|----------|-----------|----------|
| Endpoint "Unavailable" | `pjsip show endpoints` → etat Unavailable | Verifier IP du telephone, port 5060 ouvert, re-provisionner |
| Appels inter-sites echouent | `pfctl -s state \| grep 5060` → pas de session | Verifier VPN UP + regles firewall SIP/RTP sur les 2 sites |
| Audio unidirectionnel | Probleme NAT sur les flux RTP | Verifier que les ports 10000-20000/UDP sont ouverts dans les 2 sens |
| FreePBX web inaccessible | `systemctl status httpd` → inactive | `systemctl restart httpd` |
| Asterisk ne repond pas | `systemctl status asterisk` → inactive | `systemctl restart asterisk` puis verifier les logs `/var/log/asterisk/full` |

### 3.3 Problemes QoS

| Symptome | Diagnostic | Solution |
|----------|-----------|----------|
| Latence > 150ms sous charge | `pfctl -s queue` → qVoIP sans trafic | Verifier les regles de classification : source IPBX, DSCP EF, ports SIP/RTP |
| QoS sans effet visible | Queues creees mais pas de matching | Verifier que les regles sont sur l'interface **LAN**, pas WAN |
| Trafic VoIP dans qDefault | DSCP non marque | Verifier le marquage DSCP sur le FortiGate/pfSense : EF = 46 |
| Queue qVoIP saturee | Bandwidth trop faible | Augmenter la bande passante allouee a qVoIP (recommande : 30% minimum) |

### 3.4 Problemes VPN inter-sites (impact VoIP)

| Symptome | Diagnostic | Solution |
|----------|-----------|----------|
| Appels inter-sites impossibles | Tunnel VPN DOWN | Status > IPsec sur pfSense/FortiGate, reconnecter le tunnel |
| Audio coupe entre sites | MTU trop grand avec IPsec | Reduire le MTU a 1400 sur l'interface tunnel |
| Delai important inter-sites | Latence WAN | Verifier la bande passante WAN, activer la QoS sur le tunnel |

---

## 4. Arbre de decision

```
Probleme VoIP signale
│
├── Un seul poste ?
│   ├── Oui → N1 : Cable, PoE, reboot telephone
│   │         └── Si persiste → N2 : Verifier VLAN, endpoint SIP
│   │
│   └── Non (plusieurs postes / tout le site)
│       ├── Un seul site ?
│       │   ├── Oui → N2 : Switch, VLAN 40, DHCP, QoS locale
│       │   └── Non (multi-sites) → N2 : VPN tunnel, QoS WAN, FortiGate
│       │
│       └── Tous les sites ? → N2 : FreePBX (siege), Asterisk service, DNS
│
├── Type de probleme
│   ├── Pas de tonalite → N1 : Cable > PoE > Reboot > IP
│   ├── Audio degrade → N1 : Charge reseau > VLAN > Escalade N2 QoS
│   ├── Appel ne sonne pas → N1 : Numero > Interne > Inter-site > N2
│   └── Echo/bruit → N1 : Volume > Combine > Remplacer
│
└── Apres 30 min sans resolution → Escalade niveau suivant
```

---

## 5. Contacts escalade

| Niveau | Qui | Quand | Contact |
|--------|-----|-------|---------|
| N1 | Technicien sur site | Premiere intervention | Immediat |
| N2 | Admin reseau NordTransit | Probleme non resolu par N1, > 30 min | < 1h |
| N3 | Prestataire IPBX / editeur | Probleme applicatif FreePBX, bug logiciel | < 4h (contrat support) |
| Urgence | Responsable DSI | Impact total (IPBX DOWN, tous les sites) | Immediat |

---

## 6. Metriques de suivi

A configurer dans PRTG (moyen terme) :

| Sonde | Seuil alerte | Seuil critique |
|-------|-------------|----------------|
| Ping IPBX (172.16.132.30) | > 100 ms | > 300 ms ou timeout |
| Service Asterisk (port 5060) | Port ferme | Service DOWN |
| CPU FreePBX | > 80% | > 95% |
| Espace disque /var/log | > 80% | > 95% |
| Nombre d'appels simultanes | > 50 | > 70 (capacite max) |

---

## 7. Annexes

- Guide lab QoS : `docs/03-lab-poc/04-ipbx-qos.md`
- Configuration QoS pfSense : PRIQ, queues qVoIP (prio 7, 30%), qServers (prio 5, 40%), qDefault (prio 1, 30%)
- Ports a ouvrir : SIP 5060/UDP, RTP 10000-20000/UDP, ICMP
- VLAN 40 par site : Siege 192.168.10.192/26, WH1 192.168.20.160/27, WH2 192.168.30.160/27, WH3 192.168.40.160/27
