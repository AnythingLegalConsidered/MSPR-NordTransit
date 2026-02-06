---
title: "Tests de validation POC"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Tous les guides 00 a 06 completes"
  - "Toutes les VMs operationnelles"
---

# Tests de validation POC

## Objectif

> Executer les 4 tests POC qui prouvent que l'architecture cible fonctionne.
> Chaque test a un critere de succes mesurable. Documenter les resultats avec captures d'ecran.

## Prerequis

- [x] 7 VMs operationnelles
- [x] pfSense siege + Azure configures
- [x] AD deploye (DC01 + DC02 + DC-AZURE)
- [x] FreePBX + QoS configures
- [x] WMS + MySQL deployes

## Etapes

### Test 1 : QoS VoIP

**Pourquoi** : Prouver que la voix reste claire meme quand le reseau est sature.

**Protocole execute :**
1. Verification des queues QoS actives sur pfSense :
   ```bash
   pfctl -s queue
   # queue qVoIP on vtnet0 priority 7
   # queue qServers on vtnet0 priority 5
   # queue qDefault on vtnet0 priq( default )
   ```
2. Saturation du reseau LAN avec iperf3 (500 Mbits/sec entre WMS et pve02) :
   ```bash
   # Serveur sur pve02
   iperf3 -s -B 172.16.132.254 -p 5201
   # Client sur WMS
   iperf3 -c 172.16.132.254 -p 5201 -t 20 -b 500M
   # Resultat : 1.16 GBytes transferes, 500 Mbits/sec, 0 retransmissions
   ```
3. Pendant la saturation, mesure de latence vers IPBX :
   ```bash
   ping -c 100 -i 0.1 172.16.132.30
   # 100 packets transmitted, 100 received, 0% packet loss
   # rtt min/avg/max/mdev = 0.061/0.102/0.299/0.038 ms
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat | Statut |
|----------|-------|----------|--------|
| Latence | < 150 ms | **0.102 ms** (avg) | PASS |
| Gigue | < 30 ms | **0.038 ms** (mdev) | PASS |
| Perte paquets | < 1% | **0%** (100/100) | PASS |

**Stats queues QoS pendant charge :**
```
queue qVoIP    on vtnet0 priority 7  [ pkts: 1  bytes: 90  dropped: 0 ]
queue qServers on vtnet0 priority 5  [ pkts: 1  bytes: 90  dropped: 0 ]
queue qDefault on vtnet0 priq(default) [ pkts: 160  bytes: 23403  dropped: 0 ]
```

---

### Test 2 : Failover AD

**Pourquoi** : Prouver que DC02 prend le relais quand DC01 est indisponible.

**Protocole execute :**
1. Verification initiale — 3 DCs actifs :
   ```powershell
   Get-ADDomainController -Filter *
   # DC01 (172.16.132.10) - GC
   # DC02 (172.16.132.11) - GC
   # DC-AZURE (10.100.0.10) - GC
   ```
2. Replication initiale OK :
   ```
   repadmin /replsummary → 0 failures pour DC01, DC02, DC-AZURE
   ```
3. Arret brutal de DC01 (`qm stop 32010` sur Proxmox)
4. Apres 30 secondes, test DNS via DC02 :
   ```bash
   dig @172.16.132.11 lab.local +short
   # 172.16.132.11, 172.16.132.10, 10.100.0.10  → OK
   dig @172.16.132.11 dc-azure.lab.local +short
   # 10.100.0.10  → OK
   ```
5. Test authentification depuis DC02 :
   ```powershell
   nltest /dsgetdc:lab.local
   # DC: \\DC02.lab.local  Address: \\172.16.132.11
   # Flags: GC DS LDAP KDC TIMESERV WRITABLE DNS_DC DNS_DOMAIN DNS_FOREST
   ```
6. DC01 rallume (`qm start 32010`)

**Criteres de succes :**

| Metrique | Seuil | Resultat | Statut |
|----------|-------|----------|--------|
| Bascule | < 15 min | **Immediate** (DC02 repond en < 30s) | PASS |
| Auth OK sur DC02 | Oui | **Oui** (nltest → DC02.lab.local) | PASS |
| DNS fonctionne | Oui | **Oui** (dig @DC02 resout tout) | PASS |

---

### Test 3 : Failover WMS

**Pourquoi** : Prouver que le WMS (VM + BDD) survit a un arret brutal.

**Protocole execute :**
1. Verification etat initial :
   ```
   === WMS Health Check ===
   Date: Fri Feb  6 21:10:13 UTC 2026
   [OK] MySQL service running
   [OK] Database OK - 5 records found
   [OK] iperf3 installed
   id  product_name       quantity  warehouse          last_updated
   1   Colis Standard A   150       WH1-Lens           2026-02-06 19:34:57
   2   Colis Standard B   230       WH2-Valenciennes   2026-02-06 19:34:57
   3   Palette Export     45        WH3-Arras          2026-02-06 19:34:57
   4   Colis Express      89        Siege-Lille        2026-02-06 19:34:57
   5   Palette Vrac       12        CrossDock          2026-02-06 19:34:57
   ```
2. Arret brutal (`qm stop 32020` — simule coupure de courant)
3. Redemarrage (`qm start 32020`)
4. VM accessible en SSH apres ~20 secondes
5. Verification apres reboot :
   ```
   === WMS Health Check ===
   Date: Fri Feb  6 21:10:58 UTC 2026
   [OK] MySQL service running
   [OK] Database OK - 5 records found
   [OK] iperf3 installed
   → Donnees identiques (memes 5 records, memes timestamps)
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat | Statut |
|----------|-------|----------|--------|
| VM redemarre | Oui | **Oui** (~20s) | PASS |
| MySQL actif | Oui | **Oui** (service running) | PASS |
| Donnees intactes | 5 records | **5 records** (identiques) | PASS |

---

### Test 4 : Tunnel Azure

**Pourquoi** : Prouver que le siege communique avec Azure via le lien inter-sites.

> **Note lab** : Dans le lab, la communication inter-sites utilise des routes statiques
> a travers pfSense (vmbr2 = bridge partage). En production, ce sera un tunnel IPsec
> IKEv2 (cf. `docs/04-livrables/configs/vpn-ipsec.md`).

**Protocole execute :**
1. Ping cross-site depuis DC01 (siege → Azure) :
   ```
   ping 10.100.0.10
   Reply from 10.100.0.10: bytes=32 time<1ms TTL=127  (4/4, 0% loss)
   ```
2. Ping cross-site depuis DC-AZURE (Azure → siege) :
   ```
   ping 172.16.132.10
   Reply from 172.16.132.10: bytes=32 time<1ms TTL=127  (4/4, 0% loss)
   ```
3. DNS cross-site :
   ```
   nslookup dc-azure.lab.local
   Name:    dc-azure.lab.local
   Address:  10.100.0.10  → OK
   ```
4. Replication AD cross-site :
   ```
   repadmin /syncall /APed (depuis DC-AZURE)
   → SyncAll terminated with no errors.
   → 5 partitions repliquees (lab.local, Configuration, Schema,
     DomainDnsZones, ForestDnsZones)
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat | Statut |
|----------|-------|----------|--------|
| Lien inter-sites UP | Actif | **Routes statiques OK** | PASS |
| Ping cross-site | OK | **OK** (< 1ms, bidirectionnel) | PASS |
| DNS cross-site | OK | **OK** (dc-azure → 10.100.0.10) | PASS |
| Replication AD | 0 failures | **0 failures** (syncall OK) | PASS |

---

## Consolidation des resultats

### Synthese

| Test | Statut | Details |
|------|--------|---------|
| QoS VoIP | **PASS** | Latence 0.1ms, gigue 0.04ms, 0% perte sous 500Mbps de charge |
| Failover AD | **PASS** | Bascule immediate sur DC02, DNS+Auth OK |
| Failover WMS | **PASS** | VM reboot 20s, MySQL OK, 5/5 records intacts |
| Tunnel Azure | **PASS** | Ping+DNS+Replication OK cross-site |

### Preuves collectees

- [x] Resultats ping 100 paquets vers IPBX sous charge (Test 1)
- [x] Stats queues QoS pfSense — pfctl -vsq (Test 1)
- [x] Resultats iperf3 — 500 Mbits/sec, 0 retransmissions (Test 1)
- [x] nltest /dsgetdc:lab.local → DC02 repond (Test 2)
- [x] dig @DC02 lab.local → DNS OK (Test 2)
- [x] check_wms.sh avant/apres arret brutal (Test 3)
- [x] Ping bidirectionnel cross-site (Test 4)
- [x] nslookup dc-azure.lab.local (Test 4)
- [x] repadmin /syncall OK sur 5 partitions (Test 4)

Ces preuves alimentent les livrables finaux (phase 04).

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/06-wms-simulation.md`
- Guide suivant : `docs/04-livrables/architecture-technique.md`
