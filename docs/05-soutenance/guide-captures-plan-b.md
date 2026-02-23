---
title: "Guide Captures — Plan B Demo"
date: 2026-02-21
---

# Guide Captures — Plan B Demo

> **Navigation soutenance** : [**Revision express**](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · **Plan B** · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

> Captures realisees le 22/02/2026, 4/4 PASS.
> Fichier : `images/captures-poc-2026-02-22.txt`

## Captures disponibles

Les 4 tests ont ete executes et captures le 22/02. Le fichier texte contient les sorties completes :

| Test | Resultat capture |
|------|-----------------|
| QoS VoIP | Latence 0.163ms, 0% perte, queues qVoIP priority 7 |
| Failover AD | DC02 prend le relais, DNS OK sans DC01 |
| Failover WMS | 5/5 records identiques apres crash |
| Tunnel Azure | Ping bidirectionnel + replication 5 partitions OK |

## Refaire les captures (si besoin)

Toutes les commandes depuis **pve02** :

```bash
# TEST 1 : QoS
iperf3 -s -B 172.16.132.254 -p 5201                      # Terminal 1
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M" &  # Terminal 2
ssh wmsadmin@172.16.132.20 "ping -c 30 -i 0.2 172.16.132.30"
sshpass -p pfsense ssh admin@172.16.132.1 "pfctl -s queue"

# TEST 2 : Failover AD
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
qm stop 32010 && sleep 30
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
qm start 32010

# TEST 3 : Failover WMS
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
qm stop 32020 && sleep 2 && qm start 32020 && sleep 45
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"

# TEST 4 : Tunnel Azure
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "ping -n 4 10.100.0.10"
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "ping -n 4 172.16.132.10"
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "repadmin /syncall /APed"
```

## Screenshots

Pour des captures visuelles (images) :

1. Terminal en plein ecran, police 14pt minimum, fond sombre
2. Screenshot avec `Alt+PrintScreen` (Windows) ou `gnome-screenshot` (Linux)
3. Nommer : `capture-01-qos.png`, `capture-02-failover-ad.png`, etc.
4. Stocker dans `docs/05-soutenance/images/`

## Insertion dans les slides

Si la demo live plante, ouvrir `MSPR_NordTransit_Presentation.pptx` :

1. Ajouter une slide apres la partie demo : **"Resultats POC — preuves terminaux"**
2. Coller les screenshots 2 par slide (taille lisible)
3. Sous chaque capture, indiquer le nom du test et le verdict PASS

## Quand utiliser le Plan B

- Une VM refuse de demarrer malgre 2 tentatives
- Le reseau de l'ecole a un probleme
- SSH timeout sur plus de 2 VMs
- N'importe quel blocage qui prend plus de 2 minutes a resoudre

> Mieux vaut montrer des captures propres que galérer 5 minutes devant le jury.
