# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
$ErrorActionPreference = "Stop"
$ES = if ($env:ES) { $env:ES } else { "http://localhost:9200" }

function Step($t)  { Write-Host ""; Write-Host "==== $t ====" -ForegroundColor Cyan }
function Show($r)  { $r | ConvertTo-Json -Depth 8 }

Step "1. Cluster info"
Show (Invoke-RestMethod "$ES/")

Step "2. Santé"
Show (Invoke-RestMethod "$ES/_cluster/health")

Step "3. Reset + recréation produits"
try { Invoke-RestMethod -Method Delete "$ES/produits" | Out-Null } catch {}
Invoke-RestMethod -Method Put "$ES/produits" -ContentType "application/json" -Body (@{
  mappings = @{ properties = @{
    nom   = @{ type = "text" }
    prix  = @{ type = "float" }
    stock = @{ type = "integer" } } }
} | ConvertTo-Json -Depth 5)

Step "5. Insertion 3 documents"
Invoke-RestMethod -Method Put  "$ES/produits/_doc/1" -ContentType "application/json" `
  -Body '{"nom":"Casque Bluetooth","prix":89.90,"stock":12}'
Invoke-RestMethod -Method Post "$ES/produits/_doc/2" -ContentType "application/json" `
  -Body '{"nom":"Clavier mécanique","prix":129.00,"stock":5}'
Invoke-RestMethod -Method Post "$ES/produits/_doc"   -ContentType "application/json" `
  -Body '{"nom":"Souris sans fil","prix":29.90}'

Invoke-RestMethod -Method Post "$ES/produits/_refresh" | Out-Null

Step "6. Count"
Show (Invoke-RestMethod "$ES/produits/_count")

Step "7. Update partiel doc 1"
Invoke-RestMethod -Method Post "$ES/produits/_update/1" -ContentType "application/json" `
  -Body '{"doc":{"stock":8}}'
Show (Invoke-RestMethod "$ES/produits/_doc/1")

Step "8. Recherche full-text 'casque'"
Show (Invoke-RestMethod "$ES/produits/_search?q=nom:casque")

Step "9. Cleanup"
Invoke-RestMethod -Method Delete "$ES/produits/_doc/2" | Out-Null
Show (Invoke-RestMethod "$ES/produits/_count")
Invoke-RestMethod -Method Delete "$ES/produits" | Out-Null

Write-Host ""
Write-Host ">> OK : démo complète exécutée." -ForegroundColor Green
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
