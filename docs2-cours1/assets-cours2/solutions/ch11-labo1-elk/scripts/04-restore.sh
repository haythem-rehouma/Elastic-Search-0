#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${1:-}" ]]; then
  echo "Usage : $0 <fichier_backup.tar.gz>"
  ls -lh backup/ 2>/dev/null || echo "  (aucun backup trouvé)"
  exit 1
fi
file="$1"
[[ -f "$file" ]] || { echo "Fichier introuvable : $file"; exit 1; }

echo ">> Arrêt des services..."
docker compose down

echo ">> Vidage du volume ch11_esdata..."
docker run --rm -v ch11_esdata:/vol alpine sh -c "rm -rf /vol/* /vol/.[!.]* /vol/..?* 2>/dev/null || true"

echo ">> Restauration depuis $file..."
docker run --rm \
  -v ch11_esdata:/vol \
  -v "$(pwd)":/host \
  alpine sh -c "cd /vol && tar xzf /host/$file"

echo ">> Redémarrage..."
docker compose up -d
for i in {1..30}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch11-es 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then break; fi
  sleep 3
done
echo "OK : restauration terminée. Vérifier : curl -s 'http://localhost:9200/_cat/indices?v'"
