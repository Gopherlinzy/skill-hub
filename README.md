# 🚀 Skill Hub

Personal collection of Claude Code skills.

## 📦 Skills

| Skill | Description |
|-------|-------------|
| **prd-pilot** | PRD-driven development — analyzes requirements, detects gaps, reviews PRs against specs |
| **red-team** | Critical review — challenges proposals, finds logic flaws, questions assumptions |

## 📥 Installation

### 推荐方法：从 Marketplace 安装 ⭐

在 Claude Code 中执行（复制粘贴即可）：

```bash
/plugin marketplace add Gopherlinzy/skill-hub
```

然后安装你需要的 skill：

```bash
/plugin install red-team@skill-hub
/plugin install prd-pilot@skill-hub
```

或一键全装：
```bash
/plugin install red-team@skill-hub && /plugin install prd-pilot@skill-hub
```

### 开发者方法：本地安装

如果你要修改或调试 skill：

```bash
git clone https://github.com/Gopherlinzy/skill-hub.git ~/projects/skill-hub
/plugin install-local ~/projects/skill-hub
```

### 验证安装

列出已安装的 skill：
```bash
/plugin list | grep -E "red-team|prd-pilot"
```

使用 skill：
```bash
/red-team:red-team        # 调用红队审查
/prd-pilot:prd-pilot      # 调用PRD分析
```

## 📝 License

MIT
