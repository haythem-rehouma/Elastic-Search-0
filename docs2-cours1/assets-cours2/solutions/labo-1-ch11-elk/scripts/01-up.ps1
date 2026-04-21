# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")
New-Item -ItemType Directory -Force -Path "backup" | Out-Null
docker compose up -d
Write-Host ">> Attente du healthcheck ES (max 90s)..."
for ($i = 0; $i -lt 30; $i++) {
  $status = docker inspect -f '{{.State.Health.Status}}' ch11-es 2>$null
  if ($status -eq "healthy") { Write-Host "   ES healthy."; break }
  Start-Sleep -Seconds 3
}
docker compose ps
Invoke-RestMethod -Uri 'http://localhost:9200' | Format-List
Write-Host ">> Kibana sur http://localhost:5601 (peut prendre 30s de plus)"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
