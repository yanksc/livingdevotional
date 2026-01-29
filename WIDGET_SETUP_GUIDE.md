# Living Path Widget Setup Guide

This guide explains how to set up the iOS widgets for Living Path in Xcode 16.

## Overview

The widget implementation includes:
- **Verse of the Day Widget** - Shows daily verse (Small, Medium, Large, Lock Screen Rectangular)
- **Streak Widget** - Shows streak count (Lock Screen Circular)
- **Reading Plan Widget** - Shows plan progress (Lock Screen Inline)

## Step 1: Create Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Select **Widget Extension** under iOS
3. Configure:
   - **Product Name**: `LivingPathWidget`
   - **Team**: Your development team
   - **Include Configuration App Intent**: **Uncheck** this
   - **Include Live Activity**: **Uncheck** this
4. Click **Finish**
5. When prompted to activate the scheme, click **Activate**

## Step 2: Add App Group Capability

### Main App Target

1. Select the **livingdevotional** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** button and add: `group.com.ykh.livingdevotional`

### Widget Extension Target

1. Select the **LivingPathWidgetExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Select the same group: `group.com.ykh.livingdevotional`

## Step 3: Add URL Scheme

1. Select the **livingdevotional** target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL Type:
   - **Identifier**: `com.ykh.livingdevotional.widget`
   - **URL Schemes**: `livingpath`
   - **Role**: Editor

## Step 4: Replace Widget Extension Files

Delete the auto-generated files in the LivingPathWidget folder and ensure these files exist:

```
LivingPathWidget/
├── LivingPathWidgetBundle.swift
├── VerseOfTheDayWidget.swift
├── StreakWidget.swift
├── ReadingPlanWidget.swift
├── SharedDataManager.swift
├── WidgetColors.swift
└── WidgetLocalization.swift
```

## Step 5: Configure Build Settings

### Widget Extension Target

1. Select **LivingPathWidgetExtension** target
2. Go to **Build Settings**
3. Set **iOS Deployment Target** to match main app (iOS 17.0 or higher)

## Step 6: Verify File References

In Xcode 16, files should auto-sync. Verify that all widget files appear under the LivingPathWidget group in the project navigator.

## Widget Sizes Supported

| Widget | Families |
|--------|----------|
| Verse of the Day | `systemSmall`, `systemMedium`, `systemLarge`, `accessoryRectangular` |
| Streak | `accessoryCircular` |
| Reading Plan | `accessoryInline` |

## Deep Links

Widgets use the following URL scheme for navigation:

| URL | Action |
|-----|--------|
| `livingpath://widget/verse` | Opens verse of the day full screen |
| `livingpath://widget/home` | Opens home tab |
| `livingpath://widget/plan/{planId}` | Opens specific reading plan |

## Testing Widgets

### In Simulator

1. Build and run the main app first
2. Go to Home Screen
3. Long press to enter jiggle mode
4. Tap **+** to add widgets
5. Search for "Living Path"
6. Add desired widget size

### On Device

1. Install the app on your device
2. Add widget from Home Screen
3. Verify data syncs properly when you:
   - Open the app
   - Record reading progress
   - Complete a prayer
   - Start/progress a reading plan

## Troubleshooting

### Widget Shows Empty/Default Data

1. Ensure App Group is configured in both targets
2. Open the main app to trigger data sync
3. Wait for widget timeline refresh (up to 1 hour)

### Widget Doesn't Appear in Widget Gallery

1. Build and run the widget extension scheme
2. Restart the device/simulator
3. Check that the widget extension target is properly signed

### Deep Links Not Working

1. Verify URL Scheme is configured in main app Info.plist
2. Check that `livingpath` scheme matches in both Router.swift and widget URLs

## Data Flow

```
┌─────────────────────┐
│     Main App        │
│  ┌───────────────┐  │
│  │ CheckInStore  │──┼──┐
│  │ ProgressStore │  │  │
│  │ DailyVerse    │  │  │  Writes to
│  │ ReadingPlan   │  │  │
│  └───────────────┘  │  │
└─────────────────────┘  │
                         ▼
            ┌────────────────────┐
            │  App Group         │
            │  UserDefaults      │
            │  (WidgetData)      │
            └────────────────────┘
                         │
                         │  Reads from
                         ▼
┌─────────────────────┐
│   Widget Extension  │
│  ┌───────────────┐  │
│  │ TimelineProvider│ │
│  │ Widget Views  │  │
│  └───────────────┘  │
└─────────────────────┘
```

## Color Palette (Serene Sands)

The widgets use the same color palette as the main app:

| Color | Hex | Usage |
|-------|-----|-------|
| Warm Sand | #D4A574 | Primary/Accent |
| Soft Beige | #E8D5B7 | Secondary |
| Sage Green | #A8C5B8 | Accent/Streak |
| Warm Cream | #FAF7F2 | Background |

## Localization

Widgets support the same languages as the main app:
- English (en)
- Traditional Chinese (zh-Hant/cuv)
- Simplified Chinese (zh-Hans/cu1)
- Spanish (es/spa_r09)
- Portuguese (pt/por_blj)

The widget automatically uses the user's primary Bible translation language for localized strings.
