# Command Development Skill

Comprehensive guidance on creating Claude Code slash commands, including file format, frontmatter options, dynamic arguments, and best practices.

## Overview

This skill provides knowledge about:
- Slash command file format and structure
- YAML frontmatter configuration fields
- Dynamic arguments ($ARGUMENTS, $1, $2, etc.)
- File references with @ syntax
- Bash execution with !` syntax
- Command organization and namespacing
- Best practices for command development
- Plugin-specific features (${CLAUDE_PLUGIN_ROOT}, plugin patterns)
- Integration with plugin components (agents, skills, hooks)
- Validation patterns and error handling

## Skill Structure

### SKILL.md (~2,250 words)

Core skill content covering:

**Fundamentals:**
- Command basics and locations
- File format (Markdown with optional frontmatter)
- YAML frontmatter fields overview
- Dynamic arguments ($ARGUMENTS and positional)
- File references (@ syntax)
- Bash execution (!` syntax)
- Command organization patterns
- Best practices and common patterns
- Troubleshooting

**Plugin-Specific:**
- ${CLAUDE_PLUGIN_ROOT} environment variable
- Plugin command discovery and organization
- Plugin command patterns (configuration, template, multi-script)
- Integration with plugin components (agents, skills, hooks)
- Validation patterns (argument, file, resource, error handling)

### References

Detailed documentation:

- **frontmatter-reference.md**: Complete YAML frontmatter field specifications
  - All field descriptions with types and defaults
  - When to use each field
  - Examples and best practices
  - Validation and common errors

- **plugin-features-reference.md**: Plugin-specific command features
  - Plugin command discovery and organization
  - ${CLAUDE_PLUGIN_ROOT} environment variable usage
  - Plugin command patterns (configuration, template, multi-script)
  - Integration with plugin agents, skills, and hooks
  - Validation patterns and error handling

- **interactive-commands.md**: AskUserQuestion-based interactive commands
  - When to use AskUserQuestion vs. positional arguments
  - Question and option design, multi-select guidance
  - Multi-stage and conditional question flows
  - Full worked example (multi-agent swarm launch)

- **advanced-workflows.md**: Multi-step command sequences
  - Sequential, state-carrying, and conditional workflow patterns
  - Command composition (chaining, pipelines, parallel execution)
  - Workflow state management via `.local.md` files

- **testing-strategies.md**: Testing commands before release
  - Seven testing levels, from frontmatter syntax to distribution
  - Edge cases, performance, and user-experience testing
  - Points to the real validators in `scripts/`

- **documentation-patterns.md**: Self-documenting commands
  - Complete command documentation template
  - Help text, error messages, and changelog conventions

- **marketplace-considerations.md**: Distribution-specific guidance
  - Dependency awareness, namespace collisions, `.local.md` configurability
  - Version compatibility and a pre-release checklist

### Scripts

Runnable validators (see `scripts/README.md`):

- **validate-command.sh**: Validates command file structure (extension, non-empty, balanced frontmatter markers)
- **validate-frontmatter.sh**: Validates frontmatter field values (`model`, `description` length, `disable-model-invocation`)
- **test-commands.sh**: Runs both validators across every command in a directory and prints a summary

### Examples

Practical command examples:

- **simple-commands.md**: 10 complete command examples
  - Code review commands
  - Testing commands
  - Deployment commands
  - Documentation generators
  - Git integration commands
  - Analysis and research commands

- **plugin-commands.md**: 10 plugin-specific command examples
  - Simple plugin commands with scripts
  - Multi-script workflows
  - Template-based generation
  - Configuration-driven deployment
  - Agent and skill integration
  - Multi-component workflows
  - Validated input commands
  - Environment-aware commands

### Evals

- **evals/evals.json**: Task-based test cases (prompt, expected output, assertions) for exercising the skill end-to-end
- **evals/eval_queries.json**: Labeled queries for testing whether the skill's description triggers correctly

## When This Skill Triggers

Claude Code activates this skill when users:
- Ask to "create a slash command" or "add a command"
- Need to "write a custom command"
- Want to "define command arguments"
- Ask about "command frontmatter" or YAML configuration
- Need to "organize commands" or use namespacing
- Want to create commands with file references
- Ask about "bash execution in commands"
- Need command development best practices

## Progressive Disclosure

The skill uses progressive disclosure:

1. **SKILL.md** (~2,250 words): Core concepts, dynamic features, and a reference-files index
2. **References** (~12,400 words total): Detailed specifications
   - frontmatter-reference.md (~1,200 words)
   - plugin-features-reference.md (~1,825 words)
   - interactive-commands.md (~2,850 words)
   - advanced-workflows.md (~1,735 words)
   - testing-strategies.md (~1,950 words)
   - documentation-patterns.md (~2,010 words)
   - marketplace-considerations.md (~865 words)
3. **Scripts**: `validate-command.sh`, `validate-frontmatter.sh`, `test-commands.sh` — runnable, not counted in prose word totals
4. **Examples** (~2,740 words total): Complete working command examples
   - simple-commands.md (~1,140 words)
   - plugin-commands.md (~1,600 words)

Claude loads references, scripts, and examples as needed based on task.

## Command Basics Quick Reference

### File Format

```markdown
---
description: Brief description
argument-hint: [arg1] [arg2]
allowed-tools: Read, Bash(git:*)
---

Command prompt content with:
- Arguments: $1, $2, or $ARGUMENTS
- Files: @path/to/file
- Bash: !`command here`
```

### Locations

- **Project**: `.claude/commands/` (shared with team)
- **Personal**: `~/.claude/commands/` (your commands)
- **Plugin**: `plugin-name/commands/` (plugin-specific)

### Key Features

**Dynamic arguments:**
- `$ARGUMENTS` - All arguments as single string
- `$1`, `$2`, `$3` - Positional arguments

**File references:**
- `@path/to/file` - Include file contents

**Bash execution:**
- `!`command`` - Execute and include output

## Frontmatter Fields Quick Reference

| Field | Purpose | Example |
|-------|---------|---------|
| `description` | Brief description for /help | `"Review code for issues"` |
| `allowed-tools` | Restrict tool access | `Read, Bash(git:*)` |
| `model` | Specify model | `sonnet`, `opus`, `haiku` |
| `argument-hint` | Document arguments | `[pr-number] [priority]` |
| `disable-model-invocation` | Manual-only command | `true` |

## Common Patterns

### Simple Review Command

```markdown
---
description: Review code for issues
---

Review this code for quality and potential bugs.
```

### Command with Arguments

```markdown
---
description: Deploy to environment
argument-hint: [environment] [version]
---

Deploy to $1 environment using version $2
```

### Command with File Reference

```markdown
---
description: Document file
argument-hint: [file-path]
---

Generate documentation for @$1
```

### Command with Bash Execution

```markdown
---
description: Show Git status
allowed-tools: Bash(git:*)
---

Current status: !`git status`
Recent commits: !`git log --oneline -5`
```

## Development Workflow

1. **Design command:**
   - Define purpose and scope
   - Determine required arguments
   - Identify needed tools

2. **Create file:**
   - Choose appropriate location
   - Create `.md` file with command name
   - Write basic prompt

3. **Add frontmatter:**
   - Start minimal (just description)
   - Add fields as needed (allowed-tools, etc.)
   - Document arguments with argument-hint

4. **Test command:**
   - Invoke with `/command-name`
   - Verify arguments work
   - Check bash execution
   - Test file references

5. **Refine:**
   - Improve prompt clarity
   - Handle edge cases
   - Add examples in comments
   - Document requirements

## Best Practices Summary

1. **Single responsibility**: One command, one clear purpose
2. **Clear descriptions**: Make discoverable in `/help`
3. **Document arguments**: Always use argument-hint
4. **Minimal tools**: Use most restrictive allowed-tools
5. **Test thoroughly**: Verify all features work
6. **Add comments**: Explain complex logic
7. **Handle errors**: Consider missing arguments/files

## Status

**Completed enhancements:**
- ✓ Plugin command patterns (${CLAUDE_PLUGIN_ROOT}, discovery, organization)
- ✓ Integration patterns (agents, skills, hooks coordination)
- ✓ Validation patterns (input, file, resource validation, error handling)
- ✓ Interactive commands (AskUserQuestion) — `references/interactive-commands.md`, linked from SKILL.md
- ✓ Advanced workflows (multi-step command sequences) — `references/advanced-workflows.md`
- ✓ Testing strategies, with runnable validators — `references/testing-strategies.md`, `scripts/`
- ✓ Documentation patterns (command documentation best practices) — `references/documentation-patterns.md`
- ✓ Marketplace considerations (publishing and distribution) — `references/marketplace-considerations.md`
- ✓ Evals (`evals/evals.json`, `evals/eval_queries.json`)

**Known gaps (not yet implemented):**
- No `create-command` scaffolding command/script exists yet in this skill. Deferred deliberately: whether to add one, and what it should scaffold (bare file vs. full frontmatter template vs. interactive wizard), is a product decision that needs a human call rather than an automatic fix.

## Maintenance

To update this skill:
1. Keep SKILL.md focused on core fundamentals
2. Move detailed specifications to references/
3. Add new examples/ for different use cases
4. Update frontmatter when new fields added
5. Ensure imperative/infinitive form throughout
6. Test examples work with current Claude Code

## Version History

**v0.2.0** (2026-07-03):
- Linked all seven `references/` files from SKILL.md (previously only 2 of 7 were reachable; `interactive-commands.md`, `advanced-workflows.md`, `testing-strategies.md`, `documentation-patterns.md`, and `marketplace-considerations.md` were orphaned)
- Added an "Interactive Commands (AskUserQuestion)" section to SKILL.md's body, matching the capability already promised in the frontmatter `description`
- Flagged the legacy `.claude/commands/` scope explicitly in the `description` field to reduce over-triggering against the preferred `skill-development` format
- Removed the fabricated `$IF(...)` conditional macro from SKILL.md and `references/plugin-features-reference.md`; replaced with real bash-conditional-plus-prose patterns
- Trimmed SKILL.md from 884 to ~580 lines by moving content duplicated across SKILL.md, `references/plugin-features-reference.md`, and `examples/` (Common Patterns, Validation Patterns, most of Plugin-Specific Features/Integration) into references-only, leaving pointers
- Moved the undocumented top-level `version` frontmatter key into `metadata.version`
- Extracted the inline `validate-command.sh`, `validate-frontmatter.sh`, and `test-commands.sh` snippets from `references/testing-strategies.md` into real, executable files under `scripts/`, with `--help`, stdout/stderr separation, and distinct exit codes
- Cut generic, non-Claude-Code-specific filler (platform/clipboard detection, emoji-branding checklists) from `references/marketplace-considerations.md`
- Added `evals/evals.json` (task-based test cases) and `evals/eval_queries.json` (trigger-eval queries)
- Fixed stale documentation: this Status section, the Examples word-count claim, and this version history

**v0.1.0** (2025-01-15):
- Initial release with basic command fundamentals
- Frontmatter field reference
- 10 simple command examples
- Ready for plugin-specific pattern additions
