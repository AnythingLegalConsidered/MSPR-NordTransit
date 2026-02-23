# Procedure Demo Live — Jour J

> Toutes les commandes sont lancees depuis pve02.
> Connexion : PC portable → AnyDesk → PC bureau → terminal → `ssh pve02`

---

## Avant le passage (5 min avant)

```bash
ssh pve02
```

Verifier que les VMs tournent :

```bash
qm list
```

Si des VMs sont "stopped" :

```bash
for vmid in 32001 32005 32010 32011 32012 32020 32030; do qm start $vmid 2>/dev/null; done
```

Attendre 3-5 min (Windows est lent). Pret quand ca repond :

```bash
sshpass -p 'az4826QS6284**' ssh -o StrictHostKeyChecking=no Administrator@172.16.132.10 "echo ok"
```

---

## Test 1 — QoS VoIP

Ouvrir 2 terminaux SSH vers pve02.

**Terminal 1** — serveur iperf3 (reste ouvert) :

```bash
iperf3 -s -B 172.16.132.254 -p 5201
```

**Terminal 2** — saturation + ping :

```bash
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M" &
ssh wmsadmin@172.16.132.20 "ping -c 30 -i 0.2 172.16.132.30"
```

Ce qu'on voit : latence ~0.1-0.2ms, 0% perte malgre 500 Mbps de saturation.

> "La je sature le reseau a 500 Mega, et le ping vers le serveur VoIP reste stable parce que la QoS priorise le trafic voix."

Optionnel — montrer les queues QoS :

```bash
sshpass -p pfsense ssh admin@172.16.132.1 "pfctl -s queue"
```

Quand c'est fini : Ctrl+C dans le terminal 1.

---

## Test 2 — Failover AD

Montrer que le domaine repond :

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
```

Couper DC01 :

```bash
qm stop 32010
```

> "Je viens de couper brutalement le controleur de domaine principal. En production ca simule une panne serveur."

Attendre 30 secondes (parler pendant). Puis verifier :

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
```

On voit DC02 qui repond. Optionnel — montrer le DNS depuis WMS :

```bash
ssh wmsadmin@172.16.132.20 "host dc02.lab.local 172.16.132.11"
```

Remettre DC01 :

```bash
qm start 32010
```

---

## Test 3 — Failover WMS

Etat avant :

```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
```

On voit 5 lignes. Crash :

```bash
qm stop 32020 && sleep 2 && qm start 32020
```

> "Coupure de courant simulee. La VM est en train de redemarrer."

Attendre ~45 secondes. Puis :

```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
```

On voit les memes 5 lignes, memes timestamps. Zero perte de donnees.

---

## Test 4 — Tunnel Azure

Ping dans les 2 sens :

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "ping -n 4 10.100.0.10"
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "ping -n 4 172.16.132.10"
```

> "Communication bidirectionnelle entre le siege et le site Azure."

Replication AD :

```bash
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "repadmin /syncall /APed"
```

On voit "SyncAll terminated with no errors."

---

## Si le jury demande de voir l'AD en visuel (RDP)

Ouvrir un 2eme terminal sur le PC bureau :

```bash
ssh -N -L 13389:172.16.132.10:3389 -L 13390:172.16.132.11:3389 pve02
```

Ca reste ouvert. Ouvrir Bureau a distance (mstsc) → `localhost:13389`

Login : `Administrator` / `az4826QS6284**`

On peut ouvrir :
- `dsa.msc` — Active Directory Users & Computers
- `dnsmgmt.msc` — DNS Manager
- `repadmin /replsummary` dans un cmd

---

## Si ca plante

| Probleme | Solution |
|----------|----------|
| SSH refuse | Attendre 2 min, Windows est lent |
| iperf3 "address in use" | `pkill iperf3` sur pve02 puis relancer |
| nltest repond toujours DC01 | Attendre 30s ou `ipconfig /flushdns` sur DC02 |
| WMS timeout apres reboot | Attendre 1 min |
| Rien ne marche | Montrer `docs/05-soutenance/images/captures-poc-2026-02-22.txt` |
