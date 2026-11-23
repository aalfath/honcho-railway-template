# Shared environment setup for the Honcho API and the deriver (sourced by start.sh).
# Railway gives a plain postgresql:// URL; Honcho's SQLAlchemy driver needs postgresql+psycopg://.
if [ -z "${DB_CONNECTION_URI:-}" ]; then
  if [ -z "${DATABASE_URL:-}" ]; then
    echo "FATAL: DATABASE_URL (or DB_CONNECTION_URI) is not set" >&2; exit 1
  fi
  DB_CONNECTION_URI=$(printf '%s' "$DATABASE_URL" | sed -e 's#^postgres://#postgresql+psycopg://#' -e 's#^postgresql://#postgresql+psycopg://#')
  export DB_CONNECTION_URI
fi

# Empty optional template variables must look unset to Honcho.
for v in LLM_OPENAI_BASE_URL LLM_ANTHROPIC_API_KEY LLM_GEMINI_API_KEY LLM_MODEL; do
  eval "val=\${$v:-}"; [ -z "$val" ] && unset "$v"
done

# Point embeddings at the same OpenAI-compatible endpoint as the chat models.
# (Honcho reads the embedding base URL only from this per-module override.)
if [ -n "${LLM_OPENAI_BASE_URL:-}" ] && [ -z "${EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL:-}" ]; then
  export EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL="$LLM_OPENAI_BASE_URL"
fi

# One model name for every reasoning module, unless a module is set on its own.
if [ -n "${LLM_MODEL:-}" ]; then
  for m in DERIVER_MODEL_CONFIG__MODEL SUMMARY_MODEL_CONFIG__MODEL \
           DREAM_DEDUCTION_MODEL_CONFIG__MODEL DREAM_INDUCTION_MODEL_CONFIG__MODEL \
           DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL \
           DIALECTIC_LEVELS__medium__MODEL_CONFIG__MODEL DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL \
           DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL; do
    eval "cur=\${$m:-}"; [ -z "$cur" ] && export "$m=$LLM_MODEL"
  done
fi

# Small, Railway-friendly defaults (all overridable with a service variable).
export AUTH_USE_AUTH="${AUTH_USE_AUTH:-true}"
export API_WORKERS="${API_WORKERS:-1}"
export DERIVER_WORKERS="${DERIVER_WORKERS:-1}"
export DB_POOL_SIZE="${DB_POOL_SIZE:-5}"
export DB_MAX_OVERFLOW="${DB_MAX_OVERFLOW:-10}"
export CACHE_ENABLED="${CACHE_ENABLED:-false}"
export VECTOR_STORE_TYPE="${VECTOR_STORE_TYPE:-pgvector}"
export TELEMETRY_ENABLED="${TELEMETRY_ENABLED:-false}"
export SENTRY_ENABLED="${SENTRY_ENABLED:-false}"
export METRICS_ENABLED="${METRICS_ENABLED:-false}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"

if [ -z "${LLM_OPENAI_API_KEY:-}${LLM_ANTHROPIC_API_KEY:-}${LLM_GEMINI_API_KEY:-}" ]; then
  echo "WARNING: no LLM API key is set (LLM_OPENAI_API_KEY). Honcho stores data, but memory reasoning, summaries and chat will fail until you add one." >&2
fi

# Wait for Postgres (Railway starts every service at once) so the first deploy doesn't crash-loop.
/app/.venv/bin/python - <<'PY'
import os, sys, time
import psycopg
url = os.environ["DB_CONNECTION_URI"].replace("postgresql+psycopg://", "postgresql://", 1)
deadline = time.time() + float(os.environ.get("DB_WAIT_SECONDS", "180"))
while True:
    try:
        psycopg.connect(url, connect_timeout=5).close()
        print("Postgres is reachable.", flush=True)
        break
    except Exception as e:
        if time.time() > deadline:
            print(f"FATAL: Postgres not reachable: {e.__class__.__name__}", file=sys.stderr, flush=True)
            sys.exit(1)
        print("Waiting for Postgres...", flush=True)
        time.sleep(3)
PY
