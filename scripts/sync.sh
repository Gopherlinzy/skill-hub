#!/bin/bash
# 同步本地 skill 到 skill-hub（GitHub）-> 全局 skills
# 流向: ~/projects/prd-pilot -> ~/projects/skill-hub/skills/prd-pilot -> ~/.claude/skills/prd-pilot
# 使用: ./scripts/sync.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"
LOCAL_PRD="$HOME/projects/prd-pilot"

echo "🔄 开始同步 skills..."

# 同步 prd-pilot: 本地 -> skill-hub
echo "📦 同步 prd-pilot..."
if [ -d "$LOCAL_PRD" ] && [ -d "$SKILLS_DIR/prd-pilot" ]; then
  PDR_PILOT_VERSION=$(grep '"version"' "$LOCAL_PRD/package.json" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  echo "  版本: $PDR_PILOT_VERSION"

  # 清理 skill-hub 中的临时文件
  rm -rf "$SKILLS_DIR/prd-pilot/dist" "$SKILLS_DIR/prd-pilot/node_modules" 2>/dev/null || true

  # 同步源文件: 本地项目 -> skill-hub
  echo "  📥 本地项目 -> skill-hub..."
  for file in src SKILL.md README.md package.json package-lock.json pnpm-lock.yaml tsconfig.json .env .gitignore LICENSE; do
    [ -e "$LOCAL_PRD/$file" ] && cp -r "$LOCAL_PRD/$file" "$SKILLS_DIR/prd-pilot/" || true
  done

  # Build
  cd "$SKILLS_DIR/prd-pilot"
  pnpm install --silent 2>/dev/null || npm install --silent
  if npm run build 2>&1 | grep -E "error|warning|done" || true; then
    BUILD_SUCCESS=1
  else
    BUILD_SUCCESS=0
  fi

  # 同步到全局 skills: build 产物 -> 全局
  GLOBAL_SKILLS="$HOME/.claude/skills/prd-pilot"
  if [ -d "$GLOBAL_SKILLS" ]; then
    echo "  📤 skill-hub -> 全局 skills..."
    # 只同步编译产物，保留全局的 SKILL.md 和 references
    [ -d dist ] && cp -r dist "$GLOBAL_SKILLS/" || true
    [ -d src ] && cp -r src "$GLOBAL_SKILLS/" || true
    [ -f package.json ] && cp package.json "$GLOBAL_SKILLS/"
  fi
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
