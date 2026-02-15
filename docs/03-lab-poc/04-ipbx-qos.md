---
title: "FreePBX et QoS VoIP"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 03-active-directory.md complete"
  - "VM IPBX (32030) installee avec FreePBX"
  - "pfSense siege operationnel"
---

# FreePBX et QoS VoIP

## Objectif

> Installer FreePBX pour simuler la telephonie VoIP, puis configurer la QoS sur pfSense
> pour garantir que la voix est prioritaire meme sous charge reseau.
> Critere de succes : latence < 150ms, gigue < 30ms, perte < 1%.

## Prerequis

- [ ] VM IPBX (32030) creee et FreePBX installe
- [ ] pfSense siege accessible
- [ ] DC01 operationnel (DNS)

## Etapes

### 1. Installer FreePBX

**Pourquoi** : FreePBX simule l'IPBX de NordTransit. C'est la reference open-source pour PBX.

> **Prerequis** : La VM IPBX (32030) doit etre creee et l'OS SangomaOS installe
> (voir guide 01, etape 2d). L'IP statique doit etre configuree (guide 01, etape 3c).

L'installation SangomaOS est automatique (guide 01). Apres le reboot :

1. Se connecter en SSH : `ssh root@172.16.132.30` (mot de passe : `SangomaDefaultPassword`)
2. Verifier le reseau : `ip a` → doit afficher 172.16.132.30 sur eth0
3. Acceder a l'interface web : `http://172.16.132.30`
4. A la premiere connexion web, FreePBX demande de creer un compte admin :
   - Username : `admin`
   - Password : `admin` (lab uniquement)
5. Cliquer **Setup System** → selectionner la langue → **Submit**

### 2. Configurer les extensions SIP

**Pourquoi** : Des extensions SIP permettent de simuler des appels et tester la QoS.

Dans FreePBX → Applications → Extensions :
- Creer Extension 1001 (poste 1)
- Creer Extension 1002 (poste 2)
- Protocole : SIP (PJSIP)
- Mot de passe : generer automatiquement

### 3. Configurer la QoS sur pfSense

**Pourquoi** : Sans QoS, le trafic VoIP est traite comme du trafic web — sous charge, la voix se degrade.

Sur pfSense → Firewall → Traffic Shaper :

**Methode : PRIQ (Priority Queuing)**

1. Creer les queues sur l'interface LAN :
   - **qVoIP** : Priority 7, Bandwidth 30%
   - **qServers** : Priority 5, Bandwidth 40%
   - **qDefault** : Priority 1, Bandwidth 30% (best effort)

2. Creer les regles de classification :
   - Source 172.16.132.30 (IPBX) → qVoIP
   - DSCP EF (46) → qVoIP
   - Port 5060 (SIP) + 10000-20000 (RTP) → qVoIP

### 4. Generer du trafic de test

**Pourquoi** : Il faut saturer le reseau pour prouver que la QoS protege la VoIP.

Depuis le WMS :
```bash
# Installer iperf3 si pas encore fait
sudo apt install iperf3 -y

# Generer du trafic "lourd" (simuler charge reseau)
# Cote serveur (sur le host Proxmox ou une autre VM) : iperf3 -s
iperf3 -c 172.16.132.1 -t 60 -b 100M
```

> **Note** : iperf3 doit aussi etre installe cote serveur. Si vous utilisez le host Proxmox :
> `apt install iperf3 -y && iperf3 -s`

Pendant ce temps, passer un appel SIP entre les extensions 1001 et 1002.

### 5. Mesurer la qualite VoIP

**Pourquoi** : Prouver que les criteres sont respectes.

```bash
# Depuis pfSense (SSH)
pfctl -s queue    # Voir les stats des queues QoS
```

Mesurer avec un softphone ou `ping` :
```bash
# Latence vers IPBX pendant la charge
ping -c 100 172.16.132.30
```

## Verification

| Test | Methode | Critere de succes |
|------|---------|-------------------|
| QoS VoIP | Appel pendant charge iperf3 | Latence < 150ms |
| Gigue | Mesure ping | Gigue < 30ms |
| Perte paquets | Mesure ping 100 paquets | Perte < 1% |
| Queues actives | `pfctl -s queue` | qVoIP avec trafic |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| FreePBX web inaccessible | Service httpd down | `systemctl restart httpd` |
| Pas d'audio dans l'appel | Ports RTP bloques | Ouvrir 10000-20000 UDP sur pfSense |
| QoS sans effet | Mauvaise interface | Verifier que les queues sont sur LAN, pas WAN |
| Latence elevee malgre QoS | Queue mal configuree | Verifier priorite qVoIP = 7 |

## Liens

- Spec de reference : `_specs/poc/poc1-qos-voip.md`
- Guide precedent : `docs/03-lab-poc/03-active-directory.md`
- Guide suivant : `docs/03-lab-poc/05-azure-tunnel.md`
