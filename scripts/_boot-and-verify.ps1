$ErrorActionPreference = "Stop"
$Root = "C:\Users\TomBlanchard\CentralBank"
Set-Location $Root

# LF-normalize bash scripts
Get-ChildItem "$Root\scripts\*.sh" | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName) -replace "`r`n", "`n" -replace "`r", "`n"
  [IO.File]::WriteAllText($_.FullName, $t, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "Booting Anvil via persistent WSL process..."
Get-Process wsl -ErrorAction SilentlyContinue | Out-Null
$anvil = Start-Process -FilePath "wsl.exe" -ArgumentList @(
  "-e", "bash", "-lc",
  "export PATH=/root/.foundry/bin:`$HOME/.foundry/bin:`$PATH; exec anvil --host 0.0.0.0 --port 8545 --chain-id 31337"
) -PassThru -WindowStyle Hidden

$ready = $false
for ($i = 0; $i -lt 40; $i++) {
  try {
    $null = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8545" -ContentType "application/json" -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' -TimeoutSec 2
    $ready = $true
    break
  } catch {
    Start-Sleep -Milliseconds 500
  }
}
if (-not $ready) {
  # Fallback: check from inside WSL
  wsl -e bash -lc "curl -sf -X POST http://127.0.0.1:8545 -H 'content-type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}'"
  if ($LASTEXITCODE -ne 0) { throw "Anvil not ready" }
}

Write-Host "Running smoke..."
wsl -e bash -lc "export PATH=/root/.foundry/bin:`$HOME/.foundry/bin:`$PATH; cd /mnt/c/Users/TomBlanchard/CentralBank; bash scripts/lab-mvp-smoke.sh"
if ($LASTEXITCODE -ne 0) { throw "smoke failed" }

Copy-Item "$Root\api\.env.lab" "$Root\api\.env" -Force
$envLines = Get-Content "$Root\api\.env"
$envLines = $envLines | ForEach-Object {
  if ($_ -match '^ALLOW_DEMO_IDENTITIES=') { 'ALLOW_DEMO_IDENTITIES=true' }
  elseif ($_ -match '^PARAMETERS_FILE=') { "PARAMETERS_FILE=$Root\envs\lab\ecb-core\parameters.json" }
  elseif ($_ -match '^PROFILE_FILE=') { "PROFILE_FILE=$Root\profiles\eurosystem-reference.json" }
  elseif ($_ -match '^BLOCKCHAIN_RPC_URL=') { 'BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545' }
  else { $_ }
}
$envLines | Set-Content "$Root\api\.env"

Write-Host "Starting API..."
$api = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npx.cmd tsx src/index.ts" -WorkingDirectory "$Root\api" -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\centralbank-api.log" -RedirectStandardError "$env:TEMP\centralbank-api.err"

$apiReady = $false
for ($i = 0; $i -lt 90; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:3000/api/v1/health/live" -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -eq 200) { $apiReady = $true; break }
  } catch { Start-Sleep -Seconds 1 }
}
if (-not $apiReady) {
  Get-Content "$env:TEMP\centralbank-api.err" -ErrorAction SilentlyContinue
  Get-Content "$env:TEMP\centralbank-api.log" -ErrorAction SilentlyContinue
  throw "API not live"
}

Write-Host "Walking checklist..."
wsl -e bash -lc "export PATH=/root/.foundry/bin:`$HOME/.foundry/bin:`$PATH; export NODE_BIN='/mnt/c/Program Files/nodejs/node.exe'; cd /mnt/c/Users/TomBlanchard/CentralBank; bash scripts/lab-mvp-demo-checklist.sh"
$code = $LASTEXITCODE

if ($api -and -not $api.HasExited) { Stop-Process -Id $api.Id -Force -ErrorAction SilentlyContinue }
if ($anvil -and -not $anvil.HasExited) { Stop-Process -Id $anvil.Id -Force -ErrorAction SilentlyContinue }

if ($code -ne 0) { throw "checklist failed: $code" }
Write-Host "LOCAL_MVP_OK"
