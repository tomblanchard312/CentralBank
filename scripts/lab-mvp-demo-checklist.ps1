# Windows wrapper for lab MVP demo checklist (prefer WSL for Foundry/cast).
$ErrorActionPreference = "Stop"
$BashScript = Join-Path $PSScriptRoot "lab-mvp-demo-checklist.sh"

function Convert-ToWslPath([string]$WinPath) {
  $full = (Resolve-Path $WinPath).Path
  if ($full -match '^([A-Za-z]):\\(.*)$') {
    $drive = $Matches[1].ToLowerInvariant()
    $rest = $Matches[2] -replace '\\', '/'
    return "/mnt/$drive/$rest"
  }
  throw "Unable to convert path to WSL: $WinPath"
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
  $wslScript = Convert-ToWslPath $BashScript
  wsl -e bash -lc "sed -i 's/\r$//' '$wslScript' && bash '$wslScript'"
  exit $LASTEXITCODE
}

if (-not (Get-Command cast -ErrorAction SilentlyContinue)) {
  throw "Foundry (cast) not found and WSL is unavailable. Install Foundry or enable WSL."
}

& bash $BashScript
exit $LASTEXITCODE
