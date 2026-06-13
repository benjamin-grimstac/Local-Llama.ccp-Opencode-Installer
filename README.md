# LOCAL-AI One-Click Installer

This installs a local AI server and OpenCode Desktop on Windows.

You do not need to know GitHub, git, coding, PowerShell, or terminals.

## What You Get

After installing, you will have two shortcuts on your Desktop:

- `Start llama.cpp Server`
- `OpenCode Desktop`

Use them in that order.

## Before You Start

You need:

- A Windows 10 or Windows 11 computer
- An internet connection
- A lot of free disk space because the AI model is large
- An NVIDIA GPU is recommended

This installer downloads a large AI model. It may take a long time.

## Download The Installer From GitHub

1. Open this page in your web browser:

```text
https://github.com/benjamin-grimstac/Local-Llama.ccp-Opencode-Installer
```

2. Look for the green `Code` button near the top of the page.

3. Click the green `Code` button.

4. Click `Download ZIP`.

5. Wait for the ZIP file to download.

It will usually go to your `Downloads` folder.

## Unzip The Download

1. Open your `Downloads` folder.

2. Find the downloaded ZIP file. It will have a name like:

```text
Local-Llama.ccp-Opencode-Installer-main.zip
```

3. Right-click the ZIP file.

4. Click `Extract All...`.

5. Click `Extract`.

Windows will create a normal folder with the installer files inside.

## Run The Installer

1. Open the extracted folder.

2. Find this file:

```text
Install-LOCAL-AI.cmd
```

3. Double-click `Install-LOCAL-AI.cmd`.

4. If Windows asks whether you want to run it, choose `Run` or `More info` then `Run anyway`.

5. Leave the installer window open until it says installation is complete.

The installer may look quiet during large downloads. Do not close it unless it shows an error.

## Start LOCAL-AI

After install, go to your Desktop.

1. Double-click `Start llama.cpp Server`.

2. Wait for the server window to finish loading.

3. Leave that server window open.

4. Double-click `OpenCode Desktop`.

Keep the `Start llama.cpp Server` window open while using OpenCode Desktop.

## What The Installer Does

The installer automatically:

- Creates a `LOCAL-AI` folder on your Desktop
- Downloads `llama.cpp`
- Downloads NVIDIA CUDA support files
- Downloads the Qwen GGUF AI model
- Installs OpenCode Desktop
- Configures OpenCode Desktop to use your local AI server
- Creates the two Desktop shortcuts

## Where Files Are Installed

Everything is installed here:

```text
Desktop\LOCAL-AI
```

Inside that folder, you may see:

```text
Desktop\LOCAL-AI\llama.cpp
Desktop\LOCAL-AI\models
Desktop\LOCAL-AI\downloads
Desktop\LOCAL-AI\runtime
Desktop\LOCAL-AI\logs
Desktop\LOCAL-AI\config
```

You do not need to open or edit these folders.

## If Something Goes Wrong

First, try running the installer again:

```text
Install-LOCAL-AI.cmd
```

It is safe to run it again. It will reuse files that already downloaded and fill in anything missing.

Common causes of problems:

- Your internet connection dropped
- Your computer ran out of disk space
- Windows blocked the installer
- The AI model download was interrupted

The install log is here:

```text
Desktop\LOCAL-AI\logs\install.log
```

## If OpenCode Does Not Respond

Make sure you started the server first.

The correct order is:

1. `Start llama.cpp Server`
2. `OpenCode Desktop`

If you closed the server window, double-click `Start llama.cpp Server` again.

## Uninstall

To remove LOCAL-AI:

1. Delete this folder:

```text
Desktop\LOCAL-AI
```

2. Delete these shortcuts from your Desktop:

- `Start llama.cpp Server`
- `OpenCode Desktop`

3. If you also want to remove OpenCode Desktop, uninstall it from Windows Apps settings.

## Sources

- llama.cpp release: https://github.com/ggml-org/llama.cpp/releases/tag/b9264
- llama.cpp CUDA zip: https://github.com/ggml-org/llama.cpp/releases/download/b9264/llama-b9264-bin-win-cuda-13.1-x64.zip
- CUDA DLL zip: https://github.com/ggml-org/llama.cpp/releases/download/b9264/cudart-llama-bin-win-cuda-13.1-x64.zip
- model repo: https://huggingface.co/LuffyTheFox/Qwen3.6-35B-A3B-Uncensored-Genesis-V2-APEX-MTP-GGUF
- OpenCode Desktop: https://opencode.ai/download/stable/windows-x64-nsis
