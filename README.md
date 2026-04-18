# 🚀 Skill Hub

个人编写的 Claude Code Skills 集合。采用 monorepo 结构管理多个 skill。

## 📦 Skills

| Skill | 描述 | 类型 |
|-------|------|------|
| **prd-pilot** | 需求驱动的开发质量守护系统 - 分析 PRD、检测缺陷、评估 PR | TypeScript + Node |
| **red-team** | 批判性红队审查 - 挑战方案、找逻辑漏洞、质疑假设 | Markdown |

## 🛠️ 开发

### 安装依赖
```bash
cd skills/prd-pilot
npm install   # 或 pnpm install
```

### 构建
```bash
cd skills/prd-pilot
npm run build
```

### 本地测试
```bash
cd skills/prd-pilot
npm run smoke
```

## 📤 更新到 Claude Code

### 方式 1: 本地引用（开发时）
```bash
/plugin install-local /Users/admin/projects/skill-hub/skills/prd-pilot
/reload-plugins
```

### 方式 2: 从 GitHub 发布（生产）
```bash
/plugin marketplace add Gopherlinzy/skill-hub
/reload-plugins
```

## 🔄 版本发布流程

1. 修改 skill 目录下的 `package.json` 版本（或 `SKILL.md`）
2. 运行同步脚本：
```bash
./scripts/sync.sh
```
3. Push 到 GitHub：
```bash
git push origin main
```
4. GitHub Actions 自动打标签和发布（待配置）

## 📝 License

MIT
