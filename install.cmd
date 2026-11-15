@echo off
setlocal
set "SCRIPT=%~dp0install.ps1"
if exist "%SCRIPT%" goto run
set "SCRIPT=%TEMP%\windows-exe-recon-install.ps1"
echo Downloading installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Diero15/windows-exe-recon/main/install.ps1' -OutFile '%SCRIPT%'"
if errorlevel 1 goto failed
:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
if errorlevel 1 goto failed
echo.
echo Done. You can close this window.
pause
exit /b 0
:failed
echo.
echo Installation failed. Review the message above.
pause
exit /b 1
