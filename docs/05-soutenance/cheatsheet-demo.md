# CHEATSHEET DEMO — Copier-coller

> **Navigation soutenance** : [**Revision express**](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · **Cheatsheet demo** · [Plan B](guide-captures-plan-b.md) · [Questions jury](questions-jury.md) · [Fiche Ref](fiche-reference-jourj.md)

> PC portable → AnyDesk → PC bureau → terminal
> SSH ProxyJump via pve02, sans mot de passe (cle ed25519).

---

## 0. Connexion + demarrage

```
ssh pve02
```

```
for vmid in 32001 32005 32010 32011 32012 32020 32030; do qm start $vmid; done
```

Attendre 3-5 min (Windows est lent). Verifier :

```
ssh DC01 "echo ok"
```

Quand DC01 repond "ok" → tout est pret.

---

## TEST 1 — QoS VoIP

Ouvrir 2 terminaux.

**Terminal 1** — serveur iperf3 :
```
ssh pve02 "iperf3 -s -B 172.16.132.254 -p 5201"
```

**Terminal 2** — saturation + ping :
```
ssh WMS "iperf3 -c 172.16.132.254 -p 5201 -t 15 -b 500M" &
```

```
ssh WMS "ping -c 50 -i 0.2 172.16.132.30"
```

**A dire** : "On sature le reseau a 500 Mbps. Malgre ca, la latence vers le serveur VoIP reste a 0.1 ms grace a la QoS — la queue qVoIP est en priorite 7."

Stats QoS (optionnel) :
```
ssh FW-SIEGE "pfctl -s queue"
```

Quand fini, Ctrl+C dans le terminal 1.

---

## TEST 2 — Failover AD

**Etat initial** (montre que DC01 repond) :
```
ssh DC02 "nltest /dsgetdc:lab.local"
```

**Couper DC01** :
```
ssh pve02 "qm stop 32010"
```

Attendre 30 secondes. Parler pendant : "DC01 vient de tomber brutalement. En production, ca simule une panne serveur. DC02 doit prendre le relais automatiquement."

**Verifier la bascule** :
```
ssh DC02 "nltest /dsgetdc:lab.local"
```

**A voir** : la reponse dit `DC02.lab.local` au lieu de `DC01`.

**Remettre DC01** :
```
ssh pve02 "qm start 32010"
```

---

## TEST 3 — Failover WMS

**Etat avant** :
```
ssh WMS "/usr/local/bin/check_wms.sh"
```

**A voir** : MySQL running, 5 records.

**Couper brutalement + reboot** :
```
ssh pve02 "qm stop 32020 && sleep 2 && qm start 32020"
```

Attendre ~45 sec. Parler : "Coupure de courant simulee. La VM redemarre, MySQL doit survivre sans perte de donnees."

**Etat apres** :
```
ssh WMS "/usr/local/bin/check_wms.sh"
```

**A voir** : MySQL running, 5 records identiques (memes timestamps).

---

## TEST 4 — Tunnel Azure

**Ping siege → Azure** :
```
ssh DC01 "ping -n 4 10.100.0.10"
```

**Ping Azure → siege** :
```
ssh DC-AZURE "ping -n 4 172.16.132.10"
```

**A dire** : "Communication bidirectionnelle entre le siege et Azure, a travers le tunnel inter-sites. En prod, c'est du IPsec IKEv2."

**Replication AD cross-site** (optionnel si le temps) :
```
ssh DC-AZURE "repadmin /syncall /APed"
```

**A voir** : "SyncAll terminated with no errors."

---

## Si ca plante

| Probleme | Fix rapide |
|----------|-----------|
| VM demarree mais SSH refuse | Attendre 2 min de plus, Windows est lent |
| iperf3 "address already in use" | `ssh pve02 "pkill iperf3"` puis relancer |
| nltest repond toujours DC01 apres arret | Attendre 30s de plus, ou `ssh DC02 "ipconfig /flushdns"` |
| WMS SSH timeout apres reboot | Attendre 1 min, cloud-init est lent au 1er boot |
| Rien ne marche du tout | Basculer sur les captures d'ecran dans les slides |
