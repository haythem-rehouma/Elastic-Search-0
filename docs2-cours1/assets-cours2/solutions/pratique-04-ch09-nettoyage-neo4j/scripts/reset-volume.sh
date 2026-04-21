#!/usr/bin/env bash
set -euo pipefail

echo "Methode 5 (BRUTALE) : reset complet du volume Docker"
echo "  -> arret du conteneur"
echo "  -> destruction du volume p04_neo4j_data"
echo "  -> redemarrage propre"
echo ""
read -p "Confirmer ? (oui/non) : " ans
if [ "$ans" != "oui" ]; then
  echo "Annule."
  exit 0
fi

docker compose down -v
docker compose up -d

echo ""
echo "Termine. Base totalement reinitialisee."
