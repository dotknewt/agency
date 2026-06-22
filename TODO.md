# memory-management
- additional command that performs memory-management only adding changes that surfaced in the last 5 commits
# new skill: dockerize-mcp-server
- convert/transform/adapt/create a dockerized version of an MCP server. example context:
```
 agency/mcp/ludus is a Node/TypeScript stdio MCP server for managing Ludus
   cyber ranges. Today it's run via npx/node build/index.js. We want it
   packaged as a Docker image and runnable through the Docker MCP Gateway,
   which launches each MCP server in an isolated container and brokers stdio
 between the AI client and the container.                                                                                                                                                                                                 
 Target (per user): local custom catalog — build the image ourselves,
 register it in a Docker MCP catalog, set secrets, run via the gateway. No PR to
   docker/mcp-registry, no public repo required.
```

