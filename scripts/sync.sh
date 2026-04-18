#!/bin/bash
# 同步本地 skill 到 skill-hub（GitHub）
# 使用: ./scripts/sync.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"

echo "🔄 开始同步 skills..."

# 获取当前 git 提交表述
COMMIT_MSG=$(cd "$REPO_ROOT" && git log -1 --pretty=%B 2>/dev/null || echo "Sync skills")

# 同步 prd-pilot
echo "📦 同步 prd-pilot..."
if [ -d "$SKILLS_DIR/prd-pilot" ]; then
  PDR_PILOT_VERSION=$(grep '"version"' "$SKILLS_DIR/prd-pilot/package.json" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  echo "  版本: $PDR_PILOT_VERSION"
  cd "$SKILLS_DIR/prd-pilot"
  pnpm install --silent 2>/dev/null || npm install --silent
  npm run build 2>&1 | grep -E "error|warning|done" || true
  cd "$REPO_ROOT"
fi

# 同步 red-team
echo "📝 检查 red-team..."
if [ -d "$SKILLS_DIR/red-team" ]; then
  RED_TEAM_VERSION=$(grep 'version:' "$SKILLS_DIR/red-team/SKILL.md" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "1.0.0")
  echo "  版本: $RED_TEAM_VERSION"
fi

# 清理并整理
echo "🧹 清理..."
find "$SKILLS_DIR" -name ".DS_Store" -delete 2>/dev/null || true
find "$SKILLS_DIR" -name "*.bak" -delete 2>/dev/null || true

# Git 提交
echo "💾 提交变更..."
cd "$REPO_ROOT"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "sync: update skills at $(date +%Y-%m-%d)" || true
  echo "✅ 同步完成！"
  echo ""
  echo "📤 下一步，推送到 GitHub:"
  echo "  git push origin main"
else
  echo "ℹ️  没有变更需要提交"
fi
