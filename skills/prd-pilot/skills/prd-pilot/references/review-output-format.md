# Review Report Output Format

## Template

---

# 📋 PRD Review Report

**Plan**: {plan_file}
**Branch**: {branch_name}
**Base**: main ({base_commit})
**Head**: {head_commit}
**Date**: {YYYY-MM-DD HH:MM}

## 🎯 Verdict

**Overall**: 🟢 PASS / 🟡 WARN / 🔴 FAIL
**Coverage**: {n}/{total} tasks covered ({pct}%)
**Out-of-scope**: {n} files
**Missing**: {n} files

## 📊 Task Coverage

| Task | Status | Expected Files | Actual |
|------|--------|---------------|--------|
| T1: {title} | ✅ / ⚠️ / ❌ | `{file}` | ✅ changed / ❌ missing |

## 🚨 Out-of-Scope Changes

Files modified that are NOT in the Coding Plan:

| File | Severity | Analysis |
|------|----------|----------|
| `{file}` | 🔴 UNRELATED / 🟡 RELATED | {one-line explanation} |

If empty: "✅ No out-of-scope changes detected."

## ⚠️ Missing Implementations

Plan-expected files with no changes:

| Task | Expected File | Status |
|------|--------------|--------|
| T{n} | `{file}` | 🔴 MISSING / 🟡 ALTERNATIVE: may be in `{alt_file}` |

If empty: "✅ All planned changes implemented."

## 📝 Recommendations

- {Actionable items based on findings}
- {e.g., "T3 appears incomplete — proto file not regenerated"}
- {e.g., "Out-of-scope change to payment module needs justification"}

---

## Compact Format (for GitHub PR Comment)

```markdown
### 📋 PRD Review | {branch}
Plan: `{plan_file}` | Base: `{base_commit}`

**Coverage: {pct}%** ({covered}/{total} tasks)

🚨 **Out-of-scope** ({n}):
- `{file}` — {reason}

⚠️ **Missing** ({n}):
- T{n}: `{file}` not changed

✅ **Covered**:
- [x] T1: {title}
- [x] T2: {title}
- [ ] T3: {title} — missing `{file}`
```
