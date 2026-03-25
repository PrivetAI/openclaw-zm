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

## Step 1: Xcode

```bash
# Install from App Store or:
xcode-select --install

# After install, accept license:
sudo xcodebuild -license accept

# Verify:
xcodebuild -version
```

Minimum: Xcode 15+ (for iOS 15.6+ target support).

Install at least one iPhone simulator (Settings → Platforms → iOS).

## Step 2: Homebrew + Tools

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Essential tools
brew install node git gh jq
```

## Step 3: GitHub Auth

New machine = new GitHub setup. Generate SSH key and add to GitHub:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add to GitHub → Settings → SSH Keys
cat ~/.ssh/id_ed25519.pub

# Authenticate gh CLI
gh auth login

# Verify
gh auth status
ssh -T git@github.com
```

Configure git identity:
```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

## Step 4: OpenClaw

```bash
# Clone
cd ~/Desktop
git clone git@github.com:PrivetAI/openclaw.git
cd openclaw

# Install dependencies
npm install

# Run setup wizard
node openclaw.mjs onboard
```

The wizard will create `~/.openclaw/openclaw.json`. You'll need:
- Anthropic API key
- Telegram bot token

## Step 5: OpenClaw Config

After wizard, edit `~/.openclaw/openclaw.json` and ensure:

```json
{
  "agents": {
    "defaults": {
      "model": { "primary": "anthropic/claude-opus-4-6" },
      "workspace": "<FULL_PATH_TO>/.openclaw/workspace",
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
      "allowFrom": ["409266067", "7835454420"],
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

## Step 6: Workspace

```bash
# Clone workspace (contains SOUL.md, MEMORY.md, skills config, memory/)
cd ~/.openclaw
git clone git@github.com:PrivetAI/openclaw-zm.git workspace
```

Or copy from old machine:
```bash
scp -r oldmac:~/.openclaw/workspace ~/.openclaw/workspace
```

## Step 7: Update Paths

Edit `~/.openclaw/workspace/config/paths.json` — update ALL paths for the new machine:

```json
{
  "development": "/Users/<USERNAME>/Documents/development",
  "review_apps": "/Users/<USERNAME>/Documents/development/for_human_review_apps",
  "old_apps": "/Users/<USERNAME>/Documents/development/old_apps",
  "skills": "/Users/<USERNAME>/Desktop/openclaw/skills",
  "app_descriptions": "/Users/<USERNAME>/Documents/development/for_human_review_apps/APP_DESCRIPTIONS.md"
}
```

## Step 8: Create Dev Directories

```bash
mkdir -p ~/Documents/development/for_human_review_apps/approved
mkdir -p ~/Documents/development/old_apps
```

## Step 9: MCP Tools (for iOS testing)

```bash
# XcodeBuildMCP — Xcode simulator automation
npm install -g xcodebuildmcp

# MCPorter — MCP tool caller
npm install -g mcporter

```

Create mcporter config:
```bash
mkdir -p ~/.openclaw/workspace/config
cat > ~/.openclaw/workspace/config/mcporter.json << 'EOF'
{
  "mcpServers": {
    "xcodebuildmcp": {
      "command": "xcodebuildmcp mcp",
      "env": {
        "XCODEBUILDMCP_ENABLED_WORKFLOWS": "simulator,ui-automation,project-discovery,logging"
      }
    }
  },
  "imports": []
}
EOF
```

## Step 10: Start OpenClaw

```bash
cd ~/Desktop/openclaw
node openclaw.mjs gateway start
```

Send a message to the Telegram bot to verify it works.

## Verification Checklist

```bash
# All should succeed:
xcodebuild -version                    # Xcode installed
node -v                                # Node.js
gh auth status                         # GitHub authenticated
jq -r .development ~/.openclaw/workspace/config/paths.json  # Paths configured
ls ~/.openclaw/workspace/SOUL.md       # Workspace ready
mcporter list xcodebuildmcp            # MCP tools available
xcrun simctl list devices available    # Simulators available
```

## Directory Structure (after setup)

```
~/.openclaw/
├── openclaw.json              # Main config (API keys, channels)
└── workspace/                 # Agent workspace
    ├── SOUL.md                # Agent personality
    ├── USER.md                # User info
    ├── MEMORY.md              # Long-term memory
    ├── AGENTS.md              # Agent rules
    ├── TOOLS.md               # Local tool notes
    ├── IDENTITY.md            # Agent identity
    ├── HEARTBEAT.md           # Periodic tasks
    ├── config/
    │   ├── paths.json         # Portable paths
    │   └── mcporter.json      # MCP server config
    └── memory/                # Daily memory files
        └── YYYY-MM-DD.md

~/Desktop/openclaw/            # OpenClaw engine + skills
└── skills/
    ├── ios-builder/
    ├── ios-tester/
    ├── ios-app-rename/
    ├── ios-version-bump/
    ├── idea-gen/
    ├── codemagic/
    ├── github/
    └── ...

~/Documents/development/       # iOS projects
├── GUIDE.md                   # Build spec
├── APP_TRACKER.md             # App log
├── apps_overview.txt          # Existing app list
├── for_human_review_apps/     # Finished apps
│   ├── APP_DESCRIPTIONS.md    # Master list of all apps
│   └── approved/              # Approved by human
└── old_apps/                  # Archived apps
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `node` not found | `brew install node` or add to PATH |
| Xcode CLI tools missing | `xcode-select --install` |
| No simulators | Xcode → Settings → Platforms → Download iOS |
| MCP tools not found | `npm install -g xcodebuildmcp mcporter` |
| SSH key not accepted | Add `~/.ssh/id_ed25519.pub` to GitHub → Settings → SSH Keys |
| GitHub auth fails | `gh auth login` |
| Bot not responding | Check `openclaw.json` botToken + allowFrom |
| Build fails "no signing" | Expected — Manual signing, works in Simulator |
