#!/usr/bin/env bash
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")/.."

echo ">> Réactivation : replicas=1, refresh=1s..."
curl -s -X PUT "$ES/news/_settings" \
  -H 'Content-Type: application/json' \
  --data-binary @mappings/news.post-import.json | jq .

echo ">> Refresh forcé..."
curl -s -X POST "$ES/news/_refresh" >/dev/null

echo ">> Vérifications de cohérence :"
echo "  Compte total :"
curl -s "$ES/news/_count" | jq .

echo "  Top 5 catégories :"
curl -s "$ES/news/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"by_category":{"terms":{"field":"category.keyword","size":5}}}}' \
  | jq '.aggregations.by_category.buckets'

echo "  Plage de dates :"
curl -s "$ES/news/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"min_d":{"min":{"field":"date"}},"max_d":{"max":{"field":"date"}}}}' \
  | jq '.aggregations'

echo
echo ">> OK. Index 'news' opérationnel sur $ES"
echo ">> Kibana : http://localhost:5601"
