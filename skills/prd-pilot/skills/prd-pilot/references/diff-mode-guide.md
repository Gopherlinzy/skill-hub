---
name: Diff Mode Implementation Guide
description: Reference guide for implementing Diff Mode steps C1-D3 with code examples
type: reference
---

# Diff Mode — Implementation Reference

This document provides code scaffolds and decision trees for Diff Mode steps in SKILL.md.

## Quick Reference: Diff Mode Steps

| Step | Input | Output | Trigger |
|------|-------|--------|---------|
| C1 | PRD path or Feishu URL | Cache location (if found) | After Stage 1 PRD read |
| C2 | Current content + cached frontmatter | Fingerprint match result | If C1 found cache |
| C3 | Fingerprint mismatch | User choice: `--diff` or full audit | If C2 mismatch |
| D1 | Previous cached PRD + current PRD | Diff classification (REVALIDATE/INHERIT/RETIRE) | If user chooses `--diff` |
| D2 | Previous audit report + D1 classifications | Finding remappings | After D1 |
| D3 | REVALIDATE requirements | Incremental audit report | After D2 |

---

## Step C1: Cache Lookup (Code Reference)

### Feishu Document

Extract doc_id from URL, search `.prd-pilot/prd/` by frontmatter field:

```python
import re
from pathlib import Path

def extract_feishu_doc_id(url: str) -> str:
    """Extract doc_id from Feishu URL."""
    # Format: https://xxx.feishu.cn/docx/{doc_id}
    match = re.search(r'/docx/([a-zA-Z0-9]+)', url)
    if match:
        return match.group(1)
    raise ValueError(f"Invalid Feishu URL: {url}")

def find_cache_by_doc_id(doc_id: str, cache_dir: Path) -> Path | None:
    """Search .prd-pilot/prd/ for cache file matching doc_id."""
    cache_dir = cache_dir / "prd"
    if not cache_dir.exists():
        return None
    
    for cache_file in cache_dir.glob("*.md"):
        with open(cache_file) as f:
            if f"doc_id: {doc_id}" in f.read()[:500]:  # Check frontmatter only
                return cache_file
    
    return None

# Usage
feishu_url = "https://xxx.feishu.cn/docx/abc123xyz"
doc_id = extract_feishu_doc_id(feishu_url)
cache = find_cache_by_doc_id(doc_id, Path(".prd-pilot"))
if cache:
    print(f"✅ Cache found: {cache}")
else:
    print("❌ No cache found, will do full audit")
```

### Local File

```python
def find_cache_by_filename(prd_path: str, cache_dir: Path) -> Path | None:
    """Search for {filename}-cached.md in .prd-pilot/prd/."""
    prd_name = Path(prd_path).stem  # "audit_prd.md" → "audit_prd"
    cache_file = cache_dir / "prd" / f"{prd_name}-cached.md"
    
    if cache_file.exists():
        return cache_file
    return None

# Usage
cache = find_cache_by_filename("./docs/audit_prd.md", Path("."))
```

---

## Step C2: Fingerprinting (Code Reference)

### Compute Fingerprint

```python
def compute_fingerprint(content: str) -> str:
    """
    Quick delta detection: length + first 100 chars + last 100 chars.
    Detects 95%+ of meaningful PRD changes.
    """
    return f"{len(content)}_{content[:100]}_{content[-100:]}"

def extract_cache_fingerprint(cache_path: Path) -> str:
    """Extract content_fingerprint from cache frontmatter."""
    with open(cache_path) as f:
        content = f.read()
    
    # Extract YAML frontmatter
    lines = content.split('\n')
    for i, line in enumerate(lines[1:], 1):  # Skip opening ---
        if 'content_fingerprint:' in line:
            # Extract quoted value
            fingerprint = line.split('content_fingerprint:')[1].strip().strip('"')
            return fingerprint
        if line == '---':  # End of frontmatter
            break
    
    return None

# Usage
current_fingerprint = compute_fingerprint(current_prd_content)
cached_fingerprint = extract_cache_fingerprint(cache_file)

if current_fingerprint == cached_fingerprint:
    print("✅ No changes detected")
    return {"status": "cache_hit_no_changes"}
else:
    print(f"⚠️  Changes detected: {cached_fingerprint[:50]}... → {current_fingerprint[:50]}...")
    return {"status": "fingerprint_mismatch"}
```

---

## Step D1: Diff Parsing (Decision Tree)

### Requirement Matching Strategy

When comparing two PRD versions, match requirements by:

1. **Explicit ID** (if PRD uses numbered IDs like R1, R2)
   ```
   Old PRD: "R1: User login by email"
   New PRD: "R1: User login by email or phone"
   → Match on ID, classify as REVALIDATE
   ```

2. **Semantic Similarity** (if no explicit IDs; fallback)
   ```
   Old PRD: "Limit login attempts to 3 per minute"
   New PRD: "Limit login attempts to 5 per minute"
   → High text similarity → likely same requirement → REVALIDATE
   ```

3. **Position** (last resort; unreliable)
   ```
   Old PRD line 5: "Requirement X"
   New PRD line 5: "Requirement Y"
   → If no match above, use position (risk of false matches)
   ```

### Diff Classification Logic

```python
from difflib import SequenceMatcher

def classify_requirement_change(old_req: dict, new_req: dict) -> str:
    """
    Classify a requirement as REVALIDATE, INHERIT, or RETIRE.
    
    old_req: {"id": "R1", "summary": "...", "keywords": [...]}
    new_req: {"id": "R1", "summary": "...", "keywords": [...]}
    """
    
    # Compare requirement summaries
    old_text = old_req.get("summary", "").lower()
    new_text = new_req.get("summary", "").lower()
    
    # 95%+ text match = unchanged
    if SequenceMatcher(None, old_text, new_text).ratio() > 0.95:
        return "INHERIT"
    
    # Text changed = revalidate
    if old_text != new_text:
        return "REVALIDATE"
    
    # Fallback: check keyword change
    old_keywords = set(old_req.get("keywords", []))
    new_keywords = set(new_req.get("keywords", []))
    
    if old_keywords != new_keywords:
        return "REVALIDATE"
    
    return "INHERIT"

def classify_all_changes(old_reqs: list, new_reqs: list) -> dict:
    """
    Build a classification map: {req_id: "REVALIDATE"|"INHERIT"|"RETIRE"}
    """
    old_by_id = {r["id"]: r for r in old_reqs}
    new_by_id = {r["id"]: r for r in new_reqs}
    
    classifications = {}
    
    # Revalidate and inherit
    for req_id, new_req in new_by_id.items():
        if req_id in old_by_id:
            classifications[req_id] = classify_requirement_change(
                old_by_id[req_id], 
                new_req
            )
        else:
            # New requirement (not in old)
            classifications[req_id] = "REVALIDATE"
    
    # Retire
    for req_id in old_by_id:
        if req_id not in new_by_id:
            classifications[req_id] = "RETIRE"
    
    return classifications

# Usage
classifications = classify_all_changes(old_requirements, new_requirements)
for req_id, classification in classifications.items():
    print(f"{req_id}: {classification}")
```

---

## Step D2: Finding Remapping (Reference)

### Load Previous Audit Report

```python
import yaml

def load_audit_report(report_path: Path) -> dict:
    """Parse previous audit report to extract findings by req_id."""
    with open(report_path) as f:
        content = f.read()
    
    # Parse YAML frontmatter
    lines = content.split('\n')
    fm_end = None
    for i, line in enumerate(lines[1:], 1):
        if line == '---':
            fm_end = i
            break
    
    frontmatter = yaml.safe_load('\n'.join(lines[:fm_end]))
    body = '\n'.join(lines[fm_end+1:])
    
    # Extract findings by req_id (e.g., "[R1] Summary")
    import re
    findings = {}
    
    for section in body.split('#### '):
        match = re.match(r'\[(\w+)\]\s+(.*)\n', section)
        if match:
            req_id = match.group(1)
            findings[req_id] = section
    
    return {
        "frontmatter": frontmatter,
        "findings": findings
    }

# Usage
old_audit = load_audit_report(Path(".prd-pilot/audit-2026-04-10.md"))
print(f"Loaded {len(old_audit['findings'])} findings")
```

### Inherit Findings

```python
def inherit_finding(req_id: str, old_audit: dict, new_findings: list) -> None:
    """
    Copy finding from old audit directly to new report (no re-scan).
    Mark with [inherited] tag.
    """
    
    if req_id not in old_audit["findings"]:
        print(f"⚠️  No prior finding for {req_id}, skipping inherit")
        return
    
    old_section = old_audit["findings"][req_id]
    
    # Add [inherited] marker
    inherited_section = f"{old_section}\n\n> **[inherited from {old_audit['frontmatter']['date']}]**"
    
    new_findings.append(inherited_section)
```

---

## Step D3: Partial Scan Execution

### Build Scan Task List

```python
def build_revalidate_tasks(classifications: dict, new_reqs: list) -> list:
    """
    Extract requirements that need re-scanning (REVALIDATE only).
    Return a list of Stage 3 scan tasks.
    """
    tasks = []
    
    for req in new_reqs:
        if classifications.get(req["id"]) == "REVALIDATE":
            tasks.append({
                "req_id": req["id"],
                "summary": req["summary"],
                "keywords": req["keywords"],
                "type": req["type"],
                "scan_reason": "changed"
            })
    
    return tasks

def execute_partial_scan(revalidate_tasks: list, project_dir: Path) -> list:
    """
    Execute Stage 3 code search for REVALIDATE requirements only.
    Reuse Stage 4 classification logic.
    """
    findings = []
    
    for task in revalidate_tasks:
        print(f"  Scanning {task['req_id']}: {task['summary']}")
        
        # Stage 3: Targeted code search (same as full audit)
        code_files = search_keywords(task["keywords"], project_dir)
        
        # Stage 4: Cross analysis (same as full audit)
        verdict = classify_finding(task, code_files)
        
        findings.append({
            "req_id": task["req_id"],
            "verdict": verdict,
            "code_files": code_files
        })
    
    return findings

# Usage
revalidate_tasks = build_revalidate_tasks(classifications, new_reqs)
print(f"Will re-scan {len(revalidate_tasks)} changed requirements")

new_findings = execute_partial_scan(revalidate_tasks, project_dir)
```

### Report Generation (Incremental)

```python
def generate_incremental_report(
    old_audit: dict,
    new_revalidate_findings: list,
    classifications: dict,
    old_reqs: list,
    new_reqs: list
) -> str:
    """Generate incremental audit report with reused + new findings."""
    
    revalidate_count = sum(1 for c in classifications.values() if c == "REVALIDATE")
    inherit_count = sum(1 for c in classifications.values() if c == "INHERIT")
    retire_count = sum(1 for c in classifications.values() if c == "RETIRE")
    
    report = f"""# Incremental Audit Report — 2026-04-11

## Executive Summary
- Total new requirements: {len(new_reqs)}
- Changes: {revalidate_count} REVALIDATE | {inherit_count} INHERIT | {retire_count} RETIRE
- Inherited findings: {inherit_count}
- New findings: {len(new_revalidate_findings)}

## Analysis & Findings

### New / Modified Requirements (Re-scanned)
"""
    
    for finding in new_revalidate_findings:
        report += f"\n#### [{finding['req_id']}] ...\n"
    
    report += "\n### Inherited Findings (Unchanged)\n"
    
    for req_id, classification in classifications.items():
        if classification == "INHERIT" and req_id in old_audit["findings"]:
            report += old_audit["findings"][req_id]
    
    report += "\n## Historical (Retired)\n"
    
    for req_id, classification in classifications.items():
        if classification == "RETIRE":
            if req_id in old_audit["findings"]:
                report += f"- [{req_id}] (deleted from PRD)\n"
    
    return report
```

---

## Performance Metrics

### Benchmarks

On typical projects:

| Scenario | Duration | vs. Full |
|----------|----------|---|
| No cache | 5-10 min | — |
| Cache hit, no change | ~30ms | ↓99% |
| Cache hit, 10% change | 45-90 sec | ↓85% |
| Manual `--diff` | 1-2 min | ↓80% |

### Time Breakdown (Full Audit)

```
Stage 1 (Req extraction):     30 s
Stage 2 (Reconnaissance):     60 s  ← eliminated in Diff Mode (cache reuse)
Stage 2.5-2.9 (Checks):       45 s  ← eliminated in Diff Mode
Stage 3 (Code search):        180 s ← reduced proportionally (REVALIDATE only)
Stage 4 (Classification):     90 s  ← reduced proportionally
Stage 5 (Report):             15 s
─────────────────────────────────
Total: ~420 s (7 min)

Diff Mode (10% change):
C1-C2 (cache check):          2 s
D1 (parse diff):              5 s
D2 (remap findings):          8 s
D3 (partial scan):            ~42 s (10% of Stage 3 + 4)
Report generation:            10 s
─────────────────────────────────
Total: ~67 s (85% reduction)
```

---

## Troubleshooting

### Cache Miss: File Exists but Not Detected

**Symptom:** `.prd-pilot/prd/foo.md` exists, but `find_cache_by_filename()` returns None.

**Causes:**
- File name mismatch (e.g., looking for `audit_prd-cached.md` but file is `audit-prd-cached.md`)
- Frontmatter parsing failed (YAML syntax error)

**Fix:**
```python
# Debug: List all cache files
cache_dir = Path(".prd-pilot/prd")
for f in cache_dir.glob("*.md"):
    print(f"Found cache: {f.name}")
    with open(f) as fp:
        print(fp.readline()[:100])  # Print first line (should be "---")
```

### Fingerprint Always Different

**Symptom:** Fingerprint mismatch even though content looks unchanged.

**Causes:**
- Trailing whitespace/newlines differ
- Character encoding issue (UTF-8 vs. others)

**Fix:**
```python
def compute_fingerprint_normalized(content: str) -> str:
    """Normalize before fingerprinting."""
    normalized = content.strip().replace('\r\n', '\n')  # Unix line endings
    return f"{len(normalized)}_{normalized[:100]}_{normalized[-100:]}"
```

### Diff Classification Uncertain

**Symptom:** Requirement text barely changed but INHERIT classifies it as identical.

**Fix:** Adjust the semantic similarity threshold:
```python
# Current: 0.95 = very strict (minor changes not detected)
if SequenceMatcher(None, old_text, new_text).ratio() > 0.90:  # More sensitive
    return "INHERIT"
elif SequenceMatcher(None, old_text, new_text).ratio() > 0.80:
    return "REVALIDATE"  # Force re-scan on moderate changes
```

---

## See Also

- `SKILL.md` — Main Diff Mode specification
- `audit-output-format.md` — Report structure reference
- `.prd-pilot/` — Live cache directory structure
