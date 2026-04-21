#!/usr/bin/env bash
# ch08 - Charge automatiquement les fichiers cypher dans Neo4j via cypher-shell
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then cp .env.example .env; fi
source .env

echo ">> Démarrage du conteneur Neo4j..."
docker compose up -d

echo ">> Attente du healthcheck (max 90s)..."
for i in {1..30}; do
  status=$(docker inspect -f '{{.State.Health.Status}}' ch08-neo4j 2>/dev/null || echo starting)
  if [[ "$status" == "healthy" ]]; then echo "   Neo4j est healthy."; break; fi
  sleep 3
done

run_cypher () {
  local f="$1"
  echo ">> Exécution : $f"
  docker exec -i ch08-neo4j cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
      < "cypher/$f"
}

run_cypher 01-reset.cypher
run_cypher 02-create-cours.cypher
run_cypher 03-create-profs.cypher
run_cypher 04-prealable-collegues.cypher

echo ">> Vérifications :"
docker exec -i ch08-neo4j cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
    -- "MATCH (n) RETURN labels(n) AS label, count(n) AS nb;"
docker exec -i ch08-neo4j cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
    -- "MATCH ()-[r]->() RETURN type(r) AS rel, count(r) AS nb;"

cat <<EOF

  Données chargées. Ouvrez Neo4j Browser : http://localhost:7474
  Login : $NEO4J_USER / $NEO4J_PASSWORD

  Pour les requêtes d'exploration : ouvrez cypher/05-queries.cypher
  Pour démolir tout : docker compose down -v
EOF
