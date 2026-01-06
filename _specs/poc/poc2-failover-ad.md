# POC 2 - Failover AD

> Prouver la haute disponibilité Active Directory

---

## Objectif

Démontrer que l'arrêt d'un contrôleur de domaine n'impacte pas les utilisateurs.

---

## Critères de succès

| Métrique | Seuil acceptable |
| --- | --- |
| Temps de bascule | < 15 min |
| Authentification | OK pendant panne |
| Services AD | Disponibles |

---

## Procédure de test

### Prérequis
- DC01 et DC02 en réplication
- Client Windows joint au domaine
- Session utilisateur ouverte

### Étape 1 : État initial
- Vérifier `dcdiag` sur les 2 DC
- Vérifier réplication : `repadmin /replsummary`
- Noter quel DC répond (`nltest /dsgetdc:domaine`)

### Étape 2 : Simuler panne DC01
- Arrêter brutalement VM DC01
- Démarrer chronomètre

### Étape 3 : Vérifier continuité
- Tester authentification (nouveau login)
- Vérifier accès ressources
- `nltest /dsgetdc:domaine` → doit pointer DC02

### Étape 4 : Mesurer temps
- Arrêter chronomètre quand service OK
- Noter temps de bascule

### Étape 5 : Restaurer
- Redémarrer DC01
- Vérifier resynchronisation

---

## Résultats

| Test | Résultat | Statut |
| --- | --- | --- |
| Temps de bascule | ??? sec | ⬜ |
| Auth pendant panne | ??? | ⬜ |
| Resync après retour | ??? | ⬜ |

---

## Captures d'écran

*À ajouter pendant les tests*
