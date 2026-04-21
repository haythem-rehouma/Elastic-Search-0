# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
# Pipeline Bulk import complet — version PowerShell native (sans WSL).
$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

$ES = if ($env:ES) { $env:ES } else { "http://localhost:9200" }

# 0. docker compose up
Write-Host "==== 0. docker compose up ====" -ForegroundColor Cyan
docker compose up -d
Write-Host ">> Attente ES healthy..."
for ($i = 0; $i -lt 40; $i++) {
  $st = docker inspect -f '{{.State.Health.Status}}' ch14-es 2>$null
  if ($st -eq "healthy") { Write-Host "   ES healthy."; break }
  Start-Sleep -Seconds 3
}

# 1. prepare
Write-Host "==== 1. Préparation ====" -ForegroundColor Cyan
$src = "..\..\News_Category_Dataset_v2.json"
if (-not (Test-Path $src)) { throw "Dataset introuvable : $src" }
New-Item -ItemType Directory -Force -Path "data" | Out-Null
Copy-Item $src "data\raw.jsonl" -Force
$lines = (Get-Content "data\raw.jsonl" | Measure-Object -Line).Lines
Write-Host "   Lignes : $lines (attendu 200853)"

# 2. create index
Write-Host "==== 2. Création de l'index news ====" -ForegroundColor Cyan
try { Invoke-RestMethod -Method Delete "$ES/news" | Out-Null } catch {}
$mapping = Get-Content "mappings\news.mapping.json" -Raw
Invoke-RestMethod -Method Put "$ES/news" -ContentType "application/json" -Body $mapping | ConvertTo-Json -Depth 5

# 3. convert + split
Write-Host "==== 3. Conversion NDJSON + split ====" -ForegroundColor Cyan
$dst = "data\news.bulk.ndjson"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$sw = [System.IO.StreamWriter]::new((Resolve-Path "data").Path + "\news.bulk.ndjson", $false, $utf8NoBom)
$action = '{"index":{"_index":"news"}}'
Get-Content "data\raw.jsonl" | ForEach-Object {
  $sw.WriteLine($action); $sw.WriteLine($_)
}
$sw.Close()
$bulkLines = (Get-Content $dst | Measure-Object -Line).Lines
Write-Host "   NDJSON : $bulkLines lignes"

$chunkDir = "data\chunks"
if (Test-Path $chunkDir) { Remove-Item "$chunkDir\*" -Force }
New-Item -ItemType Directory -Force -Path $chunkDir | Out-Null
$idx = 0; $part = 1; $out = $null
Get-Content $dst | ForEach-Object {
  if ($idx % 5000 -eq 0) {
    if ($out) { $out.Close() }
    $f = Join-Path $chunkDir ("part_{0:D3}.ndjson" -f $part)
    $out = [System.IO.StreamWriter]::new((Resolve-Path $chunkDir).Path + ("\part_{0:D3}.ndjson" -f $part), $false, $utf8NoBom)
    $part++
  }
  $out.WriteLine($_); $idx++
}
$out.Close()
Write-Host "   chunks créés : $($part - 1)"

# 4. bulk import
Write-Host "==== 4. Bulk import ====" -ForegroundColor Cyan
$chunks = Get-ChildItem "$chunkDir\part_*.ndjson"
$total = $chunks.Count; $i = 0; $failed = 0
$start = Get-Date
foreach ($f in $chunks) {
  $i++
  try {
    $resp = Invoke-RestMethod -Method Post `
      -Uri "$ES/_bulk" `
      -ContentType "application/x-ndjson" `
      -InFile $f.FullName
    $err = if ($resp.errors) { "true" } else { "false" }
    Write-Host ("[{0,2}/{1,2}] {2} → errors: {3}" -f $i, $total, $f.Name, $err)
    if ($resp.errors) { $failed++ }
  } catch {
    Write-Host ("[{0,2}/{1,2}] {2} → ECHEC : {3}" -f $i, $total, $f.Name, $_.Exception.Message) -ForegroundColor Red
    $failed++
  }
}
$dur = (Get-Date) - $start
Write-Host (">> Terminé en {0:N0}s. Chunks en erreur : {1} / {2}" -f $dur.TotalSeconds, $failed, $total)

# 5. finalize
Write-Host "==== 5. Finalisation ====" -ForegroundColor Cyan
$post = Get-Content "mappings\news.post-import.json" -Raw
Invoke-RestMethod -Method Put "$ES/news/_settings" -ContentType "application/json" -Body $post | Out-Null
Invoke-RestMethod -Method Post "$ES/news/_refresh" | Out-Null
$count = (Invoke-RestMethod "$ES/news/_count").count
Write-Host ">> Documents indexés : $count (attendu 200853)" -ForegroundColor Green

Write-Host ""
Write-Host "===== Pipeline terminé =====" -ForegroundColor Green
Write-Host "Kibana : http://localhost:5601"
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
