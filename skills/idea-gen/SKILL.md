---
name: idea-gen
description: Generate unique iOS app ideas for App Store submission. Use when brainstorming new app concepts, given a theme/category. Checks existing apps to avoid duplicates.
---

# App Idea Generation

Generate truly unique iOS app ideas that won't get rejected for 4.3 (design spam).

## Inputs

User provides:
- **Category** — App Store category (Education, Health & Fitness, Reference, etc.)
- **Quantity** — how many ideas to generate (default: 5-10)

Brand/style is provided separately at build time, not during idea generation.

## Before Generating

**MANDATORY:** Read the existing app list first. Path is in `config/paths.json` → `app_descriptions` key.

```bash
cat "$(jq -r .app_descriptions config/paths.json)"
```

Every new idea MUST be meaningfully different from everything in that list — different core mechanic, different data domain, different user interaction pattern. Not just a reskin or renamed clone.

## Uniqueness Rules

### What Makes an Idea Unique

An idea is unique when it has a **different core loop** — the primary thing the user does repeatedly. Two apps can share a category but must differ in:

- **Input method** — tap vs draw vs type vs shake vs hold vs swipe
- **Data domain** — what the app is actually about (not just a theme swap)
- **Core mechanic** — timer vs quiz vs tracker vs calculator vs builder vs reference
- **Output** — what the user gets (score, chart, log entry, creation, knowledge)

### ❌ NOT Unique (Examples)

- "Math Quiz" + "Flag Quiz" + "Capital Quiz" = same mechanic (quiz), different database
- "Run Tracker" + "Walk Tracker" + "Swim Tracker" = same mechanic (distance tracking), different label
- "Focus Timer" + "Stretch Timer" + "Fasting Timer" = same mechanic (countdown), different context
- "Sleep Log" + "Water Log" + "Mood Log" = same mechanic (daily entry + chart), different metric

### ✅ Unique (Examples)

- Quiz app vs Drawing app vs Rhythm game vs Reference guide = all different core loops
- Timer with breathing visualization vs Timer with haptic patterns vs Timer with sound design = same base but genuinely different UX
- Tracker with manual input vs Tracker with gesture-based input vs Tracker with photo-based input = different interaction models

### The "Swap Test"

Ask: *"Could I swap the content/theme and keep the same UI and code?"*
- If YES → it's a reskin, not a unique idea
- If NO → it's genuinely different

## Output Format

For each idea, provide:

| Field | Description |
|-------|-------------|
| **Name** | App name (English, with spaces, sounds like a real app) |
| **Category** | App Store category |
| **Core mechanic** | 1 sentence: what the user actually does |
| **Why it's unique** | 1 sentence: how it differs from existing apps |

## Naming Rules

- Must contain spaces
- Must be grammatically correct English
- Must sound like a real app in the category
- Must NOT conflict with names in APP_DESCRIPTIONS.md
- Keep it short (2-3 words ideal)

## After Approval

Once user confirms which ideas to build, hand off to **ios-builder** skill.

After building + optional rename, the app gets added to `APP_DESCRIPTIONS.md` (handled by ios-builder or ios-app-rename skills).
