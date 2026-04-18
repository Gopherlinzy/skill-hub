# Skill Hub 工作流指南

## 📋 全貌

```
修改 skill  →  测试  →  同步  →  推送 GitHub  →  发布（自动）
```

## 🔄 完整流程

### Step 1: 修改 Skill

在 monorepo 内修改：

```bash
# Option A: TypeScript Skill (prd-pilot)
vim ~/projects/skill-hub/skills/prd-pilot/src/analyzers/linter.ts

# Option B: Markdown Skill (red-team)
vim ~/projects/skill-hub/skills/red-team/SKILL.md
```

### Step 2: 构建 & 测试（TypeScript 类）

```bash
cd ~/projects/skill-hub/skills/prd-pilot

# 编译 TypeScript
npm run build

# 运行烟测（smoke test）
npm run smoke

# 类型检查（可选）
npm run lint
```

### Step 3: 同步到 GitHub

```bash
cd ~/projects/skill-hub

# 方式 A: 自动脚本（推荐）
./scripts/sync.sh

# 方式 B: 快捷别名（需先配置，见下方）
skill-sync
```

`sync.sh` 会：
- ✅ 编译所有 TypeScript skills
- ✅ 清理临时文件（.DS_Store 等）
- ✅ Git commit（自动生成提交信息）
- ✅ 输出下一步提示

### Step 4: 推送到 GitHub

```bash
cd ~/projects/skill-hub

# 推送
git push origin main

# 查看日志
git log --oneline | head -5
```

**完成！** Skill 已发布到 GitHub，可以从 Claude Code 安装。

---

## ⚡ 快捷方式

### 配置别名（一次性）

在 `~/.zshrc` 或 `~/.bash_profile` 添加：

```bash
# Skill Hub 快捷命令
alias skill-sync='bash ~/.claude/skill-hub-sync-alias.sh'
```

然后：

```bash
source ~/.zshrc  # 重新加载配置
```

### 使用别名

```bash
skill-sync
# 会出现交互菜单，选择操作
```

---

## 📂 双向同步（可选）

如果你还在原地址编辑 skill（如 `/Users/admin/projects/prd-pilot/`），可以定期同步回 monorepo：

```bash
# 从原项目同步到 monorepo
cp -r /Users/admin/projects/prd-pilot/* ~/projects/skill-hub/skills/prd-pilot/

# 或反向同步
cp -r ~/projects/skill-hub/skills/prd-pilot/* /Users/admin/projects/prd-pilot/
```

**建议**：统一在 `~/projects/skill-hub/skills/` 下编辑，避免混淆。

---

## 🏷️ 版本管理

### 何时更新版本？

| 情况 | 版本 | 例子 |
|------|------|------|
| Bug 修复、文案改进 | Patch | 1.0.0 → 1.0.1 |
| 新功能、向后兼容 | Minor | 1.0.0 → 1.1.0 |
| 破坏性改动 | Major | 1.0.0 → 2.0.0 |

### 地点

**TypeScript Skills** (`prd-pilot`):
```json
// skills/prd-pilot/package.json
{
  "version": "1.0.1"
}
```

**Markdown Skills** (`red-team`):
```markdown
---
name: red-team
version: "1.0.1"  // 可选，或在 git tag 统一管理
---
```

---

## 🚨 常见错误

### ❌ Error: `npm: command not found`
→ 确保 Node.js 已安装：`node --version`

### ❌ Error: `git: fatal: not a git repository`
→ 确保在 monorepo 目录：`cd ~/projects/skill-hub`

### ❌ Error: `sync.sh: permission denied`
→ 赋予执行权限：`chmod +x scripts/sync.sh`

### ❌ Error: `GITHUB_TOKEN not found` during `git push`
→ Token 已配置在 ~/.zshrc（检查 CLAUDE.md），确保环境变量正确

---

## 📊 日常检查清单

- [ ] 修改 skill
- [ ] 运行 `npm run build`（TypeScript 类）
- [ ] 运行 `npm run smoke`（TypeScript 类）
- [ ] 运行 `./scripts/sync.sh`
- [ ] 检查 git 日志：`git log --oneline | head -3`
- [ ] 推送：`git push origin main`
- [ ] 在 Claude Code 中测试新版本

---

## 🎯 下一步

1. **创建 GitHub 仓库**
   ```bash
   # 在网页浏览器访问 github.com/new
   # 仓库名: skill-hub
   # 描述: Personal collection of Claude Code skills
   # 选择 Public
   # 创建后，添加 remote:
   
   cd ~/projects/skill-hub
   git remote add origin https://github.com/Gopherlinzy/skill-hub.git
   git branch -M main
   git push -u origin main
   ```

2. **配置 GitHub Actions**（可选）
   - 自动 tag 版本
   - 自动发布到 skill marketplace
   - 详见 `.github/workflows/` (待创建)

---

**现在就试试吧！**
```bash
cd ~/projects/skill-hub
./scripts/sync.sh
git push origin main
```
