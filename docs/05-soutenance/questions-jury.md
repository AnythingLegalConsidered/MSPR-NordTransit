---
title: "Questions Jury - Preparation Soutenance"
subtitle: "MSPR - NordTransit Logistics"
author: "Groupe 2 - PUICHAUD Ianis, ABOUYAALA Zaid, LANTSIGBLE Ojvind, LENOGUE Ewan, WANDA NKONG Blaise"
date: 2026-02-15
version: "1.0"
---

# Questions Jury — Preparation Soutenance

> **Navigation soutenance** : [**Revision express**](revision-express.md) · [Briefing](briefing-soutenance.md) · [Plan](plan-presentation.md) · [Carnet](carnet-soutenance.md) · [Aide-memoire](aide-memoire.md) · [Cheatsheet demo](cheatsheet-demo.md) · [Plan B](guide-captures-plan-b.md) · **Questions jury** · [Fiche Ref](fiche-reference-jourj.md)

> 100 questions classees du plus basique au plus difficile.
> Chaque question est suivie d'une **piste de reponse** pour aiguiller.
> Les sections 13 (pieges) et 14 (reproductibilite) sont les plus dangereuses.

---

## 1. Contexte (faciles, pour demarrer)

**1. Pouvez-vous presenter NordTransit Logistics en 2 minutes ?**
> PME logistique Hauts-de-France, 240 personnes (300 en haute saison), 4 entrepots (Lille siege, Lens, Valenciennes, Arras) + 1 cross-dock saisonnier. 65 postes, 70 telephones IP, ~20 VMs. DSI de 4 personnes.

**2. Combien de personnes composent l'equipe DSI ? Cela vous semble-t-il suffisant ?**
> 4 personnes (1 responsable, 1 admin itinerant, 1 technicien, 1 alternant). C'est tendu pour 5 sites, d'ou le besoin d'outils centralises (FortiGate unifies, PRTG) et de documentation. L'architecture cible est pensee pour etre geree par cette equipe reduite.

**3. Quel est le budget total du projet ? Etait-ce une contrainte forte ?**
> 137 301 EUR sur un plafond de 150 000 EUR. Oui, contrainte forte : ca a guide le choix de FortiGate 60F (pas 100F partout), un cluster 2 noeuds (pas 3), et Azure Reserved Instances 3 ans pour reduire le cout cloud.

**4. Combien de temps avez-vous eu pour preparer cette MSPR ?**
> 19h de preparation en equipe de 5. Contrainte temps forte qui a impose de prioriser : audit rapide, livrables directement actionnables, POC cible sur 4 tests essentiels.

**5. Comment vous etes-vous reparti les taches dans l'equipe de 5 ?**
> Adapter selon votre repartition reelle. Mentionner : qui a fait l'audit, qui a concu l'architecture, qui a monte le lab, qui a redige les livrables, qui a gere le budget.

**6. Qu'est-ce qu'un WMS ? Pourquoi est-il critique pour une entreprise de logistique ?**
> Warehouse Management System = gestion des stocks, reception, expedition, tracabilite colis en temps reel. Sans WMS, aucun colis ne peut etre recu/traite/expedie. Cout d'arret = plusieurs milliers d'euros/heure (penalites contractuelles + CA perdu).

---

## 2. Audit / Etat des lieux

**7. Qu'est-ce qu'un SPOF ? Identifiez les SPOF de l'infrastructure actuelle.**
> Single Point of Failure = composant dont la panne entraine l'arret du service. SPOF identifies : Dell R630 (hyperviseur unique, toutes les VMs dessus), NAS RAID5 unique (backups non externalises), liens WAN sans redondance (1 lien par site), FortiGate 80D EOL (plus de patches).

**8. Pourquoi le Dell R630 est-il un probleme critique ?**
> Il heberge TOUTES les VMs (AD, WMS, IPBX, supervision). Si ce serveur tombe, c'est arret total : plus d'auth, plus de WMS, plus de telephonie. C'est un SPOF unique pour l'ensemble du SI. En plus, c'est un modele de 2016, plus sous garantie.

**9. Le FortiGate 80D est en "EOL". Que signifie ce terme et quel est le risque concret ?**
> End Of Life = plus de mises a jour firmware ni de patches de securite. Risque : vulnerabilites connues (CVE) non corrigees, exploitables par des attaquants. Pour un pare-feu, c'est critique car c'est la premiere ligne de defense.

**10. Les DrayTek Vigor 2860 utilisent IPsec en IKEv1. Quelle est la difference avec IKEv2 ?**
> IKEv2 : plus rapide (moins d'echanges pour etablir le tunnel), supporte MOBIKE (changement d'IP sans coupure), meilleure gestion du NAT traversal, DPD integre nativement. IKEv1 : plus lent, plus complexe (2 phases avec plus de messages), moins resilient.

**11. Vous dites que les backups sont "non testes". Pourquoi est-ce un probleme ?**
> Un backup non teste est un backup qui ne fonctionne peut-etre pas. Le jour ou on en a besoin (crash, ransomware), on decouvre que la restauration echoue. Regle d'or : un backup qui n'a pas ete restaure avec succes n'est pas un backup.

**12. Le MFA est deploye uniquement pour l'IT. Pourquoi recommandez-vous de l'etendre ?**
> Les comptes utilisateurs sont les plus nombreux et les plus vulnerables (phishing, mots de passe faibles). Un compte compromis donne acces au WMS, aux fichiers partages. Le MFA bloque 99.9% des attaques par vol de credentials (source : Microsoft).

**13. Qu'est-ce qu'un broadcast storm et quel lien avec l'absence de VLANs ?**
> Broadcast storm = boucle de trames broadcast qui sature le reseau. Sans VLANs, un seul domaine de broadcast pour tout (data, voix, serveurs). Un broadcast storm touche TOUT le reseau. Les VLANs isolent les domaines de broadcast et limitent l'impact.

**14. Vous avez priorise P0/P1/P2/P3. Justifiez pourquoi la QoS VoIP n'est que P2 et pas P1.**
> P0 = SPOF (arret total possible), P1 = securite (vulnerabilites exploitables). La QoS VoIP est P2 car sans QoS, la VoIP fonctionne quand meme (degradee mais pas coupee), alors que les SPOF et la securite peuvent causer des arrets totaux ou des compromissions.

---

## 3. Architecture cible

**15. Pourquoi avoir choisi un cluster 2 noeuds plutot que 3 ?**
> Budget : 2x R650xs = ~30k EUR, un 3eme ajouterait ~15k EUR et depasserait le plafond. Pour une PME de 240 personnes avec ~20 VMs, 2 noeuds suffisent. Le Cloud Witness Azure gere le quorum sans 3eme noeud physique.

**16. Qu'est-ce qu'un SAN ? Pourquoi le PowerVault ME5012 plutot qu'un NAS en RAID ?**
> SAN (Storage Area Network) = stockage en mode bloc, connecte via iSCSI/FC, concu pour la virtualisation. NAS = stockage fichier (NFS/SMB). Le SAN est necessaire pour le failover cluster : les 2 noeuds accedent au meme stockage. Un NAS RAID ne supporte pas le live migration de VMs.

**17. Expliquez le role du Cloud Witness dans votre cluster. Que se passe-t-il s'il est inaccessible ?**
> Cloud Witness = temoin de quorum heberge sur Azure Blob Storage. Il depart les votes si un noeud tombe (2 noeuds + 1 witness = 3 votes). S'il est inaccessible mais qu'un noeud est OK, le cluster continue (2 votes sur 3). Si witness + 1 noeud tombent = cluster arrete.

**18. Pourquoi FortiGate et pas Palo Alto, Sophos, ou pfSense en production ?**
> FortiGate : meilleur rapport qualite/prix pour une PME (60F a ~2000 EUR), gestion centralisee FortiManager, VPN IKEv2 natif, QoS integree, UTM complet. Palo Alto = trop cher. Sophos = moins performant sur le VPN site-a-site. pfSense = pas de support entreprise, pas de gestion centralisee.

**19. Vous avez 4 VLANs (10/20/30/40). Pourquoi ces 4 et pas plus ou moins ?**
> 4 types de trafic distincts avec des besoins differents : MGMT (admin, securite renforcee), SERVEURS (VMs, stockage SAN), DATA (postes, imprimantes), VOIP (telephones, QoS EF). Moins = pas assez d'isolation. Plus = complexite inutile pour 4 personnes en DSI.

**20. Expliquez le choix de DSCP EF (46) pour la VoIP. Que se passe-t-il si un poste marque du trafic data en EF ?**
> EF (Expedited Forwarding) = plus haute priorite DSCP, pensee pour le trafic temps reel (voix). Si un poste marque du data en EF, il passe en priorite et degrade la VoIP. Solution : le FortiGate re-marque le trafic a l'entree du VLAN (trust uniquement VLAN 40).

**21. Pourquoi un FortiGate 100F au siege et des 60F en entrepot ?**
> Le siege est le hub VPN (5 tunnels), heberge toutes les VMs, debit 1 Gbps necessaire. Le 100F gere ca. Les entrepots n'ont qu'un tunnel spoke + trafic local = le 60F suffit. Criteres : debit, nombre de tunnels VPN, nombre de sessions UTM.

**22. Vous prevoyez un PRA Azure. Quel est le RTO/RPO cible ?**
> AD : RTO < 15 min, RPO = 0 (replication temps reel via DC-Azure). WMS : RTO < 1h, RPO < 15 min (Azure Site Recovery). Telephonie : RTO < 30 min. Definis par l'impact business : WMS hors service = arret operations, donc RTO agressif.

**23. Pourquoi Azure et pas AWS ou OVH pour le PRA ?**
> NordTransit utilise deja Microsoft 365 + Entra ID. Azure s'integre nativement (AD Connect, Site Recovery pour Hyper-V/VMware, Blob pour Veeam). Synergie ecosysteme Microsoft. AWS n'a pas d'equivalent natif pour AD. OVH n'a pas de service PRA automatise comparable.

**24. Vous avez un DC-Azure. Pourquoi ne pas en avoir qu'un seul dans le cloud ?**
> On a 3 DCs : DC01+DC02 on-prem (siege) + DC-Azure (cloud). Si le siege brule, DC-Azure maintient l'AD. Si Azure tombe, les 2 DCs on-prem continuent. Un seul DC cloud sans DC on-prem = dependance totale au cloud et a la latence WAN.

---

## 4. Segmentation reseau

**25. Votre VLAN 10 au siege est en /26. Ca fait combien d'hotes ? C'est suffisant ?**
> /26 = 64 adresses - 2 (reseau + broadcast) = 62 hotes. Pour le MGMT (switches, AP, firewalls, consoles admin), c'est largement suffisant. On a ~10-15 equipements d'administration au siege.

**26. Pourquoi les entrepots ont un VLAN DATA en /25 et un VLAN VoIP en /27 ?**
> DATA en /25 = 126 hotes : couvre les ~15 PC + ~10 terminaux RF + ~3 imprimantes + marge haute saison. VoIP en /27 = 30 hotes : couvre les ~15 telephones IP par site. Dimensionnement adapte au nombre d'equipements.

**27. Le cross-dock n'a pas de segmentation VLAN. Pourquoi ? N'est-ce pas un risque ?**
> Site saisonnier, activation temporaire, ~10 postes max, pas de telephonie IP. La simplicite prime (FortiGate 40F en protection perimetrique suffit). Le risque est accepte et mitige par le firewall + VPN vers le siege.

**28. Comment le trafic inter-VLAN est route ? Par le pare-feu ou par un switch L3 ?**
> Par le FortiGate (router-on-a-stick). Le FortiGate est la gateway de chaque VLAN. Avantage : filtrage inter-VLAN au meme endroit que le firewall (une seule politique). Inconvenient : tout le trafic inter-VLAN passe par le FW (mais le 100F supporte largement le debit).

**29. Vos sous-reseaux entrepots ne se chevauchent pas. Comment avez-vous planifie l'adressage ?**
> 3eme octet = identifiant de site : .10 = siege, .20 = WH1, .30 = WH2, .40 = WH3, .50 = cross-dock. 10.100.x = Azure. Schema simple et lisible, aucun chevauchement possible, facilite le routage VPN (1 route par site).

---

## 5. VPN

**30. Expliquez la topologie hub-and-spoke. Avantages et inconvenients ?**
> Hub = siege (FortiGate 100F), Spokes = entrepots + Azure. Tout le trafic inter-sites passe par le siege. Avantage : simple a gerer (N tunnels au lieu de N*(N-1)/2), politique centralisee. Inconvenient : siege = SPOF pour la communication inter-sites, latence doublee pour le trafic entrepot-entrepot.

**31. Pourquoi ne pas faire du full-mesh entre les entrepots ?**
> Les entrepots ne communiquent pas entre eux directement (pas de besoin metier). Tout passe par le siege (WMS, AD, IPBX sont au siege). Le full-mesh ajouterait de la complexite sans benefice. Si besoin futur : ADVPN FortiGate le supporte.

**32. IKEv2 avec AES-256-GCM : expliquez ce que fait GCM de plus qu'AES-256-CBC.**
> GCM = Galois/Counter Mode. C'est un mode AEAD (Authenticated Encryption with Associated Data) : il chiffre ET authentifie en une seule operation. CBC necessite un hash separe (HMAC-SHA256). GCM est plus rapide (parallelisable, hardware-accelerated) et plus sur (pas de padding oracle attack).

**33. En cas de panne du siege, les entrepots peuvent-ils communiquer entre eux ?**
> Non, car topologie hub-and-spoke. Mais les entrepots n'ont pas besoin de communiquer entre eux (pas de flux metier). Chaque entrepot peut continuer a fonctionner localement (impression, terminaux RF en cache). Le vrai impact = plus d'acces WMS et AD.

**34. Dans le POC, pas de vrai tunnel IPsec entre FW-SIEGE et FW-AZURE. Comment validez-vous le concept ?**
> Le POC valide la connectivite cross-site via routes statiques sur vmbr2. La configuration IPsec pfSense est documentee et prete a deployer (cf. vpn-ipsec.md section 3). Le tunnel aurait ajoute de la complexite au lab sans changer le resultat des tests (ping, DNS, replication AD).

**35. Qu'est-ce que le DPD ? A quoi ca sert ?**
> Dead Peer Detection = mecanisme IKEv2 qui envoie des "keepalives" (toutes les 10s, 3 retries). Si le peer ne repond pas en 30s, le tunnel est declare mort et la reenegociation demarre. Sans DPD, un tunnel mort reste "UP" cote local et le trafic est blackhole.

---

## 6. Active Directory

**36. Pourquoi 3 controleurs de domaine et pas 2 ?**
> 2 DCs on-prem (DC01+DC02 au siege) = resilience locale. 1 DC Azure = resilience geographique (PRA). Avec 2 DCs, si le siege brule, plus d'AD. Le 3eme dans Azure garantit la continuite meme en cas de sinistre total du siege.

**37. Expliquez le role de chaque DC.**
> DC01 (172.16.132.10) : DC principal, DNS principal, premier installe. DC02 (172.16.132.11) : DC secondaire, prend le relais si DC01 tombe. DC-AZURE (10.100.0.10) : DC replique cloud, sert pour le PRA et les authentifications depuis Azure.

**38. Qu'est-ce qu'un Global Catalog et pourquoi vos 3 DCs sont-ils tous GC ?**
> Le Global Catalog contient un sous-ensemble d'attributs de TOUS les objets de la foret. Il est necessaire pour les recherches cross-domaine et pour le login (groupes universels). Tous GC = chaque DC peut traiter les authentifications sans dependre d'un autre. Essentiel pour le failover.

**39. Si DC01 et DC02 tombent, DC-AZURE peut-il prendre le relais ?**
> Oui pour l'authentification et le DNS (il est GC + DNS). Limitations : latence WAN pour les clients du siege, les postes doivent pointer vers DC-AZURE en DNS, il faut que le VPN Azure soit UP. Les roles FSMO doivent etre saisis (seize) sur DC-AZURE si les DCs on-prem sont definitivement perdus.

**40. Erreur 1398 (time skew) : explication et resolution.**
> Kerberos refuse les tickets si l'ecart d'horloge entre le client et le DC depasse 5 minutes. Erreur 1398 = horloge desynchronisee entre DCs. Resolution : `w32tm /resync /force` sur le DC desynchronise, puis `repadmin /syncall /APed` pour forcer la replication. Cause racine : DC-AZURE n'avait pas de source NTP configuree.

**41. Quel mode fonctionnel ? Pourquoi WinThreshold ?**
> WinThreshold = Windows Server 2016 functional level. C'est le mode par defaut quand on installe Windows Server 2022 avec des DCs 2022. Il supporte toutes les fonctionnalites modernes (Privileged Access Management, etc.). On pourrait monter en WinServer2025 mais pas de benefice immediat.

**42. Comment fonctionne la replication AD entre sites separes par un firewall ?**
> La replication AD utilise RPC (port 135 + ports dynamiques 49152-65535) et LDAP (389). Le firewall doit ouvrir ces ports entre les DCs. Dans le lab, on a du ajouter des routes statiques + easyrules sur pfSense + desactiver le firewall Windows profil "Private" pour que la replication cross-VLAN fonctionne.

---

## 7. Telephonie / VoIP

**43. Pourquoi FreePBX et pas 3CX ou Asterisk pur ?**
> FreePBX = Asterisk + interface web de gestion. Plus facile a administrer qu'Asterisk en CLI pur. 3CX = payant pour les licences et plus ferme (moins de flexibilite). FreePBX est open source, gratuit, et largement documente.

**44. Qu'est-ce que PJSIP ? Pourquoi plutot que chan_sip ?**
> PJSIP = nouveau driver SIP d'Asterisk, remplace chan_sip (deprecie). PJSIP supporte plusieurs transports (UDP/TCP/TLS), le WebRTC, et est activement maintenu. chan_sip est abandonne depuis Asterisk 17.

**45. Expliquez votre configuration QoS sur pfSense (PRIQ, priorites 7/5/1).**
> PRIQ = Priority Queuing. 3 queues : qVoIP (priorite 7, la plus haute, trafic marque DSCP EF), qServers (priorite 5, trafic serveurs), qDefault (priorite 1, tout le reste). En cas de congestion, la VoIP passe en premier, puis les serveurs, puis le data. 7 floating rules matchent sur les ports SIP/RTP et les IP serveurs.

**46. La queue qVoIP ne montre qu'1 paquet dans le test. La QoS est-elle vraiment testee ?**
> Point faible du POC. Le test mesure la latence/gigue pendant une saturation iperf3. Le 1 paquet dans qVoIP vient du ping ICMP vers l'IPBX (classe EF). En production, un appel VoIP genererait des centaines de paquets RTP/s. Le test prouve que la priorisation fonctionne (0% perte, 0.1ms latence sous 500Mbps de charge) mais n'est pas un test VoIP reel avec des softphones.

**47. Quels sont les seuils ITU-T pour la qualite voix ?**
> ITU-T G.114 : latence < 150ms (one-way), gigue < 30ms, perte < 1%. Nos resultats (0.1ms, 0.04ms, 0%) sont bien en dessous car c'est un LAN local. En production avec tunnel VPN, latence attendue : 10-30ms (reseau fibre regional), toujours dans les seuils.

**48. Comment un telephone IP obtient-il son VLAN VoIP ?**
> Via CDP (Cisco Discovery Protocol) ou LLDP-MED. Le switch envoie le VLAN ID voix au telephone. Le telephone tag ses paquets avec le VLAN 40. Le switch a un port en mode "access" pour le DATA et un "voice VLAN" pour la VoIP. Config Cisco : `switchport voice vlan 40`.

**49. Si le lien WAN tombe, un entrepot peut-il passer des appels internes ?**
> Non dans l'architecture actuelle car l'IPBX est centralise au siege. Sans WAN = pas de SIP = pas d'appels. Solution future : survivability (SIP proxy local par site). En attendant, les utilisateurs utilisent les portables ou Teams (si M365 fonctionne via 4G backup).

---

## 8. WMS

**50. RTO < 1h et RPO < 15min. Comment les atteindre ?**
> RTO < 1h : cluster HA avec failover automatique (VM redemarree sur le 2eme noeud). RPO < 15 min : replication SAN synchrone entre les 2 noeuds + snapshots toutes les 15 min. En PRA Azure : Azure Site Recovery replique toutes les 15 min vers Azure (RPO = 15 min).

**51. Reboot en 20s dans le test. Realiste en production ?**
> Le test simule un reboot simple (meme hyperviseur). En production avec un vrai failover cluster (detection panne + demarrage VM sur l'autre noeud), compter 2-5 minutes. Reste largement dans le RTO < 1h. Le test valide surtout l'integrite des donnees MySQL apres arret brutal.

**52. Conteneurisation a long terme. Pourquoi pas immediatement ?**
> Le WMS est une application legacy (MySQL + app custom). La conteneuriser demande un effort de refactoring (separation app/BDD, gestion des volumes, orchestration). Pas dans le budget ni le scope de ce projet. Priorite = supprimer le SPOF d'abord, moderniser ensuite.

**53. Pourquoi MySQL et pas PostgreSQL ou MariaDB ?**
> Le WMS existant utilise deja MySQL. On ne change pas le SGBD dans ce projet (risque de regression). La migration vers PostgreSQL/MariaDB serait un projet a part. MySQL est parfaitement adapte au volume de NordTransit.

**54. La BDD de test a 5 records. Comment valider avec un volume realiste ?**
> Le POC valide le mecanisme (arret brutal + integrite). En production, il faudrait un test de charge avec un dump anonymise de la vraie BDD (milliers de lignes). C'est dans les recommandations moyen terme (load testing). Les 5 records suffisent a prouver que MySQL survit a un crash.

---

## 9. POC / Lab

**55. Pourquoi Proxmox pour le lab et pas VMware ou Hyper-V ?**
> Proxmox est gratuit, open source, et deja installe sur le cluster de l'ecole. VMware vSphere necessiterait des licences. Hyper-V = pas de version gratuite standalone equivalente. Pour un POC de validation, Proxmox est parfait. Note : le lab a aussi ete pre-valide sur un homelab personnel avant deploiement sur le cluster ecole.

**56. Combien de RAM et stockage le lab consomme-t-il ?**
> 7 VMs : 2+2+4+4+4+2+2 = 20 Go RAM. Le noeud Proxmox du cluster ecole dispose de suffisamment de ressources (minimum 32 Go RAM necessaires). Stockage : ~8-32 Go par VM = ~100-150 Go. Le lab tient largement sur un seul hyperviseur.

**57. pfSense simule des FortiGate. Quelles sont les limites ?**
> pfSense n'a pas d'UTM (IPS, antivirus, web filter). Pas de FortiGuard. L'interface est differente. Mais les fonctions testees (routage, firewall, QoS PRIQ, VPN IPsec) sont equivalentes. Le POC valide les concepts, pas les produits specifiques.

**58. Routes statiques au lieu d'IPsec dans le lab. C'est une vraie preuve de concept ?**
> C'est une limite assumee. Les routes statiques valident la connectivite cross-site (ping, DNS, replication AD). La config IPsec pfSense est documentee et prete (cf. vpn-ipsec.md section 3). Le tunnel ajouterait de l'encapsulation mais ne changerait pas les resultats des tests fonctionnels.

**59. NIC e1000 au lieu de VirtIO pour Windows. Pourquoi ?**
> Les drivers VirtIO ne sont pas inclus dans l'ISO Windows Server. Il faudrait injecter les drivers pendant l'installation. e1000 est reconnu nativement par Windows. Pour un lab de validation, la difference de performance (1 Gbps vs 10 Gbps theorique) n'impacte pas les tests.

**60. 7 VMs. Pourquoi ne pas avoir simule les 3 entrepots + le cross-dock ?**
> Le POC cible les concepts critiques : pare-feu, AD multi-site, VoIP/QoS, WMS failover, tunnel Azure. Les entrepots sont des "spokes" identiques — en simuler un suffit (le siege fait office de spoke). Ajouter 4 VMs n'aurait rien prouve de plus mais aurait consomme de la RAM.

---

## 10. Strategie de migration

**61. Pourquoi commencer par le cross-dock et finir par le siege ?**
> Du moins critique au plus critique. Cross-dock = site saisonnier, simple, risque minimal → on rode le processus. Les entrepots ensuite (standard, reproductible). Le siege en dernier car il heberge tout (VMs, hub VPN, IPBX). Si on rate le cross-dock, zero impact. Si on rate le siege, arret total.

**62. En combien de phases ? Combien de temps au total ?**
> 6 phases (M1 a M6) sur 6 semaines. M1 = pare-feu (5 nuits), M2 = cluster+SAN (1 WE), M3 = migration VMs (2 nuits WE), M4 = Azure (3 jours), M5 = VLAN+QoS (3 nuits), M6 = validation (1 WE).

**63. "Rollback en moins de 30 minutes". Comment garantir ?**
> Chaque phase a une procedure de rollback testee. Exemples : M1 = rebrancher l'ancien DrayTek (15 min), M3 = restaurer le snapshot VM sur le R630 (30 min), M5 = desactiver les VLANs (20 min). Le R630 reste en standby 72h apres M3. Seuil d'abandon a 03h00 pour garder 2h30 de marge avant 5h30.

**64. Migration du siege echoue a 4h du matin un dimanche. Que faites-vous ?**
> Rollback immediat : restaurer les snapshots sur le R630 (30 min). A 4h30, tester que WMS/AD/VoIP fonctionnent. A 5h00, tout est operationnel avant l'ouverture a 5h30. Documenter l'echec, analyser la cause, replanifier au week-end suivant.

**65. Coexistence ancien/nouveau. Comment gerer le DNS et le routage ?**
> Les VMs gardent les memes adresses IP. Le DNS ne change pas. Le routage VPN est mis a jour au fur et a mesure (les nouveaux FortiGate reprennent les tunnels). Pendant M1, un tunnel IKEv1 de secours est maintenu vers le FortiGate 80D tant qu'il est en place.

**66. Comment migrer les VMs du R630 vers le cluster ?**
> Via l'outil de migration de l'hyperviseur (VMware vMotion, Hyper-V Live Migration, ou export/import OVA). Si hyperviseurs differents : Veeam Backup & Replication pour convertir et restaurer. Les VMs gardent les memes IP.

---

## 11. Budget

**67. 137k EUR pour 5 sites, c'est realiste ?**
> Oui. Postes principaux : 2x R650xs (30k), SAN ME5012 (20k), 5 FortiGate (17.5k), 4 switches Cisco (12k), Azure 3 ans (11.2k), supervision (7.5k), connectivite (12.8k), main d'oeuvre (8.3k), imprevus 15% (17.9k). Les prix sont bases sur des tarifs revendeurs entreprise.

**68. Quel est le poste le plus cher ?**
> Virtualisation (2x Dell R650xs) = 30 000 EUR. Normal : c'est le coeur du SI, serveurs derniere generation avec 256 Go RAM chacun et support ProSupport 3 ans.

**69. Marge de ~13k EUR. A quoi servirait-elle ?**
> Imprevus : cable iSCSI supplementaire, licence FortiGate oubliee, depassement main d'oeuvre, materiel defectueux a remplacer. Ou investissement complementaire : softphones, formation equipe, licence PRTG supplementaire.

**70. Les licences FortiGate sont-elles incluses ? Pour combien d'annees ?**
> Oui, 3 ans de FortiCare + FortiGuard (UTM : IPS, antivirus, web filter, antispam) inclus dans les 17 520 EUR. Apres 3 ans, renouvellement annuel ou changement de gamme.

**71. Le cout Azure est-il inclus dans les 137k EUR ?**
> Oui : 11 232 EUR pour 3 ans en Reserved Instances (remise ~40% par rapport au tarif on-demand). Couvre : VPN Gateway, VM DC-Azure, Azure Site Recovery (20 VMs), Blob Storage. C'est du CAPEX pre-paye, pas de l'OPEX mensuel surprenant.

---

## 12. Securite

**72. Mots de passe en clair dans le lab. Et en production ?**
> Le lab utilise des mots de passe simples pour la reproductibilite. En production : mots de passe forts generes, stockes dans un coffre-fort (KeePass, vault), rotation reguliere. Le vault Ansible chiffre les secrets dans le code. Les PSK VPN seront remplaces par des certificats X.509.

**73. MFA pour tous. Quelle solution ?**
> FortiToken (TOTP) pour les acces VPN et admin FortiGate. Azure MFA (via Entra ID) pour les acces M365 et RDP. Microsoft Authenticator sur les smartphones. FIDO2 serait ideal mais plus cher et complexe a deployer (a envisager en phase 2).

**74. Comment proteger le plan de management des FortiGate ?**
> VLAN 10 MGMT isole. Regles : seul le VLAN MGMT accede aux interfaces d'admin des FortiGate. Acces HTTPS uniquement (pas HTTP). Trusted hosts configures (IP sources autorisees). MFA FortiToken pour les admins. Logging de toutes les connexions admin.

**75. Cle PSK VPN compromise. Que se passe-t-il ?**
> Un attaquant pourrait dechiffrer le trafic VPN ou monter un faux tunnel (MITM). Mitigation : PFS (Perfect Forward Secrecy) avec DH Group 14 protege les sessions passees. Action : changer la PSK immediatement sur les 2 endpoints. Migration vers certificats X.509 = solution definitive (PSK compromise ≠ certificat revoque).

**76. Pas de WAF. Le WMS est-il expose sur Internet ?**
> Non. Le WMS est dans le VLAN 20 (Serveurs), accessible uniquement via VPN (entrepots) ou LAN (siege). Pas d'exposition Internet directe. Un WAF n'est necessaire que si le WMS est expose publiquement (pas le cas ici).

**77. Mises a jour firmware FortiGate sur 5 sites ?**
> Via FortiManager (gestion centralisee) : deployer les firmware en masse, planifier les redemarrages en nuit. Ou manuellement via l'interface web de chaque FortiGate en suivant le meme ordre que la migration (cross-dock en premier, siege en dernier).

---

## 13. Questions difficiles / Pieges

**78. Si le siege brule demain, combien de temps pour remonter les services ?**
> Avec l'architecture cible : DC-Azure maintient l'AD (RTO AD < 15 min). Azure Site Recovery bascule les VMs (RTO WMS < 1h). Backups Veeam sur Azure Blob pour restauration complete. Sans l'architecture cible (etat actuel) : perte totale, pas de PRA, delai indefini.

**79. Cluster 2 noeuds : quel quorum en cas de split-brain ?**
> Cloud Witness Azure = 3eme vote. Si les 2 noeuds se voient mais pas le witness : le cluster continue (2/3 votes). Si un noeud perd la connectivite avec l'autre ET le witness : il s'arrete (1/3 vote). Le split-brain est evite car le witness est dans un 3eme "site" (Azure).

**80. WMS sur Ubuntu 20.04 (EOL avril 2025). Pourquoi ne pas migrer ?**
> Le WMS est une application legacy, la migration vers 22.04/24.04 pourrait casser des dependances (librairies, MySQL version). Ce n'est pas dans le scope du projet (infrastructure, pas applicatif). Recommandation moyen terme : planifier la migration OS avec l'editeur du WMS. En attendant : ESM (Extended Security Maintenance) Ubuntu.

**81. 0.1ms de latence au test QoS. En production avec IPsec ?**
> Le test est en LAN local (meme bridge Proxmox). En production : latence fibre regionale ~5-15ms + overhead IPsec ~1-3ms = 6-18ms. Toujours largement sous le seuil ITU-T de 150ms. La gigue sera plus elevee aussi (5-10ms vs 0.04ms) mais dans les normes.

**82. Ansible dans le repo mais pfSense/Windows configures manuellement. Pourquoi ?**
> Ansible automatise la creation des VMs et le post-deploy WMS (reproductible). pfSense n'a pas de bon module Ansible (configuration XML). Windows AD = promotion via PowerShell encodee en base64 (complexe a automatiser proprement). Choix pragmatique : automatiser ce qui est rentable, documenter le reste en guides pas-a-pas.

**83. DSI de 4 personnes. L'admin reseau est en arret maladie. Qui gere le FortiGate ?**
> Documentation complete (ce projet). Procedures step-by-step dans les livrables. L'admin systeme peut prendre le relais (meme interface FortiGate). En dernier recours : support FortiCare (contrat inclus). C'est aussi pourquoi on a une flotte homogene (une seule competence a maitriser).

**84. PRTG et pas Zabbix ou Grafana ?**
> PRTG : interface graphique intuitive, pas besoin de compétences Linux avancees, capteurs preconfigures, ideal pour une DSI de 4 personnes. Zabbix : puissant mais complexe a configurer/maintenir. Grafana : dashboard, pas un outil de supervision natif (besoin de Prometheus en backend). Budget : PRTG 500 capteurs suffit.

**85. Ransomware chiffre DC01 et DC02. DC-AZURE peut-il recuperer l'AD ?**
> Oui, DC-AZURE a une copie complete de l'AD (Global Catalog). Si DC01+DC02 sont perdus definitivement : seize les roles FSMO sur DC-AZURE, nettoyer les metadata des anciens DCs (ntdsutil). L'AD est fonctionnel. Puis reinstaller 2 DCs on-prem et les promouvoir. Condition : DC-AZURE ne doit pas etre chiffre aussi (isolation reseau Azure + NSG).

**86. Entra ID. Pourquoi ne pas supprimer l'AD on-prem ?**
> L'AD on-prem est necessaire pour : authentification locale (pas de dependance internet), GPO sur les postes, Kerberos pour les applications internes (WMS, partages fichiers), gestion des imprimantes. Entra ID seul ne supporte pas tout ca. L'hybride (AD on-prem + Entra ID sync) est le standard pour les PME.

**87. Telephones Cisco compatibles avec FreePBX/PJSIP ?**
> Les Cisco SPA (gamme PME) supportent SIP standard et sont compatibles. Les Cisco 7800/8800 (entreprise) aussi en mode SIP (pas SCCP). Il faut configurer le provisionning SIP sur les telephones (serveur SIP = IP IPBX). Point d'attention : certains vieux Cisco (7940/7960) ne supportent que SCCP.

**88. VLAN VoIP en /27 (30 hotes). 70 telephones sur 4 sites, ca suffit ?**
> 70 telephones / 4 sites = ~17 par site. /27 = 30 hotes. Ca passe, avec une marge de ~13 postes par site. Au siege (25 telephones), c'est en /26 = 62 hotes, largement suffisant. Si un site grandit au-dela de 30, on passe en /26 (modification du plan d'adressage).

**89. Azure subit une panne regionale. Le PRA est-il resilient ?**
> Le PRA Azure est dans une seule region. Si panne regionale : DC-Azure indisponible, mais les 2 DCs on-prem continuent. Site Recovery inoperant mais les VMs tournent au siege sur le cluster. Pour un PRA multi-region, il faudrait un budget plus eleve (geo-replication). Risque accepte pour une PME de cette taille.

**90. POC sur un seul Proxmox. Comment extrapoler a 5 sites physiques ?**
> Le POC valide les concepts (failover AD, QoS, WMS resilience, connectivite cross-site). Le passage en production ajoute : materiel reel (FortiGate vs pfSense), cablage physique, latence WAN reelle. Les principes sont les memes. La strategie de migration prevoit des tests M6 sur le materiel reel avant la mise en production.

---

## 14. Reproductibilite (objectif du projet)

**91. Un camarade peut-il refaire le lab ? En combien de temps ?**
> Oui, c'est l'objectif. Guides numerotes 00 a 07, step-by-step. Prerequis clairs (00). Ansible pour creer les VMs automatiquement. Compter ~4-6h pour tout monter (si le Proxmox est deja installe). Les ISOs a telecharger sont listes dans le guide 00.

**92. Si quelqu'un saute une etape, que se passe-t-il ?**
> Chaque guide liste ses prerequis (guides precedents). Si on saute le guide 02 (pfSense), les VMs n'ont pas de gateway → pas de reseau. Si on saute le guide 03 (AD), les DCs ne sont pas installes → pas de domaine pour les tests. L'ordre est obligatoire et documente.

**93. Ansible automatise les VMs. Pourquoi pas la config pfSense ?**
> pfSense se configure via XML (pas d'API REST simple ni de module Ansible mature). L'automatisation est possible (Ansible + module pfsensible) mais instable et mal documentee. Rapport effort/benefice defavorable pour un lab de validation. Les guides manuels sont plus fiables et reproductibles.

**94. ISOs Windows Server : ou les recuperer ? Licence ?**
> ISOs d'evaluation gratuites sur le site Microsoft (180 jours). Suffisant pour un lab de validation. En production, NordTransit a des licences via un contrat de volume (Open License ou CSP). Les liens de telechargement sont dans le guide 00.

**95. Le vault Ansible contient les secrets. Comment y acceder ?**
> Le fichier `.vault_pass` contient le mot de passe du vault. Il est sur l'hyperviseur Proxmox dans `/root/mspr-ansible/.vault_pass`. Mot de passe : communique hors-bande (pas dans le repo). Le fichier `vault.yml.example` montre la structure attendue. Commande : `ansible-vault decrypt --vault-password-file .vault_pass`.

---

## 15. Synthese / Ouverture

**96. Si vous aviez 300k EUR, que changeriez-vous ?**
> Cluster 3 noeuds (plus de marge), FortiGate 100F sur tous les sites (UTM complet partout), liens WAN redondants (2 FAI par site), PRA Azure multi-region, SIEM (FortiSIEM), 2eme SAN pour la replication, formation certifiante pour la DSI.

**97. Quel est le point le plus faible de votre architecture ?**
> La telephonie. L'IPBX est centralise au siege sans survivability en entrepot. En cas de panne WAN, les entrepots n'ont plus de telephonie. Solution future : SBC ou proxy SIP local par site, ou migration vers Teams Phone.

**98. Si vous deviez refaire ce projet, que feriez-vous differemment ?**
> Reponse personnelle. Suggestions : commencer par le lab plus tot, automatiser plus avec Ansible (y compris pfSense), faire un vrai test VoIP avec softphones, tester avec un volume de donnees WMS realiste, prevoir plus de temps pour la documentation.

**99. En quoi ce projet vous a fait progresser techniquement ?**
> Reponse personnelle. Mentionner : conception d'architecture multi-site, VPN IKEv2, Active Directory multi-site, QoS reseau, gestion de budget IT, documentation technique, travail en equipe, approche POC pour valider avant de deployer.

**100. Quelle est la prochaine etape apres cette soutenance ?**
> Pour le client fictif : lancer la phase M1 (deploiement pare-feu) apres commande du materiel. Pour l'equipe : capitaliser sur la documentation, partager les guides lab, envisager des certifications (NSE Fortinet, AZ-800 Windows Server, etc.).
