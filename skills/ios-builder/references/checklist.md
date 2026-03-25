# Pre-Delivery Checklist

Run through every item before moving app to `for_human_review_apps/`.

## Build
- [ ] Builds without errors or warnings
- [ ] No deprecated API usage
- [ ] iOS 15.6 deployment target set
- [ ] No iOS 16+ APIs used anywhere

## UI
- [ ] No UI element overlaps on any screen size
- [ ] No layers hidden beneath other elements
- [ ] Theme-independent (looks same in light/dark mode)
- [ ] All components are custom (no system components)
- [ ] No SF Symbols used
- [ ] No emoji in UI
- [ ] Icons rendered from custom Shapes
- [ ] Adaptive layout works on iPhone + iPad
- [ ] Portrait + Landscape Left + Landscape Right all work

## App Config
- [ ] App name contains spaces
- [ ] App icon generated and set
- [ ] English (US) only
- [ ] No notification code
- [ ] Local storage only
- [ ] Xcode destination: iPhone
- [ ] Orientations: Portrait, Landscape Left, Landscape Right

## Testing (via ios-tester skill)
- [ ] App launches in Simulator without crash
- [ ] ALL tabs/screens navigated and verified
- [ ] ALL interactive elements tested
- [ ] Data persistence tested (stop → relaunch → verify)
- [ ] No visual glitches (screenshot + image analysis)
- [ ] Minimum 5 screenshots from different screens

## Delivery
- [ ] APP_TRACKER.md updated
- [ ] App folder moved to for_human_review_apps/
- [ ] Master notified
