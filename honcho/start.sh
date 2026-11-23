#!/bin/sh
# Honcho API on Railway: migrate, print the admin key, serve on $PORT.
set -eu
cd /app
. /app/railway/env.sh

if [ "${AUTH_USE_AUTH}" = "true" ] && [ -z "${AUTH_JWT_SECRET:-}" ]; then
  echo "FATAL: AUTH_JWT_SECRET is empty; refusing to start an open API" >&2; exit 1
fi

echo "Running database migrations (advisory-locked, safe with the deriver running them too)..."
/app/.venv/bin/python scripts/provision_db.py

if [ "${AUTH_USE_AUTH}" = "true" ] && [ "${HONCHO_PRINT_ADMIN_KEY:-true}" = "true" ]; then
  KEY=$(/app/.venv/bin/python scripts/generate_jwt.py --admin --print-only 2>/dev/null | tail -n 1)
  echo "================================================================"
  echo "Honcho admin API key (only project members can read these logs):"
  echo "$KEY"
  echo "Use it as the SDK api_key, or mint scoped keys with POST /v3/keys."
  echo "================================================================"
  unset KEY
fi

exec /app/.venv/bin/python /app/railway/serve.py
