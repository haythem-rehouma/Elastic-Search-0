#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
# Pipeline labo2 : up + import + finalize en une commande.
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")/.."

SRC="../../News_Category_Dataset_v2.json"
[[ -f "$SRC" ]] || { echo "Dataset introuvable : $SRC"; exit 1; }

echo "==== 0. docker compose up ===="
docker compose up -d
for i in {1..40}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch17-es 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then echo "   ES healthy."; break; fi
  sleep 3
done

echo "==== 1. Préparation ===="
mkdir -p data
cp "$SRC" data/raw.jsonl
sed -i 's/\r$//' data/raw.jsonl
echo "   Lignes : $(wc -l < data/raw.jsonl)"

echo "==== 2. Création de l'index ===="
curl -s -X DELETE "$ES/news" >/dev/null || true
curl -s -X PUT "$ES/news" \
  -H 'Content-Type: application/json' \
  --data-binary @mappings/news.mapping.json | jq .

echo "==== 3. Conversion + split ===="
awk '{print "{\"index\":{\"_index\":\"news\"}}"; print}' data/raw.jsonl > data/news.bulk.ndjson
mkdir -p data/chunks
rm -f data/chunks/part_*.ndjson
split -l 5000 --numeric-suffixes=1 --additional-suffix=.ndjson \
      data/news.bulk.ndjson data/chunks/part_

echo "==== 4. Bulk import ===="
total=$(ls data/chunks/part_*.ndjson | wc -l); i=0
for f in data/chunks/part_*.ndjson; do
  i=$((i+1))
  err=$(curl -s -H 'Content-Type: application/x-ndjson' \
       -X POST "$ES/_bulk" --data-binary @"$f" | jq -r '.errors')
  printf "[%2d/%2d] %s  →  %s\n" "$i" "$total" "$(basename $f)" "$err"
done

echo "==== 5. Finalisation ===="
curl -s -X PUT "$ES/news/_settings" \
  -H 'Content-Type: application/json' \
  --data-binary @mappings/news.post-import.json | jq .
curl -s -X POST "$ES/news/_refresh" >/dev/null
echo ">> Compte final : $(curl -s "$ES/news/_count" | jq -r .count)"
echo
echo "Lancez ensuite : bash scripts/02-run-all-queries.sh"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
