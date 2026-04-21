#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SRC_DEFAULT="../../News_Category_Dataset_v2.json"
SRC="${1:-$SRC_DEFAULT}"

if [[ ! -f "$SRC" ]]; then
  echo "ERREUR : dataset introuvable à : $SRC"
  echo "Usage : $0 [chemin/vers/News_Category_Dataset_v2.json]"
  exit 1
fi

mkdir -p data
cp "$SRC" data/raw.jsonl

echo ">> Nettoyage CRLF Windows..."
sed -i 's/\r$//' data/raw.jsonl

lines=$(wc -l < data/raw.jsonl)
echo ">> Lignes : $lines (attendu : 200853)"

echo ">> Aperçu :"
head -n 1 data/raw.jsonl | jq '. | {category, headline, date}' 2>/dev/null || head -n 1 data/raw.jsonl
