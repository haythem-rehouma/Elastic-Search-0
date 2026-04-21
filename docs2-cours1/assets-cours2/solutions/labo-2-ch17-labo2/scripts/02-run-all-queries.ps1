$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")
$ES = if ($env:ES) { $env:ES } else { "http://localhost:9200" }

New-Item -ItemType Directory -Force -Path "results" | Out-Null

Get-ChildItem "queries\R*.json" | Sort-Object Name | ForEach-Object {
  $name = $_.BaseName
  Write-Host ""
  Write-Host "==== $name ====" -ForegroundColor Cyan
  $body = Get-Content $_.FullName -Raw
  $resp = Invoke-RestMethod -Method Post `
            -Uri "$ES/news/_search" `
            -ContentType "application/json" `
            -Body $body
  $out = "results\$name.json"
  $resp | ConvertTo-Json -Depth 20 | Out-File $out -Encoding utf8

  $hits  = if ($resp.hits.hits) { $resp.hits.hits.Count } else { 0 }
  $total = if ($resp.hits.total) { $resp.hits.total.value } else { 0 }
  Write-Host "  took=$($resp.took)ms  total=$total  hits_returned=$hits"
  Write-Host "  >> $out"
}

Write-Host ""
Write-Host "OK : 10 requêtes exécutées. Résultats dans results\." -ForegroundColor Green
