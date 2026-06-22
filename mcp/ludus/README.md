# ludus-mcp

MCP server for managing [Ludus](https://ludus.cloud) cyber ranges from AI coding assistants.

```
npx -y @badsectorlabs/ludus-mcp --url https://<LUDUS_HOST>:8080 --api-key <YOUR_API_KEY>
```

Full documentation at [docs.ludus.cloud](https://docs.ludus.cloud/docs/category/using-ludus).

## Run with Docker / MCP Gateway

To run ludus-mcp as a container through the Docker MCP Gateway (config injected
as env vars / secrets, container isolation), see [README-docker.md](README-docker.md):

```
docker build -t ludus-mcp:local .
printf '%s' '<API_KEY>' | docker mcp secret set ludus-mcp.api_key
docker mcp config write 'ludus-mcp:
  url: https://<LUDUS_HOST>:8080'
docker mcp gateway run --catalog "$PWD/ludus-catalog.yaml" --servers ludus-mcp
```

## Development

```
git clone https://gitlab.com/badsectorlabs/ludus-mcp.git
cd ludus-mcp
npm install
npm run build
npm test
```
