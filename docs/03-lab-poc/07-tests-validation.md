---
title: "Tests de validation POC"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-XX-XX
prerequis:
  - "Tous les guides 00 a 06 completes"
  - "Toutes les VMs operationnelles"
---

# Tests de validation POC

## Objectif

> Executer les 4 tests POC qui prouvent que l'architecture cible fonctionne.
> Chaque test a un critere de succes mesurable. Documenter les resultats avec captures d'ecran.

## Prerequis

- [ ] 7 VMs operationnelles
- [ ] pfSense siege + Azure configures
- [ ] AD deploye (DC01 + DC02 + DC-AZURE)
- [ ] FreePBX + QoS configures
- [ ] WMS + MySQL deployes

## Etapes

### Test 1 : QoS VoIP

**Pourquoi** : Prouver que la voix reste claire meme quand le reseau est sature.

**Protocole :**
1. Lancer un appel SIP entre extensions 1001 et 1002
2. Saturer le reseau avec iperf3 :
   ```bash
   iperf3 -c 172.16.132.1 -t 120 -b 100M
   ```
3. Pendant la saturation, mesurer :
   ```bash
   ping -c 100 172.16.132.30    # Latence vers IPBX
   pfctl -s queue                # Stats QoS sur pfSense
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat |
|----------|-------|----------|
| Latence | < 150 ms | _a remplir_ |
| Gigue | < 30 ms | _a remplir_ |
| Perte paquets | < 1% | _a remplir_ |

**Capture requise** : Stats des queues QoS + resultats ping

---

### Test 2 : Failover AD

**Pourquoi** : Prouver que DC02 prend le relais quand DC01 est indisponible.

**Protocole :**
1. Depuis le WMS, verifier quel DC repond :
   ```powershell
   nltest /dsgetdc:lab.local
   ```
2. Eteindre DC01 (Proxmox → VM 32010 → Shutdown)
3. Attendre 2-3 minutes
4. Tester l'authentification :
   ```powershell
   nltest /dsgetdc:lab.local
   # Verifier que DC02 repond maintenant
   ```
5. Tester la resolution DNS :
   ```bash
   nslookup lab.local
   ```
6. Rallumer DC01

**Criteres de succes :**

| Metrique | Seuil | Resultat |
|----------|-------|----------|
| Bascule | < 15 min | _a remplir_ |
| Auth OK sur DC02 | Oui | _a remplir_ |
| DNS fonctionne | Oui | _a remplir_ |

**Capture requise** : nltest avant/apres, DC02 qui repond

---

### Test 3 : Failover WMS

**Pourquoi** : Prouver que le WMS (VM + BDD) survit a un arret brutal.

**Protocole :**
1. Verifier l'etat initial :
   ```bash
   /home/wmsadmin/check_wms.sh
   ```
2. Arreter brutalement la VM WMS (Proxmox → VM 32020 → Stop, pas Shutdown)
3. Redemarrer la VM
4. Verifier l'integrite :
   ```bash
   /home/wmsadmin/check_wms.sh
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat |
|----------|-------|----------|
| VM redemarre | Oui | _a remplir_ |
| MySQL actif | Oui | _a remplir_ |
| Donnees intactes | 5 records | _a remplir_ |

**Capture requise** : check_wms.sh avant et apres

---

### Test 4 : Tunnel Azure

**Pourquoi** : Prouver que le siege communique avec Azure via le VPN.

**Protocole :**
1. Verifier le tunnel sur pfSense :
   - Status → IPsec → "Established"
2. Tester la connectivite :
   ```powershell
   # Depuis DC01 (siege)
   ping 10.100.0.10              # DC-AZURE
   nslookup dc-azure.lab.local   # DNS cross-site
   ```
3. Tester la replication AD :
   ```powershell
   repadmin /replsummary
   ```

**Criteres de succes :**

| Metrique | Seuil | Resultat |
|----------|-------|----------|
| Tunnel UP | Established | _a remplir_ |
| Ping cross-site | OK | _a remplir_ |
| DNS cross-site | OK | _a remplir_ |
| Replication AD | 0 failures | _a remplir_ |

**Capture requise** : Status IPsec + ping + nslookup + repadmin

---

## Consolidation des preuves

A la fin des tests, rassembler :
- [ ] Captures d'ecran de chaque test (numerotees)
- [ ] Tableau de resultats rempli ci-dessus
- [ ] Export des logs pfSense si pertinent

Ces preuves alimenteront les livrables finaux (phase 04).

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/06-wms-simulation.md`
- Guide suivant : `docs/04-livrables/architecture-technique.md`
