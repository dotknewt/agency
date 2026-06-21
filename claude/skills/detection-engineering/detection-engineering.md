---
name: detection-engineering
description: |
  Detection rule development standards. Activate when:
  - Writing, creating, or modifying Sigma/YARA rules
  - Reviewing detection rules for quality or completeness
  - Discussing detection coverage, gaps, or improvements
  - Working with YAML files containing detection logic
  - Asked to validate, check, or audit detection rules
  - Converting detections between formats (Sigma to KQL, SPL, etc.)
---

# Detection Engineering Standards

When working with detection rules, always:
1. Include ATT&CK technique mapping (TID format)
2. Document severity with justification
3. List known false positive conditions
4. Provide at least one test case