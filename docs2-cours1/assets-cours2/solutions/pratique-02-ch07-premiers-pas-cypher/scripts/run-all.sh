#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
set -euo pipefail

PASS='Neo4jStrongPass!'
RUN="docker exec -i p02_neo4j cypher-shell -u neo4j -p $PASS"

echo "==> Reset base"
$RUN < cypher/99-reset.cypher || true

echo ""
echo "==> 1. Creation des noeuds"
$RUN < cypher/01-create-nodes.cypher

echo ""
echo "==> 2. Creation des relations"
$RUN < cypher/02-create-relations.cypher

echo ""
echo "==> 3. Execution des 8 requetes"
$RUN < cypher/03-queries.cypher

echo ""
echo "Termine. Browser : http://localhost:7474"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
