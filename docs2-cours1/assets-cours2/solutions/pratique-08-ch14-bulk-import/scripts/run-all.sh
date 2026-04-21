#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
# Pipeline complet : démarre la stack, prépare, indexe, finalise.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==== 0. docker compose up ===="
docker compose up -d
echo ">> Attente ES healthy..."
for i in {1..40}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch14-es 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then echo "   ES healthy."; break; fi
  sleep 3
done

bash scripts/01-prepare.sh
bash scripts/02-create-index.sh
bash scripts/03-convert-and-split.sh
bash scripts/04-bulk-import.sh
bash scripts/05-finalize.sh

echo
echo "===== Pipeline terminé ====="
echo "Compte attendu : 200853 documents."
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
