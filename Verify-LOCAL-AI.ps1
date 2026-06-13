[CmdletBinding()]
param(
  [string]$BaseUrl = 'http://127.0.0.1:11434'
)

$ErrorActionPreference = 'Stop'

function Get-Json([string]$path) {
  Invoke-RestMethod -Uri ($BaseUrl + $path) -Method Get -TimeoutSec 10
}

$health = Get-Json '/health'
if ($health.status -ne 'ok') { throw "Health check failed: $($health | ConvertTo-Json -Compress)" }
$slots = Get-Json '/slots'
Write-Host '[LOCAL-AI] health:' ($health | ConvertTo-Json -Compress)
Write-Host '[LOCAL-AI] slots:' ($slots | ConvertTo-Json -Compress)
