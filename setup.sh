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
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"

sync_workspace_files() {
  mkdir -p "$WORKSPACE_DIR"

  for file in AGENTS.md SOUL.md IDENTITY.md HEARTBEAT.md setup.sh README.md; do
    if [ -f "$REPO_DIR/$file" ]; then
      cp "$REPO_DIR/$file" "$WORKSPACE_DIR/$file"
    fi
  done

  if [ -d "$REPO_DIR/skills" ]; then
    mkdir -p "$WORKSPACE_DIR/skills"
    rsync -a --delete "$REPO_DIR/skills/" "$WORKSPACE_DIR/skills/"
  fi

  if [ -f "$REPO_DIR/TOOLS.md" ]; then
    cp "$REPO_DIR/TOOLS.md" "$WORKSPACE_DIR/TOOLS.md"
  fi

  info "Synced agent files into $WORKSPACE_DIR"
  warn "Preserved USER.md, MEMORY.md, and memory/"
}

echo ""
echo "🧋 openclaw-zm — iOS dev setup"
echo "=============================="
echo ""

# --- 1. Check OpenClaw is installed ---
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
  info "OpenClaw config found"
else
  fail "OpenClaw not configured!"
  echo "  Install OpenClaw first: https://github.com/openclaw/openclaw"
  echo "  Then run: openclaw onboard"
  echo ""
  exit 1
fi

# --- 2. Ensure workspace and sync repo files into it ---
mkdir -p "$WORKSPACE_DIR"
sync_workspace_files
info "Workspace ready at $WORKSPACE_DIR"

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

# --- 9. OpenClaw bootstrap-extra-files workaround ---
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
if command -v python3 &>/dev/null; then
  TMP_CONFIG=$(mktemp)
  if python3 - "$CONFIG_FILE" "$TMP_CONFIG" << 'PY'
import json, sys
from pathlib import Path
config_path = Path(sys.argv[1]).expanduser()
out_path = Path(sys.argv[2])
obj = json.loads(config_path.read_text())
entries = obj.setdefault("hooks", {}).setdefault("internal", {}).setdefault("entries", {})
bootstrap = entries.setdefault("bootstrap-extra-files", {})
bootstrap["enabled"] = True
existing = bootstrap.get("paths") or bootstrap.get("patterns") or bootstrap.get("files") or []
want = [
    "workspace/AGENTS.md",
    "workspace/SOUL.md",
    "workspace/IDENTITY.md",
    "workspace/USER.md",
    "workspace/TOOLS.md",
    "workspace/HEARTBEAT.md",
    "workspace/BOOTSTRAP.md",
    "workspace/MEMORY.md"
]
seen = set()
merged = []
for item in list(existing) + want:
    if isinstance(item, str) and item not in seen:
        seen.add(item)
        merged.append(item)
bootstrap["paths"] = merged
for alias in ("patterns", "files"):
    if alias in bootstrap:
        del bootstrap[alias]
out_path.write_text(json.dumps(obj, indent=2) + "\n")
PY
  then
    mv "$TMP_CONFIG" "$CONFIG_FILE"
    info "Patched openclaw.json with bootstrap-extra-files paths"
    warn "Restart OpenClaw gateway so new sessions pick up workspace persona/context"
  else
    rm -f "$TMP_CONFIG"
    warn "Could not patch openclaw.json automatically"
  fi
else
  warn "python3 not found, skipped openclaw.json patch"
fi

# --- Done ---
echo ""
echo "=============================="
echo ""
info "Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Run openclaw gateway restart"
echo "  2. Start a new chat/session with the bot"
echo "  3. If needed, edit USER.md: nano $USER_FILE"
echo ""
echo "🧋 Ready to build apps!"
