#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p backup
docker compose up -d
echo ">> Attente du healthcheck ES (max 90s)..."
for i in {1..30}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch11-es 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then echo "   ES healthy."; break; fi
  sleep 3
done
docker compose ps
curl -s http://localhost:9200 | head -20
echo
echo ">> Kibana sur http://localhost:5601 (peut prendre 30s de plus)"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
