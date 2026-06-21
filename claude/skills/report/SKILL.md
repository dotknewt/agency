---
name: report
description: |
  Generate technical security incident reports (IOCs, MITRE techniques, detection/disruption/hunting/mitigation). Activate when:
  - Analyzing malicious network traffic (Arkime, Splunk, pcap)
  - Summarizing security incident findings
  - Creating incident reports for technical audience
  - Extracting indicators of compromise (IOCs) from raw data
  - Mapping observed behaviors to MITRE ATT&CK techniques
---

# Security Incident Report Generation

Reports are technical-only. No executive summaries, compliance language (GDPR, GRC), or C-level content.

## Report Structure

All reports live in `reports/` (never root) and follow this template:

```markdown
# <Incident Title> — <Date Range>

## Summary
1–2 sentences: what happened, when, confidence level.

## IOCs
| Type | Value | Context |
|------|-------|---------|
| IP | 192.0.2.254 | SSH source, brute-force pattern |
| IP | 10.3.10.17 | SSH destination, Arkime host |
| Port | 22 | TCP SSH service |

## MITRE ATT&CK
| ID | Technique | Observed Behaviour |
|----|-----------|-------------------|
| T1046 | Network Service Discovery | DNS queries, port scanning |
| T1110 | Brute Force | Repeated SSH login attempts |
| T1021.004 | Remote Services: SSH | 31 sessions from external IP |

## Tools & Artefacts
- SSH scanner / brute-force tool (e.g., Hydra, Paramiko-based)
- Potential exfiltration tool (inferred from large data transfers)

## Detection
**Arkime query:**
```
source.ip == 192.0.2.254 AND destination.port == 22 AND date=1464
```

**Splunk query (if available):**
```
index=* earliest=2026-04-01 latest=2026-05-31 src=192.0.2.254 dest_port=22 | stats count by src, dest
```

## Disruption
- Block 192.0.2.254 at perimeter firewall
- Isolate 10.3.10.17 from network (if still compromised)
- Terminate active SSH sessions

## Hunting
**Arkime query for related activity:**
```
destination.port == 22 AND bytes > 1000000 AND date=1464
```

**Splunk query for other SSH brute force:**
```
index=* earliest=2026-04-01 latest=2026-05-31 dest_port=22 | stats count by src | where count > 10
```

## Mitigation
- Disable SSH root login
- Enforce key-based auth (disable password)
- Reduce SSH timeout / connection limits
- Enable fail2ban or similar rate-limiting
- Restrict SSH to VPN-only access

## Eradication
1. Boot affected system (10.3.10.17) into safe mode or isolated environment
2. Scan disk with antivirus/malware scanner
3. Check for persistent mechanisms (cron, systemd timers, .ssh/authorized_keys)
4. Verify no backdoor user accounts created
5. Review recent file modifications (last 61 days)
6. Restore SSH keys from known-good backup if compromised
```

## Workflow

1. **Query the data source** (Arkime or Splunk)
   - Use `mcp__arkime__search_sessions`, `mcp__arkime__get_session_summary`, or `mcp__splunk__search_events`
   - Document the query and time range

2. **Extract IOCs**
   - Use `mcp__mistral__extract_iocs` or `mcp__ollama__extract_iocs` to parse raw findings
   - Validate each IOC (IP, domain, hash, port, protocol)

3. **Map to MITRE ATT&CK**
   - For each observed behaviour, use `mcp__mitre__get_technique` to find matching technique IDs
   - Document TID, technique name, and how you observed it

4. **Fill the template**
   - Summary: concise, 1–2 sentences
   - IOCs: table format, no narrative
   - MITRE: table format, map every behavior to at least one technique
   - Tools & Artefacts: inferred from traffic patterns, not speculation
   - Detection: actual Arkime/Splunk queries (copy-paste working queries)
   - Disruption: immediate actions to stop active threat
   - Hunting: broader queries to surface related activity
   - Mitigation: hardening steps (long-term, preventive)
   - Eradication: steps to remove the threat from affected systems

5. **Write to `reports/<slug>.md`**
   - Never write to repo root
   - Slug: lowercase, hyphenated, e.g., `network-traffic-apr-may-2026.md`
   - Never overwrite without explicit user confirmation

## Checklist

- [ ] Report in `reports/` (not root)
- [ ] No GDPR, GRC, compliance, or C-level language
- [ ] All IOCs in table format with context
- [ ] All MITRE IDs validated (can test with `mcp__mitre__get_technique`)
- [ ] Detection/Disruption/Hunting/Mitigation sections have concrete steps
- [ ] No executive summary or risk matrices
- [ ] Date range clearly stated in title
- [ ] Data source (Arkime / Splunk / pcap) documented
