@echo off
title LOCAL-AI One-Click Installer
echo LOCAL-AI One-Click Installer
echo.
echo This will install a local AI server and OpenCode Desktop.
echo The installer may take a while because the AI model is large.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LOCAL-AI.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if not "%EXITCODE%"=="0" (
  echo Installation did not finish. See the message above for details.
) else (
  echo Installation finished successfully.
)
echo.
pause
exit /b %EXITCODE%
