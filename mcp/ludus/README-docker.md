# Running ludus-mcp with Docker + the Docker MCP Gateway

This packages `ludus-mcp` as a Docker image and runs it through the
**Docker MCP Gateway**, which launches the server in an isolated container and
brokers stdio between your AI client and the container. Config (`LUDUS_URL`,
`LUDUS_API_KEY`) is injected by the gateway — no CLI args, no code changes.

Files in this directory that make it work:

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build → non-root stdio image (`node build/index.js`) |
| `.dockerignore` | Keeps the build context clean / forces an in-image build |
| `ludus-catalog.yaml` | A local "file catalog" the gateway reads directly |
| `server.yaml` | Catalog entry in Docker MCP registry schema (for the OCI/registry path) |

Prerequisites: Docker Desktop with the MCP Toolkit (`docker mcp` CLI available).

---

## 1. Build the image

```bash
cd /Users/dotme/Code/agency/mcp/ludus
docker build -t ludus-mcp:local .
```

Smoke-test that the image speaks MCP over stdio (optional — lists the 4 tools):

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | docker run -i --rm -e LUDUS_URL=https://YOUR_HOST:8080 -e LUDUS_API_KEY=dummy ludus-mcp:local
```

## 2. Store your API key as a secret

The gateway maps the keychain secret `ludus-mcp.api_key` to the `LUDUS_API_KEY`
env var inside the container (see `secrets:` in `ludus-catalog.yaml`).

```bash
printf '%s' '<YOUR_LUDUS_API_KEY>' | docker mcp secret set ludus-mcp.api_key
```

## 3. Point the catalog at your Ludus server

Set the `url` config variable (the gateway resolves it into `LUDUS_URL` via the
`{{ludus-mcp.url}}` template in `ludus-catalog.yaml`):

```bash
docker mcp config write 'ludus-mcp:
  url: https://198.51.100.1:8080'
docker mcp config read   # confirm the url is stored
```

- Remote / LAN / cloud Ludus host → normal URL, e.g. `https://198.51.100.1:8080`.
- Ludus on **this machine's** localhost → use `host.docker.internal`, e.g.
  `https://host.docker.internal:8080` (a container cannot reach the host via
  `127.0.0.1`). Self-signed certs are fine — the client skips TLS verification.

## 4. Run the gateway with this catalog

```bash
docker mcp gateway run \
  --catalog /Users/dotme/Code/agency/mcp/ludus/ludus-catalog.yaml \
  --servers ludus-mcp
```

This is the verified, fully self-contained path: the gateway reads the local
catalog, runs `ludus-mcp:local` (`--pull never`), injects the secret + URL, and
exposes the 4 tools.

## 5. Wire it to a client

**Claude Code (recommended for this local-catalog setup)** — add the gateway as
a stdio MCP server so it uses exactly this catalog:

```bash
claude mcp add ludus -- \
  docker mcp gateway run \
  --catalog /Users/dotme/Code/agency/mcp/ludus/ludus-catalog.yaml \
  --servers ludus-mcp
```

**Claude Desktop / other clients via the Docker MCP Toolkit** — if instead you
register the server into the Desktop-managed Toolkit (see "OCI catalog" below),
connect a supported client with:

```bash
docker mcp client connect claude-desktop   # or: claude-code, cursor, vscode, ...
```

## 6. Verify end-to-end

Ask the client to run `list_ludus_operations`. A populated operation list proves
the container reached your Ludus server and the API key works. If it's empty or
errors with a connection failure, re-check the `url` config (`docker mcp config
read`; localhost → `host.docker.internal`) and that the secret is set.

---

## File uploads (optional)

`call_ludus_api` multipart operations read file paths **from inside the
container**, not your host. To upload a local file, mount a host directory and
pass the container-side path. Uncomment and edit the `volumes:` block in
`ludus-catalog.yaml`:

```yaml
    volumes:
      - /absolute/host/path:/uploads
```

Then pass paths like `/uploads/role.tar.gz` to `call_ludus_api`.

## Alternative: OCI catalog (Desktop Toolkit)

Instead of a file catalog you can register the image into an OCI catalog managed
by the Toolkit:

```bash
docker mcp catalog create ludus --title "Ludus" --server docker://ludus-mcp:local
# inspect / manage:
docker mcp catalog ls
docker mcp catalog show ludus
```

The `server.yaml` here is written in the docker/mcp-registry schema (secrets,
`env` ← `{{ludus-mcp.url}}` parameter, optional `upload_dir` volume) so it also
serves as the basis for a future submission to the official registry — that path
additionally requires the `Dockerfile` to live at the root of the upstream repo
(`gitlab.com/badsectorlabs/ludus-mcp`) with a pinned `source.commit`.

## Reset

```bash
docker mcp secret rm ludus-mcp.api_key
docker mcp catalog reset      # only if you created an OCI catalog
```
