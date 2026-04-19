# EduOps UI Extraction and Adaptive Web Handoff

This handoff maps the implemented EduOps web UI to reusable Figma structure.

## What was extracted

- Core app shell with responsive side navigation and mobile drawer.
- Parent mobile shell with sticky top bar and bottom tab bar.
- Dashboard patterns: metric cards, activity feed cards, section headers.
- Shared tokenized color system from `src/styles/theme.css`.

## Recommended Figma frame set

- Desktop: 1440 x 1024
- Laptop: 1280 x 800
- Tablet: 1024 x 768
- Mobile: 390 x 844

## Responsive breakpoints

- Mobile: 0-767
- Tablet: 768-1023
- Desktop: 1024+

## Adaptive behavior rules

- At desktop, show permanent left sidebar.
- At tablet/mobile, convert sidebar to a slide-in drawer.
- Reserve top space for sticky mobile header and safe area inset.
- Reserve bottom space for sticky mobile tab bar and safe area inset.
- Allow data-heavy surfaces (tables, weekly grids) to scroll horizontally on small screens.

## Component mapping

- App Shell
  - Desktop sidebar
  - Mobile header
  - Mobile drawer overlay
- Parent Mobile Shell
  - Sticky header actions
  - Bottom tab navigation
- Cards
  - Metric Card
  - Standard Content Card
  - Activity Row
- Inputs and Actions
  - Primary button
  - Secondary button
  - Text input
  - Select trigger

## Color tokens

Use the exported token file `guidelines/figma-tokens.json` to create Figma Variables.

## Typography setup for Figma

- Heading scale
  - H1: 30/38, semibold
  - H2: 24/32, semibold
  - H3: 20/28, semibold
  - Body: 16/24, regular
  - Small: 14/20, regular
  - Caption: 12/16, regular

## Spacing system

- 4, 8, 12, 16, 20, 24, 32
- Radius: 8

## Asset notes

- Main logo source in code: `src/assets/06ec834f803405bdc67336243d2c3f6e0f882eba.png`

## Suggested Figma page structure

- 01 Foundations
- 02 Components
- 03 Admin Screens
- 04 Parent Screens
- 05 Responsive Specs

## Validation checklist

- Verify desktop sidebar remains fixed at 1024+.
- Verify mobile drawer opens and closes correctly under 1024.
- Verify no bottom tab overlap with content on iOS/Android safe areas.
- Verify Dashboard cards collapse from 4 -> 2 -> 1 columns as viewport shrinks.
