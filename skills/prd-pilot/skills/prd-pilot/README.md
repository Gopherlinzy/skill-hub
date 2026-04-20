# PRD Pilot

**PRD × 代码库冲突检测器 — 专为 AI 编码代理设计的需求校验工具**

PRD Pilot 在编码开始前，将产品需求文档与现有代码库进行交叉验证，输出有代码证据支撑的冲突报告——作为 spec-kit 和 Superpowers 等工具的前置输入。

📖 **Blog Post / 博客文章**: [AI 写代码之前，先让它读懂 PRD——PRD Pilot 的设计与思考](https://linzyblog.netlify.app/2026/03/28/prd-pilot-design-and-thoughts/)

[中文文档](#中文文档) | [English](#features)

---

## Features

- 🔍 **Conflict Detection** — Cross-analyze PRD requirements against actual code, backed by file path + line numbers
- 📄 **Documentation Health Check** — Detect stale/inaccurate docs before relying on them
- 🗺️ **Auto Code Map** — Generate codebase understanding when docs are insufficient
- ⚡ **Diff Mode** — `prd:audit --diff v1.md v2.md` only scans changed requirements, skipping unchanged ones
- 🔗 **Tool Ecosystem Integration** — Output feeds directly into spec-kit and Superpowers

## Tool Ecosystem — When to Use What

prd-pilot is the **conflict detection layer**. Its output feeds into other tools:

```
PRD Document
    ↓
[prd-pilot: prd:audit]   ← You are here (conflict detector)
    ↓ outputs audit-YYYYMMDD.md
    ├─→ spec-kit: cp audit-*.md .specify/memory/
    │              specify init . --ai claude
    └─→ Superpowers: "Read audit-*.md as constraint context before design phase"
```

| Scenario | Recommended Tool | Reason |
|----------|-----------------|--------|
| New project, unclear requirements | **spec-kit** | PRD → Spec → Code (forward flow) |
| Existing codebase, worry about agent drift | **Superpowers** | TDD + execution guardrails |
| Team collaboration, unified doc standards | **spec-kit** | Built-in document standards |
| Solo dev, code quality + TDD | **Superpowers** | Automated TDD + review |
| Internal/private model, no CLI install | **Superpowers** | Works without CLI tools |
| Jira/DevOps integration | **spec-kit** | Rich extension ecosystem |
| Want both | **spec-kit + Superpowers-bridge** | Full pipeline integration |

## PRD Input Sources

| Source | Method | Example |
|--------|--------|---------|
| **Local file** | Direct file path | `prd:audit ./docs/prd-v1.md` |
| **Feishu Doc** | Feishu MCP API (auto-detect URL) | `prd:audit https://xxx.feishu.cn/docx/xxx` |
| **Feishu Wiki** | Feishu Wiki API | `prd:audit https://xxx.feishu.cn/wiki/xxx` |

## How It Works

### Conflict Detection (`prd:audit`)

```
PRD Document → Requirement Extraction → Code Search → Cross Analysis → Audit Report
```

1. Extracts structured requirements from your PRD (with search keywords)
2. Scans codebase using `rg/grep/find` — never relies on LLM memory
3. Classifies each requirement: **CONFLICT** / **WARNING** / **PASS** / **GAP** / **UNKNOWN**
4. Every finding includes code evidence (file path, line numbers, snippets)

### Diff Mode (`prd:audit --diff v1.md v2.md`)

Only scan requirements that changed between two PRD versions:

- **ADDED** / **MODIFIED** → full audit
- **REMOVED** → check for dangling code
- **UNCHANGED** → skip (⏭️ SKIP)

Ideal for iterative development when only part of the PRD is updated.

### Standardized Output Format

```markdown
---
audit_version: "1.0"
prd_source: "..."
project: "..."
date: "YYYY-MM-DD"
summary:
  conflict: N
  warning: N
  gap: N
  pass: N
  unknown: N
---

### [CONFLICT] R1 — {summary}
- **PRD**: "{excerpt}"
- **Code**: `path/to/file:10-25`
- **Gap**: {specific difference}
- **Action**: {what needs to change}
```

Output is machine-readable by spec-kit, Superpowers, and taskforce_plan.

## Installation

### As an OpenClaw Skill

```bash
git clone https://github.com/Gopherlinzy/prd-pilot.git ~/.openclaw/skills/prd-pilot
```

### As a Claude Code Skill

```bash
git clone https://github.com/Gopherlinzy/prd-pilot.git ~/.claude/skills/prd-pilot
```

### Install Companion Tools

```bash
# spec-kit (GitHub official)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Superpowers (Claude Code marketplace)
/plugin install superpowers@claude-plugins-official
# or for Codex:
# fetch https://raw.githubusercontent.com/obra/superpowers/main/.codex/INSTALL.md
```

## Usage

### Trigger Words

| Command | Action |
|---------|--------|
| `prd:audit` | Run conflict detection |
| `prd:audit --diff v1.md v2.md` | Diff mode — scan only changed requirements |
| `审 PRD` | Run conflict detection (Chinese) |
| `需求冲突检测` | Run conflict detection (Chinese) |

### Quick Start

```
# 1. Audit PRD against codebase
prd:audit ./docs/requirements.md

# 2. Feed results into spec-kit or Superpowers
cp .prd-pilot/audit-*.md .specify/memory/
specify init . --ai claude
```

### Output Files

```
.prd-pilot/
├── audit-2026-04-11.md       # Conflict detection report (structured, machine-readable)
└── code-map-2026-04-11.md    # Auto-generated code map (when docs insufficient)
```

## Integration

### With OpenClaw Taskforce

1. Run `prd:audit` before `执行:` to validate requirements
2. Copy `audit-*.md` to `blackboard/active/` — Neko reads it for Spec generation
3. CONFLICTs become explicit resolution items; GAPs become new implementation items

### With spec-kit

```bash
cp .prd-pilot/audit-*.md .specify/memory/
specify init . --ai claude
```

### With Superpowers

In Claude Code, before the design phase:
```
Read .prd-pilot/audit-2026-04-11.md as constraint context before design phase
```

## Roadmap

### Phase 1.2 (Q2 2026) — Diff Mode & Caching ✅ Live
- ✅ **Diff Mode** — `prd:audit --diff v1.md v2.md` cache detection + incremental scanning
- ✅ **Content Fingerprinting** — Fast delta detection (Steps C1-C2)
- ✅ **Smart Requirement Classification** — REVALIDATE / INHERIT / RETIRE (Step D1)
- ⏳ **Feishu Doc Auto-Caching** — Auto-detect Feishu URLs and cache by doc_id
- ⏳ **Cache TTL Management** — Auto-expire stale caches; team cache sharing

### Phase 2 (Q3 2026) — Performance Scale-Up
- **Parallel Code Search** — Multi-agent concurrent requirement scanning (>5k LOC projects)
- **Smart Scan Budget** — Pre-estimate audit cost; user-configurable LOC limits (Stage 2.9)
- **Code Map Versioning** — Persist Stage 2.8 code maps across audits

### Phase 3 (Q4 2026) — Ecosystem & Automation
- **Remote Repository Support** — GitHub/GitLab/Gitee URL as project input (no local clone needed)
- **Audit Report v2** — Machine-readable JSON sidecar; code dependency graphs
- **spec-kit Integration** — Auto-convert CONFLICTs/WARNINGs to spec items
- **taskforce Bridge** — Neko reads audit reports for Spec refinement

## Limitations

- Cannot trace through highly dynamic dispatch (eval, reflection, complex DI)
- May miss implementations behind 3+ levels of abstraction
- Non-functional requirements (performance, scalability) cannot be verified by static analysis
- Best for: API contracts, data models, feature flags, UI routes, config schemas

## License

MIT

---

# 中文文档

## PRD Pilot — PRD 与代码交叉冲突检测工具

**在编码开始前，验证 PRD 需求与现有代码库是否一致。输出有证据支撑的冲突报告，作为 spec-kit 和 Superpowers 的前置输入。**

## 工具生态定位

```
PRD 文档
    ↓
[prd-pilot: prd:audit]   ← 冲突检测层（你在这里）
    ↓ 输出 audit-YYYYMMDD.md
    ├─→ spec-kit: cp audit-*.md .specify/memory/
    └─→ Superpowers: "在设计阶段前读取 audit-*.md 作为约束上下文"
```

| 场景 | 推荐工具 | 理由 |
|------|----------|------|
| 新项目，需求不清晰 | **spec-kit** | PRD → 规格 → 代码（正向流程） |
| 已有代码，担心 Agent 乱改 | **Superpowers** | TDD + 执行看护 |
| 团队协作，统一文档规范 | **spec-kit** | 内置文档标准 |
| 个人开发，代码质量优先 | **Superpowers** | 自动化 TDD + Review |
| 接入公司内网模型 | **Superpowers** | 无需 CLI 工具 |
| Jira/DevOps 集成 | **spec-kit** | 丰富扩展生态 |
| 两者都想要 | **spec-kit + Superpowers-bridge** | 全流程集成 |

## 功能特性

- 🔍 **冲突检测** — 将 PRD 需求与实际代码交叉分析，每条发现附带代码证据
- 📄 **文档健康检查** — 检测过期/不准确的项目文档
- 🗺️ **自动代码地图** — 当文档不足时自动生成代码库结构
- ⚡ **差量审计** — `prd:audit --diff v1.md v2.md` 只扫变化的需求，跳过未改动项
- 🔗 **生态集成** — 输出格式兼容 spec-kit 和 Superpowers

## 工作流程

### 冲突检测 (`prd:audit`)

1. 从 PRD 提取结构化需求列表（含搜索关键词）
2. 使用 `rg/grep/find` 扫描代码库（不依赖 LLM 记忆）
3. 对每个需求分类：**CONFLICT** / **WARNING** / **PASS** / **GAP** / **UNKNOWN**
4. 每条发现附带代码证据（文件路径、行号、片段）

### 差量审计 (`prd:audit --diff v1.md v2.md`)

只扫 PRD 版本间变化的需求：
- **新增 / 修改** → 完整扫描
- **删除** → 检查是否有悬空代码（DANGLING_CODE）
- **未变** → 跳过（⏭️ SKIP）

## 安装

```bash
# OpenClaw 用户
git clone https://github.com/Gopherlinzy/prd-pilot.git ~/.openclaw/skills/prd-pilot

# Claude Code 用户
git clone https://github.com/Gopherlinzy/prd-pilot.git ~/.claude/skills/prd-pilot
```

## 触发命令

| 命令 | 动作 |
|------|------|
| `prd:audit` / `审 PRD` / `需求冲突检测` | 运行冲突检测 |
| `prd:audit --diff v1.md v2.md` / `只审变化的需求` | 差量审计 |

## 许可证

MIT
