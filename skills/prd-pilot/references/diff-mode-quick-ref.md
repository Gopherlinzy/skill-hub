---
name: Diff Mode Quick Reference Card
description: One-page cheat sheet for Diff Mode steps C1-D3
type: reference
---

# Diff Mode — Quick Reference Card

## When to Use Diff Mode

```
✅ USE if:
- PRD was audited before (cache exists)
- PRD has been updated (new version)
- User says: "re-audit changed sections", "incremental audit"
- Command: prd:audit --diff <old.md> <new.md>

❌ DON'T USE if:
- First time auditing this PRD (no cache)
- PRD unchanged (fingerprint matches)
- User wants full re-scan
```

---

## Step C1: Locate Cache (30 seconds)

```
For FEISHU DOC:
  1. Extract doc_id from URL: https://xxx.feishu.cn/docx/{doc_id}
  2. Search .prd-pilot/prd/ for file with matching frontmatter doc_id

For LOCAL FILE:
  1. Get filename: audit_prd.md
  2. Search for audit_prd-cached.md in .prd-pilot/prd/

Result:
  ✅ Cache found  → Step C2
  ❌ Not found    → Full Phase 1 → Step C4
```

---

## Step C2: Fingerprint Check (5 seconds)

```
fingerprint = len(content) + "_" + content[:100] + "_" + content[-100:]

Compare: current_fingerprint == cached_fingerprint?

✅ MATCH    → "No changes detected. Reusing report." EXIT
❌ MISMATCH → User confirmation (Step C3)
```

---

## Step C3: User Confirmation (15 seconds)

```
Detected update in "{title}" (cached {cached_at}).

📋 Options:
   ① "Yes, audit changes only (faster)"  → D1-D3 (Diff Mode)
   ② "No, re-scan everything"            → Full Phase 1 → C4
   
Wait for choice before proceeding.
```

---

## Step D1: Parse Diff (1-2 minutes)

```
For each requirement in old PRD vs new PRD:

  text_identical?  → INHERIT (copy old finding, no scan)
  text_changed?    → REVALIDATE (must re-scan code)
  deleted?         → RETIRE (archive old finding)

Output: classification map
  {req_id: "INHERIT"|"REVALIDATE"|"RETIRE"}
```

---

## Step D2: Remap Findings (1-2 minutes)

```
Load old audit report (.prd-pilot/audit-YYYY-MM-DD.md)

For each requirement:
  
  INHERIT  → Copy old finding verbatim to new report
             Mark: [inherited from YYYY-MM-DD]
             Skip code scan entirely
  
  REVALIDATE → Mark for re-scanning (Stage 3)
               Save old finding for comparison
  
  RETIRE   → Archive in "Historical" section
```

---

## Step D3: Partial Scan (depends on % changes)

```
Execute Stage 3 & 4 for REVALIDATE requirements ONLY.

Example: 10 requirements, 10% changed
  REVALIDATE (1 req):  ~30 sec to scan
  INHERIT (9 req):     0 sec (reused)
  ───────────────────────────────
  Total: ~30 sec vs 300 sec full audit = 90% faster
```

---

## Step C4: Write Cache (if chosen)

```
After FULL audit (not after Diff Mode):

Path: .prd-pilot/prd/{title}-v{version}.md

Frontmatter:
  source_type:      feishu_doc | local_file
  doc_id:           {extracted}                   (Feishu only)
  source_url:       https://...                   (Feishu only)
  title:            {PRD title}
  version:          {increment by 1}
  cached_at:        2026-04-11
  content_fingerprint: {compute via C2 formula}
  last_audit:       ../.prd-pilot/audit-2026-04-11.md

Body: {full current PRD content}
```

---

## Performance Benchmarks

| Scenario | Time | vs. Full |
|----------|------|----------|
| Cache hit + no change | 30 ms | ↓99% |
| Cache hit + 5% change | 45 sec | ↓85% |
| Cache hit + 10% change | 90 sec | ↓90% |
| Full audit (no cache) | 7-10 min | — |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Cache not found | Filename mismatch | Check `.prd-pilot/prd/` directory |
| Fingerprint always different | Whitespace/encoding | Normalize content before computing |
| INHERIT classification wrong | Text similarity threshold too high | Lower from 0.95 to 0.90 |

---

## References

- **Full spec:** `SKILL.md` → "Diff Mode" section
- **Code examples:** `references/diff-mode-guide.md`
- **Cache directory:** `.prd-pilot/prd/`
- **Contact:** See README.md for development status
