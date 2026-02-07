# Developer Disk Analyzer - Design Specification

**Version:** 2.0
**Date:** 2026-02-06
**Status:** Implementation Complete

---

## Executive Summary

This document provides a Figma-ready design specification for the **Developer Disk Analyzer**, a macOS application that transforms generic filesystem analysis into developer-intelligence tool. The app targets iOS, Android, and cross-platform developers, providing actionable insights into developer tool disk usage with safe cleanup workflows.

---

## 1. Design Principles

### Core Philosophy
- **Developer-First**: Tools, not folders. Intelligence, not paths.
- **Safety-Aware**: Every action explains risk and rebuild cost
- **Actionable**: Clear paths from insight to cleanup
- **Opinionated**: Hide filesystem complexity, surface developer context

### Key Differentiators
- ❌ NOT a Finder replacement
- ❌ NOT a generic disk analyzer
- ✅ Developer tool artifact intelligence
- ✅ Safe, workflow-aware cleanup
- ✅ Simulator-centric management

---

## 2. Information Architecture

### Navigation Structure

```
Application Root
├── Sidebar (Tool Navigation)
│   ├── Scan System Button
│   ├── Tool List
│   │   ├── Xcode
│   │   ├── iOS Simulators
│   │   ├── Android SDK
│   │   ├── Node.js
│   │   ├── Docker
│   │   ├── Homebrew
│   │   ├── Python
│   │   └── Rust
│   └── Summary Stats
│
├── Content Area
│   ├── Dashboard (Default)
│   │   ├── Tool Cards Grid
│   │   └── Quick Actions
│   │
│   └── Tool Detail View
│       ├── Tool Header
│       ├── Safe Cleanup Actions
│       └── Artifact List
│
└── Detail Pane
    └── Artifact Detail View
        ├── What is this?
        ├── Size Information
        ├── Rebuild Cost
        ├── Safety Status
        └── Underlying Paths
```

---

## 3. Screen Specifications

### 3.1 Sidebar - Tool Navigation

**Purpose**: Primary navigation by developer tool
**Width**: 250-320px
**Background**: System sidebar background

#### Components

1. **Header Section**
   - Title: "Developer Tools" (SF Pro, 17pt, Bold)
   - Scan Button: Prominent, full-width

2. **Tool List Item**
   ```
   Layout: HStack
   ├── Icon (32x32, rounded 6pt)
   ├── VStack
   │   ├── Tool Name (Body)
   │   └── Size + Safe Count (Caption2, Secondary)
   └── Selection Indicator

   Padding: 8pt vertical, 12pt horizontal
   Background: Selection = Accent 15% opacity
   Corner Radius: 8pt
   ```

3. **Summary Footer**
   - Total Size (Caption, Bold)
   - Safe to Delete (Caption, Green)
   - Last Scan Time (Caption2, Tertiary)
   - Spacing: 8pt between items

#### States
- **Default**: Gray icon background, no selection
- **Selected**: Accent background, accent icon background
- **Hover**: Light gray background

---

### 3.2 Dashboard View

**Purpose**: Overview of all tool footprints
**Layout**: Scrollable grid

#### Header
```
Title: "Developer Disk Usage" (Large Title, Bold)
Subtitle: "Found X tool(s) using Y GB" (Title3, Secondary)
Padding: 24pt top/bottom, 16pt horizontal
```

#### Tool Cards Grid
```
Layout: LazyVGrid
Columns: Adaptive(min: 300, max: 400)
Spacing: 16pt
Padding: 16pt horizontal
```

#### Tool Card Component
```
Size: Min 300pt width, adaptive
Background: Control background
Border: 2pt accent (when selected)
Corner Radius: 12pt
Padding: 16pt

Structure:
├── Header HStack
│   ├── Icon (50x50, accent background, radius 10pt)
│   └── VStack
│       ├── Tool Name (Title3, Bold)
│       └── Artifact Count (Caption, Secondary)
│
├── Stats VStack (8pt padding vertical)
│   ├── Total Size Row
│   └── Safe to Delete Row (if > 0)
│
├── Divider
│
└── Actions HStack (12pt spacing)
    ├── View Details (Bordered)
    └── Clean Safe (Prominent, Green) [if applicable]
```

---

### 3.3 Tool Detail View

**Purpose**: Show all artifacts for a specific tool
**Layout**: Scrollable vertical stack

#### Tool Header
```
Layout: HStack (80pt icon, title, stats)
Padding: 16pt
Background: None

├── Icon (80x80, accent bg, radius 16pt)
├── VStack
│   ├── Tool Name (Large Title, Bold)
│   └── Stats HStack
│       ├── Size Badge
│       └── Artifact Count Badge
└── Spacer
```

#### Quick Actions Section
```
Layout: HStack (12pt spacing)
Padding: 16pt

├── Safe to Delete Card
│   ├── Label: "Safe to Delete" (Caption, Secondary)
│   ├── Amount (Title2, Bold, Green)
│   └── Background: Green 10% opacity
│
└── Clean Button (Prominent, Green)
    └── Label: "Clean Safe Artifacts"
```

#### Artifacts List
```
Layout: VStack (12pt spacing)
Padding: 16pt horizontal

For each artifact:
└── ArtifactCard Component
```

---

### 3.4 Artifact Card Component

**Purpose**: Display single artifact with actions
**Size**: Full width, adaptive height
**Background**: Control background
**Corner Radius**: 12pt
**Padding**: 16pt

#### Structure
```
VStack (12pt spacing)
│
├── Header HStack
│   ├── VStack
│   │   ├── Type (Headline)
│   │   └── Last Used (Caption, Secondary)
│   └── Risk Badge (Capsule)
│
├── Description (Body, Secondary, 3 lines)
│
├── HStack
│   ├── Size Badge
│   └── Rebuild Cost (Caption, Secondary)
│
├── Divider
│
└── Actions HStack (12pt spacing)
    ├── Details Button (Bordered)
    └── Delete Button (Prominent, Risk Color) [if safe]
```

#### Risk Badge Variants
```
Safe:
- Icon: checkmark.shield.fill
- Color: Green
- Text: "Safe"

Slow Rebuild:
- Icon: clock.arrow.circlepath
- Color: Orange
- Text: "Slow Rebuild"

Unsafe:
- Icon: exclamationmark.triangle.fill
- Color: Red
- Text: "Unsafe"

Unknown:
- Icon: questionmark.circle.fill
- Color: Gray
- Text: "Unknown"

Style: Capsule, 8pt horizontal padding, 4pt vertical
```

---

### 3.5 Artifact Detail View

**Purpose**: Detailed information about a single artifact
**Layout**: Scrollable vertical sections

#### Header
```
HStack
├── Icon (50x50)
├── VStack
│   ├── Artifact Type (Title, Bold)
│   └── Tool Name (Subheadline, Secondary)
└── Risk Badge (Large)
```

#### Detail Sections
Each section follows this pattern:
```
VStack (20pt spacing)
│
└── DetailSection
    ├── Label + Icon (Headline)
    └── Content (Body)
        └── Background: Control background
        └── Padding: 16pt
        └── Radius: 8pt
```

**Sections:**
1. What is this? (info.circle)
2. Size (externaldrive)
3. Rebuild Cost (clock)
4. Last Used (calendar) [if available]
5. Safety Status (shield)
6. Locations (folder) - with "Show in Finder" buttons

---

## 4. Component Library

### Buttons

#### Primary Actions
```
Style: .borderedProminent
Height: 32pt
Corner Radius: 6pt
Font: System (13pt)
Padding: 8pt horizontal

Variants:
- Default: Accent color
- Safe Action: Green tint
- Destructive: Red tint
```

#### Secondary Actions
```
Style: .bordered
Height: 32pt
Corner Radius: 6pt
Font: System (13pt)
Padding: 8pt horizontal
```

#### Icon Buttons
```
Style: .borderless
Size: 24x24pt
Icon: SF Symbol (13pt)
```

### Badges

#### Tool Icon Badge
```
Size: Varies (32x32, 50x50, 80x80)
Background: Accent or tool color
Foreground: White
Corner Radius: 6-16pt (scales with size)
```

#### Risk Badge
```
Shape: Capsule
Padding: 8pt horizontal, 4pt vertical
Font: Caption, Bold
Background: Risk color 20% opacity
Foreground: Risk color
```

#### Stat Badge
```
Layout: Label (icon + text)
Font: Subheadline / Caption
Foreground: Secondary
```

### Progress Indicators

#### Linear Progress
```
Style: .linear
Height: 4pt
Accent color
Corner Radius: 2pt

With label:
├── VStack
│   ├── Progress text (Caption)
│   ├── Current item (Caption2, Secondary)
│   └── ProgressView
```

---

## 5. Typography Scale

### System Font: SF Pro

```
Large Title:  34pt, Bold     - Screen titles
Title:        28pt, Bold     - Section headers
Title2:       22pt, Bold     - Stats, important values
Title3:       20pt, Regular  - Subtitles
Headline:     17pt, Semibold - Card titles
Body:         17pt, Regular  - Primary text
Callout:      16pt, Regular  - Secondary text
Subheadline:  15pt, Regular  - Metadata
Footnote:     13pt, Regular  - Help text
Caption:      12pt, Regular  - Labels
Caption2:     11pt, Regular  - Tertiary info
```

---

## 6. Color Palette

### System Colors (macOS)
```
Primary:           System label color
Secondary:         System secondary label
Tertiary:          System tertiary label
Background:        System background
Control Background: System control background
Accent:            System accent (blue)
```

### Semantic Colors
```
Safe:         Green (#34C759)
Warning:      Orange (#FF9500)
Destructive:  Red (#FF3B30)
Info:         Blue (#007AFF)
Neutral:      Gray (#8E8E93)
```

### Color Usage
- **Safe Actions**: Green background 10-20% opacity, green foreground
- **Slow Rebuild**: Orange background 10-20% opacity, orange foreground
- **Unsafe/Destructive**: Red background 10-20% opacity, red foreground
- **Selection**: Accent 15% opacity background
- **Hover**: Secondary 8% opacity background

---

## 7. Spacing System

### Base Unit: 4pt

```
Micro:    4pt   - Internal component padding
Small:    8pt   - Component spacing
Medium:   12pt  - Section spacing
Large:    16pt  - Screen padding
XLarge:   24pt  - Major section breaks
XXLarge:  32pt  - Screen margins
```

### Component-Specific
```
Card Padding:        16pt
Card Corner Radius:  12pt
Badge Corner Radius: 6pt
Button Height:       32pt
Icon Sizes:          24, 32, 50, 80pt
```

---

## 8. Interaction Patterns

### Deletion Flow

1. **Single Artifact**
   ```
   User clicks "Delete" on artifact card
   → Confirmation dialog appears
   → Shows: Type, Size, Risk, Explanation
   → Actions: Delete (destructive) | Cancel
   → On confirm: Delete + refresh tool view
   → Show result alert
   ```

2. **Batch Delete (Clean Safe)**
   ```
   User clicks "Clean Safe Artifacts"
   → Confirmation dialog appears
   → Shows: Count, Total size to reclaim
   → Actions: Delete All (destructive) | Cancel
   → On confirm: Delete all + refresh
   → Show result alert with success/failure count
   ```

### Confirmation Dialog Format
```
Title: Action name
Message: Impact description
Actions:
- Destructive button (red)
- Cancel button (default)
```

---

## 9. Empty States

### No Scan Results
```
ContentUnavailableView
├── Icon: magnifyingglass
├── Title: "No Scan Results"
└── Description: "Click 'Scan System' in the sidebar..."
```

### No Artifacts Selected
```
ContentUnavailableView
├── Icon: square.stack.3d.up
├── Title: "Select an Artifact"
└── Description: "Choose an artifact from the list..."
```

### No Safe Deletions
```
ContentUnavailableView
├── Icon: checkmark.shield
├── Title: "No Safe Deletions Available"
└── Description: "All artifacts require manual review"
```

---

## 10. Animation & Transitions

### List Updates
- Duration: 0.3s
- Easing: Spring (response: 0.3, damping: 0.7)
- Type: Fade + slide

### Button States
- Duration: 0.15s
- Easing: Ease-in-out
- States: Default → Hover → Pressed

### Progress Updates
- Linear interpolation
- Update frequency: 60fps during scan
- Smooth value changes (no jumps)

---

## 11. Accessibility

### Contrast Ratios
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum
- Interactive elements: 3:1 minimum

### Dynamic Type
- All text scales with system preferences
- Layouts adapt to larger text sizes
- Minimum touch target: 44x44pt

### VoiceOver
- All interactive elements labeled
- Risk badges announced with context
- Progress updates announced
- Confirmation dialogs fully accessible

---

## 12. Error States

### Scan Errors
```
Alert
├── Title: "Scan Error"
├── Message: Tool-specific error description
└── Action: "OK"
```

### Deletion Errors
```
Alert
├── Title: "Deletion Result"
├── Message: Success count + error details
└── Action: "OK"
```

### Permission Errors
```
Alert
├── Title: "Permission Required"
├── Message: Explanation of required access
└── Actions: "Open Settings" | "Cancel"
```

---

## 13. Implementation Notes

### SwiftUI Components Used
- `NavigationSplitView` (3-column layout)
- `LazyVGrid` (Dashboard cards)
- `ScrollView` + `VStack` (Detail views)
- `ContentUnavailableView` (Empty states)
- `.confirmationDialog` (Deletions)
- `.alert` (Results)

### Performance Considerations
- Lazy loading for large artifact lists
- Background scanning with progress
- Cached scan results
- Throttled UI updates (progress max 60fps)

### Platform Integration
- macOS 14.0+ minimum
- Native system colors
- SF Symbols for icons
- File system access via security-scoped bookmarks

---

## 14. Future Enhancements

### Planned Features
1. **Simulator Manager Tab**
   - iOS runtime management
   - Android AVD management
   - Device-specific cleanup

2. **Search & Filter**
   - Filter by risk level
   - Search artifacts by name
   - Sort by size/date

3. **Scheduled Scans**
   - Weekly automatic scans
   - Notifications for cleanup opportunities

4. **Export Reports**
   - CSV export
   - Cleanup history
   - Disk usage trends

---

## 15. Figma Export Checklist

When translating to Figma:

- [ ] Create component variants for all states
- [ ] Define auto-layout rules for responsive sizing
- [ ] Establish color and typography styles
- [ ] Create reusable components:
  - [ ] ToolCard
  - [ ] ArtifactCard
  - [ ] RiskBadge
  - [ ] DetailSection
  - [ ] ToolSidebarRow
- [ ] Document spacing system (4pt grid)
- [ ] Create frames for each screen
- [ ] Add interaction prototypes for key flows
- [ ] Export icon set (SF Symbols reference)
- [ ] Define component properties:
  - [ ] Tool type (enum)
  - [ ] Risk level (enum)
  - [ ] Selection state (boolean)
  - [ ] Has safe artifacts (boolean)

---

## 16. Success Metrics

The design succeeds when users can answer:

✅ **Why is my disk full?**
→ Dashboard shows tool footprints immediately

✅ **What is safe to delete?**
→ Every artifact has safety badge + explanation

✅ **How much space can I reclaim?**
→ "Safe to Delete" shown at sidebar, dashboard, and tool level

✅ **Which tools are the problem?**
→ Tools sorted by size, clear visual hierarchy

✅ **What happens if I delete this?**
→ Rebuild cost + risk explanation on every artifact

---

## Appendix A: Key Architectural Decisions

### Why Tool-Centric, Not Folder-Centric?

**Before**: Users navigate `~/Library/Developer/Xcode/DerivedData/ProjectName-xyz`
**After**: Users see "Xcode DerivedData for ProjectName (2.3 GB, safe to delete, 5-min rebuild)"

Developers don't think in filesystem paths. They think:
- "My Xcode is slow"
- "I need to clean simulators"
- "Docker is eating my disk"

The filesystem is an implementation detail.

### Why "Safe to Delete" vs "Deletable"?

"Deletable" implies permission. "Safe to delete" implies risk assessment.

Every artifact includes:
- Safety level (safe | slow rebuild | unsafe)
- Rebuild cost estimate
- Explanation of what happens

This transforms anxiety ("Will this break things?") into confidence ("5-minute rebuild, safe to proceed").

### Why No Simulator View in v1?

The dedicated Simulator view (iOS/Android tabs, runtime management) is planned but not implemented in this version. Current simulator detection works through the artifact system. The full simulator management UI requires:
- Runtime version grouping
- Device-level actions
- Boot state awareness
- Batch runtime deletion

These are complex enough to warrant their own feature milestone.

---

## Appendix B: Tool Detection Reference

### Supported Tools

| Tool | Artifact Types | Detection Method |
|------|---------------|------------------|
| **Xcode** | DerivedData, Archives, DeviceSupport, DeviceLogs | Directory enumeration at known paths |
| **iOS Simulators** | Devices, Runtimes, Caches | `xcrun simctl` JSON parsing |
| **Android SDK** | SDK components, AVDs | Directory scan + manifest parsing |
| **Node.js** | npm cache, Yarn cache | Known cache paths |
| **Docker** | Images, containers, volumes | Docker data directory |
| **Homebrew** | Download cache | Homebrew cache path |
| **Python** | pip cache, Poetry cache | Known cache paths |
| **Rust** | Cargo registry, Cargo git | Known Cargo paths |

### Detection Reliability
- **High Confidence**: Xcode, iOS Simulators (uses system APIs)
- **Medium Confidence**: Android, Docker (directory-based)
- **Low Confidence**: Cache-only tools (no version detection)

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-02-06 | Complete redesign from folder-based to artifact-based |
| 1.0 | 2026-02-04 | Initial folder-based design |

---

**End of Specification**
