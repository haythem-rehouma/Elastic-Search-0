#!/usr/bin/env bash
set -euo pipefail

echo "==> 1. Conteneur en cours d'execution ?"
docker ps --filter name=p01_neo4j --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "==> 2. Endpoint HTTP (Browser) repond ?"
curl -fsS http://localhost:7474 | head -c 200 && echo ""

echo ""
echo "==> 3. Endpoint Bolt (port 7687) en ecoute ?"
if command -v ss >/dev/null 2>&1; then
  ss -tuln | grep 7687 || echo "(port pas en ecoute)"
elif command -v netstat >/dev/null 2>&1; then
  netstat -an | grep 7687 || echo "(port pas en ecoute)"
fi

echo ""
echo "==> 4. APOC charge ?"
docker exec p01_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' \
  "RETURN apoc.version() AS apoc_version;"

echo ""
echo "==> 5. Test ecriture / lecture"
docker exec p01_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' \
  "CREATE (n:Test {message: 'Pratique 1 OK', ts: timestamp()}) RETURN n.message AS msg, n.ts AS ts;"

echo ""
echo "Tous les checks ont reussi. Browser accessible sur http://localhost:7474"
