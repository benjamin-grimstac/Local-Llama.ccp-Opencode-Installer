# LOCAL-AI One-Click Installer

This installs a local AI server and OpenCode Desktop on Windows.

## Install

Double-click:

```text
Install-LOCAL-AI.cmd
```

Wait for the installer to finish. The AI model is large, so the download can take a while.

When it is done, two shortcuts will be on your Desktop:

- `Start llama.cpp Server`
- `OpenCode Desktop`

## What It Installs

- `llama.cpp` local AI server
- CUDA support files for NVIDIA GPUs
- Qwen GGUF model
- OpenCode Desktop GUI
- OpenCode settings that point to the local AI server
- Two desktop shortcuts: one for the server and one for OpenCode Desktop

## Requirements

- Windows 10 or Windows 11
- NVIDIA GPU recommended
- Internet connection
- Enough free disk space for the model and llama.cpp files

## Where Files Go

Everything is installed under:

```text
Desktop\LOCAL-AI
```

The installer creates these folders:

```text
Desktop\LOCAL-AI\llama.cpp
Desktop\LOCAL-AI\models
Desktop\LOCAL-AI\downloads
Desktop\LOCAL-AI\runtime
Desktop\LOCAL-AI\logs
Desktop\LOCAL-AI\config
```

## How To Start

After install:

1. Double-click `Start llama.cpp Server`.
2. Wait for the server window to finish loading.
3. Double-click `OpenCode Desktop`.

Keep the server window open while using OpenCode Desktop.

## Extra Launchers

Inside `Desktop\LOCAL-AI` there are also matching launcher files:

- `Start-LLM-Server.cmd` starts only the local AI server.
- `Open-OpenCode.cmd` opens only OpenCode Desktop.

Most people should use the two Desktop shortcuts instead.

## If Something Goes Wrong

Run `Install-LOCAL-AI.cmd` again. It is safe to re-run.

The installer reuses files that already downloaded and fills in anything missing.

Logs are saved here:

```text
Desktop\LOCAL-AI\logs\install.log
```

## Uninstall

Delete this folder:

```text
Desktop\LOCAL-AI
```

Then delete these shortcuts from your Desktop:

- `Start llama.cpp Server`
- `OpenCode Desktop`

If you also want to remove OpenCode Desktop, uninstall it from Windows Apps settings.

## Sources

- llama.cpp release: https://github.com/ggml-org/llama.cpp/releases/tag/b9264
- llama.cpp CUDA zip: https://github.com/ggml-org/llama.cpp/releases/download/b9264/llama-b9264-bin-win-cuda-13.1-x64.zip
- CUDA DLL zip: https://github.com/ggml-org/llama.cpp/releases/download/b9264/cudart-llama-bin-win-cuda-13.1-x64.zip
- model repo: https://huggingface.co/LuffyTheFox/Qwen3.6-35B-A3B-Uncensored-Genesis-V2-APEX-MTP-GGUF
- OpenCode Desktop: https://opencode.ai/download/stable/windows-x64-nsis
