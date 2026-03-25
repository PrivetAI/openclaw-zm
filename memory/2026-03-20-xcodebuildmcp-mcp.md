# 2026-03-20 — xcodebuildmcp MCP Setup + openclaw-zm repo

## openclaw-zm repo
- Created `PrivetAI/openclaw-zm` (private) — portable OpenClaw config
- Contains: skills/, workspace/, config/openclaw.template.json (tokens redacted)
- README with all tool dependencies documented
- Viktor requested this for portability

## xcodebuildmcp → MCP (not CLI)
- Added xcodebuildmcp as MCP server via mcporter
- Config: `~/.openclaw/workspace/config/mcporter.json`
- Key: env var `XCODEBUILDMCP_ENABLED_WORKFLOWS=simulator,ui-automation,project-discovery,logging` enables tap/type/swipe tools
- Without that env var, only 27 tools (no UI automation); with it, 39 tools including tap, type_text, swipe, gesture, long_press, touch, key_press, key_sequence
- Also created `~/.xcodebuildmcp/config.yaml` with schemaVersion 1 and enabledWorkflows
- ios-tester SKILL.md fully rewritten to use `mcporter call xcodebuildmcp.*` instead of CLI
- All calls now: `mcporter call xcodebuildmcp.tap label="Button"` etc.

## Config notes
- `enabledWorkflows` (not `workflows`) in config.yaml
- Config file location: `<workspace-root>/.xcodebuildmcp/config.yaml` or `~/.xcodebuildmcp/config.yaml`
- Docs: https://github.com/getsentry/XcodeBuildMCP/blob/main/docs/CONFIGURATION.md
