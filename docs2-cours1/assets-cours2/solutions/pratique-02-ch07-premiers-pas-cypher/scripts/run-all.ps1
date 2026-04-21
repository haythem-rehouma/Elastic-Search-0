# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
$ErrorActionPreference = 'Stop'
$pass = 'Neo4jStrongPass!'

function Run-Cypher($file) {
    Get-Content $file | docker exec -i p02_neo4j cypher-shell -u neo4j -p $pass
}

Write-Host "==> Reset base" -ForegroundColor Cyan
try { Run-Cypher 'cypher/99-reset.cypher' } catch { }

Write-Host ""
Write-Host "==> 1. Creation des noeuds" -ForegroundColor Cyan
Run-Cypher 'cypher/01-create-nodes.cypher'

Write-Host ""
Write-Host "==> 2. Creation des relations" -ForegroundColor Cyan
Run-Cypher 'cypher/02-create-relations.cypher'

Write-Host ""
Write-Host "==> 3. Execution des 8 requetes" -ForegroundColor Cyan
Run-Cypher 'cypher/03-queries.cypher'

Write-Host ""
Write-Host "Termine. Browser : http://localhost:7474" -ForegroundColor Green
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
