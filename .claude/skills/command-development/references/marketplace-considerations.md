# Marketplace Considerations for Commands

Guidelines for creating commands designed for distribution through a plugin marketplace, where users won't have the author's context and can't be walked through setup by hand.

## Overview

Commands distributed through a marketplace get invoked by people who never saw the source, don't know the plugin's conventions, and won't file a support ticket before giving up. This reference covers the parts of that problem that are actually specific to how Claude Code commands and plugins work — naming, `${CLAUDE_PLUGIN_ROOT}`-relative dependencies, `.local.md` configuration, and `/help` discovery. General software-distribution advice (cross-platform shell scripting, UI branding, analytics) is not repeated here — it applies the same way it would to any CLI tool and isn't Claude-Code-specific.

## Dependency Awareness

Plugin commands often shell out to external tools (`gh`, `jq`, `docker`, language runtimes). Because the command runs in whatever environment the plugin is installed into, check for required tools before using them rather than assuming they're present:

```markdown
---
description: Dependency-aware command
allowed-tools: Bash(*)
---

Checking availability...

MISSING_DEPS=""
for tool in git jq node; do
  if ! command -v "$tool" > /dev/null; then
    MISSING_DEPS="$MISSING_DEPS $tool"
  fi
done

if [ -n "$MISSING_DEPS" ]; then
  ❌ Missing required dependencies:$MISSING_DEPS
  Install them and try again.
  Exit.
fi
```

Document required vs. optional dependencies in a comment so users (and Claude, when troubleshooting) know what's expected without reading the whole command:

```markdown
<!--
DEPENDENCIES:
  Required: git 2.0+, jq 1.6+
  Optional: gh (enables PR operations), docker (enables containerized tests)
-->
```

**Graceful degradation:** when an optional dependency is missing, detect it and reduce functionality instead of failing outright:

```markdown
if command -v gh > /dev/null; then
  # Full functionality with GitHub integration
else
  ⚠ Limited functionality: 'gh' not installed. Install it for PR operations.
fi
```

## Namespace Awareness

Plugin commands are shown in `/help` as "(plugin:plugin-name)", and subdirectories add a further namespace segment ("(plugin:plugin-name:category)") — see `references/plugin-features-reference.md` for the discovery mechanics. Because multiple installed plugins share one command namespace, generic names (`/test`, `/run`, `/deploy`) are likely to collide. Prefer a plugin-specific prefix or a clear verb-noun name (`/plugin-name-deploy`, `/analyze-performance`) and document why you chose it if the reasoning isn't obvious from the name alone.

## Configurability via `.local.md`

Plugins that need per-user or per-project settings should read them from a `.claude/plugin-name.local.md` file (see the `plugin-settings` skill for the full pattern) rather than requiring arguments on every invocation:

```markdown
---
description: Configurable command
allowed-tools: Read
---

Checking for user config: .claude/plugin-name.local.md

if [ -f ".claude/plugin-name.local.md" ]; then
  # Parse YAML frontmatter for settings (verbose, color, max_results, etc.)
  echo "✓ Using user configuration"
else
  echo "Using default configuration"
  echo "Create .claude/plugin-name.local.md to customize"
fi
```

Pick defaults that work for most invocations, and document how to override them — most users will never create the `.local.md` file, so the command must be useful without one.

## Version Compatibility

Plugin commands can drift out of sync with the plugin they ship in. If a command relies on a config format, script interface, or field that changed between plugin versions, check compatibility explicitly and point users at the update command:

```markdown
<!--
COMMAND VERSION: 2.1.0
COMPATIBILITY: Requires plugin version >= 2.0.0
-->

if [ "$PLUGIN_VERSION" \< "2.0.0" ]; then
  ❌ This command requires plugin version >= 2.0.0 (current: $PLUGIN_VERSION)
  Update with: /plugin update plugin-name
  Exit.
fi
```

When deprecating a flag or argument, keep handling both forms for a transition period and say so in the command output, rather than breaking silently:

```markdown
if [ "$1" = "--old-flag" ]; then
  ⚠ --old-flag is deprecated as of v2.0.0, use --new-flag instead. Continuing for now...
fi
```

## Marketplace Discovery

`/help` and marketplace listings surface only the frontmatter `description` — it is the entire pitch for whether someone tries the command. Make it specific to what the command does, not to the fact that it's a command:

```yaml
# Good — specific, scannable
description: Review pull request for security and quality issues

# Bad — vague, tells the reader nothing
description: Do the thing
```

## Pre-Release Checklist

Before publishing a command for others to install:

- [ ] `description` is specific and under 60 characters
- [ ] `argument-hint` documents every argument the command uses
- [ ] Required and optional dependencies are documented
- [ ] Missing arguments and missing files produce a helpful message, not a silent failure or a stack trace
- [ ] `allowed-tools` is as narrow as the command actually needs
- [ ] Command name doesn't collide with a common or another plugin's command name
- [ ] Tested with `scripts/validate-command.sh` and `scripts/validate-frontmatter.sh` (see `references/testing-strategies.md`)
- [ ] README or plugin docs mention the command and its `.local.md` configuration options, if any

## Best Practices Summary

1. **Check, don't assume.** Verify tools and files exist before depending on them; degrade gracefully when optional ones are missing.
2. **Namespace deliberately.** Choose command names assuming other plugins are installed alongside yours.
3. **Configure via `.local.md`, not required arguments.** Sensible defaults plus optional per-project overrides beat forcing every invocation to pass the same flags.
4. **Version-check when it matters.** Only add compatibility checks where a real breaking change exists — don't add version theater for its own sake.
5. **Write the `description` for a stranger.** It's the only thing marketplace users see before installing.
