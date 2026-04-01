---
name: ios-app-rename
description: Comprehensive iOS app renaming - folders, files, Xcode project, code references, bundle ID, and GitHub repo. Use when rebranding an existing iOS app to a completely new name.
---

# iOS App Rename + WebView Setup

Rename an iOS app everywhere (folders, files, Xcode project, code, GitHub) and update WebView URL + check domain.

## Inputs from User

User provides:
- **Old app name** (e.g. "Cobra Sleep Log")
- **New app name** (e.g. "BNation Rest")
- **New WebView URL** (e.g. `https://bnationrest.org/click.php`)
- **New check domain** (e.g. `freeprivacypolicy.com`) — if not specified, use `freeprivacypolicy.com`

Derive automatically:
- Old/new PascalCase: `CobraSleepLog` / `BNationRest`
- Old/new camelCase: `cobraSleepLog` / `bnationRest`
- Old/new short prefix from old code (find via grep)
- New bundle ID: `com.<newnamelower>.<appnamelower>` (or ask user)
- New GitHub repo name: dashes between words (e.g. `BNation-Rest`)

## Paths

All paths resolved from `config/paths.json` in workspace root.
- Apps live in: `review_apps` key
- GitHub org: `PrivetAI`

## Process

### 1. Find the App

```bash
cd "/Users/PrinceTyga/Documents/development/for_human_review_apps"
ls -d "*Old*" 2>/dev/null  # find exact folder name
```

### 2. Grep Old References

```bash
cd "Old App Name"
grep -ri "oldprefix\|OldName\|old.name" . --exclude-dir=build --exclude-dir=.git --exclude="*.xcuserstate" -l
```

Identify all old variable prefixes (e.g. `cobra`, `cobraSourceLink`, `CobraWebPanel`).

### 3. Rename Folder Structure

```bash
cd "/Users/PrinceTyga/Documents/development/for_human_review_apps"
mv "Old App Name" "New App Name"
cd "New App Name"
mv "Old App Name" "New App Name"
mv "Old App Name.xcodeproj" "New App Name.xcodeproj"
```

### 4. Rename Swift Files

Rename all files containing old name patterns:

```bash
# Find files with old prefix
find "New App Name" -name "*.swift" | grep -i "old"
# Rename each: OldXxx.swift → NewXxx.swift
```

Common patterns:
- `OldNameApp.swift` → `NewNameApp.swift`
- `OldWebPanel.swift` → `NewWebPanel.swift`
- `OldLoadingScreen.swift` → `NewLoadingScreen.swift`
- `OldRedirectTracker` (may be inline in App.swift)

### 5. Update All Code References

For EVERY Swift file, replace:

**Structs/Classes:**
- `struct OldNameApp` → `struct NewNameApp`
- `class OldRedirectTracker` → `class NewRedirectTracker`
- `struct OldWebPanel` → `struct NewWebPanel`
- `struct OldLoadingScreen` → `struct NewLoadingScreen`

**Variables:**
- `oldSourceLink` → `newSourceLink`
- `oldLinkReady` → `newLinkReady`
- `oldDisplayPage` → `newDisplayPage`
- `oldLoadedView` → `newLoadedView`

**Strings/Comments:**
- `"Old App Name"` → `"New App Name"`
- `// Old comment` → `// New comment`

**UserDefaults keys** — keep old keys OR migrate data.

### 6. Update WebView URL + Check Domain

Find and replace the WebView URL and check domain in code:

```bash
# Find current URL
grep -r "example\.com\|\.org/click\|\.com/click" "New App Name/" --include="*.swift"

# Find current check domain
grep -r "freeprivacypolicy\|sites\.google\|example" "New App Name/" --include="*.swift" | grep -i "contains"
```

Replace:
- Old URL (e.g. `https://example.com`) → New URL (e.g. `https://bnationrest.org/click.php`)
- Old check domain → New check domain in ALL `.contains("...")` calls
- Update in App.swift (launch check) AND SettingsView/ProfileView (direct link)
- **Privacy Policy button** in SettingsView MUST link to the **WebView URL** (not the check domain). Always set it to the new WebView URL.

**CRITICAL:** Check domain appears in TWO places minimum:
1. `RedirectTracker.checkDomain` or `init(checkDomain:)` — mid-chain interception
2. Final URL check: `if finalURL.contains("checkdomain")` — post-redirect check

Update BOTH.

### 7. Update project.pbxproj

```bash
PBXPROJ="New App Name.xcodeproj/project.pbxproj"
sed -i '' 's/Old App Name/New App Name/g' "$PBXPROJ"
sed -i '' 's/com.old.bundle/com.new.bundle/g' "$PBXPROJ"
```

Also replace old PascalCase references (file names changed in step 4).

**Fix signing & destinations** (in BOTH Debug and Release build configs):

```bash
# Signing — see codemagic skill for full details
sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' "$PBXPROJ"
sed -i '' '/DEVELOPMENT_TEAM = /d' "$PBXPROJ"
sed -i '' '/PROVISIONING_PROFILE_SPECIFIER = /d' "$PBXPROJ"
sed -i '' '/CODE_SIGN_IDENTITY = /d' "$PBXPROJ"

# ⚠️ CRITICAL: iPhone-only destinations
# Without these, Xcode adds "Mac (Designed for iPhone)" and "Apple Vision (Designed for iPhone)" destinations
# Remove any existing values first, then add correct ones before each TARGETED_DEVICE_FAMILY line
sed -i '' '/SUPPORTS_MACCATALYST/d' "$PBXPROJ"
sed -i '' '/SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD/d' "$PBXPROJ"
sed -i '' '/SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD/d' "$PBXPROJ"
sed -i '' '/TARGETED_DEVICE_FAMILY/i\
				SUPPORTS_MACCATALYST = NO;\
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;\
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;' "$PBXPROJ"

# Verify TARGETED_DEVICE_FAMILY = 1 (iPhone only)
sed -i '' 's/TARGETED_DEVICE_FAMILY = "1,2"/TARGETED_DEVICE_FAMILY = 1/g' "$PBXPROJ"

# ⚠️ Orientation: support Portrait + Landscape Left + Landscape Right
# Set in Info.plist (NOT pbxproj)
INFOPLIST="New App Name/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations" "$INFOPLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations array" "$INFOPLIST"
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" "$INFOPLIST"
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:1 string UIInterfaceOrientationLandscapeLeft" "$INFOPLIST"
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:2 string UIInterfaceOrientationLandscapeRight" "$INFOPLIST"
```

### 8. Update Schemes

```bash
cd "New App Name.xcodeproj/xcshareddata/xcschemes"
mv "Old App Name.xcscheme" "New App Name.xcscheme" 2>/dev/null || true
# Update content of scheme file
sed -i '' 's/Old App Name/New App Name/g' "New App Name.xcscheme"
```

### 9. Update Info.plist

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'New App Name'" "New App Name/Info.plist"
```

Bundle ID is set via pbxproj (step 7).

### 10. Delete Junk Files

**DO NOT create any .md, .txt, or report files in the project (no RENAME_COMPLETE.md, no TEST_REPORT.md, etc.).**

```bash
# Remove any markdown, txt, sh, py files
find . -maxdepth 2 \( -name "*.md" -o -name "*.txt" -o -name "*.sh" -o -name "*.py" \) ! -path "./.git/*" -delete
```

### 11. Build & Verify

```bash
xcodebuild -project "New App Name.xcodeproj" \
  -scheme "New App Name" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | tail -5
```

Must show `BUILD SUCCEEDED`.

### 12. Final Grep

```bash
# Check NO old name references remain
grep -ri "oldprefix\|OldName" . --exclude-dir=build --exclude-dir=.git --exclude="*.xcuserstate"
# Should return nothing
```

### 13. Git Commit & Push

```bash
git add -A
git commit -m "Rename to New App Name + update WebView URL"
git push
```

### 14. Rename GitHub Repo

```bash
gh repo rename New-App-Name --repo PrivetAI/Old-App-Name --yes
git remote set-url origin https://github.com/PrivetAI/New-App-Name.git
```

## WebView URL Rules

- **New apps (ios-builder):** Always use `example.com` as placeholder URL, check domain `example`
- **Rename skill:** Replace URL + check domain with values provided by user
- **Check domain** is used in `.contains("domain")` — always use `.contains()`, never `.hasPrefix()`
- URL appears in: App.swift (targetURL/sourceLink), SettingsView (privacy link), LoadingScreen (sometimes)

### 15. Update APP_DESCRIPTIONS.md

After rename, add/update the app entry in the master list:

```bash
# Path from config/paths.json → app_descriptions key
# Add a row with the NEW name and a 1-line description (Russian)
# If old name exists in the list, replace it with the new name
```

## Checklist

- [ ] Folders renamed (main, inner, xcodeproj)
- [ ] Swift files renamed
- [ ] All code references updated (structs, classes, variables, comments)
- [ ] WebView URL updated to new URL
- [ ] Check domain updated in ALL `.contains()` calls
- [ ] project.pbxproj updated (paths, product name, bundle ID)
- [ ] Schemes renamed + updated
- [ ] Info.plist display name updated
- [ ] No junk files (.md, .txt, .sh, .py)
- [ ] Build succeeds
- [ ] No old name references in grep
- [ ] Git committed + pushed
- [ ] GitHub repo renamed
- [ ] Git remote URL updated
- [ ] APP_DESCRIPTIONS.md updated with new name

## .gitignore Rules
- **NEVER add `screenshots/` to .gitignore** — screenshots must always be tracked in git
- If existing .gitignore excludes screenshots/, remove that line during rename
