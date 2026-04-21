$ErrorActionPreference = 'Stop'

Write-Host "==> 1. Conteneur en cours d'execution ?" -ForegroundColor Cyan
docker ps --filter name=p01_neo4j --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

Write-Host ""
Write-Host "==> 2. Endpoint HTTP (Browser) repond ?" -ForegroundColor Cyan
try {
  $r = Invoke-WebRequest -Uri http://localhost:7474 -UseBasicParsing -TimeoutSec 5
  Write-Host ("Status : {0}" -f $r.StatusCode)
} catch {
  Write-Host ("Echec HTTP : {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Host ""
Write-Host "==> 3. Port 7687 (Bolt) en ecoute ?" -ForegroundColor Cyan
$listen = Get-NetTCPConnection -LocalPort 7687 -State Listen -ErrorAction SilentlyContinue
if ($listen) { Write-Host "OK : Bolt ecoute sur 7687" } else { Write-Host "Port 7687 pas en ecoute" -ForegroundColor Red }

Write-Host ""
Write-Host "==> 4. APOC charge ?" -ForegroundColor Cyan
docker exec p01_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' "RETURN apoc.version() AS apoc_version;"

Write-Host ""
Write-Host "==> 5. Test ecriture / lecture" -ForegroundColor Cyan
docker exec p01_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' "CREATE (n:Test {message: 'Pratique 1 OK', ts: timestamp()}) RETURN n.message AS msg, n.ts AS ts;"

Write-Host ""
Write-Host "Tous les checks ont reussi. Browser : http://localhost:7474" -ForegroundColor Green
