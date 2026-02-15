---
title: "WMS - Simulation sur Ubuntu"
phase: "03-lab-poc"
author: "Equipe NordTransit"
date: 2026-02-06
prerequis:
  - "Guide 03-active-directory.md complete (DNS fonctionnel)"
  - "VM WMS (32020) installee avec Ubuntu 22.04"
---

# WMS - Simulation sur Ubuntu

## Objectif

> Deployer une simulation du WMS (Warehouse Management System) sur Ubuntu avec MySQL.
> On simule la base de donnees d'inventaire pour tester le failover et la disponibilite.

## Prerequis

- [ ] VM WMS (32020) avec Ubuntu 22.04 installe (guide 01, etape 2c)
- [ ] IP statique configuree : 172.16.132.20 (guide 01, etape 3b)
- [ ] DNS pointe vers DC01 (172.16.132.10)
- [ ] Utilisateur : `wmsadmin` (cree pendant l'installation Ubuntu)

## Etapes

### 1. Mettre a jour le systeme

**Pourquoi** : Partir d'un systeme a jour evite les problemes de dependances.

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Installer MySQL Server

**Pourquoi** : Le WMS reel utilise une base de donnees. MySQL simule cette base.

```bash
sudo apt install mysql-server iperf3 -y
sudo systemctl enable mysql
sudo systemctl start mysql
```

> **Note** : iperf3 est installe ici car il sera necessaire pour les tests QoS (guide 04 et 07).

### 3. Creer la base de donnees WMS

**Pourquoi** : Des donnees de test permettent de verifier l'integrite apres un failover.

```bash
sudo mysql <<'EOF'
CREATE DATABASE wms_test;
USE wms_test;

CREATE TABLE inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    warehouse VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO inventory (product_name, quantity, warehouse) VALUES
    ('Colis Standard A', 150, 'WH1-Lens'),
    ('Colis Standard B', 230, 'WH2-Valenciennes'),
    ('Palette Export', 45, 'WH3-Arras'),
    ('Colis Express', 89, 'Siege-Lille'),
    ('Palette Vrac', 12, 'CrossDock');

SELECT * FROM inventory;
EOF
```

**Resultat attendu** : 5 lignes affichees dans la table inventory.

### 4. Creer un script de verification

**Pourquoi** : Apres un failover, on lance ce script pour verifier que les donnees sont intactes.

```bash
cat > /home/wmsadmin/check_wms.sh << 'SCRIPT'
#!/bin/bash
# Check WMS database integrity
echo "=== WMS Health Check ==="
echo "Date: $(date)"
echo ""

# Check MySQL service
if systemctl is-active --quiet mysql; then
    echo "[OK] MySQL service running"
else
    echo "[FAIL] MySQL service down"
    exit 1
fi

# Check database
COUNT=$(mysql -u root -e "SELECT COUNT(*) FROM wms_test.inventory;" -sN 2>/dev/null)
if [ "$COUNT" -ge 5 ]; then
    echo "[OK] Database OK - $COUNT records found"
else
    echo "[FAIL] Database issue - expected >= 5 records, got $COUNT"
    exit 1
fi

# Show data
mysql -u root -e "SELECT * FROM wms_test.inventory;" 2>/dev/null
echo ""
echo "=== Check complete ==="
SCRIPT
chmod +x /home/wmsadmin/check_wms.sh
```

### 5. Tester

```bash
/home/wmsadmin/check_wms.sh
```

**Resultat attendu** : MySQL running, 5 records, donnees affichees.

## Verification

| Test | Commande | Resultat attendu |
|------|----------|-------------------|
| MySQL actif | `systemctl status mysql` | Active (running) |
| BDD existe | `mysql -e "SHOW DATABASES;"` | wms_test presente |
| Donnees OK | `/home/wmsadmin/check_wms.sh` | 5 records, OK |
| Connectivite | `ping 172.16.132.10` | DC01 joignable |

## Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| MySQL n'installe pas | Repo manquant | `sudo apt update` puis reessayer |
| Acces refuse a MySQL | Auth socket | `sudo mysql` (pas besoin de mdp en root local) |
| Script echoue | Permissions | `chmod +x check_wms.sh` |

## Liens

- Spec de reference : `_specs/poc/guide-lab.md`
- Guide precedent : `docs/03-lab-poc/05-azure-tunnel.md`
- Guide suivant : `docs/03-lab-poc/07-tests-validation.md`
