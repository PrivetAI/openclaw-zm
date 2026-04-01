#!/bin/bash
# setup.sh — Bootstrap openclaw-zm on a fresh Mac
# Usage: curl -sL https://raw.githubusercontent.com/PrivetAI/openclaw-zm/main/setup.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
ask()   { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "🧋 openclaw-zm setup"
echo "===================="
echo ""

# --- 1. Homebrew ---
if command -v brew &>/dev/null; then
  info "Homebrew found"
else
  warn "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
fi

# --- 2. Node.js ---
if command -v node &>/dev/null && [[ "$(node -v | cut -d. -f1 | tr -d v)" -ge 20 ]]; then
  info "Node.js $(node -v) found"
else
  warn "Installing Node.js 22..."
  brew install node@22
fi

# --- 3. GitHub CLI ---
if command -v gh &>/dev/null; then
  info "GitHub CLI found"
else
  warn "Installing GitHub CLI..."
  brew install gh
fi

if ! gh auth status &>/dev/null; then
  warn "GitHub CLI not authenticated"
  ask "Run 'gh auth login' after setup"
fi

# --- 4. Xcode check ---
if xcode-select -p &>/dev/null; then
  info "Xcode CLI tools found"
else
  warn "Installing Xcode CLI tools..."
  xcode-select --install
  echo "    → After install, run: sudo xcodebuild -license accept"
fi

if command -v xcodebuild &>/dev/null; then
  info "Xcode $(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}') found"
else
  warn "Xcode not installed — install from App Store"
fi

# --- 5. XcodeBuildMCP (optional) ---
if command -v xcodebuildmcp &>/dev/null; then
  info "XcodeBuildMCP found"
else
  warn "Installing XcodeBuildMCP..."
  brew install nicklama/tap/xcodebuildmcp 2>/dev/null || warn "XcodeBuildMCP install failed (optional, skip)"
fi

# --- 6. OpenClaw ---
OPENCLAW_DIR="$HOME/Desktop/openclaw"
if [ -d "$OPENCLAW_DIR/.git" ]; then
  info "OpenClaw found at $OPENCLAW_DIR"
else
  warn "Cloning OpenClaw..."
  git clone https://github.com/openclaw/openclaw.git "$OPENCLAW_DIR"
  cd "$OPENCLAW_DIR" && npm install
  info "OpenClaw installed"
fi

# --- 7. Workspace (this repo) ---
WORKSPACE_DIR="$HOME/.openclaw/workspace"
if [ -d "$WORKSPACE_DIR/.git" ]; then
  info "Workspace found at $WORKSPACE_DIR"
else
  warn "Cloning openclaw-zm workspace..."
  mkdir -p "$HOME/.openclaw"
  git clone git@github.com:PrivetAI/openclaw-zm.git "$WORKSPACE_DIR"
  info "Workspace installed"
fi

# --- 8. Directory structure ---
DEV_DIR="$HOME/Documents/development"
mkdir -p "$DEV_DIR/for_human_review_apps"
mkdir -p "$DEV_DIR/old_apps"
info "Development directories ready"

# --- 9. Create USER.md if missing ---
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

# --- 10. Create config/paths.json ---
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
info "config/paths.json created for user: $USERNAME"

# --- 11. Config check ---
echo ""
echo "===================="
echo ""

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
  info "OpenClaw config exists at $CONFIG_FILE"
else
  warn "OpenClaw config not found!"
  echo ""
  echo "  Run the setup wizard:"
  echo "    cd $OPENCLAW_DIR && node openclaw.mjs onboard"
  echo ""
  echo "  You'll need:"
  echo "    - Anthropic API key"
  echo "    - Telegram bot token"
  echo "    - Allowed Telegram user IDs"
fi

echo ""
info "Setup complete! Next steps:"
echo ""
if [ ! -f "$CONFIG_FILE" ]; then
  echo "  1. Run: cd $OPENCLAW_DIR && node openclaw.mjs onboard"
  echo "  2. Run: gh auth login (if not done)"
  echo "  3. Edit: $WORKSPACE_DIR/USER.md (your info)"
  echo "  4. Start: cd $OPENCLAW_DIR && node openclaw.mjs gateway start"
else
  echo "  1. Run: gh auth login (if not done)"
  echo "  2. Edit: $WORKSPACE_DIR/USER.md (your info)"
  echo "  3. Start: cd $OPENCLAW_DIR && node openclaw.mjs gateway start"
fi
echo ""
echo "🧋 Ready to build apps!"
