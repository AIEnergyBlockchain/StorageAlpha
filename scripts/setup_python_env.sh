#!/usr/bin/env bash
set -euo pipefail

VENV_DIR="${VENV_DIR:-.venv}"
MODE="${1:-api}"

case "$MODE" in
  api)
    REQUIREMENTS_FILE="requirements-api.txt"
    ;;
  full)
    REQUIREMENTS_FILE="requirements.txt"
    ;;
  *)
    echo "Unsupported mode: $MODE"
    echo "Usage: bash scripts/setup_python_env.sh [api|full]"
    exit 2
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found"
  exit 1
fi

python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip || true
if [[ -n "${WHEELHOUSE_DIR:-}" ]]; then
  echo "[setup] using offline wheelhouse: ${WHEELHOUSE_DIR}"
  INSTALL_CMD=(python -m pip install --no-index --find-links "$WHEELHOUSE_DIR" -r "$REQUIREMENTS_FILE")
else
  INSTALL_CMD=(python -m pip install -r "$REQUIREMENTS_FILE")
fi

if ! "${INSTALL_CMD[@]}"; then
  echo "[setup] dependency installation failed."
  echo "[setup] check outbound network or configure an internal PyPI mirror/proxy."
  echo "[setup] tips:"
  echo "  1) export PIP_INDEX_URL=<your-mirror-url>"
  echo "  2) or export WHEELHOUSE_DIR=<path-to-offline-wheels>"
  exit 1
fi

echo "[setup] installed dependencies from $REQUIREMENTS_FILE"
echo "[setup] validating API import"
python -c "from services.api import create_app; print('api_import_ok')"

echo "[setup] running smoke check"
python scripts/smoke_api_flow.py

echo "[setup] success"
