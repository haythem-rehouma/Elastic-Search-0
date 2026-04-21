#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p backup
ts=$(date +%F_%H%M)
out="backup/ch11_esdata_${ts}.tar.gz"

echo ">> Sauvegarde du volume ch11_esdata vers $out"
docker run --rm \
  -v ch11_esdata:/vol \
  -v "$(pwd)/backup":/backup \
  alpine sh -c "cd /vol && tar czf /backup/ch11_esdata_${ts}.tar.gz ."

ls -lh backup/
echo "OK : sauvegarde créée."
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
