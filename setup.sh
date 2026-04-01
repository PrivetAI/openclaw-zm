#!/bin/bash
# setup.sh — iOS dev addon for OpenClaw
# Prerequisites: OpenClaw installed and configured (https://github.com/openclaw/openclaw)
#
# Usage:
#   git clone git@github.com:PrivetAI/openclaw-zm.git ~/.openclaw/workspace
#   bash ~/.openclaw/workspace/setup.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; }

WORKSPACE_DIR="$HOME/.openclaw/workspace"

echo ""
echo "🧋 openclaw-zm — iOS dev setup"
echo "=============================="
echo ""

# --- 1. Check OpenClaw is installed ---
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
  info "OpenClaw config found"
else
  fail "OpenClaw not configured!"
  echo "  Install OpenClaw first: https://github.com/openclaw/openclaw"
  echo "  Then run: openclaw onboard"
  echo ""
  exit 1
fi

# --- 2. Check workspace ---
if [ -d "$WORKSPACE_DIR/skills" ]; then
  info "Workspace found at $WORKSPACE_DIR"
else
  fail "Workspace not found! Clone it first:"
  echo "  git clone git@github.com:PrivetAI/openclaw-zm.git $WORKSPACE_DIR"
  exit 1
fi

# --- 3. Xcode ---
if command -v xcodebuild &>/dev/null; then
  info "Xcode $(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}') found"
else
  fail "Xcode not installed — install from App Store"
  echo "  Then run: xcode-select --install && sudo xcodebuild -license accept"
fi

# --- 4. GitHub CLI ---
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null; then
    info "GitHub CLI authenticated"
  else
    warn "GitHub CLI installed but not authenticated"
    echo "  Run: gh auth login"
  fi
else
  warn "Installing GitHub CLI..."
  brew install gh 2>/dev/null || fail "Could not install gh — install manually: brew install gh"
fi

# --- 5. XcodeBuildMCP ---
if command -v xcodebuildmcp &>/dev/null; then
  info "XcodeBuildMCP found"
else
  warn "Installing XcodeBuildMCP..."
  brew install nicklama/tap/xcodebuildmcp 2>/dev/null || warn "XcodeBuildMCP install failed (optional)"
fi

# --- 6. Dev directories ---
DEV_DIR="$HOME/Documents/development"
mkdir -p "$DEV_DIR/for_human_review_apps"
mkdir -p "$DEV_DIR/old_apps"
info "Dev directories ready"

# --- 7. USER.md ---
USER_FILE="$WORKSPACE_DIR/USER.md"
if [ ! -f "$USER_FILE" ]; then
  cat > "$USER_FILE" << 'EOF'
# USER.md

- **Name:** Change Me
- **What to call them:** Boss
- **Timezone:** Your/Timezone (GMT+X)
- **Telegram ID:** 000000000

## Context

- Goals and preferences here
EOF
  warn "USER.md created — edit it: nano $USER_FILE"
else
  info "USER.md exists"
fi

# --- 8. config/paths.json ---
USERNAME=$(whoami)
PATHS_DIR="$WORKSPACE_DIR/config"
PATHS_FILE="$PATHS_DIR/paths.json"
mkdir -p "$PATHS_DIR"
cat > "$PATHS_FILE" << EOF
{
  "development": "/Users/$USERNAME/Documents/development",
  "review_apps": "/Users/$USERNAME/Documents/development/for_human_review_apps",
  "old_apps": "/Users/$USERNAME/Documents/development/old_apps",
  "skills": "/Users/$USERNAME/.openclaw/workspace/skills",
  "app_descriptions": "/Users/$USERNAME/Documents/development/for_human_review_apps/APP_DESCRIPTIONS.md"
}
EOF
info "config/paths.json generated"

# --- Done ---
echo ""
echo "=============================="
echo ""
info "Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Edit USER.md: nano $USER_FILE"
echo "  2. Start OpenClaw: openclaw gateway start"
echo "  3. Message the bot in Telegram"
echo ""
echo "🧋 Ready to build apps!"
