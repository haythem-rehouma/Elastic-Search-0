#!/usr/bin/env bash
# Exécute les 10 requêtes R01..R10 et écrit les sorties dans results/.
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")/.."
mkdir -p results

for q in queries/R*.json; do
  name=$(basename "$q" .json)
  echo
  echo "==== $name ===="
  out="results/${name}.json"
  curl -s -X POST "$ES/news/_search?pretty" \
       -H 'Content-Type: application/json' \
       --data-binary @"$q" | tee "$out" | jq '. | {took, total: .hits.total, hits: (.hits.hits | length), aggs_keys: (.aggregations|keys?)}'
  echo ">> sortie complète : $out"
done

echo
echo "OK : 10 requêtes exécutées. Résultats détaillés dans results/."
