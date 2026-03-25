---
name: ios-tester
description: Test iOS apps in Simulator like a real user using xcodebuildmcp via MCP (mcporter). Build, launch, navigate UI, tap buttons, type text, take screenshots, verify functionality, and fix any bugs found. Use when testing iOS apps after building.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧪",
        "requires": { "bins": ["mcporter", "xcodebuildmcp"] },
      },
  }
---

# iOS Tester

Test iOS apps in Simulator using xcodebuildmcp via MCP — interact like a real user, find bugs, fix them, retest.

## ⚠️ CRITICAL: Sequential Testing Only
**There is only ONE iOS Simulator.** When testing multiple apps, test them ONE AT A TIME — NEVER in parallel.
Spawn sub-agents sequentially: wait for one to finish before starting the next.
Parallel sub-agents will fight over the simulator and all fail.

## Prerequisites
- `xcodebuildmcp` installed globally (`npm install -g xcodebuildmcp@latest`)
- `mcporter` installed (`npm install -g mcporter`)
- mcporter config with xcodebuildmcp server (see Setup)
- iOS Simulator available (Xcode installed)
- Preferred simulator: **iPhone 17**

## Setup (one-time)

mcporter config must have xcodebuildmcp with ui-automation enabled:

```json
// ~/.openclaw/workspace/config/mcporter.json
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
```

## Quick Reference — MCP Tool Calls

All calls use: `mcporter call xcodebuildmcp.<tool> --timeout 30000 key=value`

**⚠️ CRITICAL: Always pass `--timeout 30000` (or higher for builds: `--timeout 120000`).** The default mcporter timeout is too short — snapshot_ui, tap, and other commands will SIGKILL without it.

### Session Setup
```bash
# Set project defaults (do this first!)
mcporter call xcodebuildmcp.session_set_defaults --timeout 30000 \
  projectPath="/path/to/App.xcodeproj" \
  scheme="AppName" \
  simulatorName="iPhone 17"

# Show current defaults
mcporter call xcodebuildmcp.session_show_defaults --timeout 15000
```

### Build & Launch
```bash
# Build and run (single step — preferred, use long timeout!)
mcporter call xcodebuildmcp.build_run_sim --timeout 120000

# Build only (no launch)
mcporter call xcodebuildmcp.build_sim --timeout 120000

# Stop app
mcporter call xcodebuildmcp.stop_app_sim --timeout 15000

# Relaunch (persistence testing)
mcporter call xcodebuildmcp.launch_app_sim --timeout 15000
```

### See What's on Screen
```bash
# View hierarchy with coordinates
mcporter call xcodebuildmcp.snapshot_ui --timeout 30000

# Screenshot (returns file path)
mcporter call xcodebuildmcp.screenshot --timeout 15000 returnFormat=path
```
Always analyze screenshots with the `image` tool for visual verification.

### Interact with UI
```bash
# Tap by label (preferred)
mcporter call xcodebuildmcp.tap --timeout 15000 label="Settings"

# Tap by accessibility id
mcporter call xcodebuildmcp.tap --timeout 15000 id="settings_button"

# Tap by coordinates (fallback)
mcporter call xcodebuildmcp.tap --timeout 15000 x=200 y=400

# Type text
mcporter call xcodebuildmcp.type_text --timeout 15000 text="Hello World"

# Swipe
mcporter call xcodebuildmcp.swipe --timeout 15000 x1=200 y1=600 x2=200 y2=200

# Gesture presets (scroll-up, scroll-down, scroll-left, scroll-right, swipe-from-left-edge, etc.)
mcporter call xcodebuildmcp.gesture --timeout 15000 preset=scroll-down

# Long press
mcporter call xcodebuildmcp.long_press --timeout 15000 x=200 y=400 duration=2

# Hardware buttons (home, lock, side-button, siri, apple-pay)
mcporter call xcodebuildmcp.button --timeout 15000 buttonType=home

# Key press by keycode
mcporter call xcodebuildmcp.key_press --timeout 15000 keyCode=36

# Type key sequence
mcporter call xcodebuildmcp.key_sequence --timeout 15000 keyCodes='["36","49"]'
```

### Project Discovery
```bash
# Find Xcode projects in a directory
mcporter call xcodebuildmcp.discover_projs --timeout 15000 workspaceRoot="/path/to/dir"

# List schemes
mcporter call xcodebuildmcp.list_schemes projectPath="/path/to/App.xcodeproj"

# Get bundle ID from built app
mcporter call xcodebuildmcp.get_app_bundle_id appPath="/path/to/App.app"
```

### Logging
```bash
# Start log capture
mcporter call xcodebuildmcp.start_sim_log_cap

# Stop and get logs
mcporter call xcodebuildmcp.stop_sim_log_cap logSessionId="<id>"
```

## Testing Workflow

### Phase 1: Test

#### 1. Set Defaults & Build
```bash
mcporter call xcodebuildmcp.session_set_defaults \
  projectPath="/path/to/App.xcodeproj" \
  scheme="App Name" \
  simulatorName="iPhone 17"

mcporter call xcodebuildmcp.build_run_sim
```

#### 2. Explore All Screens
For each screen/tab:
1. `snapshot_ui` → read all elements
2. `screenshot returnFormat=path` → visual verification with `image` tool
3. `tap label="Tab Name"` → navigate to next screen
4. Repeat for every tab/screen in the app

#### 3. Test All Interactive Elements
For each button/input/toggle/slider:
1. `snapshot_ui` → find element label or coordinates
2. `tap` or `type_text` → interact
3. `snapshot_ui` → verify state changed (compare before/after)
4. `screenshot` → visual proof
5. **If nothing changed when it should have → BUG**

#### 4. Test Core Functionality
- If it's a quiz app → try to play a round
- If it has timers → verify they count
- If it has calculations → verify results
- If it has data entry → enter data and verify it displays
- **If a feature doesn't work → BUG**

#### 5. Test Data Persistence
1. Add data (type text, toggle settings, etc.)
2. `stop_app_sim`
3. `launch_app_sim`
4. `snapshot_ui` + `screenshot` → verify data persisted
5. **If data is lost → BUG**

#### 6. Visual Analysis (MANDATORY)
**After EVERY screenshot, analyze it visually using the `image` tool.** This catches issues that snapshot_ui cannot detect:

```bash
# Take screenshot
mcporter call xcodebuildmcp.screenshot --timeout 15000 returnFormat=path
# Then ALWAYS analyze it:
# image(image="/path/to/screenshot.png", prompt="Analyze this iOS app screenshot. Check for: 1) UI overlaps or clipping 2) Text truncation or overflow 3) Color/contrast issues 4) Misaligned elements 5) Empty states that look broken 6) Any visual bugs. Describe what you see and flag any issues.")
```

**Check for these visual issues:**
- Text cut off or overlapping other elements
- Buttons too small or too close together
- Colors not matching brand (wrong background, wrong accent color)
- Empty spaces where content should be
- Elements going off-screen or under notch/safe area
- Inconsistent spacing or alignment
- Loading states that look broken

**If visual issues found → fix code → rebuild → re-screenshot → re-analyze**

#### 7. Save Screenshots
- **Delete old screenshots first** — remove entire `screenshots/` folder before saving new ones
- Take **4-5 screenshots** showing the app's **core functionality**
- Save them to `screenshots/` folder inside the project directory
- Name them descriptively: `01-home.jpg`, `02-gameplay.jpg`, `03-results.jpg`, etc.

```bash
rm -rf "/path/to/project/screenshots"
mkdir -p "/path/to/project/screenshots"
cp "$SCREENSHOT_PATH" "/path/to/project/screenshots/01-home.jpg"
```

### Phase 2: Fix Bugs

**When bugs are found during testing, fix them immediately:**

1. **Identify the root cause** — read the relevant Swift source files
2. **Fix the code** — edit the Swift files directly
3. **Rebuild & relaunch** — `build_run_sim` again
4. **Retest the fix** — verify the bug is gone with snapshot_ui + screenshot
5. **Continue testing** — don't stop at the first bug, test everything

#### Common Bug Patterns
- **NavigationLink in sheet/overlay** — gets destroyed when sheet dismisses. Fix: move to parent view
- **UI overlaps** — elements stacked. Fix: adjust padding/spacing/ZStack order
- **Buttons not responding** — wrong hit area or gesture conflict. Fix: check frame sizes
- **Data not persisting** — UserDefaults not saving. Fix: verify @AppStorage keys
- **Layout broken on iPad** — hardcoded sizes. Fix: use GeometryReader or adaptive layouts

### Phase 3: Final Verification

After all bugs are fixed:
1. **Clean rebuild** — `build_run_sim`
2. **Retest ALL screens** — not just the fixed ones
3. **Take fresh screenshots** — 4-5 showing core functionality, save to `project/screenshots/`
4. **Write test report** — see template below

## Test Report Template

```
## Test Report: [App Name]

### Build
- ✅/❌ Builds without errors
- ✅/❌ Launches without crash

### Screens Tested
- [Screen 1]: ✅/❌ — [notes]
- [Screen 2]: ✅/❌ — [notes]

### Bugs Found & Fixed
- BUG-1: [description] → FIXED: [what was changed]

### Bugs Found & NOT Fixed (if any)
- BUG-N: [description] — Reason: [why not fixed]

### Screenshots (saved to project/screenshots/)
- 01-home.jpg — Main screen
- 02-gameplay.jpg — Core feature
- 03-results.jpg — Output/results

### Overall: PASS / FAIL
```

## Testing Checklist
- [ ] App builds without errors
- [ ] App launches without crash
- [ ] ALL tabs/screens navigated
- [ ] ALL interactive elements tested (buttons, inputs, toggles)
- [ ] Core functionality works (main feature of the app)
- [ ] State changes verified (snapshot_ui before/after)
- [ ] Data persistence tested (stop → relaunch → verify)
- [ ] No visual glitches (verified via screenshots + `image` tool analysis — MANDATORY)
- [ ] No UI overlaps or hidden elements
- [ ] 4-5 screenshots saved to `project/screenshots/`
- [ ] **All bugs found during testing are FIXED**
- [ ] **Retested after fixes — all clear**

### Phase 4: Cleanup

After testing is complete, **shut down the simulator**:

```bash
xcrun simctl shutdown all
```

This frees system resources. Always do this as the last step.

## Tips
- **Always use `label=` for taps when possible** — more reliable than coordinates
- **`snapshot_ui` is your eyes** — run it after every action to see what changed
- **`screenshot` + `image` tool = visual verification** — catch layout issues
- If an element has no label, use coordinates from `snapshot_ui`
- After typing text, tap elsewhere to dismiss keyboard before next action
- **Don't just report bugs — FIX THEM, rebuild, and retest**
- Use `--output json` with mcporter for machine-readable output when scripting
