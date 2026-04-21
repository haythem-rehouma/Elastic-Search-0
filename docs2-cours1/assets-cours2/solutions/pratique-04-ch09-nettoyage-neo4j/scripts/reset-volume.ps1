# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
$ErrorActionPreference = 'Stop'

Write-Host "Methode 5 (BRUTALE) : reset complet du volume Docker"
Write-Host "  -> arret du conteneur"
Write-Host "  -> destruction du volume p04_neo4j_data"
Write-Host "  -> redemarrage propre"
Write-Host ""
$ans = Read-Host "Confirmer ? (oui/non)"
if ($ans -ne 'oui') {
    Write-Host "Annule."
    exit 0
}

docker compose down -v
docker compose up -d

Write-Host ""
Write-Host "Termine. Base totalement reinitialisee." -ForegroundColor Green
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
