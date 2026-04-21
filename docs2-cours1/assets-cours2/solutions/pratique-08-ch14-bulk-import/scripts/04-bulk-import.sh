#!/usr/bin/env bash
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")/.."

[[ -d data/chunks ]] || { echo "ERREUR : data/chunks/ vide. Lancez 03-convert-and-split.sh."; exit 1; }

total=$(ls data/chunks/part_*.ndjson | wc -l)
i=0
failed=0
start=$(date +%s)

for f in data/chunks/part_*.ndjson; do
  i=$((i+1))
  resp=$(curl -s -H 'Content-Type: application/x-ndjson' \
        -X POST "$ES/_bulk" \
        --data-binary @"$f")
  err=$(echo "$resp" | jq -r '.errors')
  printf "[%2d/%2d] %s  →  errors: %s\n" "$i" "$total" "$(basename $f)" "$err"
  if [[ "$err" == "true" ]]; then
    failed=$((failed+1))
    echo "$resp" | jq '.items[] | select(.index.error != null) | .index.error' | head -3
  fi
done

end=$(date +%s)
echo ">> Terminé en $((end-start))s. Chunks en erreur : $failed / $total."

curl -s -X POST "$ES/news/_refresh" >/dev/null
echo ">> Compte final :"
curl -s "$ES/news/_count" | jq .
