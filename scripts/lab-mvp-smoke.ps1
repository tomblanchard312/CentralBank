# Reference MVP lab smoke (Windows): prefer WSL for Foundry, else local forge/anvil.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$BashScript = Join-Path $PSScriptRoot "lab-mvp-smoke.sh"

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

if (-not (Get-Command forge -ErrorAction SilentlyContinue)) {
  throw "Foundry (forge) not found and WSL is unavailable. Install Foundry or enable WSL."
}

& bash $BashScript
exit $LASTEXITCODE
