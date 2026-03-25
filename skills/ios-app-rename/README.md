# iOS App Rename Skill

Comprehensive iOS app renaming workflow - handles folders, files, Xcode project, code references, bundle ID, and GitHub repo.

## Usage

Use this skill when:
- Rebranding an existing iOS app to a new name
- Fixing naming mistakes from initial development
- Batch renaming multiple apps with new brand identity

## What It Handles

1. ✅ Folder structure (main folder, inner folder, xcodeproj)
2. ✅ Swift files (App, WebPanel, LoadingScreen, etc.)
3. ✅ Code references (structs, classes, variables, comments, strings)
4. ✅ Xcode project (project.pbxproj, schemes)
5. ✅ Info.plist (display name, bundle ID)
6. ✅ Supporting files (readme.txt, TESTING_REPORT.md)
7. ✅ Build verification
8. ✅ Git commit and push
9. ✅ GitHub repository rename

## Quick Start

1. Gather information:
   - Current folder name
   - Old internal name
   - New display name
   - New internal name
   - New GitHub repo name

2. Follow the step-by-step process in `SKILL.md`

3. Verify build succeeds

4. Push and rename GitHub repo

## Example

Renaming "Cobra Sleep Log" to "BNation Rest":

- Old: `Cobra`, `cobra`, `CobraSleepLog`
- New: `BNation`, `bnation`, `BNationRest`
- Display: "BNation Rest"
- GitHub: `BNation-Rest`

Full walkthrough provided in `SKILL.md`.

## Important Notes

- **Destructive process** - ensure clean git state before starting
- **UserDefaults keys** - decide whether to migrate or keep old keys
- **Bundle ID** - usually keep unchanged unless required
- **Build first** - always verify build succeeds before pushing
- **One at a time** - do not rename multiple apps in parallel

## Recent Renames

Successfully used for:
- Cobra Sleep Log → BNation Rest
- Jade Water Tracker → AquaNacional: Your Choice
- Venom Focus Timer → 88 Focus Starz
