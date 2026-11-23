#!/bin/sh
# Honcho deriver (background worker) on Railway. Exits non-zero on any failure so Railway restarts it.
set -eu
cd /app
. /app/railway/env.sh
echo "Ensuring the database schema is current (advisory-locked)..."
/app/.venv/bin/python scripts/provision_db.py
echo "Starting Honcho deriver..."
exec /app/.venv/bin/python -m src.deriver
