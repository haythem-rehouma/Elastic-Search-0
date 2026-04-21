#!/usr/bin/env bash
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
set -euo pipefail
ES=${ES:-http://localhost:9200}

step () { echo; echo "==== $* ===="; }
req  () { echo "+ $*"; eval "$@"; echo; }

step "1. Infos cluster"
req "curl -s '$ES/' | jq"

step "2. Santé"
req "curl -s '$ES/_cluster/health?pretty'"

step "3. Indices existants"
req "curl -s '$ES/_cat/indices?v'"

step "4. Reset puis recréation de produits avec mapping"
req "curl -s -X DELETE '$ES/produits' >/dev/null; echo deleted"
req "curl -s -X PUT '$ES/produits' -H 'Content-Type: application/json' -d '{
  \"mappings\":{\"properties\":{
    \"nom\":  {\"type\":\"text\"},
    \"prix\": {\"type\":\"float\"},
    \"stock\":{\"type\":\"integer\"}}}}'"

step "5. Insertion de 3 documents (PUT id=1, POST id=2, POST auto-id)"
req "curl -s -X PUT '$ES/produits/_doc/1' -H 'Content-Type: application/json' \
     -d '{\"nom\":\"Casque Bluetooth\",\"prix\":89.90,\"stock\":12}'"
req "curl -s -X POST '$ES/produits/_doc/2' -H 'Content-Type: application/json' \
     -d '{\"nom\":\"Clavier mécanique\",\"prix\":129.00,\"stock\":5}'"
req "curl -s -X POST '$ES/produits/_doc' -H 'Content-Type: application/json' \
     -d '{\"nom\":\"Souris sans fil\",\"prix\":29.90}'"

step "6. Refresh + count"
req "curl -s -X POST '$ES/produits/_refresh' >/dev/null; echo refreshed"
req "curl -s '$ES/produits/_count?pretty'"

step "7. Update partiel (stock du doc 1)"
req "curl -s -X POST '$ES/produits/_update/1' -H 'Content-Type: application/json' \
     -d '{\"doc\":{\"stock\":8}}'"
req "curl -s '$ES/produits/_doc/1?pretty'"

step "8. Recherche full-text"
req "curl -s '$ES/produits/_search?q=nom:casque&pretty'"
req "curl -s '$ES/produits/_search?pretty' -H 'Content-Type: application/json' \
     -d '{\"query\":{\"match\":{\"nom\":\"casque\"}}}'"

step "9. Suppression doc 2 + compte final"
req "curl -s -X DELETE '$ES/produits/_doc/2'"
req "curl -s '$ES/produits/_count?pretty'"

step "10. Cleanup"
req "curl -s -X DELETE '$ES/produits'"
echo
echo ">> OK : démo complète exécutée."
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
