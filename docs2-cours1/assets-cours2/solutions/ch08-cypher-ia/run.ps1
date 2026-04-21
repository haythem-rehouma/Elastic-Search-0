$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
Get-Content ".env" | ForEach-Object {
  if ($_ -match "^\s*([^#=]+)=(.*)$") { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
}

Write-Host ">> Démarrage du conteneur Neo4j..."
docker compose up -d

Write-Host ">> Attente du healthcheck (max 90s)..."
for ($i = 0; $i -lt 30; $i++) {
  $status = docker inspect -f '{{.State.Health.Status}}' ch08-neo4j 2>$null
  if ($status -eq "healthy") { Write-Host "   Neo4j est healthy."; break }
  Start-Sleep -Seconds 3
}

function Run-Cypher($file) {
  Write-Host ">> Exécution : $file"
  Get-Content "cypher\$file" -Raw | docker exec -i ch08-neo4j cypher-shell -u $env:NEO4J_USER -p $env:NEO4J_PASSWORD
}

Run-Cypher "01-reset.cypher"
Run-Cypher "02-create-cours.cypher"
Run-Cypher "03-create-profs.cypher"
Run-Cypher "04-prealable-collegues.cypher"

Write-Host ">> Vérifications :"
"MATCH (n) RETURN labels(n) AS label, count(n) AS nb;" | docker exec -i ch08-neo4j cypher-shell -u $env:NEO4J_USER -p $env:NEO4J_PASSWORD
"MATCH ()-[r]->() RETURN type(r) AS rel, count(r) AS nb;" | docker exec -i ch08-neo4j cypher-shell -u $env:NEO4J_USER -p $env:NEO4J_PASSWORD

Write-Host ""
Write-Host "  Données chargées. Ouvrez Neo4j Browser : http://localhost:7474"
Write-Host "  Login : $($env:NEO4J_USER) / $($env:NEO4J_PASSWORD)"
Write-Host ""
Write-Host "  Pour les requêtes d'exploration : ouvrez cypher\05-queries.cypher"
Write-Host "  Pour démolir tout : docker compose down -v"
