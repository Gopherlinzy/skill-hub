# Infrastructure Improvements

These improvements enhance reliability and performance without changing user-facing commands or interaction patterns.
Load this file only when needed (large projects, long audits, or explicit user request).

## Checkpoint & Resume (Opt-in)

Long audits (10+ requirements, large codebases) may fail mid-process due to context limits, tool errors, or session interruption. Checkpoint is **disabled by default** — enable with `--checkpoint`.

**Protocol:**
1. Only activate when user explicitly includes `--checkpoint` in their command (e.g., `prd:audit ./prd.md --checkpoint`).
   - If `--checkpoint` is NOT present → skip all checkpoint logic entirely. No checkpoint files, no security notices.
   - If `--checkpoint` IS present → proceed with checkpoint as below.
2. After completing each requirement's code search (Stage 3), save intermediate results to `.prd-pilot/checkpoint-{date}.json`
3. **Security notice (display once per session when first checkpoint is written):**
   ```
   ⚠️ Checkpoint 文件包含从代码库提取的代码片段，请勿将其提交到版本控制。
   💡 建议将 .prd-pilot/ 加入 .gitignore 以避免提交审计报告和缓存文件。
   ```
   Do NOT auto-modify `.gitignore`. Only display the suggestion above.
4. Checkpoint format:
   ```json
   {
     "audit_date": "2026-03-28",
     "base_commit": "abc123",
     "prd_source": "./docs/prd-v1.md",
     "completed_requirements": ["R1", "R2", "R3"],
     "pending_requirements": ["R4", "R5"],
     "stage": "3-code-search",
     "results": { "R1": { "verdict": "CONFLICT", "files": [...] }, ... }
   }
   ```
5. On resume: detect existing checkpoint → ask user "Resume from checkpoint (3/5 requirements done)?" → skip completed requirements
6. Checkpoint is deleted after successful report generation

## Parallel Code Search (Future)

Stage 3 currently searches requirements sequentially. Since requirements are independent, they can be searched in parallel for significant speedup. **This feature is not yet implemented.**

**Environment Detection (when implemented):**
- If running within OpenClaw taskforce with parallel agent support → use parallel subagents
- If running in single-agent mode (standard Claude Code / claude.ai) → fall back to sequential search
  with a progress indicator:
  ```
  🔍 顺序搜索中（单 Agent 模式）：R1/{total} → R2/{total} → ...
  ```
  Sequential search in single-agent mode is functionally equivalent; only throughput differs.

**Protocol (multi-agent mode):**
1. After Stage 1 (requirement extraction), group requirements into independent batches
2. In Stage 3, search multiple requirements simultaneously rather than one-by-one
3. Use parallel subagent spawns when available
4. Merge results after all searches complete
5. Expected speedup: 3-5x for audits with 8+ requirements

**Constraint:** Parallel search must not compromise evidence quality. Each requirement still needs full `rg` search with context lines.

## Graceful Degradation & Error Recovery

Tool commands may fail due to missing dependencies or environment issues. Implement fallback chains instead of aborting.

**Fallback chains:**

| Tool | Primary | Fallback 1 | Fallback 2 |
|------|---------|------------|------------|
| Code search | `timeout {T} rg -n -C 5` | `timeout {T} grep -rn` | `find + cat` |
| Git operations | `git diff`, `git log` | `diff` on files | Skip git-dependent features, note in report |
| Feishu doc read | `feishu_doc` API | `feishu_wiki` API | Prompt user to paste content manually |
| Project structure | `timeout {T} find -maxdepth 3` | `ls -R` | `tree` (if available) |

**Error reporting:** When a fallback is activated, include a note in the audit report:
```
⚠️ DEGRADED: rg not available, fell back to grep. Search results may be less precise.
```

## Code Map Persistence & Reuse

Stage 2.8 generates a code map when documentation is insufficient. Enable reuse across sessions.

**Protocol:**
1. After generating code map, save to `.prd-pilot/code-map-{date}.md`
2. On subsequent audits, check for existing code map:
   - If exists and less than 7 days old → load and reuse (skip Stage 2.8)
   - If exists but older than 7 days → regenerate and replace
   - If codebase has changed significantly (>20% files modified since map date via `git diff --stat`) → regenerate
3. Support explicit refresh: when user says "prd:audit --refresh-map" or "重新生成代码地图", force regeneration
4. Code map file includes generation metadata:
   ```markdown
   <!-- Generated: 2026-03-28 | Commit: abc123 | Files analyzed: 142 -->
   ```

Note: Code map is best-effort. Mark any uncertain entries with `(?)`. An incorrect code map can be more misleading than having none — always cross-verify key claims with `rg`.

## Context Window Management

For large monorepos (100k+ LOC), the 2000-line-per-requirement cap in Stage 3 may be insufficient or wasteful. Adapt based on project scale.

**Protocol:**
1. During Stage 2 (Project Reconnaissance), estimate project scale:
   - Small (<10k LOC): 2000 lines/requirement (default)
   - Medium (10k-50k LOC): 1500 lines/requirement
   - Large (50k-100k LOC): 1000 lines/requirement, prioritize by keyword hit density
   - Very large (100k+ LOC): 800 lines/requirement, use file-level summaries for low-relevance matches
2. For files exceeding the per-requirement budget:
   - Extract only the functions/classes containing keyword hits (not entire file)
   - Include surrounding context (10 lines before/after the match)
3. Report the context budget used in the audit summary:
   ```
   📊 Context budget: 1000 lines/requirement (large project, 85k LOC)
   Total context consumed: 8,420 lines across 8 requirements
   ```
