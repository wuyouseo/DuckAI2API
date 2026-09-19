@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PY="
if exist "C:\Users\Win11\.workbuddy\binaries\python\versions\3.13.12\python.exe" set "PY=C:\Users\Win11\.workbuddy\binaries\python\versions\3.13.12\python.exe"
if not defined PY ( where py >nul 2>&1 && set "PY=py" )
if not defined PY set "PY=python"

set "RUNNING=0"
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":8080" ^| findstr "LISTENING"') do set "RUNNING=1"
if "%RUNNING%"=="1" (
  echo DuckAI2API is already running on port 8080.
  echo Open: http://localhost:8080/v1/models
  echo To restart, run stop.bat first, then start.bat.
  pause
  goto :eof
)

if not exist ".venv\Scripts\python.exe" (
  echo Creating venv and installing dependencies...
  "%PY%" -m venv .venv
  call .venv\Scripts\activate.bat
  python -m pip install -r requirements.txt
) else (
  echo venv exists, skip install.
)

if not exist ".env" (
  copy example.env .env >nul
  echo Created .env (open access, no API key needed)
) else (
  echo .env exists, skip.
)

echo Starting uvicorn on port 8080...
start "" /MIN cmd /c ".venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8080 > server.log 2>&1"
echo.
echo ============================================
echo  Service started (minimized window in taskbar)
echo  Wait 5-15s, then open: http://localhost:8080/v1/models
echo  Log file: DuckAI2API-main\server.log
echo ============================================
echo.
echo Press any key to close this window (server keeps running)...
pause >nul
endlocal
