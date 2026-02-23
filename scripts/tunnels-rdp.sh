#!/bin/bash
# ============================================================
#  Tunnels SSH pour RDP vers les Windows du lab
#  Lancer depuis le PC bureau (via AnyDesk)
#
#  Apres lancement :
#    mstsc /v:localhost:13389   → DC01
#    mstsc /v:localhost:13390   → DC02
#    mstsc /v:localhost:13391   → DC-AZURE
#
#  Login : Administrator / az4826QS6284**
# ============================================================

echo "Ouverture des tunnels RDP vers pve02..."
echo ""
echo "  localhost:13389  →  DC01     (172.16.132.10)"
echo "  localhost:13390  →  DC02     (172.16.132.11)"
echo "  localhost:13391  →  DC-AZURE (10.100.0.10)"
echo ""
echo "Utilisez mstsc (Bureau a distance) pour vous connecter."
echo "Ctrl+C pour fermer les tunnels."
echo ""

ssh -N \
    -L 13389:172.16.132.10:3389 \
    -L 13390:172.16.132.11:3389 \
    -L 13391:10.100.0.10:3389 \
    pve02
