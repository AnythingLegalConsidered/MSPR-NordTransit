-- Schema WMS NordTransit — base de test pour validation POC
-- Idempotent : peut etre relance sans erreur

CREATE DATABASE IF NOT EXISTS wms_test;
USE wms_test;

CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    warehouse VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert seulement si la table est vide (evite les doublons)
INSERT INTO inventory (product_name, quantity, warehouse)
SELECT * FROM (
    SELECT 'Colis Standard A' AS product_name, 150 AS quantity, 'WH1-Lens' AS warehouse
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM inventory LIMIT 1);

INSERT INTO inventory (product_name, quantity, warehouse)
SELECT 'Colis Standard B', 230, 'WH2-Valenciennes'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inventory WHERE product_name = 'Colis Standard B');

INSERT INTO inventory (product_name, quantity, warehouse)
SELECT 'Palette Export', 45, 'WH3-Arras'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inventory WHERE product_name = 'Palette Export');

INSERT INTO inventory (product_name, quantity, warehouse)
SELECT 'Colis Express', 89, 'Siege-Lille'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inventory WHERE product_name = 'Colis Express');

INSERT INTO inventory (product_name, quantity, warehouse)
SELECT 'Palette Vrac', 12, 'CrossDock'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inventory WHERE product_name = 'Palette Vrac');
