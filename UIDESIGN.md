# UIDESIGN.md

## Overview

This document describes the current UI look and feel for IRTSW. Update this file whenever UI elements, themes, or layout conventions change.

## Current State

The project currently has a main menu UI implemented in `Scenes/UI/main_menu.tscn` with supporting scripts in `Scripts/UI/`. This is the only UI scene at present.

## Visual Theme

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Background Dark | #11161a | Primary background |
| Background Panel | #0b131680 | Semi-transparent panels |
| Panel Background | #091721 | Panel backgrounds |
| Accent Cyan | #48c9d4 | Accents, highlights |
| Accent Light | #78d9ec | Hover states |
| Text Primary | #dbe2e8 | Button text, labels |
| Text Muted | #737d84 | Secondary text |
| Text Dim | #555d61 | Status text |
| Border Light | #9ba6ad | Button borders |
| Button Base Light | #48525a | Button base color |
| Button Base Dark | #222a30 | Button gradient |
| Grid Lines | #b8c8cc09 | Subtle grid overlay |

### Typography

- Primary font size: 22px for buttons
- Title: 58px with outline (8px, Color #02030359)
- Subtitle: 14px
- Section labels: 13px
- Status text: 13px

All text uses the default Godot font with color overrides applied through theme.

### Layout Structure

The main menu uses a hierarchical container structure:

```
MainMenu (Control - full screen)
├── SafeArea (MarginContainer - 64px sides, 56px top, 48px bottom)
    └── Layout (VBoxContainer)
        ├── Header (HBoxContainer)
        │   ├── TitleBlock (VBoxContainer)
        │   │   ├── Title (Label): "IRTSW"
        │   │   └── Subtitle (Label): "PERSISTENT WORLD // COMMAND INTERFACE"
        │   ├── Spacer
        │   └── BuildLabel (Label): "FORWARD+  //  SYSTEM READY"
        ├── AccentLine (Panel - 2px cyan line)
        ├── Content (HBoxContainer)
        │   ├── MenuPanel (PanelContainer - 410px min width)
        │   │   └── Margin (MarginContainer - 32px margins)
        │   │       └── Buttons (VBoxContainer)
        │   │           ├── SectionLabel: "SELECT OPERATION"
        │   │           ├── Login (Button)
        │   │           ├── JoinGame (Button)
        │   │           ├── Settings (Button)
        │   │           └── Credits (Button)
        │   └── VisualSpace (Control - expands to fill)
        └── Footer (HBoxContainer)
            ├── Connection (Label): "●  NETWORK STANDBY"
            ├── FooterSpacer
            └── Version (Label): "PRE-ALPHA"
└── StatusDialog (AcceptDialog)
```

### Visual Effects

The main menu background features:
- Dark gradient from #333b41 (top) to #0b0f12 (bottom)
- Subtle white grid lines on 64px spacing at low opacity (0.035)
- Diagonal reflection polygon with cyan tint (0.025 opacity)

### Button Style (MetalMenuButton)

Custom button class with:
- Flat style with empty StyleBox overrides
- Corner cut effect (16px default)
- Color transitions: base color lerps between #48525a and #596872 on hover
- Hover effect: cyan glow (Color #52d8ff at 0.1 opacity)
- Pressed effect: darkens by 12%
- Border: #9ba6ad to #78d9ec gradient on hover
- Top-left highlight lines for depth
- Text colors: #dbe2e8 (normal), #ffffff (hover/focus), #a9f3ff (pressed)
- Outline: 3px, Color #10161b

## Known Issues

- **Fixed**: Menu labels not displaying (resolved by removing `_draw()` from main_menu.gd that was covering child controls)
- **Fixed**: Button text not displaying (resolved by adding text drawing to MetalMenuButton's `_draw()`)
- **Fixed**: MenuPanel background visibility (resolved by setting all StylePanel colors to fully transparent)

## Design Principles

1. **Sci-fi/industrial aesthetic**: Dark backgrounds, cyan accents, metallic button finishes
2. **Clean typography**: High contrast text with subtle outlines for readability
3. **Responsive layout**: Uses anchor-based layout with safe area margins
4. **Visual hierarchy**: Clear separation between header, content, and footer
5. **Status feedback**: All menu actions show a modal dialog with descriptive messages

## Future UI Development

When adding new UI elements:
- Maintain the dark color palette with cyan accents
- Use the same typography scale (13px, 14px, 22px, 58px)
- Continue the industrial/metallic button style for interactive elements
- Ensure all UI respects the safe area margins
- Document new components in this file

## Update History

- 2026-10-17: Initial version documenting main menu UI structure, visual theme, and color palette
- 2026-10-17: Fixed menu label visibility issue by removing `_draw()` from main_menu.gd
- 2026-10-17: Fixed button text visibility by adding manual text drawing to MetalMenuButton
- 2026-10-17: Made MenuPanel fully invisible by setting all StylePanel properties to transparent/zero
