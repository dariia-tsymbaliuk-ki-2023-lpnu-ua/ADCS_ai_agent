#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PYTHON="${PYTHON:-python3}"
VENV_PY=".venv/bin/python"

command -v "$PYTHON" >/dev/null 2>&1 || { echo "[FAIL] $PYTHON not found"; exit 1; }

if [ ! -x "$VENV_PY" ]; then
  echo "[INFO] Creating virtual environment .venv"
  "$PYTHON" -m venv .venv
fi

"$VENV_PY" -m pip install --upgrade pip
"$VENV_PY" -m pip install -r requirements-dev.txt

"$VENV_PY" -m pytest
PYTHONPATH=src "$VENV_PY" -m hello_world.main

echo "[OK] Build and tests passed"
