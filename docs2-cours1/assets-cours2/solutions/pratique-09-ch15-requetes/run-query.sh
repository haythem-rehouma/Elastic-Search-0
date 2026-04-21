#!/usr/bin/env bash
# Exécute une requête JSON du dossier queries/ contre l'index news.
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")"

if [[ -z "${1:-}" ]]; then
  echo "Usage : $0 <fichier-de-queries/>"
  echo
  echo "Disponibles :"
  ls queries/
  exit 1
fi

f="queries/$1"
[[ -f "$f" ]] || { echo "Introuvable : $f"; exit 1; }

curl -s -X POST "$ES/news/_search?pretty" \
     -H 'Content-Type: application/json' \
     --data-binary @"$f"
