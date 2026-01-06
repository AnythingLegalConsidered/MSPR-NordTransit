# POC 1 - QoS VoIP

> Prouver que la voix est prioritaire

---

## Objectif

Démontrer que la configuration QoS garantit la qualité des appels VoIP même en cas de charge réseau.

---

## Critères de succès

| Métrique | Seuil acceptable |
| --- | --- |
| Latence | < 150 ms |
| Gigue | < 30 ms |
| Perte paquets | < 1% |

---

## Configuration QoS

### Marquage DSCP

| Type de trafic | DSCP | Valeur |
| --- | --- | --- |
| Voix (RTP) | EF | 46 |
| Signalisation (SIP) | AF31 | 26 |
| Vidéo | AF41 | 34 |
| Données | BE | 0 |

### Règles pfSense
1. Créer file prioritaire pour VLAN VoIP
2. Limiter bande passante DATA à 70%
3. Réserver 30% pour VoIP

---

## Procédure de test

### Étape 1 : Setup
- Démarrer IPBX (FreePBX)
- Configurer 2 softphones
- Vérifier appel sans charge

### Étape 2 : Générer charge
- Lancer iperf3 entre 2 VMs
- Saturer le lien à 100%

### Étape 3 : Mesurer
- Appel VoIP pendant la charge
- Capturer avec Wireshark
- Mesurer latence/gigue/perte

---

## Résultats

| Test | Sans QoS | Avec QoS | Statut |
| --- | --- | --- | --- |
| Latence | ??? ms | ??? ms | ⬜ |
| Gigue | ??? ms | ??? ms | ⬜ |
| Perte | ??? % | ??? % | ⬜ |

---

## Captures d'écran

*À ajouter pendant les tests*
