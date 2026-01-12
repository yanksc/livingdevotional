# Project Structure Guide

## Important: File Organization Rules

**CRITICAL**: This project uses a **single source directory structure**. All Swift source files must be placed in the `livingdevotional/` subdirectory, NOT in the root directory.

## Correct File Locations

### ✅ CORRECT - Use These Directories:
- `livingdevotional/Views/` - All view files
- `livingdevotional/Models/` - All model files
- `livingdevotional/Data/` - All data store/service files
- `livingdevotional/ViewModels/` - All view model files
- `livingdevotional/Features/` - Feature-specific views
- `livingdevotional/Services/` - Service implementations
- `livingdevotional/Utils/` - Utility files
- `livingdevotional/Core/` - Core functionality (Router, etc.)
- `livingdevotional/livingdevotionalApp.swift` - Main app file
- `livingdevotional/ContentView.swift` - Root content view

### ❌ INCORRECT - Do NOT Create Files Here:
- `Views/` (root level)
- `Models/` (root level)
- `Data/` (root level)
- `ViewModels/` (root level)
- `ContentView.swift` (root level)
- `livingdevotionalApp.swift` (root level)

## Why This Structure?

1. **Xcode 16 Compatibility**: Xcode 16 automatically syncs files in the target directory. Files outside the main source directory may not be properly included in the build.

2. **Single Source of Truth**: Having duplicate files in different locations causes:
   - Confusion about which file is actually being used
   - Build errors and runtime issues
   - Maintenance nightmares

3. **Project Configuration**: The Xcode project is configured to use `livingdevotional/` as the main source directory.

## Before Creating New Files

1. **Check if the file already exists** in `livingdevotional/` directory
2. **Always create files** in the `livingdevotional/` subdirectory
3. **Never create duplicates** in the root directory

## File Naming Conventions

- Views: `[Name]View.swift` (e.g., `ReadingView.swift`, `SettingsView.swift`)
- Models: `[Name].swift` (e.g., `SavedVerse.swift`, `BibleData.swift`)
- ViewModels: `[Name]ViewModel.swift` (e.g., `ReadingViewModel.swift`)
- Services: `[Name]Service.swift` or `[Name]Store.swift`
- Utilities: `[Name].swift` (e.g., `AppTheme.swift`)

## How to Verify Correct Location

Before committing changes, verify:
1. File is in `livingdevotional/[Category]/` directory
2. No duplicate exists in root-level directories
3. File appears in Xcode project navigator under the correct group

## Common Mistakes to Avoid

1. ❌ Creating `Views/ReadingView.swift` when `livingdevotional/Views/ReadingView.swift` already exists
2. ❌ Copying files to root directory "just in case"
3. ❌ Creating files in both locations "to be safe"
4. ❌ Assuming root-level files will be used by Xcode

## If You Find Duplicates

1. Identify which version is actually being used (check imports, Xcode project)
2. Merge any unique changes from the duplicate
3. Delete the duplicate file
4. Verify the app still builds and runs correctly

## Directory Structure Overview

```
livingdevotional/
├── livingdevotionalApp.swift      # Main app entry point
├── ContentView.swift               # Root content view
├── Models/                        # Data models
│   ├── BibleData.swift
│   ├── Models.swift
│   └── SavedVerse.swift
├── Views/                         # UI Views
│   ├── ReadingView.swift
│   ├── SettingsView.swift
│   ├── MainTabView.swift
│   ├── SaveVerseSheet.swift
│   └── SavedNotesListView.swift
├── ViewModels/                    # View logic
│   ├── BibleViewModel.swift
│   └── ReadingViewModel.swift
├── Data/                          # Data stores
│   ├── BibleService.swift
│   ├── NoteStore.swift
│   ├── ProgressStore.swift
│   └── SettingsStore.swift
├── Features/                      # Feature modules
│   ├── Home/
│   └── Auth/
├── Services/                      # Service implementations
├── Utils/                         # Utilities
└── Core/                          # Core functionality
```

## Remember

**When in doubt, check the `livingdevotional/` directory first. If a file exists there, edit that one. Never create a duplicate in the root directory.**


