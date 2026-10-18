@echo off
setlocal

cd /d "%~dp0.."

set "VENV_PY=.venv\Scripts\python.exe"

where python >nul 2>&1
if errorlevel 1 (
  echo [FAIL] python not found
  exit /b 1
)

if not exist "%VENV_PY%" (
  echo [INFO] Creating virtual environment .venv
  python -m venv .venv
  if errorlevel 1 exit /b 1
)

"%VENV_PY%" -m pip install --upgrade pip
if errorlevel 1 exit /b 1

"%VENV_PY%" -m pip install -r requirements-dev.txt
if errorlevel 1 exit /b 1

"%VENV_PY%" -m pytest
if errorlevel 1 exit /b 1

set "PYTHONPATH=src"
"%VENV_PY%" -m hello_world.main
if errorlevel 1 exit /b 1

echo [OK] Build and tests passed
exit /b 0
