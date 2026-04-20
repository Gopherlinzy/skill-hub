# Coding Plan Output Format

## Template

---

# 📋 Coding Plan

**PRD**: {prd_file}
**Audit**: {audit_file}
**Base Commit**: `{git rev-parse --short HEAD}`
**Generated**: {YYYY-MM-DD HH:MM}

## 🎯 Executive Summary

共 **{n}** 个变更任务，涉及 **{n}** 个文件
执行策略：先解决 {n} 个 CONFLICT，再实现 {n} 个 GAP

**执行顺序**: T1 → T2 → [T3 ∥ T4] → T5
（方括号表示可并行）

## 📝 变更任务清单

### [T1] 解决 C{id}: {冲突标题}

- **来源**: CONFLICT C{id}
- **涉及文件**:
  - `{file_path}` — {改动方向，1 句话描述}
  - `{file_path}` — {改动方向}
- **依赖**: 无
- **风险**: 🟢低 / 🟡中 / 🔴高
- **验收标准**: {从 PRD 继承}

---

### [T2] 解决 C{id}: {冲突标题}

(Same format, repeat for each CONFLICT)

---

### [T3] 实现 G{id}: {新功能标题}

- **来源**: GAP G{id}
- **涉及文件**:
  - `{new_file}` — 新建
  - `{existing_file}` — 修改（注册路由/添加依赖等）
- **依赖**: 依赖 T1（需要先修复 proto 定义）
- **规模**: small / medium / large
- **验收标准**: {AC}

---

### [DEFERRED] W{id}: {延后项标题}

- **状态**: 指挥官决定延后
- **原因**: {理由}
- **后续**: {什么条件下重新评估}

## 📊 执行顺序（依赖拓扑排序）

```
1. T1 (CONFLICT, 无依赖)     ← 先做
2. T2 (CONFLICT, 无依赖)     ← 可和 T1 并行
3. T3 (GAP, 依赖 T1)         ← T1 完成后
4. T4 (WARNING, 依赖 T3)     ← T3 完成后
```

## 🤖 CC 执行指引

- 本 Plan 为文件级指引，CC 在实现时可自主决定函数设计和代码组织
- 每完成一个 T{n}，执行 `git commit -m "[prd-pilot] T{n}: {简述}"`
- 遇到 Plan 未覆盖的情况，优先完成 Plan 内任务，额外发现记录到 `.claude-progress.md`
- 如果发现代码已在 base commit 之后被修改，标记受影响的任务并继续
