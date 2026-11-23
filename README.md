[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/honcho?utm_medium=integration&utm_source=button&utm_campaign=honcho)

# Honcho on Railway

One-click Railway template for [Honcho](https://github.com/plastic-labs/honcho) **v3.6.1** by Plastic Labs, an open-source memory server for stateful AI agents. Your app stores workspaces, peers, sessions and messages through Honcho's REST API, and a background worker reasons over them to build memories, summaries and peer cards your agents can query.

## What it deploys

| Service | Built from | Role |
|---|---|---|
| **Honcho** | `honcho/` (`ghcr.io/plastic-labs/honcho:v3.6.1@sha256:2ced1a95…`) | REST API on a public domain. Runs migrations on boot, prints an admin key to its deploy logs. Health check `/health`. |
| **Honcho Deriver** | `deriver/` (same image) | Background worker that derives memories, summaries and peer cards. No public port. |
| **Honcho MCP** | `mcp/` (Honcho's `mcp/` at the v3.6.1 commit, `oven/bun:1.4.4@sha256:1d22548f…`) | Honcho's MCP server in Streamable HTTP mode on a public domain (`/mcp`). Health check `/health`. |
| **Postgres** | Railway PostgreSQL 18 (pgvector) | Database and vector store, on a volume. |

Redis is left out: upstream uses it only as an optional cache, and Honcho falls back to an in-memory cache.

## Variables

| Service | Variable | Default | Notes |
|---|---|---|---|
| Honcho | `LLM_OPENAI_API_KEY` | *(you enter it)* | The only prompt. OpenAI key, or a key from any OpenAI-compatible provider. Models must support tool calling. |
| Honcho | `LLM_OPENAI_BASE_URL` | empty (OpenAI) | Optional, e.g. `https://openrouter.ai/api/v1`. Embeddings use the same endpoint. |
| Honcho | `LLM_MODEL` | `gpt-5.4-mini` | Model for every reasoning module (deriver, summaries, dreams, chat). |
| Honcho | `AUTH_JWT_SECRET` | `${{secret(64,…)}}` | Signs API keys. Auth is always on. Rotating it invalidates every key. |
| Honcho | `DATABASE_URL`, `PORT` | references / `8000` | Wired to Postgres over the private network. |
| Honcho Deriver | `DATABASE_URL`, `AUTH_JWT_SECRET`, `LLM_*` | references to Honcho | Follows the Honcho service. |
| Honcho MCP | `HONCHO_API_URL`, `PORT` | private URL of Honcho / `3000` | |

Any other [Honcho setting](https://docs.honcho.dev/v3/contributing/configuration) (`DERIVER_*`, `DIALECTIC_*`, `EMBEDDING_*`…) can be added as a service variable. Set embedding settings before you store data: the vector size is fixed once the tables exist.

## After deploy

1. Open the **Honcho** service's latest deploy logs and copy the key under "Honcho admin API key".
2. Use it with the SDK: `Honcho(base_url="https://YOUR-HONCHO-DOMAIN", api_key=KEY, workspace_id="my-app")`.
3. Mint narrower keys for apps with `POST /v3/keys?workspace_id=my-app`.

MCP clients that speak Streamable HTTP:

```json
{
  "mcpServers": {
    "honcho": {
      "url": "https://YOUR-HONCHO-MCP-DOMAIN/mcp",
      "headers": { "Authorization": "Bearer YOUR-KEY", "X-Honcho-Workspace-ID": "my-app" }
    }
  }
}
```

## Resources

Each service fits in Railway's 0.5 GB per-service limit (API and deriver about 300 MB each, MCP about 90 MB, measured on Railway). Every unexpected stop exits non-zero, so Railway's on-failure restart brings it back.

## Updates

Every service builds from this repo's `main` branch. When we bump Honcho, deployers get Railway's "update available" notice; read [CHANGELOG.md](CHANGELOG.md) (breaking changes first) before applying it. Migrations run on the next boot.

## Licence

Honcho is AGPL-3.0 (Plastic Labs). This wrapper only adds start scripts and Dockerfiles.
