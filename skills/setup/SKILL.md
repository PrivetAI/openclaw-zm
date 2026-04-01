---
name: setup
description: Fresh setup of OpenClaw + iOS dev workflow on a new Mac. Use when deploying to a new device from scratch.
---

# Setup — OpenClaw + iOS Dev Workflow

## Prerequisites

- macOS 14+
- Apple ID signed into Mac
- Anthropic API key
- Telegram bot token (from @BotFather)
- GitHub SSH key

## Installation

### Step 1: OpenClaw

Install OpenClaw following the official guide: https://github.com/openclaw/openclaw

```bash
# After install, run the setup wizard:
openclaw onboard
# Enter: Anthropic API key, Telegram bot token, allowed user IDs
```

### Step 2: Xcode

```bash
# Install from App Store, then:
xcode-select --install
sudo xcodebuild -license accept
```

Install at least one iPhone simulator (Settings → Platforms → iOS).

### Step 3: Workspace + Tools

```bash
# Clone this repo as workspace
git clone git@github.com:PrivetAI/openclaw-zm.git ~/.openclaw/workspace

# Run setup — installs tools, creates directories
bash ~/.openclaw/workspace/setup.sh

# Fill in your info
nano ~/.openclaw/workspace/USER.md
```

setup.sh checks/installs:
- GitHub CLI (`gh`)
- XcodeBuildMCP (simulator automation)
- Dev directories (`~/Documents/development/`)
- `USER.md` template
- `config/paths.json`

### Step 4: GitHub Auth

```bash
gh auth login
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Step 5: Start

```bash
openclaw gateway start
```

Message the bot in Telegram to verify.

## USER.md

Created by setup.sh. Fill in:

```markdown
# USER.md

- **Name:** Your Name
- **What to call them:** Boss
- **Timezone:** Your/Timezone (GMT+X)
- **Telegram ID:** 000000000

## Context

- Goals and preferences here
```

## Verification

```bash
xcodebuild -version                    # Xcode
node -v                                # Node.js 20+
gh auth status                         # GitHub
ls ~/.openclaw/workspace/skills/       # Skills (14)
xcrun simctl list devices available    # Simulators
xcodebuildmcp --version                # XcodeBuildMCP
```

## Directory Structure

```
~/.openclaw/
├── openclaw.json                  # OpenClaw config (API keys, channels)
└── workspace/                     # This repo
    ├── AGENTS.md, SOUL.md, IDENTITY.md
    ├── HEARTBEAT.md
    ├── setup.sh
    ├── skills/ (14)
    │   ├── ios-builder/
    │   ├── ios-tester/
    │   ├── ios-app-rename/
    │   ├── ios-version-bump/
    │   ├── codemagic/
    │   ├── idea-gen/
    │   └── ...
    │
    │   Local (gitignored):
    ├── USER.md
    ├── config/paths.json
    ├── memory/
    └── MEMORY.md

~/Documents/development/           # iOS projects
├── for_human_review_apps/         # Finished apps
└── old_apps/                      # Archived
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Xcode CLI missing | `xcode-select --install` |
| No simulators | Xcode → Settings → Platforms → Download iOS |
| XcodeBuildMCP not found | `brew install nicklama/tap/xcodebuildmcp` |
| GitHub auth fails | `gh auth login` |
| Bot not responding | Check `~/.openclaw/openclaw.json` botToken + allowFrom |
