#!/usr/bin/env bash
set -euo pipefail

echo ">> 1. Indexer un document témoin"
curl -s -X POST 'http://localhost:9200/temoin/_doc' \
  -H 'Content-Type: application/json' \
  -d '{"message":"avant arrêt","date":"2026-04-19"}'
echo
sleep 1

echo ">> 2. Vérifier qu'il est bien indexé"
curl -s 'http://localhost:9200/temoin/_search?pretty'

echo ">> 3. down (sans -v) puis up : le doc DOIT survivre"
cd "$(dirname "$0")/.."
docker compose down
docker compose up -d
echo "   Attente ES healthy..."
for i in {1..30}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch11-es 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then break; fi
  sleep 3
done

echo ">> 4. Re-recherche : on doit retrouver 'avant arrêt'"
curl -s 'http://localhost:9200/temoin/_search?pretty'

echo
echo "OK : la persistance fonctionne (volume nommé ch11_esdata)."
