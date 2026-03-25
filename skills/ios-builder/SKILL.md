---
name: ios-builder
description: Build and deliver iOS apps for App Store submission. Use when generating app ideas, creating Xcode projects, building Swift apps, delivering finished apps. Covers the full lifecycle from idea to for_human_review_apps delivery.
---

# iOS Builder

## Paths
All paths are resolved from `config/paths.json` in the workspace root.
- Dev root: `development` key
- Delivery: `review_apps` key
- App descriptions: `app_descriptions` key

Relative files inside dev root:
- Guide: `GUIDE.md`
- App tracker: `APP_TRACKER.md`
- Apps overview: `apps_overview.txt`

## App Store Moderation Rules
- **Goal**: Develop fully working applications that pass App Store moderation without rejections
- Must pass moderation — no bugs or issues that cause rejection
- **Avoid popular mechanics/designs** — risk of 4.3(a) rejection (design spam)
- **Creativity is unlimited** — the more unique, the better
- No notifications allowed
- Language: English (US) only
- App name must contain spaces
- No errors allowed in final build

## Workflow
1. Generate unique app ideas when Master requests
2. Wait for Master's confirmation before building
3. Create Xcode project in **dev root** (from `config/paths.json`) following GUIDE.md
4. Build with `xcodebuild` — target iOS 15.6+
5. **Test the app using the `ios-tester` skill** — build & launch in Simulator, navigate all screens, test interactions, take screenshots. **If bugs found → fix code → rebuild → retest until clean**
6. Update `APP_TRACKER.md`
7. **Move** (not copy!) finished app to `for_human_review_apps/`, report to Master

## File Locations (CRITICAL — no duplicates!)
- **In progress** → `development/` (root) — build and test here
- **Finished** → `for_human_review_apps/` — move with `mv`, not `cp`
- **NEVER leave copies** in both places — one canonical location only
- `in_build/` — do NOT use, deprecated
- After `mv` to `for_human_review_apps/`, the app must NOT exist in dev root anymore

## Critical Constraints (memorize these)
- **iOS 15.6+ ONLY** — no iOS 16+ APIs (NavigationStack, .scrollDismissesKeyboard, Charts framework, etc.)
- Use `NavigationView`, NOT `NavigationStack`
- Use `UIScreen.main.bounds`, NOT newer geometry APIs
- Swift only, no SwiftUI 4+ features
- **Custom UI only** — no SF Symbols, no system components, no native icons
- **No emoji** in UI — use custom Shape-based icons via Image rendering
- App name must contain spaces
- English (US) only
- Local storage only (UserDefaults, CoreData, files) — no cloud/network
- No notifications
- App size < 99 MB
- **Theme-independent appearance** — app must NOT change based on device theme (light/dark); force light mode or use custom colors
- Adaptive layout: iPhone + iPad
- Xcode: iPhone destination only; Portrait + Landscape Left + Landscape Right
- **Signing & Destinations in pbxproj** — MUST set in BOTH Debug AND Release sections:
  - `CODE_SIGN_STYLE = Manual;`
  - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";`
  - `SUPPORTS_MACCATALYST = NO;`
  - `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;`
  - `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;`
  - `TARGETED_DEVICE_FAMILY = 1;` (1 = iPhone only)
- **Generate and install app icon** — create a 1024x1024 icon matching the app's theme/brand and install it into `Assets.xcassets/AppIcon.appiconset/`
- **No UI overlaps or hidden layers** — UI elements must not overlap; no layers beneath elements
- **No bugs or errors allowed** — app must run without crashes or issues

## Idea Generation
→ **Use the `idea-gen` skill** for generating app ideas. It handles uniqueness checks against `APP_DESCRIPTIONS.md`, the swap test, and naming rules.

## Brand Identity
When Master provides brand authenticity/identity, apply it to ALL apps in the batch:
- **Color palette** — use provided brand colors as primary/accent/background
- **Visual style** — follow the brand's aesthetic (minimal, bold, retro, etc.)
- **Typography feel** — match the brand's tone (clean, playful, serious, etc.)
- **Icon style** — app icons should reflect the brand identity
- **UI components** — buttons, cards, headers should use brand colors/style consistently
- Brand identity is provided per-batch; each new batch may have a different brand

## Naming Convention
- App name MUST be relevant to the given theme/topic
- MUST contain spaces (e.g., "Drift Line Tracker", NOT "DriftLineTracker")
- Must sound like a real app in the given category
- Must be grammatically correct English
- Check `apps_overview.txt` to avoid conflicts with existing names

## WebView Integration
- Follow `references/webview-guide.md` for complete implementation pattern
- **ALWAYS use `https://example.com` as the WebView URL** — placeholder for all new apps
- **Check domain:** `"example"` — used in `.contains("example")` checks
- **Logic:** App launch → RedirectTracker follows redirects → if final URL contains "example" show app, else show WebView fullscreen
- **Implementation:** Modify App.swift with launch check + RedirectTracker, create WebPanel & LoadingScreen components, add to Settings
- **Code must be unique per app** — rename all variables, structs, functions, classes per app
- **Files modified:** App.swift, Info.plist (add NSAllowsArbitraryLoads), SettingsView.swift, plus 2 new files (WebPanel, LoadingScreen)
- **Timeout:** 5 seconds — falls back to showing app on error/timeout

## Assets
- Images can be generated
- **App icon:** generate 1024x1024 PNG matching theme/brand, install into `Assets.xcassets/AppIcon.appiconset/` with proper `Contents.json`
- Use custom Shape-based icons rendered as Images for in-app UI (no SF Symbols, no emoji)

## Build Commands
```bash
# Build
xcodebuild -project "App Name.xcodeproj" -scheme "App Name" -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath build/ build

# List simulators
xcrun simctl list devices available

# Boot & install
xcrun simctl boot <UDID>
xcrun simctl install <UDID> build/Build/Products/Debug-iphonesimulator/AppName.app

# Launch
xcrun simctl launch <UDID> <bundle-id>

# Screenshot
xcrun simctl io <UDID> screenshot screenshot.png
```

## Codemagic

For Codemagic setup, use the `codemagic` skill. It handles codemagic.yaml creation, pbxproj signing, and bundle ID matching.

## NO Extra Files
- **Do NOT create** README.md, DELIVERY_SUMMARY.md, RENAME_SUMMARY.md, TESTING_REPORT.md, or any other markdown summary files in the app folder
- App folder should only contain: xcodeproj, source folder, screenshots folder, codemagic.yaml (when provided), and .git
- No .py, .sh, .txt, or other non-essential files in the final delivery

## Delivery Checklist
Before moving app to `for_human_review_apps/`, verify:
- [ ] Builds without errors
- [ ] Runs in Simulator without crashes
- [ ] iOS 15.6 compatible (no iOS 16+ APIs)
- [ ] iPhone + iPad adaptive layout
- [ ] No UI overlaps or hidden layers
- [ ] Theme-independent appearance (light mode forced or custom colors)
- [ ] Custom components only (no system/SF Symbols)
- [ ] No emoji in UI
- [ ] App name contains spaces
- [ ] English (US) only
- [ ] Local storage only (no cloud/network)
- [ ] No notifications
- [ ] Only Portrait + Landscape Left + Landscape Right supported
- [ ] Only IPhone destination
- [ ] Automatically manage signing disabled
- [ ] `APP_TRACKER.md` updated

Also read `references/checklist.md` for complete requirements.
Use the **`ios-tester` skill** for full UI testing workflow (xcodebuildmcp).

## Custom Tab Bar (CRITICAL)
- **NEVER use SwiftUI `TabView` with custom icon views** — `.tabItem` only renders `Image` + `Text`, custom Canvas/Shape views are invisible
- **Always build a custom tab bar** using `HStack` of `Button`s with a `switch` for content
- Pattern:
```swift
ZStack(alignment: .bottom) {
    VStack(spacing: 0) {
        Group {
            switch selectedTab {
            case 0: NavigationView { FirstView() }.navigationViewStyle(StackNavigationViewStyle())
            case 1: NavigationView { SecondView() }.navigationViewStyle(StackNavigationViewStyle())
            // ...
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // Custom Tab Bar
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Tab1", icon: AnyView(MyIcon(size: 24, color: selectedTab == 0 ? Brand.primary : Brand.text.opacity(0.4))))
            // ...
        }
        .padding(.top, 8).padding(.bottom, 4)
        .background(Brand.cardBackground.edgesIgnoringSafeArea(.bottom))
    }
}
```
- Each `tabButton` is a `Button` containing `VStack { icon; Text(label) }` with `.frame(maxWidth: .infinity)`

## .gitignore Rules
- **NEVER add `screenshots/` to .gitignore** — screenshots must always be tracked in git
- Standard .gitignore should exclude: build/, DerivedData/, xcuserdata/, *.xcuserstate, .DS_Store
