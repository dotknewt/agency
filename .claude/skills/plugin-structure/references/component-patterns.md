# Component Organization Patterns

Advanced patterns for organizing plugin components effectively.

## Component Lifecycle

### Discovery Phase

When Claude Code starts:

1. **Scan enabled plugins**: Read `.claude-plugin/plugin.json` for each
2. **Discover components**: Look in default and custom paths
3. **Parse definitions**: Read YAML frontmatter and configurations
4. **Register components**: Make available to Claude Code
5. **Initialize**: Start MCP servers, register hooks

**Timing**: Component registration happens during Claude Code initialization, not continuously.

### Activation Phase

When components are used:

**Commands**: User types slash command → Claude Code looks up → Executes
**Agents**: Task arrives → Claude Code evaluates capabilities → Selects agent
**Skills**: Task context matches description → Claude Code loads skill
**Hooks**: Event occurs → Claude Code calls matching hooks
**MCP Servers**: Tool call matches server capability → Forwards to server

## Command Organization Patterns

### Flat Structure

Single directory with all commands:

```
commands/
├── build.md
├── test.md
├── deploy.md
├── review.md
└── docs.md
```

**When to use**:
- 5-15 commands total
- All commands at same abstraction level
- No clear categorization

**Advantages**:
- Simple, easy to navigate
- No configuration needed
- Fast discovery

### Categorized Structure

Multiple directories for different command types:

```
commands/              # Core commands
├── build.md
└── test.md

admin-commands/        # Administrative
├── configure.md
└── manage.md

workflow-commands/     # Workflow automation
├── review.md
└── deploy.md
```

**Manifest configuration**:
```json
{
  "commands": [
    "./commands",
    "./admin-commands",
    "./workflow-commands"
  ]
}
```

**When to use**:
- 15+ commands
- Clear functional categories
- Different permission levels

**Advantages**:
- Organized by purpose
- Easier to maintain
- Can restrict access by directory

### Hierarchical Structure

Nested organization for complex plugins:

```
commands/
├── ci/
│   ├── build.md        # /build (plugin:plugin-name:ci)
│   ├── test.md         # /test (plugin:plugin-name:ci)
│   └── lint.md         # /lint (plugin:plugin-name:ci)
├── deployment/
│   ├── staging.md      # /staging (plugin:plugin-name:deployment)
│   └── production.md   # /production (plugin:plugin-name:deployment)
└── management/
    ├── config.md       # /config (plugin:plugin-name:management)
    └── status.md       # /status (plugin:plugin-name:management)
```

**Note**: Subdirectories under `commands/` load automatically — no manifest entry needed. Each subdirectory name becomes a namespace segment, surfaced in `/help` as `(plugin:plugin-name:subdirectory)`. See the `command-development` skill's "Namespaced Structure" / "Namespaced Plugin Commands" sections for the full behavior.

**When to use**:
- 20+ commands
- Multi-level categorization
- Complex workflows

**Advantages**:
- Maximum organization
- Clear boundaries
- Scalable structure
- No manifest configuration required

## Agent Organization Patterns

### Role-Based Organization

Organize agents by their primary role:

```
agents/
├── code-reviewer.md        # Reviews code
├── test-generator.md       # Generates tests
├── documentation-writer.md # Writes docs
└── refactorer.md          # Refactors code
```

**When to use**:
- Agents have distinct, non-overlapping roles
- Users invoke agents manually
- Clear agent responsibilities

### Capability-Based Organization

Organize by specific capabilities:

```
agents/
├── python-expert.md        # Python-specific
├── typescript-expert.md    # TypeScript-specific
├── api-specialist.md       # API design
└── database-specialist.md  # Database work
```

**When to use**:
- Technology-specific agents
- Domain expertise focus
- Automatic agent selection

### Workflow-Based Organization

Organize by workflow stage:

```
agents/
├── planning-agent.md      # Planning phase
├── implementation-agent.md # Coding phase
├── testing-agent.md       # Testing phase
└── deployment-agent.md    # Deployment phase
```

**When to use**:
- Sequential workflows
- Stage-specific expertise
- Pipeline automation

## Skill Organization Patterns

### Topic-Based Organization

Each skill covers a specific topic:

```
skills/
├── api-design/
│   └── SKILL.md
├── error-handling/
│   └── SKILL.md
├── testing-strategies/
│   └── SKILL.md
└── performance-optimization/
    └── SKILL.md
```

**When to use**:
- Knowledge-based skills
- Educational or reference content
- Broad applicability

### Tool-Based Organization

Skills for specific tools or technologies:

```
skills/
├── docker/
│   ├── SKILL.md
│   └── references/
│       └── dockerfile-best-practices.md
├── kubernetes/
│   ├── SKILL.md
│   └── examples/
│       └── deployment.yaml
└── terraform/
    ├── SKILL.md
    └── scripts/
        └── validate-config.sh
```

**When to use**:
- Tool-specific expertise
- Complex tool configurations
- Tool best practices

### Workflow-Based Organization

Skills for complete workflows:

```
skills/
├── code-review-workflow/
│   ├── SKILL.md
│   └── references/
│       ├── checklist.md
│       └── standards.md
├── deployment-workflow/
│   ├── SKILL.md
│   └── scripts/
│       ├── pre-deploy.sh
│       └── post-deploy.sh
└── testing-workflow/
    ├── SKILL.md
    └── examples/
        └── test-structure.md
```

**When to use**:
- Multi-step processes
- Company-specific workflows
- Process automation

### Skill with Rich Resources

Comprehensive skill with all resource types:

```
skills/
└── api-testing/
    ├── SKILL.md              # Core skill (1500 words)
    ├── references/
    │   ├── rest-api-guide.md
    │   ├── graphql-guide.md
    │   └── authentication.md
    ├── examples/
    │   ├── basic-test.js
    │   ├── authenticated-test.js
    │   └── integration-test.js
    ├── scripts/
    │   ├── run-tests.sh
    │   └── generate-report.py
    └── assets/
        └── test-template.json
```

**Resource usage**:
- **SKILL.md**: Overview and when to use resources
- **references/**: Detailed guides (loaded as needed)
- **examples/**: Copy-paste code samples
- **scripts/**: Executable test runners
- **assets/**: Templates and configurations

## Hook Organization Patterns

### Monolithic Configuration

Single hooks.json with all hooks:

```
hooks/
├── hooks.json     # All hook definitions
└── scripts/
    ├── validate-write.sh
    ├── validate-bash.sh
    └── load-context.sh
```

**hooks.json**:
```json
{
  "PreToolUse": [...],
  "PostToolUse": [...],
  "Stop": [...],
  "SessionStart": [...]
}
```

**When to use**:
- 5-10 hooks total
- Simple hook logic
- Centralized configuration

### Event-Based Organization

**Note**: `hooks/hooks.json` must be literal, valid JSON — Claude Code does not support `${file:...}` references or any other file-inclusion syntax inside it. All events live in the one file it actually loads:

```
hooks/
├── hooks.json              # All events, valid JSON
└── scripts/
    ├── validate/
    │   ├── write.sh
    │   └── bash.sh
    └── context/
        └── load.sh
```

**hooks.json**:
```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate/write.sh",
          "timeout": 30
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate/bash.sh",
          "timeout": 30
        }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": ".*",
      "hooks": [
        {
          "type": "command",
          "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/context/load.sh",
          "timeout": 15
        }
      ]
    }
  ]
}
```

**If per-event source files are useful for authoring** (e.g. different teams own different events), keep those fragments *outside* `hooks/` — for example `hooks/src/pre-tool-use.json`, `hooks/src/post-tool-use.json` — and add your own build step (a script using `jq -s 'add'` or equivalent) that merges them into the real `hooks/hooks.json` before the plugin ships. Commit the generated `hooks.json`, not just the sources, since Claude Code only ever reads the merged file.

**When to use**:
- 10+ hooks
- Different teams managing different events
- Complex hook configurations

### Purpose-Based Organization

Group by functional purpose:

```
hooks/
├── hooks.json
└── scripts/
    ├── security/
    │   ├── validate-paths.sh
    │   ├── check-credentials.sh
    │   └── scan-malware.sh
    ├── quality/
    │   ├── lint-code.sh
    │   ├── check-tests.sh
    │   └── verify-docs.sh
    └── workflow/
        ├── notify-team.sh
        └── update-status.sh
```

**When to use**:
- Many hook scripts
- Clear functional boundaries
- Team specialization

## Script Organization Patterns

### Flat Scripts

All scripts in single directory:

```
scripts/
├── build.sh
├── test.py
├── deploy.sh
├── validate.js
└── report.py
```

**When to use**:
- 5-10 scripts
- All scripts related
- Simple plugin

### Categorized Scripts

Group by purpose:

```
scripts/
├── build/
│   ├── compile.sh
│   └── package.sh
├── test/
│   ├── run-unit.sh
│   └── run-integration.sh
├── deploy/
│   ├── staging.sh
│   └── production.sh
└── utils/
    ├── log.sh
    └── notify.sh
```

**When to use**:
- 10+ scripts
- Clear categories
- Reusable utilities

### Language-Based Organization

Group by programming language:

```
scripts/
├── bash/
│   ├── build.sh
│   └── deploy.sh
├── python/
│   ├── analyze.py
│   └── report.py
└── javascript/
    ├── bundle.js
    └── optimize.js
```

**When to use**:
- Multi-language scripts
- Different runtime requirements
- Language-specific dependencies

## Cross-Component Patterns

### Shared Resources

Components sharing common resources:

```
plugin/
├── commands/
│   ├── test.md        # Uses lib/test-utils.sh
│   └── deploy.md      # Uses lib/deploy-utils.sh
├── agents/
│   └── tester.md      # References lib/test-utils.sh
├── hooks/
│   └── scripts/
│       └── pre-test.sh # Sources lib/test-utils.sh
└── lib/
    ├── test-utils.sh
    └── deploy-utils.sh
```

**Usage in components**:
```bash
#!/bin/bash
source "${CLAUDE_PLUGIN_ROOT}/lib/test-utils.sh"
run_tests
```

**Benefits**:
- Code reuse
- Consistent behavior
- Easier maintenance

### Layered Architecture

Separate concerns into layers:

```
plugin/
├── commands/          # User interface layer
├── agents/            # Orchestration layer
├── skills/            # Knowledge layer
└── lib/
    ├── core/         # Core business logic
    ├── integrations/ # External services
    └── utils/        # Helper functions
```

**When to use**:
- Large plugins (100+ files)
- Multiple developers
- Clear separation of concerns

### Plugin Within Plugin

Nested plugin structure:

```
plugin/
├── .claude-plugin/
│   └── plugin.json
├── core/              # Core functionality
│   ├── commands/
│   └── agents/
└── extensions/        # Optional extensions
    ├── extension-a/
    │   ├── commands/
    │   └── agents/
    └── extension-b/
        ├── commands/
        └── agents/
```

**Manifest**:
```json
{
  "commands": [
    "./core/commands",
    "./extensions/extension-a/commands",
    "./extensions/extension-b/commands"
  ]
}
```

**When to use**:
- Modular functionality
- Optional features
- Plugin families

## Best Practices

### Naming

1. **Consistent naming**: Match file names to component purpose
2. **Descriptive names**: Indicate what component does
3. **Avoid abbreviations**: Use full words for clarity

### Organization

1. **Start simple**: Use flat structure, reorganize when needed
2. **Group related items**: Keep related components together
3. **Separate concerns**: Don't mix unrelated functionality

### Scalability

1. **Plan for growth**: Choose structure that scales
2. **Refactor early**: Reorganize before it becomes painful
3. **Document structure**: Explain organization in README

### Maintainability

1. **Consistent patterns**: Use same structure throughout
2. **Minimize nesting**: Keep directory depth manageable
3. **Use conventions**: Follow community standards

### Performance

1. **Avoid deep nesting**: Impacts discovery time
2. **Minimize custom paths**: Use defaults when possible
3. **Keep configurations small**: Large configs slow loading
