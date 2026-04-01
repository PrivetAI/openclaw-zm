---
name: setup
description: Fresh setup of OpenClaw + iOS dev workflow on a new Mac. Use when deploying to a new device from scratch.
---

# Fresh Setup — OpenClaw + iOS Dev Workflow

Complete guide to get a new Mac ready for autonomous iOS app building.

## Prerequisites

- macOS 14+ (Sonoma or newer)
- Apple ID signed into Mac
- Anthropic API key
- Telegram bot token (from @BotFather)
- GitHub account with SSH key

## Quick Start (Automated)

The workspace repo includes a bootstrap script that handles most of the setup:

```bash
# 1. Clone workspace first (it has the setup script)
cd ~/.openclaw
git clone git@github.com:PrivetAI/openclaw-zm.git workspace

# 2. Run setup
chmod +x workspace/setup.sh
./workspace/setup.sh
```

The script installs: Homebrew, Node.js, GitHub CLI, XcodeBuildMCP, clones OpenClaw, creates directories, and generates `config/paths.json`.

After the script, you still need to:
1. Install Xcode from App Store
2. Configure OpenClaw config with tokens
3. Set up GitHub SSH key
4. Edit `USER.md`

## Manual Setup (Step by Step)

### Step 1: Xcode

```bash
# Install from App Store, then:
xcode-select --install
sudo xcodebuild -license accept
xcodebuild -version
```

Install at least one iPhone simulator (Settings → Platforms → iOS).

### Step 2: Homebrew + Tools

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install node@22 git gh jq
```

### Step 3: GitHub Auth

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub → Settings → SSH Keys
cat ~/.ssh/id_ed25519.pub

# Authenticate gh CLI
gh auth login

# Configure git identity
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"

# Verify
gh auth status
ssh -T git@github.com
```

### Step 4: OpenClaw

```bash
cd ~/Desktop
git clone git@github.com:PrivetAI/openclaw.git
cd openclaw
npm install

# Run setup wizard — creates ~/.openclaw/openclaw.json
node openclaw.mjs onboard
```

### Step 5: OpenClaw Config

Edit `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": { "primary": "anthropic/claude-opus-4-6" },
      "workspace": "<HOME>/.openclaw/workspace",
      "compaction": { "mode": "safeguard" },
      "maxConcurrent": 8,
      "subagents": { "maxConcurrent": 8 }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "botToken": "<BOT_TOKEN>",
      "allowFrom": ["<TELEGRAM_USER_ID>"],
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback"
  }
}
```

### Step 6: Workspace

```bash
cd ~/.openclaw
git clone git@github.com:PrivetAI/openclaw-zm.git workspace
cd workspace

# Create local files from templates
cp USER.md.example USER.md
nano USER.md  # fill in your info

# Create config directory (setup.sh does this automatically)
mkdir -p config
cat > config/paths.json << EOF
{
  "development": "/Users/$(whoami)/Documents/development",
  "review_apps": "/Users/$(whoami)/Documents/development/for_human_review_apps",
  "old_apps": "/Users/$(whoami)/Documents/development/old_apps",
  "skills": "/Users/$(whoami)/.openclaw/workspace/skills",
  "app_descriptions": "/Users/$(whoami)/Documents/development/for_human_review_apps/APP_DESCRIPTIONS.md"
}
EOF
```

### Step 7: Create Dev Directories

```bash
mkdir -p ~/Documents/development/for_human_review_apps
mkdir -p ~/Documents/development/old_apps
```

### Step 8: MCP Tools (for iOS testing)

```bash
# XcodeBuildMCP — Xcode simulator automation
brew install nicklama/tap/xcodebuildmcp

# MCPorter config (optional, for MCP integration)
cat > ~/.openclaw/workspace/config/mcporter.json << 'EOF'
{
  "mcpServers": {
    "xcodebuildmcp": {
      "command": "xcodebuildmcp mcp",
      "env": {
        "XCODEBUILDMCP_ENABLED_WORKFLOWS": "simulator,ui-automation,project-discovery,logging"
      }
    }
  }
}
EOF
```

### Step 9: Start

```bash
cd ~/Desktop/openclaw
node openclaw.mjs gateway start
```

Send a message to the Telegram bot to verify.

## Verification Checklist

```bash
xcodebuild -version                    # Xcode installed
node -v                                # Node.js 20+
gh auth status                         # GitHub authenticated
ls ~/.openclaw/workspace/SOUL.md       # Workspace ready
ls ~/.openclaw/workspace/skills/       # Skills present
xcrun simctl list devices available    # Simulators available
xcodebuildmcp --version                # XcodeBuildMCP installed
```

## Directory Structure (after setup)

```
~/.openclaw/
├── openclaw.json                  # Main config (API keys, channels)
└── workspace/                     # Agent workspace (this repo)
    ├── AGENTS.md                  # Agent rules
    ├── SOUL.md                    # Agent personality
    ├── IDENTITY.md                # Agent identity
    ├── HEARTBEAT.md               # Periodic tasks
    ├── setup.sh                   # Bootstrap script
    ├── skills/                    # All skills live here
    │   ├── ios-builder/
    │   ├── ios-tester/
    │   ├── ios-app-rename/
    │   ├── ios-version-bump/
    │   ├── codemagic/
    │   ├── idea-gen/
    │   ├── github/
    │   └── ...
    │
    │   Created locally (not in repo):
    ├── USER.md                    # User info (from .example)
    ├── TOOLS.md                   # Local tool notes
    ├── MEMORY.md                  # Long-term memory (auto)
    ├── config/
    │   ├── paths.json             # Portable paths
    │   └── mcporter.json          # MCP server config
    └── memory/                    # Daily logs (auto)

~/Desktop/openclaw/                # OpenClaw engine
└── openclaw.mjs

~/Documents/development/           # iOS projects
├── for_human_review_apps/         # Finished apps
└── old_apps/                      # Archived apps
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `node` not found | `brew install node@22` or add to PATH |
| Xcode CLI tools missing | `xcode-select --install` |
| No simulators | Xcode → Settings → Platforms → Download iOS |
| XcodeBuildMCP not found | `brew install nicklama/tap/xcodebuildmcp` |
| SSH key not accepted | Add `~/.ssh/id_ed25519.pub` to GitHub → SSH Keys |
| GitHub auth fails | `gh auth login` |
| Bot not responding | Check `openclaw.json` botToken + allowFrom |
| Build fails "no signing" | Expected — Manual signing, works in Simulator |
