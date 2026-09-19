@echo off
setlocal EnableExtensions
cd /d "%~dp0"
echo Stopping DuckAI2API on port 8080...
set "KILLED=0"
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":8080" ^| findstr "LISTENING"') do (
  taskkill /PID %%a /F >nul 2>&1 && echo Stopped PID=%%a && set "KILLED=1"
)
if "%KILLED%"=="0" echo No process is listening on port 8080.
echo Done.
pause
