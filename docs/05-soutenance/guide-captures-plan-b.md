---
title: "Guide Captures — Plan B Demo"
date: 2026-02-21
---

# Guide Captures — Plan B Demo

> A faire ce weekend (21-22/02). Objectif : avoir des preuves statiques en cas de panne live lundi.

## Methode de capture

Sur pve02, utiliser `script` pour enregistrer toute la session terminal :

```bash
# Lancer l'enregistrement
script -a capture-demo-$(date +%Y%m%d).log

# ... executer les commandes de test ...

# Arreter l'enregistrement
exit
```

Le fichier `.log` contient tout ce qui s'est affiche dans le terminal.

## Les 4 captures a faire

### Capture 1 — QoS VoIP

```bash
# Terminal 1 : serveur iperf3
iperf3 -s -B 172.16.132.254 -p 5201

# Terminal 2 : saturation + ping
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 20 -b 500M" &
ssh wmsadmin@172.16.132.20 "ping -c 100 -i 0.1 172.16.132.30"

# Terminal 1 : stats queues apres le test
sshpass -p pfsense ssh admin@172.16.132.1 "pfctl -s queue"
```

**Ce que le jury doit voir :** latence ~0.1 ms, 0% perte, queues qVoIP priority 7.

### Capture 2 — Failover AD

```bash
# Avant
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"

# Arret DC01
qm stop 32010
sleep 30

# Verification DC02 prend le relais
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"

# Remise en route
qm start 32010
```

**Ce que le jury doit voir :** nltest retourne `DC02.lab.local` apres arret DC01.

### Capture 3 — Failover WMS

```bash
# Avant
ssh wmsadmin@172.16.132.20 "/usr/local/bin/check_wms.sh"

# Arret brutal + reboot
qm stop 32020 && sleep 2 && qm start 32020
sleep 45

# Apres
ssh wmsadmin@172.16.132.20 "/usr/local/bin/check_wms.sh"
```

**Ce que le jury doit voir :** 5/5 records identiques avant/apres, MySQL running.

### Capture 4 — Tunnel Azure

```bash
# Ping bidirectionnel
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "ping -n 4 10.100.0.10"
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "ping -n 4 172.16.132.10"

# DNS cross-site
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "nslookup dc-azure.lab.local"

# Replication AD
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "repadmin /syncall /APed"
```

**Ce que le jury doit voir :** Reply from, DNS resolu, "no errors" replication.

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
