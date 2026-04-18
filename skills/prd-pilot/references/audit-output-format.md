# PRD Audit Report Output Format

## Template

The report must follow this exact structure. Prioritize readability — key findings first, details second.

---

# 📋 PRD Audit Report

**PRD**: {prd_file_path}
**Project**: {project_dir}
**Date**: {YYYY-MM-DD HH:MM}

## 🎯 Executive Summary (Read This First)

**Overall Risk**: {HIGH / MEDIUM / LOW}

> {2-3 句话总结最重要的发现。例如："3 个核心冲突需要在编码前解决，其中 C1 和 C2 涉及 proto 重新生成。4 个新功能需求需要从零搭建模块。"}

**Top 3 Action Items:**
1. {最重要的行动项}
2. {第二重要}
3. {第三重要}

## 📊 Verdict Summary

| 🔴 CONFLICT | 🟡 WARNING | 🟢 PASS | 🔵 GAP | ⚪ UNKNOWN |
|:-:|:-:|:-:|:-:|:-:|
| {n} | {n} | {n} | {n} | {n} |

## 🔴 CONFLICTS (Must Resolve Before Coding)

### C1: {一句话标题}

**PRD 要求**: {简短引用}
**代码现状**: `{file}:{lines}` — {一句话说明代码做了什么}
**冲突点**: {为什么不兼容，2 句话}
**建议**: {怎么改}

---

(Repeat for each CONFLICT. Keep each under 8 lines.)

## 🟡 WARNINGS (Need Human Decision)

### W1: {一句话标题}

**情况**: {简短描述}
**代码参考**: `{file}:{lines}`
**为什么是 WARNING 不是 CONFLICT**: {一句话解释}
**需要确认**: {具体要确认什么，和谁确认}

---

## 🟢 PASSES

| Req | Summary | Evidence |
|:---|:---|:---|
| R{id} | {一句话} | `{file}:{lines}` ✓ |

## 🔵 GAPS (New Code Needed)

| Req | What's Needed | Estimated Scope |
|:---|:---|:---|
| R{id} | {一句话} | {small/medium/large} |

## 📝 Spec Coding Recommendations

Priority order for implementation:
1. **Resolve conflicts first**: {list C IDs}
2. **Confirm warnings**: {list W IDs + who to ask}
3. **Implement gaps by dependency**: {suggested order}
4. **Architectural note**: {any cross-cutting concern, e.g., proto regeneration, DB migration}
