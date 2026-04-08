#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
RELOAD="${RELOAD:-1}"

PYTHON_BIN=""
if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
  PYTHON_BIN="$REPO_ROOT/.venv/bin/python"
elif [[ -x "$SCRIPT_DIR/venv/bin/python" ]]; then
  PYTHON_BIN="$SCRIPT_DIR/venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
else
  echo "Error: No Python interpreter found."
  exit 1
fi

if ! "$PYTHON_BIN" -c "import uvicorn" >/dev/null 2>&1; then
  echo "Error: uvicorn is not installed in: $PYTHON_BIN"
  echo "Run: $PYTHON_BIN -m pip install -r $SCRIPT_DIR/requirements.txt"
  exit 1
fi

echo "Using Python: $PYTHON_BIN"
echo "Starting backend on http://$HOST:$PORT"

cd "$SCRIPT_DIR"

UVI_ARGS=(main:app --app-dir "$SCRIPT_DIR" --host "$HOST" --port "$PORT")
if [[ "$RELOAD" == "1" ]]; then
  UVI_ARGS+=(--reload)
fi

exec "$PYTHON_BIN" -m uvicorn "${UVI_ARGS[@]}"
