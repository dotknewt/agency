---
name: delegate-task
description: Delegate defensive security operations tasks like to the most appropriate MCP (Mistral or Ollama) based on task characteristics and model size requirements
---

# Delegate Task to Appropriate MCP

Routes detection engineering tasks to Mistral (cloud, high-quality) or Ollama (local, fast, private) based on task analysis. Recommends the best model size for each MCP.

## How It Works

The delegator analyzes task descriptions for signals like:
- **Code generation** (YARA, Sigma, SPL) → Code-optimized models
- **Privacy/local** → Ollama only
- **High quality/reasoning** → Mistral large or Ollama medium
- **Time-sensitive/batch** → Fast models (Mistral Small: 5 RPS, Ollama small)
- **General extraction** → Local fast models

## Agent Path: Use the Driver

Run the delegator to recommend MCP + model for any task:

```powershell
cd .claude/skills/delegate-task
python driver.py
```

This demo analyzes 9 representative tasks and outputs:
- **Recommended MCP** (mistral or ollama)
- **Model name** (size-optimized for the MCP)
- **Rationale** (why this choice)
- **Fallback** (alternative if preferred MCP unavailable)

JSON output at end shows how to integrate programmatically.

### Programmatic Invocation

```python
from driver import TaskDelegator

delegator = TaskDelegator()
rec = delegator.delegate("Write a Sigma rule for PowerShell logging")

print(f"Use: {rec.preferred_mcp} / {rec.model}")
# Output: Use: ollama / qwen2.5-coder:7b
```

## Decision Logic

| Task Characteristic | Preferred | Model | Why |
|---|---|---|---|
| Requires privacy / local | Ollama | medium/large | Never leaves machine |
| Code generation (Sigma/YARA/SPL) | Ollama | qwen2.5-coder:7b | Code-focused, local fast |
| Code generation + time-sensitive | Mistral | devstral-2512 | Code + high RPS (0.83) |
| Code generation + high quality | Mistral | mistral-large-2512 | Best code quality (slow) |
| High reasoning / analysis quality | Mistral | mistral-medium/large | Stronger reasoning |
| Time-sensitive / batch (1000+) | Mistral | mistral-small-2506 | 5 RPS, high throughput |
| General reasoning | Ollama | qwen2.5:14b | Balanced, local |
| General / extraction | Ollama | mistral:7b | Fast, no API calls |

## Mistral Models (Cloud)

| Model | RPS | TPM | Best For |
|---|---:|---:|---|
| mistral-small-2506 | 5.00 | 2.25M | Batch work, time-sensitive |
| devstral-2512 | 0.83 | 1.0M | Code generation |
| mistral-medium-2505 | 0.42 | 375K | High-quality reasoning |
| mistral-large-2512 | 0.07 | 250K | Highest quality (one-shot) |

## Ollama Models (Local)

| Model | Latency | Best For |
|---|---|---|
| mistral:7b | ~100ms | Fast extraction, general |
| qwen2.5:14b | ~200ms | Balanced reasoning |
| qwen2.5-coder:7b | ~150ms | Code generation, YAML |
| qwen2.5:32b | ~500ms | High quality (requires patience) |

## Gotchas

1. **Mistral rate limiting is per-model.** If you hit RPS limits on mistral-small-2506, the fallback is local Ollama, not another Mistral model.
2. **Code generation quality varies.** Ollama's qwen2.5-coder is surprisingly good for detection rules, but mistral-large-2512 will catch subtle syntax issues.
3. **Privacy assumption.** This skill assumes privacy = "no cloud." If your environment allows Mistral on private networks, override the privacy signal.
4. **Task description matters.** The analysis looks for keyword signals ("code", "generate", "urgent", "offline"). Be explicit.
5. **Mistral-large is slow.** 0.07 RPS = 14 seconds between requests. Use only for one-shot deep analysis, not iteration.

## Test Driven

The demo runs 9 real detection tasks:

```
[1] Write a YARA rule → Ollama coder (local, fast)
[2] Extract IOCs → Ollama small (general, fastest)
[3] Triage alert → Mistral medium (reasoning, quality)
[4] Convert Sigma to SPL → Ollama coder (code)
[5] Lint Sigma rule → Ollama coder (code + understanding)
[6] Normalize fields → Ollama small (extraction)
[7] Deep analysis of logic → Mistral large (quality > speed)
[8] Batch 1000 logs → Mistral small (high RPS)
[9] Private incident analysis → Ollama medium (privacy)
```

All recommendations verified by running demo output.

## Troubleshooting

**"Why is this code task going to Mistral/Ollama?"**
The delegator looks for "code", "write", "generate", "convert", "yara", "sigma", "spl", "kql", "eql". Make sure your task includes one of these keywords.

**"Why not always use Mistral for quality?"**
Mistral is rate-limited. Ollama is local and fast. The delegator prefers Ollama + fallback to Mistral for common tasks. Reverse the priority if you have generous Mistral quotas.

**"How do I force a specific MCP?"**
Edit `driver.py` logic, or call delegator directly in Python and override the recommendation.
