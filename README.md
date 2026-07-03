# agency

The Claude Code plugin marketplace for dotKnewt's personal extensions. Add it with:

```
/plugin marketplace add dotknewt/agency
```

This repo is just the manifest (`.claude-plugin/marketplace.json`) — it aggregates plugins that live in sibling repos, each independently addable if you only want that slice:

- [`dotknewt/skills`](https://github.com/dotknewt/skills) — standalone skills
- [`dotknewt/agents`](https://github.com/dotknewt/agents) — agent-persona plugins
- [`dotknewt/toolkits`](https://github.com/dotknewt/toolkits) — composite skills+agents+commands+hooks bundles, including the Ludus cyber-range toolkit + MCP server (`ludus-toolkit`)

See `AGENTS.md` for manifest conventions.
