# Deploy and Host Honcho on Railway

Honcho is an open-source memory server for stateful AI agents, made by Plastic Labs. Your app sends it workspaces, peers, sessions and messages through a REST API. A background worker reasons over them and builds long-term memories, peer cards and summaries that your agents can query in plain language.

## About Hosting Honcho

Honcho runs as an API server and a background worker (the deriver) that share one PostgreSQL database with pgvector. Both call an LLM provider, so you bring one API key. This template builds Honcho v3.6.1 from the official image, pinned by digest, as three services from a public GitHub repo: the API, the deriver and Honcho's MCP server. It adds Railway Postgres on a volume, runs the database migrations on boot, generates the JWT signing secret and turns API auth on from the first deploy. The API prints an admin key to its deploy logs, which only project members can read. All services talk over Railway's private network.

## Common Use Cases

* Give chatbots and agents durable memory of each user across sessions
* Build peer cards and representations of users from their conversations
* Fetch session context and summaries sized to your model's context window
* Ask Honcho what it knows about a user, in natural language, from your agent or an MCP client

## Dependencies for Honcho Hosting

* PostgreSQL with pgvector (included: Railway Postgres 18 with a volume)
* An LLM API key: OpenAI by default, or any OpenAI-compatible provider (OpenRouter, Together, Groq, a LiteLLM proxy…) through the base URL variable. The models must support tool calling.

### Deployment Dependencies

* [Honcho on GitHub](https://github.com/plastic-labs/honcho) and the [v3.6.1 release](https://github.com/plastic-labs/honcho/releases/tag/v3.6.1)
* [Self-hosting guide](https://docs.honcho.dev/v3/contributing/self-hosting) and [configuration reference](https://docs.honcho.dev/v3/contributing/configuration)
* [Template source](https://github.com/aalfath/honcho-railway-template)

### Implementation Details

**Services**

* **Honcho**: the REST API on a public domain (`/health` is the health check, `/docs` the API reference). Runs the migrations on boot.
* **Honcho Deriver**: the background worker that turns messages into memories, summaries and peer cards. No public port.
* **Honcho MCP**: Honcho's own MCP server in Streamable HTTP mode on a public domain, for Claude, Cursor and other MCP clients. It passes your Honcho key through to the API.
* **Postgres**: Railway PostgreSQL with pgvector, on a volume.

**The one prompt:** `LLM_OPENAI_API_KEY`, an OpenAI key from https://platform.openai.com/api-keys or a key from any OpenAI-compatible provider. For another provider, also set `LLM_OPENAI_BASE_URL` (for example `https://openrouter.ai/api/v1`) and `LLM_MODEL` (default `gpt-5.4-mini`) on the Honcho service; the deriver follows it. Embeddings use `text-embedding-3-small` at the same endpoint, so that endpoint must also serve embeddings.

**After deploy**

1. Open the Honcho service's latest deploy logs and copy the line under "Honcho admin API key". It is a JWT signed with the generated `AUTH_JWT_SECRET`.
2. Point the SDK at your domain: `Honcho(base_url="https://YOUR-HONCHO-DOMAIN", api_key="YOUR-KEY", workspace_id="my-app")` in Python, or `new Honcho({ baseURL, apiKey, workspaceId })` in TypeScript.
3. For apps, mint narrower keys with `POST /v3/keys?workspace_id=my-app` using the admin key, so you don't ship the admin key.

MCP client config (Claude Desktop, Cursor and others that speak Streamable HTTP):

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

Without a key header the MCP server answers 401, and the API refuses calls with no key or a wrong one. Rotating `AUTH_JWT_SECRET` invalidates every issued key.

**Memory:** each service runs in 0.5 GB of RAM (the API and the deriver use about 250–300 MB each). Redis is left out: upstream uses it only as an optional cache, and Honcho falls back to an in-memory cache. Change `EMBEDDING_*` settings only before you store data, because the vector size is fixed once the tables exist.

**Updates:** every service builds from the template's GitHub repo. When we move to a newer Honcho release, Railway shows an update in your project; read the repo's CHANGELOG first, then apply it. Migrations run on the next boot.

## Why Deploy Honcho on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Honcho on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
