# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")
New-Item -ItemType Directory -Force -Path "backup" | Out-Null
$ts = Get-Date -Format "yyyy-MM-dd_HHmm"
$out = "backup/ch11_esdata_$ts.tar.gz"
Write-Host ">> Sauvegarde du volume ch11_esdata vers $out"
$pwdPath = (Get-Location).Path
docker run --rm `
  -v ch11_esdata:/vol `
  -v "${pwdPath}\backup:/backup" `
  alpine sh -c "cd /vol && tar czf /backup/ch11_esdata_$ts.tar.gz ."
Get-ChildItem backup
Write-Host "OK : sauvegarde créée."
# Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
