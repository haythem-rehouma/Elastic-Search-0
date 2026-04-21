#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f data/raw.jsonl ]] || { echo "ERREUR : data/raw.jsonl manquant. Lancez 01-prepare.sh d'abord."; exit 1; }

echo ">> Conversion en NDJSON (action _bulk + document)..."
awk '{ print "{\"index\":{\"_index\":\"news\"}}"; print }' data/raw.jsonl > data/news.bulk.ndjson

lines_raw=$(wc -l < data/raw.jsonl)
lines_bulk=$(wc -l < data/news.bulk.ndjson)
echo "   raw       : $lines_raw lignes"
echo "   bulk NDJSON : $lines_bulk lignes (attendu : 2 × $lines_raw)"

echo ">> Découpage en chunks de 5000 lignes..."
mkdir -p data/chunks
rm -f data/chunks/part_*.ndjson
split -l 5000 --numeric-suffixes=1 --additional-suffix=.ndjson \
      data/news.bulk.ndjson data/chunks/part_

ls data/chunks | wc -l | xargs -I{} echo "   chunks créés : {}"
