---
name: Diff Mode Scenario Examples
description: Real-world scenarios and step-by-step walkthroughs for Diff Mode usage
type: reference
---

# Diff Mode Scenarios & Walkthroughs

## Scenario 1: Minor PRD Update (Feature Parameter Change)

### Context
You audited a "User Registration" PRD yesterday. Today the product team updated it: the SMS verification timeout changed from 5 minutes to 10 minutes.

### Walkthrough

```
User: prd:audit ./docs/registration-prd.md

[Stage 1] Extract requirements...

[Diff Mode Auto-Detection]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CACHE HIT: Found cached "registration-prd-v1.md"
  Last updated: 2026-04-10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Detected update in "User Registration PRD" (last cached: 2026-04-10).

Options:
  1. "Yes, audit changes only (faster)"  → ~30 sec (9 INHERIT + 1 REVALIDATE)
  2. "No, re-scan everything"            → ~5 min (full audit)

→ User chooses: "Yes, audit changes only"

[Step D1] Parse diff...
  R1: Registration page UI                → INHERIT (unchanged)
  R2: Email verification                  → INHERIT (unchanged)
  R3: SMS verification timeout [UPDATED]  → REVALIDATE (param changed: 5min → 10min)
  R4: Rate limiting                       → INHERIT (unchanged)
  ...

[Step D2] Load previous findings...
  ✅ R1 (INHERIT): Copy "PASS" from audit-2026-04-10.md
  ✅ R2 (INHERIT): Copy "PASS" from audit-2026-04-10.md
  🔄 R3 (REVALIDATE): Old finding was "WARNING: timeout hardcoded to 300s"
  ✅ R4-R9 (INHERIT): Copy all findings...

[Step D3] Partial scan — R3 only...
  
  Search keywords: [sms, verification, timeout, config]
  Found: server/auth/sms.ts:45-60
    Line 50: const SMS_TIMEOUT = 300000; // 5 minutes
  
  Verdict: STILL WARNING (hardcoded, not from config)
           Recommendation: Extract 300000 to config, parameterize

[Stage 5] Generate incremental report...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRD AUDIT REPORT — 2026-04-11 (Incremental)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  Total requirements: 10
  ✅ PASS: 8 | ⚠️  WARNING: 1 | ❌ CONFLICT: 0 | 📍 GAP: 1

Incremental audit performed:
  - 1 requirement re-scanned (R3: SMS timeout)
  - 8 requirements inherited from 2026-04-10
  - 1 requirement new (R10: added after v1)

## Findings

### Updated Requirements

#### [R3] SMS Verification Timeout
- **PRD Excerpt**: "SMS verification code expires after 10 minutes if not verified"
- **Code Location**: `server/auth/sms.ts:50`
- **Old Finding**: WARNING (timeout hardcoded to 300s = 5 min)
- **New Status**: STILL WARNING
- **Reasoning**: PRD specifies 10 min, code still has 300s (5 min).
  Mismatch persists. May be intentional (stricter than PRD), but needs review.
- **Recommendation**: Confirm design intent. If intentional, update PRD to match.
                     If unintentional, update code to 600s (10 min).

### Inherited Findings (Unchanged)

#### [R1] User Registration Page
- **Status**: ✅ PASS [inherited from 2026-04-10]

#### [R2] Email Verification
- **Status**: ✅ PASS [inherited from 2026-04-10]

#### [R4-R9] (shown as inherited)

### New Requirements

#### [R10] Two-Factor Authentication (newly added)
- **Search Result**: No code found for keywords: [2fa, two-factor, totp, mfa]
- **Implication**: New feature, not yet implemented

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ REPORT WRITTEN: .prd-pilot/audit-2026-04-11.md
   (version: registration-prd-v1 → unchanged; cache not updated)
```

### Key Points
- **Time saved:** ~4 minutes 30 seconds (90% reduction)
- **Work scanned:** Only 1 requirement (R3) instead of all 10
- **Confidence:** High — 8 findings reused from tested previous audit
- **Output:** Incremental report showing exactly what changed

---

## Scenario 2: Medium Restructure (Sections Reorganized)

### Context
Your team reorganized the PRD. Sections got reordered and some requirements were consolidated, but the core functionality is the same.

### Walkthrough

```
User: prd:audit ./docs/payment-prd-v2.md

[Diff Mode Auto-Detection]

Cache found: payment-prd-v1.md (from 2026-04-05)

[Step C2] Fingerprint check...
  Cached fingerprint:   "8234_Payment feature includes..."
  Current fingerprint:  "8456_Payment integration allows..."
  
  Mismatch detected (length changed: 8234 → 8456)

[Step C3] User confirmation...
  
  📋 Options:
    1. "Yes, audit changes only"
    2. "No, full re-scan"
    
  → User chooses: "Yes, audit changes only"

[Step D1] Parse diff...
  
  Old structure (v1):
    R1: Payment gateway setup
    R2: Transaction logging
    R3: Refund processing
    R4: Payment success notification
    R5: Error handling & retry
  
  New structure (v2):
    R1: Payment gateway + setup & config (CONSOLIDATED from old R1)
    R2: Transaction logging (UNCHANGED)
    R3: Refund processing (UNCHANGED)
    R4: Success & error handling (CONSOLIDATED from old R4+R5)
    R5: Success notifications (SPLIT from old R4)
  
  Classification:
    R1 (new) → REVALIDATE (text changed: additions)
    R2       → INHERIT (identical)
    R3       → INHERIT (identical)
    R4 (new) → REVALIDATE (consolidated, text changed)
    R5 (new) → REVALIDATE (split, text changed)
    
  Old R4 → Split into new R4+R5
  Old R5 → Merged into new R4

[Step D2] Remap findings...
  
  R2 (INHERIT): Copy "PASS: payment-gateway.ts:10-50" → new audit
  R3 (INHERIT): Copy "PASS: refunds.ts:100-150" → new audit
  
  R1 (REVALIDATE): Old R1 was "PASS", but text contains new config detail
                   Plan to re-check code matches new config requirement
  
  R4 (REVALIDATE): Combination of old R4 (PASS) + old R5 (CONFLICT)
                   Will re-scan to verify conflict still present
  
  R5 (REVALIDATE): Split from old R4, was PASS
                   Quick re-check on new notification requirement

[Step D3] Partial scan — R1, R4, R5 only...
  
  R1: Config requirement
    Code check: payment-gateway.ts has ConfigManager 
    Verdict: PASS (code supports config)
  
  R4: Error handling
    Code check: error-handler.ts:45-80 has retry logic
    Verdict: PASS (matches requirement)
  
  R5: Notifications
    Code check: notifier.ts exists
    Verdict: PASS (implementation found)

[Report generation...]

Summary:
  Total requirements: 5 (consolidated from 5 in v1, but restructured)
  ✅ PASS: 5 | ⚠️  WARNING: 0 | ❌ CONFLICT: 0
  
  Incremental audit:
    - 3 unchanged → INHERIT
    - 3 re-scanned → PASS (all good)
    - No conflicts detected after restructure
```

### Key Points
- **Reorganization handled:** Semantic matching detected that R4+R5 are consolidations/splits
- **Time saved:** ~3 minutes (70% reduction vs full audit)
- **Result:** Confirmed PRD restructure doesn't introduce issues
- **Next step:** Update code cache version to v2 (increment via Step C4 after this verification)

---

## Scenario 3: Manual Diff Command (Before & After Comparison)

### Context
You have two PRD snapshots: v1.5 (pre-feedback) and v2.0 (post-feedback). You want to audit only what changed between them, without caching.

### Walkthrough

```
User: prd:audit --diff ./docs/api-v1.5.md ./docs/api-v2.0.md

[Diff Mode triggered manually]

[Step D1] Parse diff...
  
  Comparing v1.5 ← → v2.0
  
  v1.5 requirements (10 total):
    R1-R7: Unchanged (tokens match)
    R8: "Limit requests to 100/min per user"          (old)
    R9: "Cache responses for 60 sec"                  (old)
    R10: "Log all API calls"                          (old)
  
  v2.0 requirements (11 total):
    R1-R7: [INHERIT]
    R8: "Limit requests to 500/min per user"          [REVALIDATE]
    R9: "Cache responses for 5 min"                   [REVALIDATE]
    R10: "Log all API calls (only errors)"            [REVALIDATE]
    R11: "Add request ID tracing"                     [NEW → REVALIDATE]

[Step D2] Load previous findings...
  
  From cache "api-prd-v1.md":
    R1-R7: All PASS (+3 WARNINGs) → copy to new report
    R8: CONFLICT (code has 100/min hardcoded)
    R9: WARNING (no cache config)
    R10: PASS

[Step D3] Partial scan — R8, R9, R10, R11...
  
  R8 (rate limit updated):
    Code: middleware/rate-limiter.ts:30
    Old: const LIMIT = 100;  [CONFLICT]
    New requirement: 500/min
    Verdict: STILL CONFLICT (code hasn't changed, param mismatch persists)
    Recommendation: Update code to LIMIT = 500
  
  R9 (cache duration updated):
    Code: middleware/cache.ts:15
    Old: const TTL = 60;  [WARNING]
    New requirement: 5 min (300 sec)
    Verdict: Still CONFLICT (config mismatch)
    Recommendation: Update TTL to 300
  
  R10 (logging scope changed):
    Code: logger.ts:50 → logs all calls
    New requirement: only errors
    Verdict: WARNING (implementation over-logs vs. requirement, needs clarification)
    Recommendation: Add filter for error-only logging or confirm all-logging is intentional
  
  R11 (new requirement):
    Search: [request-id, trace-id, tracing]
    Result: NOT FOUND
    Verdict: GAP (new feature)

[Report: Diff-only findings]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRD DIFF AUDIT REPORT — v1.5 → v2.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4 requirements changed:
  1 CONFLICT (rate limit mismatch)
  1 WARNING (logging scope)
  1 CONFLICT (cache TTL)
  1 GAP (request ID tracing not implemented)

### Blockers (CONFLICT)
- R8: Rate limit 500/min required but code hardcoded to 100
- R9: Cache duration 5 min required but code uses 60 sec

### Review Items (WARNING + GAP)
- R10: Logging scope redefined; code logs all calls, PRD wants errors only
- R11: New feature (request ID tracing) not yet implemented

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Diff report printed to console (no cache written for --diff manual command)
```

### Key Points
- **No cache used:** `--diff` command is one-time; no caching overhead
- **Focused output:** Only shows what changed between versions
- **Actionable:** Clear blockers for developers (rate limit, cache TTL)
- **Time:** ~1-2 minutes (vs 5-10 for full audit)

---

## Scenario 4: Large PRD, Small Change (Where Diff Mode Shines)

### Context
You have a 50-requirement PRD for a complex e-commerce system. One requirement changed: "Shift from immediate order confirmation email to delayed 5-minute digest."

### Performance Impact

```
Regular audit (full Phase 1-5):
  Stage 1 (extract): 2 min      (parse 50 reqs)
  Stage 2 (recon):   1 min
  Stage 3 (search):  4 min      (search 50 × 10 keywords = 500 searches)
  Stage 4 (classify): 2 min
  Stage 5 (report):   1 min
  ──────────────────────────────
  TOTAL: ~10 min

Diff Mode (cache hit + 1 change):
  C1-C2 (cache check):  10 sec
  D1 (parse diff):      30 sec  (parse + classify 50 reqs + 1 changed)
  D2 (remap findings):  45 sec  (copy 49 findings from cache)
  D3 (partial scan):    1 min   (search 1 req × 10 keywords = 10 searches)
  Report assembly:      45 sec
  ──────────────────────────────
  TOTAL: ~3 min 10 sec

TIME SAVED: ~6 min 50 sec (68% reduction)
```

### Why This Matters

In iterative product cycles:
- **Day 1** → Audit full PRD (10 min) → Generate spec
- **Day 2** → Update 1 requirement → Re-audit min (3 min) vs 10 min
- **Day 3** → Update 2 requirements → Re-audit min (4 min) vs 10 min
- **Day 4** → Update 3 requirements → Re-audit min (5 min) vs 10 min
- **Day 5** → User accepts all 4 updates → Full audit once (10 min)

**Total time over 5 days:**
- Without Diff Mode: 10 + 10 + 10 + 10 + 10 = **50 min**
- With Diff Mode: 10 + 3 + 4 + 5 + 10 = **32 min** (36% improvement)

---

## Quick Decision Tree

```
Start: PRD has been audited before?

├─ YES, cache exists
│  ├─ Fingerprint matches (content unchanged)?
│  │  └─ YES → Reuse previous report, exit ✅
│  │  └─ NO  → Ask user
│  │          ├─ "Audit changes only" → Diff Mode (D1-D3) ⚡
│  │          └─ "Full re-scan"      → Phase 1 (full)
│  │
│  └─ NO cache found → Phase 1 (full audit)
│
└─ NO, first time (no cache)
   └─ Phase 1 (full audit) + Step C4 (write cache)

Special case: User provides --diff command
└─ Always use D1-D3 (no cache overhead)
```

---

## References

- **SKILL.md** — Full Diff Mode specification
- **diff-mode-guide.md** — Code implementation reference
- **diff-mode-quick-ref.md** — One-page cheat sheet
