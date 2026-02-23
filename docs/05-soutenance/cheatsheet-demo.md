# CHEATSHEET DEMO — Copier-coller

> **Navigation soutenance** : [**Revision express**](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · **Cheatsheet demo** · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

> PC portable → AnyDesk → PC bureau → terminal → `ssh pve02`
> Toutes les commandes ci-dessous sont a lancer **depuis pve02**.

---

## 0. Connexion + demarrage

```bash
ssh pve02
```

```bash
for vmid in 32001 32005 32010 32011 32012 32020 32030; do qm start $vmid 2>/dev/null; done
```

Attendre 3-5 min (Windows est lent). Verifier :

```bash
sshpass -p 'az4826QS6284**' ssh -o StrictHostKeyChecking=no Administrator@172.16.132.10 "echo ok"
```

Quand ca repond "ok" → tout est pret.

---

## TEST 1 — QoS VoIP

Ouvrir 2 terminaux SSH vers pve02.

**Terminal 1** — serveur iperf3 :
```bash
iperf3 -s -B 172.16.132.254 -p 5201
```

**Terminal 2** — saturation + ping :
```bash
ssh wmsadmin@172.16.132.20 "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M" &
ssh wmsadmin@172.16.132.20 "ping -c 30 -i 0.2 172.16.132.30"
```

**A dire** : "On sature le reseau a 500 Mbps. Malgre ca, la latence vers le serveur VoIP reste a 0.1 ms grace a la QoS — la queue qVoIP est en priorite 7."

Stats QoS (optionnel) :
```bash
sshpass -p pfsense ssh admin@172.16.132.1 "pfctl -s queue"
```

Quand fini, Ctrl+C dans le terminal 1.

---

## TEST 2 — Failover AD

**Etat initial** :
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
```

**Couper DC01** :
```bash
qm stop 32010
```

Attendre 30 secondes. Parler pendant : "DC01 vient de tomber brutalement. En production, ca simule une panne serveur. DC02 doit prendre le relais automatiquement."

**Verifier la bascule** :
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.11 "nltest /dsgetdc:lab.local"
```

**A voir** : la reponse dit `DC02.lab.local`.

Optionnel — DNS depuis WMS :
```bash
ssh wmsadmin@172.16.132.20 "host dc02.lab.local 172.16.132.11"
```

**Remettre DC01** :
```bash
qm start 32010
```

---

## TEST 3 — Failover WMS

**Etat avant** :
```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
```

**A voir** : 5 lignes (Colis Standard A, B, Palette Export, Colis Express, Palette Vrac).

**Couper brutalement + reboot** :
```bash
qm stop 32020 && sleep 2 && qm start 32020
```

Attendre ~45 sec. Parler : "Coupure de courant simulee. La VM redemarre, MySQL doit survivre sans perte de donnees."

**Etat apres** :
```bash
ssh wmsadmin@172.16.132.20 "sudo mysql -e 'SELECT * FROM wms_test.inventory;'"
```

**A voir** : les memes 5 lignes, memes timestamps. Zero perte.

---

## TEST 4 — Tunnel Azure

**Ping siege → Azure** :
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@172.16.132.10 "ping -n 4 10.100.0.10"
```

**Ping Azure → siege** :
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "ping -n 4 172.16.132.10"
```

**A dire** : "Communication bidirectionnelle entre le siege et Azure, a travers le tunnel inter-sites. En prod, c'est du IPsec IKEv2."

**Replication AD cross-site** :
```bash
sshpass -p 'az4826QS6284**' ssh Administrator@10.100.0.10 "repadmin /syncall /APed"
```

**A voir** : "SyncAll terminated with no errors."

---

## Si le jury veut voir l'AD en visuel (RDP)

Ouvrir un 2eme terminal sur le PC bureau :

```bash
ssh -N -L 13389:172.16.132.10:3389 -L 13390:172.16.132.11:3389 pve02
```

Ca reste ouvert. Ouvrir Bureau a distance (mstsc) → `localhost:13389`

Login : `Administrator` / `az4826QS6284**`

Ouvrir : `dsa.msc` (AD Users), `dnsmgmt.msc` (DNS), ou `repadmin /replsummary` dans un cmd.

---

## Si ca plante

| Probleme | Fix rapide |
|----------|-----------|
| SSH refuse | Attendre 2 min, Windows est lent |
| iperf3 "address already in use" | `pkill iperf3` puis relancer |
| nltest repond toujours DC01 apres arret | Attendre 30s de plus, ou `ipconfig /flushdns` sur DC02 |
| WMS SSH timeout apres reboot | Attendre 1 min, cloud-init est lent |
| Rien ne marche du tout | Montrer `docs/05-soutenance/images/captures-poc-2026-02-22.txt` |
