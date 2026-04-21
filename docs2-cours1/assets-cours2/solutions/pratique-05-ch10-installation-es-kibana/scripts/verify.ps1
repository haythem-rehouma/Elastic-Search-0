$ErrorActionPreference = 'Continue'

Write-Host "==> 1. Conteneurs en cours d'execution ?" -ForegroundColor Cyan
docker ps --filter name=p05_ --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

Write-Host ""
Write-Host "==> 2. Elasticsearch repond ?" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri http://localhost:9200 -TimeoutSec 5
    $r | ConvertTo-Json -Depth 5 | Out-String | Write-Host
} catch {
    Write-Host "ECHEC : $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==> 3. Sante du cluster" -ForegroundColor Cyan
Invoke-RestMethod -Uri http://localhost:9200/_cluster/health | ConvertTo-Json | Write-Host

Write-Host ""
Write-Host "==> 4. Liste des indexes" -ForegroundColor Cyan
(Invoke-WebRequest -Uri 'http://localhost:9200/_cat/indices?v' -UseBasicParsing).Content

Write-Host ""
Write-Host "==> 5. Kibana repond ?" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri http://localhost:5601/api/status -UseBasicParsing -TimeoutSec 5
    Write-Host ("Kibana /api/status : HTTP {0}" -f $r.StatusCode)
} catch {
    Write-Host ("Kibana pas encore pret : {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==> 6. Test ecriture / lecture" -ForegroundColor Cyan
$body = '{"message":"Pratique 5 OK"}'
Invoke-RestMethod -Method Post -Uri 'http://localhost:9200/test_p05/_doc?refresh=true' -ContentType 'application/json' -Body $body | ConvertTo-Json | Write-Host
Invoke-RestMethod -Uri 'http://localhost:9200/test_p05/_search' | ConvertTo-Json -Depth 5 | Write-Host

Write-Host ""
Write-Host "Tous les checks ont reussi." -ForegroundColor Green
Write-Host "Elasticsearch : http://localhost:9200"
Write-Host "Kibana        : http://localhost:5601"
