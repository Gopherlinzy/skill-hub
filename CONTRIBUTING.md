# 贡献指南

## 开发流程

### 1. 修改本地 Skill

在项目目录修改：
- **prd-pilot**: `/Users/admin/projects/prd-pilot/` 或直接在 `skills/prd-pilot/`
- **red-team**: `/Users/admin/.claude/skills/red-team/` 或直接在 `skills/red-team/`

### 2. 测试（仅限 TypeScript Skills）

```bash
cd skills/prd-pilot
npm run build
npm run smoke  # 运行烟测
```

### 3. 同步到 skill-hub

```bash
cd ~/projects/skill-hub
./scripts/sync.sh
```

这会：
- ✅ 编译 TypeScript skills
- ✅ 清理临时文件
- ✅ 提交变更
- ✅ 输出 push 指令

### 4. 发布

```bash
git push origin main
```

GitHub 会自动：
- 🏷️ 创建版本标签（基于 package.json）
- 📤 发布到 skill marketplace（待配置）

## 版本管理

### 语义版本（SemVer）

更新 skill 的版本号时，遵循 SemVer：

- `patch` (1.0.1): Bug fixes、文案改进
- `minor` (1.1.0): 新功能、不影响兼容性
- `major` (2.0.0): 破坏性改动

**TypeScript Skills** — 在 `skills/*/package.json`:
```json
{
  "version": "1.0.1"
}
```

**Markdown Skills** — 可在 `SKILL.md` 顶部注释中标注（可选）:
```markdown
---
version: "1.0.1"
---
```

## 目录说明

```
skill-hub/
├── skills/prd-pilot/     # PRD 质量审查工具
│   ├── src/              # TypeScript 源码
│   ├── dist/             # 编译输出（自动生成）
│   ├── package.json      # 依赖和版本
│   └── SKILL.md          # Skill 元数据 + 使用说明
│
├── skills/red-team/      # 红队审查 skill
│   └── SKILL.md          # 完整 Markdown 定义
│
└── scripts/
    └── sync.sh           # 同步脚本
```

## 常见问题

**Q: 如何同时更新多个 skill？**
A: 依次修改，然后运行一次 `./scripts/sync.sh` 会一起提交

**Q: Red-team 没有 package.json，怎么管理版本？**
A: Red-team 是纯 Markdown，无版本号。可在 SKILL.md 备注，或在 monorepo 的 git tag 统一管理

**Q: 本地还要保留原来的 prd-pilot 项目吗？**
A: 
- 保留无害，两者同步（可双向编辑）
- 建议都编辑 `~/projects/skill-hub/skills/prd-pilot/`，然后偶尔同步回原项目

## 工作流速记

```bash
# 1. 修改 skill
vim skills/prd-pilot/src/...

# 2. 测试（可选）
cd skills/prd-pilot && npm run build && npm run smoke

# 3. 同步
cd ~/projects/skill-hub && ./scripts/sync.sh

# 4. 推送
git push origin main

# 完成！skill 已发布到 marketplace
```
