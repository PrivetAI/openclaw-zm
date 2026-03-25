---
name: codemagic
description: Create and configure codemagic.yaml for iOS apps + fix pbxproj signing for Codemagic CI/CD builds. Use when setting up Codemagic, fixing build errors, or creating codemagic.yaml files.
---

# Codemagic Setup

## Prerequisites from User
- **Bundle ID** (e.g. `com.askelskovgaard.jaxer-logic-trap`) — this is the App Store Connect bundle ID, NOT the dev bundle ID
- **Apple ID** (numeric, e.g. `6760821566`)
- **Provisioning profile name** — usually matches app display name (e.g. `Jaxer: Logic Trap`)
- **App folder name** — the folder on disk (NO colons, e.g. `Jaxer Logic Trap`)

## Step 1: Create codemagic.yaml

```yaml
workflows:
  ios-native-quick-start:
    name: iOS Native
    max_build_duration: 60
    instance_type: mac_mini_m2
    integrations:
      app_store_connect: 'PROVISIONING_PROFILE_NAME'
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: BUNDLE_ID
      vars:
        BUNDLE_ID: "BUNDLE_ID"
        XCODE_WORKSPACE: "APP_FOLDER_NAME.xcodeproj"
        XCODE_SCHEME: "APP_FOLDER_NAME"
        APP_STORE_APPLE_ID: APPLE_ID_NUMBER
      xcode: latest
      cocoapods: default
    scripts:
      - name: Set up provisioning profiles settings on Xcode project
        script: xcode-project use-profiles
      - name: Build ipa for distribution
        script: |
          xcode-project build-ipa \
            --project "$CM_BUILD_DIR/$XCODE_WORKSPACE" \
            --scheme "$XCODE_SCHEME"
    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log
      - $HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.app
      - $HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.dSYM
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
```

**Replace:**
- `PROVISIONING_PROFILE_NAME` — exact provisioning profile name (with colon if needed, e.g. `Jaxer: Logic Trap`)
- `BUNDLE_ID` — App Store Connect bundle ID (e.g. `com.askelskovgaard.jaxer-logic-trap`)
- `APP_FOLDER_NAME` — folder name on disk, NO colons (e.g. `Jaxer Logic Trap`)
- `APPLE_ID_NUMBER` — numeric Apple ID (e.g. `6760821566`)

## Step 2: Fix pbxproj Signing

**⚠️ CRITICAL: The bundle ID in pbxproj MUST match the bundle ID in codemagic.yaml**

This is the #1 cause of Codemagic build failures. During development, apps often have a dev bundle ID (e.g. `com.joka.memorychaos`). The codemagic.yaml uses the App Store bundle ID (e.g. `com.urazyavuzalp.joka-memory-chaos`). These MUST match.

```bash
PBXPROJ="APP_FOLDER_NAME.xcodeproj/project.pbxproj"

# 1. Set bundle ID to match codemagic.yaml
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = OLD_BUNDLE_ID/PRODUCT_BUNDLE_IDENTIFIER = NEW_BUNDLE_ID/g' "$PBXPROJ"

# 2. Set CODE_SIGN_STYLE = Manual (only this line, nothing else)
sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' "$PBXPROJ"

# 3. REMOVE all other signing fields — use-profiles fills them at build time
sed -i '' '/DEVELOPMENT_TEAM = /d' "$PBXPROJ"
sed -i '' '/PROVISIONING_PROFILE_SPECIFIER = /d' "$PBXPROJ"
sed -i '' '/CODE_SIGN_IDENTITY = /d' "$PBXPROJ"
```

### Verify
```bash
grep "CODE_SIGN\|PROVISIONING\|DEVELOPMENT_TEAM\|PRODUCT_BUNDLE_IDENTIFIER" "$PBXPROJ"
```

Should show ONLY:
```
CODE_SIGN_STYLE = Manual;
CODE_SIGN_STYLE = Manual;
PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
```

No `DEVELOPMENT_TEAM`, no `PROVISIONING_PROFILE_SPECIFIER`, no `CODE_SIGN_IDENTITY`.

## Common Errors

### "requires a provisioning profile"
**Cause:** Bundle ID mismatch between pbxproj and codemagic.yaml, OR extra signing fields in pbxproj.
**Fix:**
1. Check `PRODUCT_BUNDLE_IDENTIFIER` in pbxproj matches `bundle_identifier` in codemagic.yaml
2. Remove `DEVELOPMENT_TEAM`, `PROVISIONING_PROFILE_SPECIFIER`, `CODE_SIGN_IDENTITY` from pbxproj

### "No signing certificate"
**Cause:** `integrations.app_store_connect` value doesn't match a provisioning profile in App Store Connect.
**Fix:** Verify the profile name is exact (including colons, spaces, capitalization).

### Build succeeds locally but fails on Codemagic
**Cause:** Local Xcode uses your signing identity. Codemagic needs `use-profiles` to set it up.
**Fix:** Ensure `xcode-project use-profiles` runs BEFORE the build step.

## Reference: Working Projects
- **SledPack Ice Fishing Planner** — `CODE_SIGN_STYLE = Manual` only, works
- **Sweetoria Candy Odyssey** — `CODE_SIGN_STYLE = Automatic` only, works (also valid)
- Both have NO `DEVELOPMENT_TEAM`/`PROVISIONING_PROFILE_SPECIFIER`/`CODE_SIGN_IDENTITY`

## Checklist
- [ ] codemagic.yaml created with correct bundle ID, Apple ID, profile name
- [ ] pbxproj `PRODUCT_BUNDLE_IDENTIFIER` matches codemagic.yaml `bundle_identifier`
- [ ] pbxproj has `CODE_SIGN_STYLE = Manual` (both Debug and Release)
- [ ] pbxproj has NO `DEVELOPMENT_TEAM`, `PROVISIONING_PROFILE_SPECIFIER`, `CODE_SIGN_IDENTITY`
- [ ] Git committed and pushed
