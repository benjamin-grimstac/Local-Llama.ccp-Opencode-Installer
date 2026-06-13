[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'LOCAL-AI'),
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$LlamaZipUrl = 'https://github.com/ggml-org/llama.cpp/releases/download/b9264/llama-b9264-bin-win-cuda-13.1-x64.zip'
$CudaZipUrl = 'https://github.com/ggml-org/llama.cpp/releases/download/b9264/cudart-llama-bin-win-cuda-13.1-x64.zip'
$OpenCodeUrl = 'https://opencode.ai/download/stable/windows-x64-nsis'
$ModelFileName = 'Qwen3.6-35B-A3B-Uncensored-Genesis-MTP-APEX-Compact.gguf'
$ModelUrl = "https://huggingface.co/LuffyTheFox/Qwen3.6-35B-A3B-Uncensored-Genesis-V2-APEX-MTP-GGUF/resolve/main/$ModelFileName?download=true"

$Root = $InstallRoot
$Downloads = Join-Path $Root 'downloads'
$Runtime = Join-Path $Root 'runtime'
$Logs = Join-Path $Root 'logs'
$Config = Join-Path $Root 'config'
$LlamaDir = Join-Path $Root 'llama.cpp'
$ModelsDir = Join-Path $Root 'models'
$OpenCodeDir = Join-Path $Root 'OpenCode'
$OpenCodeConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$LogFile = Join-Path $Logs 'install.log'

$LlamaZip = Join-Path $Downloads 'llama.cpp-windows-cuda.zip'
$CudaZip = Join-Path $Downloads 'llama.cpp-cuda-runtime.zip'
$OpenCodeInstaller = Join-Path $Downloads 'opencode-desktop-installer.exe'
$ModelPath = Join-Path $ModelsDir $ModelFileName
$ServerExe = Join-Path $LlamaDir 'llama-server.exe'

function Write-Line([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::White) {
  Write-Host $Message -ForegroundColor $Color
}

function Write-Step([int]$Number, [int]$Total, [string]$Message) {
  Write-Line ""
  Write-Line "Step $Number of ${Total}: $Message" Cyan
}

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Log([string]$Message) {
  Ensure-Dir $Logs
  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Add-Content -LiteralPath $LogFile -Value "[$stamp] $Message"
}

function Fail-Friendly([string]$FriendlyMessage, [string]$Details) {
  Write-Log "ERROR: $Details"
  Write-Line ""
  Write-Line "Installation could not finish." Red
  Write-Line $FriendlyMessage Yellow
  Write-Line ""
  Write-Line "Details were saved here:" Gray
  Write-Line $LogFile Gray
  exit 1
}

function Download-File([string]$Url, [string]$Destination, [string]$Label) {
  Ensure-Dir (Split-Path -Parent $Destination)

  if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
    Write-Line "Already downloaded: $Label" DarkGray
    Write-Log "Reusing $Label at $Destination"
    return
  }

  $Temp = "$Destination.download"
  if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Force }

  Write-Line "Downloading $Label..."
  Write-Log "Downloading $Label from $Url"
  & curl.exe -L -A 'Mozilla/5.0' --retry 5 --retry-all-errors --fail --output $Temp $Url
  if ($LASTEXITCODE -ne 0) {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Force }
    throw "Download failed for $Label"
  }

  Move-Item -LiteralPath $Temp -Destination $Destination -Force
  Write-Log "Downloaded $Label to $Destination"
}

function Expand-ZipInto([string]$ZipPath, [string]$Destination, [string]$Label) {
  if (-not (Test-Path -LiteralPath $ZipPath)) { throw "$Label zip is missing: $ZipPath" }
  Ensure-Dir $Destination
  Write-Line "Extracting $Label..."
  Write-Log "Extracting $ZipPath to $Destination"
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $Destination -Force
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  Ensure-Dir (Split-Path -Parent $Path)
  $Encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function New-Shortcut([string]$ShortcutPath, [string]$TargetPath, [string]$Arguments, [string]$WorkingDirectory, [string]$Description) {
  $Shell = New-Object -ComObject WScript.Shell
  $Shortcut = $Shell.CreateShortcut($ShortcutPath)
  $Shortcut.TargetPath = $TargetPath
  $Shortcut.Arguments = $Arguments
  $Shortcut.WorkingDirectory = $WorkingDirectory
  $Shortcut.Description = $Description
  $Shortcut.IconLocation = "$TargetPath,0"
  $Shortcut.Save()
}

function Find-OpenCodeExe {
  $Candidates = @(
    (Join-Path $OpenCodeDir 'OpenCode.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\OpenCode\OpenCode.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\opencode\OpenCode.exe'),
    (Join-Path $env:LOCALAPPDATA 'OpenCode\OpenCode.exe'),
    (Join-Path $env:ProgramFiles 'OpenCode\OpenCode.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'OpenCode\OpenCode.exe')
  )

  $Direct = $Candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
  if ($Direct) { return $Direct }

  if (Test-Path -LiteralPath $OpenCodeDir) {
    $Found = Get-ChildItem -LiteralPath $OpenCodeDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match 'OpenCode' } |
      Select-Object -First 1
    if ($Found) { return $Found.FullName }
  }

  return $null
}

function Backup-IfExists([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    $BackupDir = Join-Path $Root 'backups'
    Ensure-Dir $BackupDir
    $Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $Leaf = Split-Path -Leaf $Path
    Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupDir "$Leaf.$Stamp.bak") -Force
  }
}

try {
  Clear-Host
  Write-Line 'LOCAL-AI One-Click Installer' Green
  Write-Line 'This will install a local AI server and OpenCode Desktop.' Gray
  Write-Line "Install location: $Root" Gray
  Write-Log 'Installer started'

  Write-Step 1 7 'Preparing folders'
  foreach ($Dir in @($Root, $Downloads, $Runtime, $Logs, $Config, $LlamaDir, $ModelsDir, $OpenCodeDir)) {
    Ensure-Dir $Dir
  }

  Write-Step 2 7 'Downloading the local AI server'
  Download-File -Url $LlamaZipUrl -Destination $LlamaZip -Label 'llama.cpp server'
  Download-File -Url $CudaZipUrl -Destination $CudaZip -Label 'CUDA support files'

  Write-Step 3 7 'Installing the local AI server'
  if ($Force -and (Test-Path -LiteralPath $LlamaDir)) {
    Remove-Item -LiteralPath $LlamaDir -Recurse -Force
    Ensure-Dir $LlamaDir
  }
  Expand-ZipInto -ZipPath $LlamaZip -Destination $LlamaDir -Label 'llama.cpp server'
  Expand-ZipInto -ZipPath $CudaZip -Destination $LlamaDir -Label 'CUDA support files'
  if (-not (Test-Path -LiteralPath $ServerExe)) {
    Fail-Friendly 'The local AI server was downloaded, but Windows could not find llama-server.exe after extraction. Please run the installer again.' "Missing $ServerExe"
  }

  Write-Step 4 7 'Downloading the AI model'
  Download-File -Url $ModelUrl -Destination $ModelPath -Label 'AI model'
  if (-not (Test-Path -LiteralPath $ModelPath)) {
    Fail-Friendly 'The AI model could not be downloaded. Check your internet connection and run the installer again.' "Missing $ModelPath"
  }

  Write-Step 5 7 'Installing OpenCode Desktop'
  Download-File -Url $OpenCodeUrl -Destination $OpenCodeInstaller -Label 'OpenCode Desktop'
  Write-Line 'Installing OpenCode Desktop...'
  Write-Log "Running OpenCode installer: $OpenCodeInstaller"
  Start-Process -FilePath $OpenCodeInstaller -ArgumentList @('/S', "/D=$OpenCodeDir") -Wait
  $OpenCodeExe = Find-OpenCodeExe
  if (-not $OpenCodeExe) {
    Fail-Friendly 'OpenCode Desktop installed, but the launcher could not find it. Please run the installer again.' 'OpenCode executable not found'
  }
  Write-Log "OpenCode executable found at $OpenCodeExe"

  Write-Step 6 7 'Creating launchers and settings'
  $LocalOpenCodeConfigDir = Join-Path $Config 'opencode'
  Ensure-Dir $LocalOpenCodeConfigDir
  Ensure-Dir $OpenCodeConfigDir

  $OpenCodeConfig = @"
{
  "`$schema": "https://opencode.ai/config.json",
  "provider": {
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LOCAL-AI llama.cpp",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "qwen-local": {
          "name": "LOCAL-AI Qwen",
          "limit": {
            "context": 100000,
            "output": 8192
          }
        }
      }
    }
  },
  "model": "llamacpp/qwen-local",
  "small_model": "llamacpp/qwen-local"
}
"@

  Write-Utf8NoBom (Join-Path $LocalOpenCodeConfigDir 'opencode.json') $OpenCodeConfig
  Backup-IfExists (Join-Path $OpenCodeConfigDir 'opencode.json')
  Write-Utf8NoBom (Join-Path $OpenCodeConfigDir 'opencode.json') $OpenCodeConfig

  $ServerLauncher = Join-Path $Runtime 'Start-LLM-Server.ps1'
  $OpenCodeLauncher = Join-Path $Runtime 'Open-OpenCode.ps1'
  $ServerCmd = Join-Path $Root 'Start-LLM-Server.cmd'
  $OpenCodeCmd = Join-Path $Root 'Open-OpenCode.cmd'

  $ServerScript = @"
[CmdletBinding()]
param()

`$ErrorActionPreference = 'Stop'
Remove-Item Env:\LLAMA_CHAT_TEMPLATE_KWARGS -ErrorAction SilentlyContinue
Remove-Item Env:\LLAMA_ARG_CHAT_TEMPLATE_KWARGS -ErrorAction SilentlyContinue

`$Root = Split-Path -Parent (Split-Path -Parent `$MyInvocation.MyCommand.Path)
`$ServerExe = Join-Path `$Root 'llama.cpp\llama-server.exe'
`$ModelPath = Join-Path `$Root 'models\$ModelFileName'
`$ServerDir = Split-Path -Parent `$ServerExe

if (-not (Test-Path -LiteralPath `$ServerExe)) { throw "The local AI server is missing. Run Install-LOCAL-AI.cmd again." }
if (-not (Test-Path -LiteralPath `$ModelPath)) { throw "The AI model is missing. Run Install-LOCAL-AI.cmd again." }

Set-Location `$ServerDir
& `$ServerExe ``
  -m `$ModelPath ``
  --host 127.0.0.1 ``
  --port 11434 ``
  --timeout 3600 ``
  --ctx-size 100000 ``
  --parallel 1 ``
  --n-gpu-layers auto ``
  --n-cpu-moe 34 ``
  --fit off ``
  --flash-attn on ``
  --threads 16 ``
  --threads-batch 16 ``
  --batch-size 512 ``
  --ubatch-size 512 ``
  --cache-type-k q4_0 ``
  --cache-type-v q4_0 ``
  --kv-unified ``
  --cache-idle-slots ``
  --cache-ram 8192 ``
  --temp 0.35 ``
  --top-p 0.9 ``
  --top-k 20 ``
  --min-p 0.00 ``
  --repeat-penalty 1.05 ``
  --presence-penalty 0.3 ``
  --reasoning off ``
  --jinja ``
  --no-mmap ``
  --no-warmup ``
  --perf
"@
  Write-Utf8NoBom $ServerLauncher $ServerScript

  $OpenCodeScript = @"
[CmdletBinding()]
param()

`$ErrorActionPreference = 'Stop'
`$Root = Split-Path -Parent (Split-Path -Parent `$MyInvocation.MyCommand.Path)
`$Candidates = @(
  '$($OpenCodeExe.Replace("'", "''"))',
  (Join-Path `$Root 'OpenCode\OpenCode.exe'),
  (Join-Path `$env:LOCALAPPDATA 'Programs\OpenCode\OpenCode.exe'),
  (Join-Path `$env:LOCALAPPDATA 'Programs\opencode\OpenCode.exe')
)
`$OpenCodeExe = `$Candidates | Where-Object { `$_ -and (Test-Path -LiteralPath `$_) } | Select-Object -First 1
if (-not `$OpenCodeExe) { throw 'OpenCode Desktop could not be found. Run Install-LOCAL-AI.cmd again.' }
Start-Process -FilePath `$OpenCodeExe -WorkingDirectory (Split-Path -Parent `$OpenCodeExe)
"@
  Write-Utf8NoBom $OpenCodeLauncher $OpenCodeScript

  Write-Utf8NoBom $ServerCmd "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0runtime\Start-LLM-Server.ps1`"`r`npause`r`n"
  Write-Utf8NoBom $OpenCodeCmd "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0runtime\Open-OpenCode.ps1`"`r`n"

  $Desktop = [Environment]::GetFolderPath('Desktop')
  foreach ($OldPath in @(
    (Join-Path $Desktop 'LOCAL-AI.lnk'),
    (Join-Path $Root 'Start-LOCAL-AI.cmd'),
    (Join-Path $Runtime 'Start-LOCAL-AI.ps1'),
    (Join-Path $Runtime 'Start-LOCAL-AI-All.ps1')
  )) {
    if (Test-Path -LiteralPath $OldPath) { Remove-Item -LiteralPath $OldPath -Force }
  }

  $ServerShortcut = Join-Path $Desktop 'Start llama.cpp Server.lnk'
  $OpenCodeShortcut = Join-Path $Desktop 'OpenCode Desktop.lnk'
  New-Shortcut -ShortcutPath $ServerShortcut -TargetPath $ServerCmd -Arguments '' -WorkingDirectory $Root -Description 'Start the local llama.cpp AI server'
  New-Shortcut -ShortcutPath $OpenCodeShortcut -TargetPath $OpenCodeCmd -Arguments '' -WorkingDirectory $Root -Description 'Open OpenCode Desktop'

  Write-Step 7 7 'Checking the install'
  foreach ($Required in @($ServerExe, $ModelPath, $OpenCodeExe, $ServerCmd, $OpenCodeCmd)) {
    if (-not (Test-Path -LiteralPath $Required)) { throw "Missing required file: $Required" }
  }

  Write-Log 'Installer finished successfully'
  Write-Line ""
  Write-Line 'Installation complete.' Green
  Write-Line 'Two shortcuts were added to your Desktop:' White
  Write-Line '1. Start llama.cpp Server' White
  Write-Line '2. OpenCode Desktop' White
  Write-Line 'Start the server first, then open OpenCode Desktop.' White
  Write-Line "Installed at: $Root" Gray
  Write-Line ""
  Write-Line 'You can close this window.' Gray
  exit 0
} catch {
  Fail-Friendly 'Something went wrong. Check your internet connection, make sure you have enough disk space, and run Install-LOCAL-AI.cmd again.' $_.Exception.Message
}
