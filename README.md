# 🚀 Skill Hub

Personal collection of Claude Code skills.

## 📦 Skills

| Skill | Description |
|-------|-------------|
| **prd-pilot** | PRD-driven development — analyzes requirements, detects gaps, reviews PRs against specs |
| **red-team** | Critical review — challenges proposals, finds logic flaws, questions assumptions |

## 📥 Installation

### Method 1: Install from Marketplace (Recommended) ⭐

One-command add the entire marketplace:

```bash
/plugin marketplace add Gopherlinzy/skill-hub
```

Then install skills you need:

| Skill | Command |
|-------|---------|
| 🔴 Red Team | `/plugin install red-team@skill-hub` |
| 📋 PRD Pilot | `/plugin install prd-pilot@skill-hub` |

Or install all at once:
```bash
/plugin install red-team@skill-hub && /plugin install prd-pilot@skill-hub
```

### Method 2: Local Installation (For Development)

Clone the repository:
```bash
git clone https://github.com/Gopherlinzy/skill-hub.git ~/projects/skill-hub
```

Install from local path:
```bash
/plugin install-local ~/projects/skill-hub
```

### Verification

List installed skills:
```bash
/plugin list
```

Invoke a skill:
```bash
/red-team:red-team        # Red team review
/prd-pilot:prd-pilot      # PRD pilot analysis
```

## 📝 License

MIT
