# AI-Assisted Agent Generation Template

Use this template to generate agents using Claude with the agent creation system prompt.

> **See also:** this template duplicates most of what the live `.claude/agents/agent-creator.md` agent already automates end-to-end. If you're working inside Claude Code, just ask for the `agent-creator` agent (or run `/create-agent`) instead of driving this by hand. Use this template when you need to drive the prompt manually — outside the Task tool, via a raw API call, or to understand the underlying pattern.

## Usage Pattern

### Step 1: Describe Your Agent Need

Think about:
- What task should the agent handle?
- When should it be triggered — explicit request, proactive, or both?
- What phrasings would a real user use?
- What are the key responsibilities?

### Step 2: Use the Generation Prompt

Send this to Claude (with `references/agent-creation-system-prompt.md` loaded as the system prompt):

```
Create an agent configuration based on this request: "[YOUR DESCRIPTION]"

Write the complete agent markdown file directly, including 2-4 <example>/<commentary>
blocks in the description field.
```

**Replace `[YOUR DESCRIPTION]` with your agent requirements.**

### Step 3: Claude Designs and Writes the Agent File

Following the system prompt's 6 steps (see `references/agent-creation-system-prompt.md`), Claude:

1. Extracts the core intent and responsibilities
2. Designs an expert persona
3. Architects the system prompt (responsibilities, process, quality standards, output format, edge cases)
4. Picks an identifier (lowercase, hyphens, 3-50 chars)
5. Crafts 2-4 `<example>`/`<commentary>` blocks covering different phrasings and both explicit and proactive triggering
6. Writes the finished file directly to `agents/[identifier].md` — there is no JSON intermediate step to convert afterward

### Step 4: Review the Result

Read the generated `agents/[identifier].md` and confirm:
- `name` and `description` are present (the only required fields)
- `description:` opens with "Use this agent when..." and contains 2-4 `<example>` blocks
- The examples cover varied phrasing and both explicit and proactive triggers
- The system prompt has clear responsibilities, process, and output format

## Example 1: Code Review Agent

**Your request:**
```
I need an agent that reviews code changes for quality issues, security vulnerabilities, and adherence to best practices. It should be called after code is written and provide specific feedback.
```

**Claude generates `agents/code-quality-reviewer.md`:**

```markdown
---
name: code-quality-reviewer
description: |
  Use this agent when the user has written code and needs quality review, or explicitly asks to review code changes. Examples:

  <example>
  Context: Assistant just implemented an authentication feature
  user: "Add login with email and password"
  assistant: "Here's the login flow. Now let me review it for quality and security before we call it done."
  <commentary>
  Proactive review after writing security-sensitive code — trigger before declaring the task complete.
  </commentary>
  assistant: "I'll use the code-quality-reviewer agent to check the new login flow."
  </example>

  <example>
  Context: User explicitly asks for a review
  user: "Can you review the changes I just made?"
  assistant: "I'll use the code-quality-reviewer agent to review the recent changes."
  <commentary>
  Direct request to review recent changes.
  </commentary>
  </example>
model: inherit
color: blue
tools: ["Read", "Grep", "Glob"]
---

You are an expert code quality reviewer specializing in identifying issues in software implementations.

**Your Core Responsibilities:**
1. Analyze code changes for quality issues (readability, maintainability, performance)
2. Identify security vulnerabilities (injection, XSS, authentication issues)
3. Check adherence to project best practices and coding standards
4. Provide actionable, specific feedback with line numbers

**Review Process:**
1. Read the code changes using available tools
2. Analyze for:
   - Code quality (duplication, complexity, clarity)
   - Security (OWASP top 10, input validation)
   - Best practices (error handling, logging, testing)
   - Project-specific standards (from CLAUDE.md)
3. Identify issues with severity (critical/major/minor)
4. Provide specific recommendations with examples

**Output Format:**
Provide a structured review:
1. Summary (2-3 sentences)
2. Critical Issues (must fix)
3. Major Issues (should fix)
4. Minor Issues (nice to fix)
5. Positive observations
6. Overall assessment

Include file names and line numbers for all findings.
```

## Example 2: Test Generation Agent

**Your request:**
```
Create an agent that generates unit tests for code. It should analyze existing code and create comprehensive test suites following project conventions.
```

**Claude generates `agents/test-generator.md`** with identifier `test-generator`, a `description:` containing `<example>` blocks for both an explicit test request and proactive coverage after new untested code, and a system prompt covering test analysis, generation process, and output format — same structure as Example 1 above.

## Example 3: Documentation Agent

**Your request:**
```
Build an agent that writes and updates API documentation. It should analyze code and generate clear, comprehensive docs.
```

**Result:** Agent file with identifier `api-docs-writer`, a `description:` with `<example>` blocks covering an explicit doc request and proactive documentation after new API surface, and a system prompt for analyzing code and generating docs in the project's standard format.

## Tips for Effective Agent Generation

### Be Specific in Your Request

**Vague:**
```
"I need an agent that helps with code"
```

**Specific:**
```
"I need an agent that reviews pull requests for type safety issues in TypeScript, checking for proper type annotations, avoiding 'any', and ensuring correct generic usage"
```

### Include Triggering Preferences

Tell Claude when the agent should activate, including whether it should be proactive:

```
"Create an agent that generates tests. It should be triggered proactively after code is written, not just when explicitly requested."
```

### Mention Project Context

```
"Create a code review agent. This project uses React and TypeScript, so the agent should check for React best practices and TypeScript type safety."
```

### Define Output Expectations

```
"Create an agent that analyzes performance. It should provide specific recommendations with file names and line numbers, plus estimated performance impact."
```

## Validation After Generation

Always validate generated agents:

```bash
# Validate structure
./scripts/validate-agent.sh agents/your-agent.md

# Check triggering works — test with realistic invocation phrasings
```

## Iterating on Generated Agents

If a generated agent needs improvement:

1. Identify what's missing or wrong
2. Manually edit the agent file
3. Focus on:
   - Better-varied `<example>`/`<commentary>` blocks in `description:`
   - More specific system prompt
   - Clearer process steps
   - Better output format definition
4. Re-validate
5. Test again

## Advantages of AI-Assisted Generation

- **Comprehensive**: includes edge cases and quality checks
- **Consistent**: follows the proven, actually-used pattern
- **Fast**: seconds vs. manual writing
- **Complete**: full system prompt plus properly-formed `<example>` triggers

## When to Edit Manually

Edit generated agents when:
- You need very specific project patterns
- You require custom tool combinations
- You want a unique persona or style
- You're integrating with existing agents
- You need more precise triggering examples

Start with generation, then refine manually for best results.
