---
name: ios-version-bump
description: Bump build number and/or marketing version of an iOS app. Handles both hardcoded Info.plist values and $(VARIABLE) references from pbxproj. Use when incrementing build number, updating app version, or preparing a new release submission.
---

# iOS Version Bump

Bump build number (CFBundleVersion) and/or marketing version (CFBundleShortVersionString) for iOS apps.

## Paths

Resolve paths from `config/paths.json` in the workspace root.
- Apps live in the `review_apps` key
- GitHub org: `PrivetAI`

## Inputs

User provides:
- **App name** (folder name in for_human_review_apps)
- **What to bump**: build number, version, or both
- **Target values** (optional): specific version/build to set. If not given, auto-increment.

## Two Patterns

iOS apps store version info in two ways. **Detect which pattern before editing.**

### Pattern A: Hardcoded in Info.plist

```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

→ Edit Info.plist directly with PlistBuddy.

### Pattern B: Variable references in Info.plist

```xml
<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>
<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>
```

→ Edit `project.pbxproj` (values live there, plist just references them).

## Detection

```bash
APP_ROOT="$(python3 - <<'PY'
import json, os
from pathlib import Path
cfg = Path(os.path.expanduser('~/.openclaw/workspace/config/paths.json'))
print(json.loads(cfg.read_text())['review_apps'])
PY
)/App Name"
cd "$APP_ROOT"
PLIST=$(find . -name "Info.plist" -not -path "./.git/*" -not -path "*/build/*" | head -1)
grep -A1 "CFBundleVersion" "$PLIST"
grep -A1 "CFBundleShortVersionString" "$PLIST"
```

- If values contain `$(` → **Pattern B** (variable)
- If values are plain numbers → **Pattern A** (hardcoded)

## Bump: Pattern A (Hardcoded)

```bash
# Read current values
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST"

# Set new build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion '2'" "$PLIST"

# Set new version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString '1.1'" "$PLIST"
```

**Also update pbxproj** to keep them in sync:

```bash
PBXPROJ="$(find . -name "project.pbxproj" | head -1)"
# Replace CURRENT_PROJECT_VERSION
sed -i '' 's/CURRENT_PROJECT_VERSION = [0-9][0-9]*/CURRENT_PROJECT_VERSION = 2/g' "$PBXPROJ"
# Replace MARKETING_VERSION
sed -i '' 's/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*/MARKETING_VERSION = 1.1/g' "$PBXPROJ"
```

## Bump: Pattern B (Variable)

Only edit pbxproj — plist reads from variables automatically.

```bash
PBXPROJ="$(find . -name "project.pbxproj" | head -1)"

# Read current values
grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1
grep "MARKETING_VERSION" "$PBXPROJ" | head -1

# Set new build number (appears multiple times — Debug + Release)
sed -i '' 's/CURRENT_PROJECT_VERSION = [0-9][0-9]*/CURRENT_PROJECT_VERSION = 2/g' "$PBXPROJ"

# Set new version
sed -i '' 's/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*/MARKETING_VERSION = 1.1/g' "$PBXPROJ"
```

## Auto-Increment Logic

If user doesn't specify target values:
- **Build number**: current + 1 (e.g. `1` → `2`, `5` → `6`)
- **Marketing version**: bump patch (e.g. `1.0` → `1.1`, `2.3` → `2.4`)

If user says "bump version to 2.0": set marketing version to `2.0`, reset build to `1`.

## Verify

```bash
# Confirm values are set
grep "CURRENT_PROJECT_VERSION" "$PBXPROJ"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null

# Build to verify nothing broke
xcodebuild -project "*.xcodeproj" -scheme "App Name" \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -3
```

## Commit & Push

```bash
git add -A
git commit -m "Bump version to X.Y (build Z)"
git push
```

## Batch Mode

When bumping multiple apps, process sequentially. Report summary:

```
✅ App Name 1: 1.0 (1) → 1.1 (2)
✅ App Name 2: 1.0 (3) → 1.0 (4)
```
