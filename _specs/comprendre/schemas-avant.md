# Schémas réseau AVANT

> Diagrammes de l'architecture actuelle

---

## 1. Architecture globale actuelle

```mermaid
graph TB
    subgraph INTERNET["INTERNET"]
        ISP_LILLE["ISP Lille - Lien capacitaire"]
        ISP_WH1["ISP Lens - 200 Mbps"]
        ISP_WH2["ISP Valenciennes - 200 Mbps"]
        ISP_WH3["ISP Arras - 200 Mbps"]
    end

    subgraph CLOUD["CLOUD MICROSOFT"]
        M365["Microsoft 365"]
        ENTRA["Entra ID"]
    end

    subgraph SIEGE["SIEGE LILLE"]
        FW_SIEGE["FortiGate 80D - EOL proche"]

        subgraph VMS["Dell R630 - SPOF"]
            DC01["DC01"]
            DC02["DC02"]
            WMS["WMS App+DB"]
            IPBX["IPBX"]
        end

        NAS["NAS 6To"]
    end

    subgraph WH1["WH1 LENS"]
        FW_WH1["DrayTek 2860"]
    end

    subgraph WH2["WH2 VALENCIENNES"]
        FW_WH2["DrayTek 2860"]
    end

    subgraph WH3["WH3 ARRAS"]
        FW_WH3["DrayTek 2860"]
    end

    ISP_LILLE --> FW_SIEGE
    ISP_WH1 --> FW_WH1
    ISP_WH2 --> FW_WH2
    ISP_WH3 --> FW_WH3

    FW_SIEGE <-.->|"VPN"| FW_WH1
    FW_SIEGE <-.->|"VPN"| FW_WH2
    FW_SIEGE <-.->|"VPN"| FW_WH3

    FW_SIEGE --> M365
    FW_SIEGE --> ENTRA
```

---

## 2. Plan d'adressage actuel

| Site | Réseau | Passerelle | Serveurs | DHCP |
| --- | --- | --- | --- | --- |
| Siège Lille | 192.168.10.0/24 | .254 | .10-.60 | .100-.200 |
| WH1 Lens | 192.168.20.0/24 | .254 | - | .100-.200 |
| WH2 Valenciennes | 192.168.30.0/24 | .254 | - | .100-.200 |
| WH3 Arras | 192.168.40.0/24 | .254 | - | .100-.200 |
| Cross-dock | 192.168.50.0/24 | .254 | - | .100-.200 |
| **Azure (cible)** | 10.100.0.0/16 | - | - | - |

---

## 3. Flux critiques WMS

```mermaid
flowchart TD
    subgraph ENTREPOTS["ENTREPOTS"]
        RF1["Terminaux RF WH1"]
        RF2["Terminaux RF WH2"]
        RF3["Terminaux RF WH3"]
        IMP["Imprimantes Etiquettes"]
    end

    subgraph VPN_T["TUNNELS VPN"]
        VPN["VPN Site-a-Site - Fragilite"]
    end

    subgraph SIEGE_WMS["SIEGE"]
        APP["WMS-APP - CRITIQUE"]
        DB["WMS-DB - CRITIQUE"]
    end

    RF1 & RF2 & RF3 -->|"Wi-Fi + VPN"| VPN
    VPN -->|"Dependance"| APP
    APP <-->|"SQL"| DB
    APP -->|"Print"| VPN --> IMP
```

---

## 4. Points de défaillance (SPOF)

```mermaid
flowchart TB
    subgraph SPOF["POINTS UNIQUES DE DEFAILLANCE"]
        HV["HYPERVISEUR - Dell R630 - SPOF #1"]
        NAS["STOCKAGE - NAS RAID5 - SPOF #2"]
        WMS["WMS - App + DB - SPOF #3"]
        PBX["IPBX - Telephonie - SPOF #4"]
        FW["PARE-FEU - FortiGate - SPOF #5"]
    end

    HV -->|"Heberge"| WMS & PBX
    NAS -->|"Stocke"| HV
```

---

## 5. Topologie VPN actuelle (Hub & Spoke)

```mermaid
graph TD
    HUB["SIEGE - FortiGate 80D - HUB"]

    SP1["WH1 - DrayTek"]
    SP2["WH2 - DrayTek"]
    SP3["WH3 - DrayTek"]

    HUB <-->|"IPsec - Pas backup"| SP1
    HUB <-->|"IPsec - Pas backup"| SP2
    HUB <-->|"IPsec - Pas backup"| SP3
```

> **Problème** : Pas de communication directe entre entrepôts, tout passe par le siège
