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

# --- 9. Update paths.json for this Mac ---
USERNAME=$(whoami)
PATHS_FILE="$WORKSPACE_DIR/config/paths.json"
if [ -f "$PATHS_FILE" ]; then
  cat > "$PATHS_FILE" << EOF
{
  "development": "/Users/$USERNAME/Documents/development",
  "review_apps": "/Users/$USERNAME/Documents/development/for_human_review_apps",
  "old_apps": "/Users/$USERNAME/Documents/development/old_apps",
  "skills": "/Users/$USERNAME/Desktop/openclaw/skills",
  "app_descriptions": "/Users/$USERNAME/Documents/development/for_human_review_apps/APP_DESCRIPTIONS.md"
}
EOF
  info "paths.json updated for user: $USERNAME"
fi

# --- 10. Config reminder ---
echo ""
echo "===================="
echo ""

CONFIG_FILE="$OPENCLAW_DIR/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  warn "OpenClaw config not found!"
  echo ""
  echo "  Create $CONFIG_FILE with:"
  echo "    - Anthropic API key"
  echo "    - Telegram bot token"
  echo "    - Allowed user IDs"
  echo ""
  echo "  Example: cp $OPENCLAW_DIR/config.example.yaml $CONFIG_FILE"
else
  info "OpenClaw config exists"
fi

echo ""
info "Setup complete! Next steps:"
echo ""
echo "  1. Configure tokens in $OPENCLAW_DIR/config.yaml"
echo "  2. Run: gh auth login (if not done)"
echo "  3. Start: cd $OPENCLAW_DIR && node openclaw.mjs gateway start"
echo ""
echo "🧋 Ready to build apps!"
