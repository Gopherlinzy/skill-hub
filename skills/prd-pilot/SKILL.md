---
name: prd-pilot
description: >
  PRD-to-code conflict detection. Activate when: (1) user asks to audit/check/validate a PRD against existing code, (2) user says "prd:audit", "审 PRD", "需求冲突检测", "PRD 审查", (3) user provides a PRD document and asks if it conflicts with current implementation, (4) before Spec Coding to validate requirements feasibility. Output: structured audit report with CONFLICT/WARNING/GAP/PASS findings, each backed by code evidence (file path + line numbers). NOT for: plan generation, code review, writing PRDs, or tasks better handled by spec-kit / Superpowers.
---

# PRD Pilot — Code-Requirement Cross Analyzer

Analyze a PRD document against a project codebase to detect conflicts, gaps, and implementation risks
before coding begins. Output a structured audit report with evidence-backed findings.

## Diff Mode (Fast Path for Iterative PRD Changes)

Use Diff Mode when:
- PRD has been updated since last audit
- You have a previous audit report and want to re-audit only changed sections
- User provides `prd:audit --diff <old.md> <new.md>` command
- User says: "re-audit changed sections", "incremental audit", "only verify updates"

**Why Diff Mode matters:** PRD audits are expensive. Diff Mode detects content changes (via fingerprinting), then re-scans only modified requirements, inheriting PASS/GAP findings from unchanged sections. On typical 5-10% PRD changes, this reduces audit time by 85-90%.

### Diff Mode Workflow

#### Step C1 — Locate Cache

After reading PRD in Stage 1, immediately check for cached audit:

**For Feishu documents (with MCP):**
1. Extract `doc_id` from the PRD URL (format: `https://xxx.feishu.cn/docx/{doc_id}`)
2. Call `mcp__feishu-docs__search-doc` with empty query to retrieve document metadata
3. Locate the document entry matching `doc_id` and extract `update_time` and `create_time`
4. Search `.prd-pilot/prd/` for cache file with matching `doc_id` in frontmatter
5. Example match: `.prd-pilot/prd/user-login-v1.md` has `doc_id: xxxxxx` + `feishu_update_time: 2026-04-10` → cache found

**For local markdown files:**
- Search for `{filename}-cached.md` in `.prd-pilot/prd/`
- Example: `audit_prd.md` → look for `audit_prd-cached.md`

**If no cache found → skip Diff Mode, execute full Phase 1, then run Step C4 (cache write)**

**Note:** Feishu MCP integration provides authoritative `update_time` from the server, enabling precise version tracking without relying on content inspection alone.

#### Step C2 — Content Fingerprint Verification + Cache Staleness Check

**Cache Staleness Pre-Check (before fingerprint comparison):**

Even if fingerprint matches, verify cache is still valid:

```python
**Cache Staleness Check (Executable Commands):**

```bash
# Rule 1: Check cache age
CACHE_FILE=".prd-pilot/audit-YYYY-MM-DD.md"
CACHE_AGE_DAYS=$(( ($(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null)) / 86400 ))

if [ "$CACHE_AGE_DAYS" -gt 30 ]; then
  # Rule 2: Check if >20% of code files changed since cache
  TOTAL_CODE_FILES=$(find {project_dir} -type f \( -name "*.go" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.js" \) | wc -l)
  
  CHANGED_FILES=$(find {project_dir} -type f \( -name "*.go" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.js" \) -newer "$CACHE_FILE" | wc -l)
  
  CHANGE_PERCENTAGE=$(( (CHANGED_FILES * 100) / TOTAL_CODE_FILES ))
  
  if [ "$CHANGE_PERCENTAGE" -gt 20 ]; then
    echo "⚠️ Cache is $CACHE_AGE_DAYS days old and $CHANGE_PERCENTAGE% of code changed."
    echo "Consider running full audit for accuracy."
    # Show user prompt: "Run full audit" or "Use cache anyway"
  fi
fi
```

**Logic:**
1. Check if cache file age > 30 days
2. If yes, count how many code files modified `-newer` than cache file
3. If > 20% changed, warn user and offer choice

# If staleness detected, show user prompt:
# "⚠️  Cache is {n} days old and {change_percentage}% of code has changed since then.
#  Previous audit conclusions may be outdated. Consider running full audit for accuracy.
#  Options: ['Run full audit', 'Use cache anyway']"
```

**SKIP fingerprint comparison if:**
- Cache is > 30 days old AND > 20% code files changed since cache date
- User chooses "Run full audit" (bypass Diff Mode entirely)

**PROCEED to fingerprint comparison if:**
- Cache is fresh (< 30 days old), OR
- Code changes < 20%, OR
- User chooses "Use cache anyway"

---

**For Feishu documents (preferred):**

Use authoritative server-side metadata for fingerprinting:

```python
# Feishu API provides precise update_time
feishu_fingerprint = f"{feishu_metadata.update_time}_{doc_id}"
# Example: "2026-04-10T15:30:00+08:00_GSYawcl6jiKe0skYjxvcrt9qnbh"
```

**For local files (fallback):**

Compute client-side content fingerprint with Unicode normalization (for Chinese/multi-byte support):

```python
import unicodedata

def compute_fingerprint(content: str) -> str:
    """
    Content fingerprint with three-segment sampling for comprehensive change detection.
    
    Takes prefix, middle, and suffix to detect changes anywhere in the document,
    not just at head/tail.
    """
    import unicodedata
    
    # Normalize to NFD (Compatibility Decomposed) for stable hashing
    normalized = unicodedata.normalize('NFD', content)
    
    # Strip whitespace fluctuations (extra newlines, indentation)
    normalized = '\n'.join(line.strip() for line in normalized.split('\n') if line.strip())
    
    # Three-segment fingerprinting for better coverage
    # prefix + middle + suffix ensures changes anywhere in document are detected
    mid = len(normalized) // 2
    fingerprint = (
        f"{len(normalized)}_"
        f"{normalized[:80]}_"
        f"{normalized[mid:mid+80]}_"
        f"{normalized[-80:]}"
    )
    
    return fingerprint

# Example:
# content = "用户登录功能 —— 用户需要能通过手机号和密码登录系统..."
# fingerprint = compute_fingerprint(content)
# Result: "156_用户登录功能 —— 用户需要能通过手机号和密码登录系统_...登录失败则提示错误信息"
```

**Comparison logic:**

Compare computed fingerprint with cached `content_fingerprint`:

- **Match** → PRD unchanged. Display to user: "No changes detected in {title} (cached {cached_at}). Reusing previous audit report." Then output cached report and exit.
- **Mismatch** → PRD updated. Proceed to Step C3.

**Fingerprinting precision:** Feishu API timestamps are 100% accurate vs. content-based hashing (~85% reliable for small changes).

#### Step C3 — User Confirmation

Ask user which audit path to take:

```
Detected update in "{title}" (last cached: {cached_at}).

Options:
1. "Yes, audit changes only (faster)"        → Run Steps D1-D3 (Diff Mode)
2. "No, re-scan everything"                  → Run full Phase 1, then Step C4
```

Wait for user selection before proceeding.

#### Step C4 — Write/Update Cache

**Execution timing:** After every full Phase 1 audit (not after Diff Mode audits)

**Cache file structure:**

Create or update `.prd-pilot/prd/{title}-v{n}.md`:

```yaml
---
source_type: feishu_doc | local_file
source_url: https://xxx.feishu.cn/docx/xxxxxx        # (only for Feishu)
doc_id: xxxxxx                                        # (only for Feishu; used for matching)
title: User Login Feature PRD
version: 1                                            # Increment on each full audit
cached_at: 2026-04-11

# Feishu API metadata (populated only when source_type=feishu_doc)
feishu_update_time: "2026-04-10T15:30:00+08:00"      # Server timestamp (used for C2 comparison)
feishu_created_time: "2026-04-10T10:00:00+08:00"     # Document creation time
feishu_owner: "露娜-macbook"                          # Document owner
feishu_doc_type: "DOCX"                               # Document type

# Content fingerprint (used for local files in C2 comparison)
# Format: len_prefix80_middle80_suffix80 (three-segment for comprehensive change detection)
content_fingerprint: "15234_用户登录功能。用户需要能够通过手机号和密码登录系统_...登录失败则返回错误信息"

last_audit: ../.prd-pilot/audit-2026-04-10.md        # Path to previous Stage 5 audit report
---

{full PRD content here}
```

**Cache Field Meanings:**
- **For Feishu docs**: `feishu_update_time` is compared in Step C2
- **For local files**: `content_fingerprint` is compared in Step C2
- **Both**: `cached_at` used for staleness check (> 30 days)

**Version increment logic:**
- First cache: `version: 1`
- Each subsequent full audit: `version += 1`
- Diff Mode audits: do NOT increment version or update cache

### Manual Triggers for Diff Mode

Users can trigger Diff Mode explicitly without waiting for auto-detection:

**Command syntax:**
```bash
prd:audit --diff <old.md> <new.md>
```

**User phrases:**
- "Re-audit only the changed requirements"
- "Incremental audit"
- "Check what's new in the updated PRD"

---

### Diff Steps (D1–D3)

#### Step D1 — Parse Diff

Compare current PRD content with cached content. Classify each requirement:

| Classification | Definition | Action |
|---|---|---|
| **REVALIDATE** | New requirement or modified text | Must re-scan code in Stage 3 |
| **INHERIT** | Unchanged requirement text | Reuse finding from `last_audit` report; skip code scan |
| **RETIRE** | Requirement deleted from PRD | Check for DANGLING_CODE; mark as historical |

**Diff extraction approach:**
1. Parse both cached and current PRD into requirement lists (same structure as Stage 1)
2. Match by requirement ID or semantic similarity (if IDs change)
3. For each match, compare text:
   - If `text_changed` → REVALIDATE
   - If `text_identical` → INHERIT
   - If `no_match_in_current` → RETIRE

**RETIRE handling: Dangling Code Detection**

For each RETIRE requirement:
1. Retrieve code evidence from previous audit report (e.g., "code_file: auth.ts:45-60")
2. Extract keywords from the old requirement
3. Run quick check: `timeout 60s rg -l "{keywords}" {project_dir}`
4. If code still found:
   - Flag as ⚠️ **DANGLING_CODE** in new report
   - Reasoning: "Feature requirement removed from PRD but code still present — potential technical debt"
   - Recommendation: "Review and either: (a) add requirement back to PRD if feature is still needed, or (b) remove code from codebase"
5. If code not found:
   - Mark as **CLEAN_RETIRE** (code already removed)
   - No action needed

#### Step D2 — Map to Previous Findings

Load the `last_audit` report (from cache frontmatter). For each requirement:

- **REVALIDATE** → Note the old finding, but plan to re-scan
- **INHERIT** → Copy the old finding directly to new report (no code re-scan needed)
- **RETIRE** → Archive the old finding in a "Historical" section

**Example:**
```
Previous audit: R1 "User login by email" → PASS (finding: session.ts:45-60)
Current PRD: R1 text unchanged → INHERIT → Copy PASS to new report

Previous audit: R2 "Rate limit 3/min" → CONFLICT (finding: no rate limit code)
Current PRD: R2 text modified to "Rate limit 5/min" → REVALIDATE → Re-scan code
```

#### Step D3 — Partial Code Scan

Execute Stage 3 & 4 only for REVALIDATE requirements. For INHERIT requirements, skip Stage 3 scanning entirely.

**Scan budget for Diff Mode:**
```
- Unchanged requirements (INHERIT):  0 scans (reuse findings)
- Modified requirements (REVALIDATE): Standard Stage 3 scan per requirement
- RETIRE requirements:                0 scans (archived)

Example savings:
  Full PRD: 10 requirements, ~300 LOC to scan per req = 3000 LOC total
  Diff (10% change): 1 REVALIDATE req + 9 INHERIT
                     ~300 LOC to scan + 0 (reused)
                     = 90% reduction
```

**Output: Incremental Audit Report**

Generate Stage 5 report with:
- CONFLICT/WARNING/GAP/PASS findings from REVALIDATE scanning
- PASS findings inherited from previous audit (marked as `[inherited]`)
- Historical RETIRE findings in appendix
- Summary callout: "Incremental audit: 1 requirement changed, 9 inherited"

---

### Cache Directory Structure

```
.prd-pilot/
├── prd/                                              # Cache directory
│   ├── user-login-v1.md                             # Cached: Feishu doc
│   ├── user-login-v2.md                             # Cached: v2 (newer)
│   ├── feature-spec-cached.md                       # Cached: local file
│   └── README.md                                     # (optional) cache guide
├── audit-2026-04-10.md                              # Full audit report
├── audit-2026-04-11.md                              # Full audit report (newer)
└── code-map-2026-04-10.md                           # Generated code map (Stage 2.8)
```

### Performance Impact

| Scenario | Audit Time | vs. Full Scan | Cache Hit Rate |
|----------|-----------|---|---|
| **First audit (no cache)** | Full scan | — | 0% |
| **Cache hit + no changes** | ~30ms | ↓98% | 100% |
| **Cache hit + 10% PRD changed** | ~15-20% of full scan | ↓80-85% | 90% INHERIT |
| **Manual `--diff` specified** | Only changed sections | ↓70-90% | N/A |
| **Large project (>10k LOC) + 5% change** | ~2-3 min | ↓87% | 95% INHERIT |

---

### Diff Mode Activation Rules

Diff Mode auto-activates when ALL conditions true:

1. **Cache found** (Step C1 success)

2. **PRD content changed** (Step C2):
   - **Feishu documents**: `feishu_update_time` in cached file differs from current `update_time` (from MCP search-doc API)
   - **Local files**: `content_fingerprint` mismatch (three-segment fingerprinting)

3. **User confirms** "audit changes only" (Step C3)

**Fallback conditions:**
- If no cache found → Skip to Phase 1 (full audit)
- If cache staleness check fails (> 30 days + > 20% code changed) → Offer user choice
- User explicitly calls `prd:audit --diff` → Force Diff Mode regardless

## Inputs

Two required inputs:
1. **PRD document**: Local markdown file path (e.g., `./docs/prd-v1.md`) or Feishu doc URL
2. **Project directory**: Local codebase root (defaults to current working directory)

If user provides a Feishu doc URL, follow this confirmation protocol before extracting content:

1. Call `mcp__feishu-docs__fetch-doc` (Feishu MCP) with the document ID extracted from the URL,
   but **only read the first ~200 characters** to obtain the document title / opening line.
2. Use AskUserQuestion:
   - Question: "检测到飞书文档「{document_title}」，确认是该文档吗？"
   - Options: ["确认，继续执行", "URL 有误，我来重新提供"]
3. Wait for user's selection before proceeding.
4. Only after confirmation: extract full content, save to a temp file, and proceed.

### 🔄 Diff Mode Check (After Content Confirmed, Before Stage 1)

**CRITICAL TIMING:** Execute Diff Mode **immediately after PRD content is confirmed** (Inputs protocol), **before** entering Stage 1.

**Why this order matters:** If Diff Mode matches cache, we skip Stage 1 entirely (no need to re-extract requirements). If we do Stage 1 first and *then* discover cache, the extraction work is wasted.

**Execution flow:**
```
1. User provides PRD URL/path
2. Inputs protocol: confirm Feishu title (if URL)
3. Extract full PRD content ← Content ready
4. ↓
5. ✨ EXECUTE DIFF MODE NOW (Steps C1-C3)
   ├─ C1: Locate cache by doc_id or filename
   ├─ C2: Check fingerprint (server-time or text-based)
   └─ C3: Ask user "audit changes only or full audit?"
   
   If cache hit + no changes → Exit, output cached report
   If cache hit + changes → Enter Diff Mode (Steps D1-D3)
   If no cache found → Continue to Stage 1
   
6. ↓
7. [Stage 1 — Requirement Extraction] (only if no cache or Diff Mode decision)
```

**Key decision:** After C1-C3, make a **binary choice**:
- **Path A:** Diff Mode (C1-C3 → D1-D3) — for cached PRD with changes
- **Path B:** Full Phase 1 audit — for new PRD or cache miss
- **Path C:** Reuse cached report — for cached PRD with no changes, exit

## Phase 1: Conflict Detection (PRD vs Code)

Execute these stages sequentially. Do not skip stages.

**Note:** Phase 1 is only entered if Diff Mode check (above) determines a full audit is needed.

### Stage 1 — Requirement Extraction

Read the PRD document. Extract a structured requirement list:

```
For each requirement, extract:
- req_id: Sequential identifier (R1, R2, R3...)
- summary: One-line description
- keywords: 3-8 search terms for locating related code
- type: FEATURE_NEW | FEATURE_MODIFY | FEATURE_REMOVE | CONSTRAINT | NON_FUNCTIONAL
```

For keyword extraction guidance, read `references/requirement-taxonomy.md` if it exists.

After outputting the table, use AskUserQuestion:
- Question: "以上共 {n} 条需求，确认后进入 Stage 2，或告知需要调整的条目。"
- Options: ["确认，全部正确", "有条目需要调整（请在 Other 中说明）"]
Wait for user's response before proceeding.

### Stage 2 — Project Reconnaissance

**Command Timeout Convention:**
All external commands (`rg`, `find`, `grep`) use `timeout {T}` where T adapts to project scale:
- Small project (<30 files): T=30s
- Medium project (30-200 files): T=60s
- Large project (200+ files): T=120s
Estimate file count early via `find <dir> -maxdepth 2 -type f | wc -l` and set T accordingly.

**Path Safety Check (execute first):**
- Resolve `<dir>` to an absolute path
- Verify it is NOT a system root (`/`, `/etc`, `/usr`, `C:\`, `C:\Windows`, etc.)
- If validation fails → abort with: `❌ 项目目录路径异常：{path}。请提供项目根目录的绝对路径。`

1. Read top-level structure: `timeout {T} find <dir> -maxdepth 3 -type f | head -80`
2. Read key metadata files (if they exist): README.md, package.json, pyproject.toml, go.mod, etc.
3. Read source folder tree: `timeout {T} find <src> -maxdepth 4 -type f | head -120`

Produce a ≤300-word **Project Profile** (language, framework, main dirs, DB, API layer).

### Stage 2.5 — Documentation Health Check (Best-Effort)

> ⚠️ This stage is best-effort. Results inform but do not gate subsequent stages.

**Scale-Adaptive Skip:**
Estimate project size: `timeout {T} find <src_dir> -type f \( -name "*.go" -o -name "*.ts" -o -name "*.py" -o -name "*.java" \) | wc -l`
- If < 30 files (small project): **Full documentation check** (fast, few files — easy to verify completely).
- If >= 30 files: **Sampling check** — randomly select 5 key documents for freshness + accuracy verification.
- All project sizes continue with Stage 2.5 → 2.8 → 2.9.

**Existence check:**
- `timeout {T} find <project_dir> -maxdepth 2 -name "*.md" -not -path "*/node_modules/*" | head -20`
- If no documentation found → flag `⚠️ DOC_MISSING`

**Freshness check:**
- If last modified > 90 days ago → flag `⚠️ DOC_STALE: {filename} last updated {date}`

**Accuracy verification (best-effort):**
Spot-check a few key claims in docs against actual code (paths exist? imports match?).
Record: ✅ VERIFIED / ❌ CONTRADICTED / ⚠️ UNVERIFIABLE

**Output: Documentation Trust Score**
```
📋 Documentation Health
- Trust Level: HIGH (>80% verified) / MEDIUM (50-80%) / LOW (<50%) / NONE (no docs)
```

**Impact on subsequent stages:**
- Trust HIGH → Stage 3 can use doc-suggested paths as primary search targets
- Trust MEDIUM/LOW/NONE → Stage 3 treats docs as low-confidence hints, relies on `rg/find` discovery

### Stage 2.8 — Auto-Generate Code Map (when docs insufficient)

**Trigger**: Documentation Trust Level is MEDIUM, LOW, or NONE. Skip if HIGH.

Generate a structured code map by reading the actual codebase:

```bash
# Find entry points, routers, handlers
timeout {T} rg -l "func main\b|app\.listen|router\.|@Controller|func.*Handler" <project> -t code | head -30
# Find model/entity definitions
timeout {T} rg -l "type.*struct|class.*Model|@Entity|schema\.|CREATE TABLE" <project> -t code | head -30
# Find API route definitions
timeout {T} rg -n "GET\|POST\|PUT\|DELETE\|@Get\|@Post\|router\.\|HandleFunc" <project> -t code | head -50
```

Write to `{project_dir}/.prd-pilot/code-map-{date}.md`. Mark uncertain entries with `(?)`.
This code map becomes the primary reference for Stage 3 and Stage 4.

### Stage 2.9 — Scan Budget Preview

Estimate scan cost and confirm with user:

```bash
timeout {T} find <src_dir> -type f \( -name "*.go" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.js" \) | xargs wc -l 2>/dev/null | tail -1
```

Use AskUserQuestion:
- Question: "预计扫描 {N} 个文件、{LOC}k 行，共 {R} 条需求，继续执行 Stage 3？"
- Options: ["继续，使用默认上限", "调整上限（请在 Other 中填写数字）"]

### Stage 3 — Targeted Code Search

For each requirement from Stage 1:

1. `timeout {T} rg -l "<keyword>" <project_dir> --type-add 'code:*.{ts,tsx,js,jsx,py,go,rs,java,rb,vue,svelte}' -t code`
2. If 0 matching files → mark as `UNLOCATED`
3. For located requirements, read relevant sections: `timeout {T} rg -n -C 5 "<keyword>" <file>`
4. Cap at **2000 lines of code context per requirement** (adjust per `references/infrastructure.md` context management)

This stage is tool-driven (rg/grep/find). Do not rely on LLM memory of the codebase.

### Stage 4 — Cross Analysis

For each requirement, classify into:

| Verdict | Meaning | Action Required |
|---------|---------|-----------------|
| **CONFLICT** | PRD demands X, code does Y | Must resolve before coding |
| **WARNING** | Possible mismatch, could be indirect implementation | Human review needed |
| **PASS** | Requirement satisfied or compatible | No action |
| **GAP** | No existing code found (new feature needed) | Expected for new features |
| **UNKNOWN** | Cannot determine | Human review needed |

**Evidence rules:**
- Every CONFLICT and WARNING must include: `prd_excerpt`, `code_file`, `code_lines`, `reasoning`
- If you cannot cite specific code evidence → classify as UNKNOWN, never as CONFLICT
- Err on the side of WARNING over CONFLICT when uncertain

**False positive prevention:**
- Before marking CONFLICT, ask: "Could a developer reasonably handle this without code changes?"
- HTTP status codes can convey success/failure → front-end maps codes to text
- Missing explicit string literals ≠ "cannot display"
- Standard framework conventions count as implementation
- "Different approach, same outcome" → PASS with note, not CONFLICT

**Classification Decision Tree (boundary examples):**

| Scenario | Verdict | Reasoning |
|----------|---------|-----------|
| PRD: "显示成功提示", code returns `{code: 200}` without message | PASS | Frontend maps status codes to display text |
| PRD: "限制每人每天3次", no rate limiting code found | CONFLICT | Core constraint with no implementation evidence |
| PRD: "支持 Excel 导出", code has CSV export only | WARNING | Similar but not identical — context-dependent |
| PRD: "使用 Redis 缓存", code uses in-memory cache | WARNING | Different approach, may be intentional |
| PRD: "删除用户时同步删除关联数据", code soft-deletes only | CONFLICT | Data integrity requirement not met |

### Stage 5 — Report Assembly

**First-time write permission check:**
Before writing to `{project_dir}/.prd-pilot/` for the first time in a session, use AskUserQuestion:
- Question: "需要在项目目录创建 .prd-pilot/ 文件夹存放审计报告，是否允许？"
- Options: ["允许", "不允许，输出到终端即可"]
If user declines → print report to conversation only; do not create files.

Read `references/audit-output-format.md` if it exists; otherwise use standardized format:

```markdown
---
report_type: prd_audit
date: {YYYY-MM-DD}
prd_source: {source}
project_name: {name}
commit_hash: {hash}
summary:
  conflict: {n}
  warning: {n}
  gap: {n}
  pass: {n}
  unknown: {n}
---

# PRD Audit Report — {YYYY-MM-DD}

## Executive Summary
- Total requirements: {n}
- Status distribution: CONFLICT {n} | WARNING {n} | GAP {n} | PASS {n} | UNKNOWN {n}
- Blockers: {brief description of CONFLICTs requiring resolution}

## Findings by Category

### CONFLICT Findings
#### [{req_id}] {summary}
- **PRD Excerpt**: "{text}"
- **Code Location**: `{file}:{lines}`
- **Reasoning**: {2-3 sentences explaining mismatch}
- **Resolution**: [suggest action]

### WARNING Findings
#### [{req_id}] {summary}
- **PRD Excerpt**: "{text}"
- **Code Location**: `{file}:{lines}`
- **Reasoning**: {2-3 sentences explaining ambiguity}
- **Recommendation**: [human review suggestion]

### GAP Findings
#### [{req_id}] {summary}
- **PRD Excerpt**: "{text}"
- **Search Result**: [no code found for keywords: ...]
- **Implication**: New feature required or indirect implementation

### PASS Findings
#### [{req_id}] {summary}
- **Status**: Requirement satisfied in codebase

### UNKNOWN Findings
#### [{req_id}] {summary}
- **Reason**: [insufficient evidence to determine status]
- **Recommendation**: [suggest manual inspection or code context]

## Integration Notes

**For spec-kit:** CONFLICTs and WARNINGs become spec review items.
**For Superpowers:** Use findings to inform `superpowers:writing-plans` workflow.
**For taskforce_plan:** Neko consumes this report to refine specification and identify implementation blockers.
```

Write to: `{project_dir}/.prd-pilot/audit-{YYYY-MM-DD}.md`
If within taskforce, also copy to `blackboard/active/{task_id}_prd_audit.md`

If `.prd-pilot/` is not in `.gitignore`, display (do NOT auto-modify):
`💡 建议将 .prd-pilot/ 加入 .gitignore 以避免提交审计报告和缓存文件。`

## Tool Ecosystem & Recommended Workflow

**prd-pilot works best as part of a multi-tool pipeline.** Use this chart to choose companion tools:

| Scenario | Primary Tool | Companion | Purpose |
|----------|--------------|-----------|---------|
| Audit existing PRD | **prd-pilot** | — | Detect conflicts, gaps, risks |
| From audit → spec | prd-pilot | **spec-kit** | Convert audit findings to spec |
| From audit → plan | prd-pilot | **Superpowers:writing-plans** | Generate implementation roadmap |
| From audit → code | prd-pilot | **taskforce_plan** | Neko consumes audit for spec refinement |
| Review PR against PRD | **Superpowers** (verification-before-completion) | — | Check if changes match audit scope |
| Incremental PRD changes | **prd-pilot** (Diff Mode) | — | Re-audit only changed sections |

**Recommended Workflow:**
```
1. Run prd-pilot to audit PRD against code
   ↓
2. Review audit report (CONFLICT/WARNING/GAP/PASS)
   ↓
3. Choose path:
   a) Use spec-kit to convert findings → formal spec
   b) Use Superpowers:writing-plans to generate implementation roadmap
   c) Feed audit to taskforce_plan for automated planning
   ↓
4. Execute plan
   ↓
5. Use Superpowers `verification-before-completion` or spec-kit review to validate PR coverage
```

> 💡 **spec-kit** and **Superpowers** are recommended companion tools — not required.
> Install them independently when needed; prd-pilot works standalone without them.

## Integration with Taskforce

When used as a pre-step before `taskforce_act`:
1. PRD Pilot writes audit report to `blackboard/active/{task_id}_prd_audit.md`
2. In subsequent `taskforce_plan`, Neko reads this file to inform Spec generation
3. CONFLICTs become explicit resolution items; GAPs become new implementation items
4. PRD Pilot does NOT generate specs or code — it only detects and reports

## Limitations

- Cannot trace through highly dynamic dispatch (eval, reflection, complex DI containers)
- May miss implementations behind 3+ levels of indirection
- Non-functional requirements cannot be verified by static analysis
- Best suited for: API contracts, data models, feature flags, UI routes, config schemas
- Least suited for: cross-service interactions, runtime behavior, timing constraints

## Roadmap

See [README.md](./README.md#roadmap) for planned features and timeline.
