#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
set -euo pipefail

echo "==> 1. Conteneurs en cours d'execution ?"
docker ps --filter name=p05_ --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "==> 2. Elasticsearch repond ?"
curl -fsS http://localhost:9200 | head -c 400
echo ""

echo ""
echo "==> 3. Sante du cluster"
curl -fsS http://localhost:9200/_cluster/health?pretty

echo ""
echo "==> 4. Liste des indexes systeme"
curl -fsS 'http://localhost:9200/_cat/indices?v'

echo ""
echo "==> 5. Kibana repond ?"
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/api/status)
echo "Kibana /api/status : HTTP $status"

echo ""
echo "==> 6. Test ecriture / lecture"
curl -fsS -X POST 'http://localhost:9200/test_p05/_doc?refresh=true' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Pratique 5 OK"}'
echo ""
curl -fsS 'http://localhost:9200/test_p05/_search?pretty'

echo ""
echo "Tous les checks ont reussi."
echo "Elasticsearch : http://localhost:9200"
echo "Kibana        : http://localhost:5601"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
