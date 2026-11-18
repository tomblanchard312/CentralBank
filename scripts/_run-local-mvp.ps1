$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

function Convert-ToWslPath([string]$WinPath) {
  $full = (Resolve-Path $WinPath).Path
  if ($full -match '^([A-Za-z]):\\(.*)$') {
    $drive = $Matches[1].ToLowerInvariant()
    $rest = $Matches[2] -replace '\\', '/'
    return "/mnt/$drive/$rest"
  }
  throw "Unable to convert path to WSL: $WinPath"
}

foreach ($rel in @(
  'scripts\lab-mvp-smoke.sh',
  'scripts\lab-mvp-demo-checklist.sh',
  'scripts\_run-local-mvp.sh'
)) {
  $p = Join-Path $Root $rel
  $t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n" -replace "`r", "`n"
  [IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding $false))
}

$runner = Convert-ToWslPath (Join-Path $Root 'scripts\_run-local-mvp.sh')
wsl -e bash "$runner"
if ($LASTEXITCODE -ne 0) { throw "local MVP runner failed with exit $LASTEXITCODE" }
Write-Host "LOCAL_MVP_OK"
