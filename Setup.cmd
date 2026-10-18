@echo off
setlocal
cd /d "%~dp0"
echo Ultrakill Craft setup
echo Install both games and sign in to the official Minecraft Launcher first.
echo Close both games and the launcher before continuing.
echo.
rem Execution policy applies only to this process; no Windows policy is changed.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" %*
set "setupExit=%errorlevel%"
if not "%setupExit%"=="0" (
  echo.
  echo Setup did not finish. Read the error above, fix it, and run this file again.
)
echo.
pause
endlocal & exit /b %setupExit%
