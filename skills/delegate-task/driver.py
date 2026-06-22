#!/usr/bin/env python3
"""
Task delegation orchestrator for Mistral and Ollama MCPs.

Analyzes task characteristics and recommends the most appropriate MCP
and model size. Can optionally invoke the recommended service.
"""

import sys
import json
from dataclasses import dataclass
from typing import Literal


@dataclass
class TaskCharacteristics:
    """Extracted attributes of a task."""
    needs_code_generation: bool = False
    needs_code_understanding: bool = False
    requires_reasoning: bool = False
    requires_high_quality: bool = False
    time_sensitive: bool = False
    requires_privacy: bool = False
    task_type: str = "general"  # general, code, detection, analysis, extraction
    complexity: str = "low"  # low, medium, high
    token_budget: str = "standard"  # tight, standard, generous


@dataclass
class Recommendation:
    """Delegation recommendation."""
    preferred_mcp: Literal["mistral", "ollama"]
    model: str
    rationale: str
    fallback_mcp: str | None = None
    fallback_model: str | None = None


class TaskDelegator:
    """Routes tasks to appropriate MCP and model."""

    # Ollama models (local, privacy-preserving, low-latency)
    OLLAMA_MODELS = {
        "small": "mistral:7b",              # Fast, general-purpose
        "medium": "qwen2.5:14b",            # Balanced, reasoning
        "code": "qwen2.5-coder:7b",         # Code-focused
        "large": "qwen2.5:32b",             # High quality (slower)
    }

    # Mistral models (cloud, high-quality, rate-limited)
    MISTRAL_MODELS = {
        "small": "mistral-small-2506",      # 5 RPS, general-purpose
        "code": "devstral-2512",            # 0.83 RPS, code generation
        "medium": "mistral-medium-2505",    # 0.42 RPS, high quality
        "large": "mistral-large-2512",      # 0.07 RPS, highest quality
    }

    def analyze_task(self, task_description: str) -> TaskCharacteristics:
        """Extract task characteristics from description."""
        task_lower = task_description.lower()

        # Code generation signals
        needs_code = any(word in task_lower for word in [
            "write code", "generate", "implement", "function", "script",
            "convert", "yara", "sigma", "spl", "kql", "eql"
        ])

        # Code understanding signals
        needs_understanding = any(word in task_lower for word in [
            "lint", "fix", "review", "syntax", "yaml", "parse"
        ])

        # Reasoning signals
        needs_reasoning = any(word in task_lower for word in [
            "assess", "evaluate", "analyze", "compare", "explain",
            "reason", "triage", "categorize", "prioritize"
        ])

        # High quality signals
        needs_quality = any(word in task_lower for word in [
            "accuracy", "thorough", "comprehensive", "deep analysis",
            "quality", "detail", "expert"
        ])

        # Time sensitivity signals
        time_sensitive = any(word in task_lower for word in [
            "fast", "quick", "urgent", "immediately", "high throughput",
            "batch", "many", "volume"
        ])

        # Privacy signals
        needs_privacy = any(word in task_lower for word in [
            "local", "private", "confidential", "sensitive", "offline",
            "no cloud"
        ])

        # Task type classification
        if "code" in task_lower or "yara" in task_lower or "sigma" in task_lower:
            task_type = "code"
        elif any(w in task_lower for w in ["detect", "threat", "ioc", "malware"]):
            task_type = "detection"
        elif any(w in task_lower for w in ["analyze", "assess", "evaluate", "review"]):
            task_type = "analysis"
        elif any(w in task_lower for w in ["extract", "map", "normalize", "transform"]):
            task_type = "extraction"
        else:
            task_type = "general"

        # Complexity inference
        if needs_reasoning or needs_quality:
            complexity = "high"
        elif needs_code or "detect" in task_lower:
            complexity = "medium"
        else:
            complexity = "low"

        # Token budget inference
        if time_sensitive or "batch" in task_lower:
            token_budget = "tight"
        elif needs_quality:
            token_budget = "generous"
        else:
            token_budget = "standard"

        return TaskCharacteristics(
            needs_code_generation=needs_code,
            needs_code_understanding=needs_understanding,
            requires_reasoning=needs_reasoning,
            requires_high_quality=needs_quality,
            time_sensitive=time_sensitive,
            requires_privacy=needs_privacy,
            task_type=task_type,
            complexity=complexity,
            token_budget=token_budget,
        )

    def delegate(self, task_description: str) -> Recommendation:
        """Recommend MCP and model for a task."""
        chars = self.analyze_task(task_description)

        # Privacy-first: if local/private needed, use Ollama
        if chars.requires_privacy:
            model_size = "large" if chars.requires_high_quality else "medium"
            return Recommendation(
                preferred_mcp="ollama",
                model=self.OLLAMA_MODELS[model_size],
                rationale=f"Privacy required: using local Ollama {model_size} model",
                fallback_mcp=None,
            )

        # Code generation: prefer code-specific models
        if chars.needs_code_generation:
            # Time-sensitive code: fast mistral code model
            if chars.time_sensitive:
                return Recommendation(
                    preferred_mcp="mistral",
                    model=self.MISTRAL_MODELS["code"],
                    rationale="Code generation + time-sensitive: Mistral Codestral (0.83 RPS)",
                    fallback_mcp="ollama",
                    fallback_model=self.OLLAMA_MODELS["code"],
                )
            # High quality code: large mistral model
            elif chars.requires_high_quality:
                return Recommendation(
                    preferred_mcp="mistral",
                    model=self.MISTRAL_MODELS["large"],
                    rationale="Code generation + high quality: Mistral Large (slow but best quality)",
                    fallback_mcp="ollama",
                    fallback_model=self.OLLAMA_MODELS["large"],
                )
            # Standard code: ollama or medium mistral
            else:
                return Recommendation(
                    preferred_mcp="ollama",
                    model=self.OLLAMA_MODELS["code"],
                    rationale="Code generation: Ollama coder model (local, fast)",
                    fallback_mcp="mistral",
                    fallback_model=self.MISTRAL_MODELS["code"],
                )

        # High complexity/quality: prefer Mistral
        if chars.complexity == "high" or (chars.requires_high_quality and not chars.time_sensitive):
            model_size = "large" if chars.requires_high_quality else "medium"
            return Recommendation(
                preferred_mcp="mistral",
                model=self.MISTRAL_MODELS[model_size],
                rationale=f"High complexity/quality: Mistral {model_size} model",
                fallback_mcp="ollama",
                fallback_model=self.OLLAMA_MODELS["medium"],
            )

        # Time-sensitive: prefer fast Mistral
        if chars.time_sensitive:
            return Recommendation(
                preferred_mcp="mistral",
                model=self.MISTRAL_MODELS["small"],
                rationale="Time-sensitive: Mistral Small (5 RPS, high throughput)",
                fallback_mcp="ollama",
                fallback_model=self.OLLAMA_MODELS["small"],
            )

        # Default: balance local speed and quality
        if chars.requires_reasoning:
            return Recommendation(
                preferred_mcp="ollama",
                model=self.OLLAMA_MODELS["medium"],
                rationale="Reasoning task: Ollama medium (local, balanced)",
                fallback_mcp="mistral",
                fallback_model=self.MISTRAL_MODELS["small"],
            )

        # General/extraction tasks: fast local model
        return Recommendation(
            preferred_mcp="ollama",
            model=self.OLLAMA_MODELS["small"],
            rationale="General task: Ollama small (local, fast)",
            fallback_mcp="mistral",
            fallback_model=self.MISTRAL_MODELS["small"],
        )


def main():
    """Demo and test the delegator."""
    delegator = TaskDelegator()

    # Test cases covering different task types
    test_tasks = [
        "Write a YARA rule to detect the malware from these IOCs",
        "Extract indicators of compromise from this log dump",
        "Triage this alert: is it likely a false positive?",
        "Convert this Sigma rule to Splunk SPL for index=main",
        "Lint and fix this Sigma detection rule",
        "Normalize raw log fields to ECS schema",
        "Deep analysis of detection logic: why did this rule miss X?",
        "Batch process 1000 logs and extract IOCs quickly",
        "Analyze this security incident privately (no cloud)",
    ]

    print("=" * 80)
    print("TASK DELEGATION ANALYZER")
    print("=" * 80)

    for i, task in enumerate(test_tasks, 1):
        print(f"\n[Task {i}] {task}")
        recommendation = delegator.delegate(task)
        print(f"  MCP: {recommendation.preferred_mcp}")
        print(f"  Model: {recommendation.model}")
        print(f"  Rationale: {recommendation.rationale}")
        if recommendation.fallback_mcp:
            print(f"  Fallback: {recommendation.fallback_mcp} / {recommendation.fallback_model}")

    # JSON output mode (for programmatic use)
    print("\n" + "=" * 80)
    print("JSON OUTPUT (for integration)")
    print("=" * 80)
    task = "Write a Sigma detection rule for PowerShell script block logging"
    rec = delegator.delegate(task)
    output = {
        "task": task,
        "recommendation": {
            "mcp": rec.preferred_mcp,
            "model": rec.model,
            "rationale": rec.rationale,
            "fallback": {
                "mcp": rec.fallback_mcp,
                "model": rec.fallback_model,
            } if rec.fallback_mcp else None,
        }
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
