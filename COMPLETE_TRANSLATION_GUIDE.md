# Complete Guide: Adding a New Bible Translation

This guide documents ALL files that must be updated when adding a new Bible translation. Follow this checklist to avoid compilation errors.

## Overview

When adding a new translation (e.g., WEB - World English Bible), you must:
1. Add the data files to the bundle
2. Update ALL Swift files that reference translation text fields

## Step-by-Step Checklist

### Step 1: Prepare Data Files

1. **Convert data to app format** (if needed):
   - Create a conversion script in `scripts/` (e.g., `convert_web.py`)
   - Use existing logic from `scripts/download_bible_data.py`
   - Output format must be: `[{"verse": 1, "text": "..."}, ...]`

2. **Add to BibleData.bundle**:
   ```
   livingdevotional/Resources/BibleData.bundle/{translation_code}/
   ├── GEN/
   │   ├── 1.json
   │   └── ...
   ├── EXO/
   └── ... (66 book folders)
   ```

### Step 2: Update Models.swift

**File**: `livingdevotional/Models/Models.swift`

1. **Add to `Language` enum** (around line 56):
   ```swift
   case web = "web"  // Add new case
   ```

2. **Update `displayName`** in Language enum:
   ```swift
   case .web: return "English (WEB)"
   ```

3. **Update `description`** in Language enum:
   ```swift
   case .web: return "World English Bible"
   ```

4. **Add property to `BibleVerse` struct**:
   ```swift
   let textWeb: String  // Add after textKjv
   ```

5. **Add CodingKey to `BibleVerse`**:
   ```swift
   case textWeb = "text_web"
   ```

6. **Update `text(for:)` in `BibleVerse`**:
   ```swift
   case .web: return textWeb
   ```

7. **Add property to `DailyVerse` struct**:
   ```swift
   let textWeb: String  // Add after textKjv
   ```

8. **Add CodingKey to `DailyVerse`**:
   ```swift
   case textWeb = "text_web"
   ```

9. **Update `text(for:)` in `DailyVerse`**:
   ```swift
   case .web: return textWeb
   ```

### Step 3: Update BibleData.swift

**File**: `livingdevotional/Models/BibleData.swift`

Update legacy helper methods to include new translation in English group:
- `localizedBookName(_:language:)` - add `.web` to English cases
- `localizedTestamentName(_:language:)` - add `.web` to English cases  
- `localizedChapterText(language:)` - add `.web` to English cases

Example:
```swift
case .bsb, .kjv, .web, .none:  // Add .web
    return bookName
```

### Step 4: Update BibleService.swift

**File**: `livingdevotional/Data/BibleService.swift`

1. **Add folder mapping** in `loadVerses()`:
   ```swift
   case .web:
       translationFolder = "web"
   ```

2. **Update BibleVerse initialization** (2 places - around lines 92 and 115):
   ```swift
   textWeb: translation == .web ? verseJson.text : "",
   ```

3. **Update dual-language merge** in `loadVersesDualLanguage()`:
   ```swift
   textWeb: primaryVerse.textWeb.isEmpty ? secondaryVerse.textWeb : primaryVerse.textWeb,
   ```

### Step 5: Update DailyVerseService.swift

**File**: `livingdevotional/Services/DailyVerseService.swift`

1. **Add variable**:
   ```swift
   var textWeb = ""
   ```

2. **Add loading logic**:
   ```swift
   // Load WEB
   if let webVerses = try? await bibleService.loadVerses(..., translation: .web),
      let verse = webVerses.first(where: { $0.verseNumber == selection.verse }) {
       textWeb = verse.textWeb
   }
   ```

3. **Update DailyVerse initialization**:
   ```swift
   textWeb: textWeb,
   ```

4. **Update empty check**:
   ```swift
   if textBsb.isEmpty && ... && textWeb.isEmpty && ...
   ```

### Step 6: Update AIService.swift

**File**: `livingdevotional/Services/AI/AIService.swift`

Update `DailyVerse` initialization in `findVerseForPrayer()` (around line 1419):
```swift
textWeb: verse.textWeb,
```

### Step 7: Update View Files with BibleVerse/DailyVerse Initializations

Search for all `BibleVerse(` and `DailyVerse(` initializations and add `textWeb`:

**Files to check**:
- `livingdevotional/Views/SaveVerseSheet.swift` - Preview provider
- `livingdevotional/Views/ReadingView.swift` - Temporary verse creation
- `livingdevotional/Views/PrayerFlowView.swift` - DailyVerse creation

### Step 8: Verify No ViewBuilder Issues

If you see "Type '()' cannot conform to 'View'" errors:
- Check for `let` statements inside SwiftUI `ViewBuilder` closures (like Button labels)
- Extract logic to helper functions that return `String` or other types

## Quick Verification Commands

After making changes, run these to find any missed files:

```bash
# Find BibleVerse initializations missing textWeb
grep -rn "textKjv:" livingdevotional --include="*.swift" | grep -v "textWeb"

# Verify all initializations have textWeb after textKjv
grep -A1 "textKjv:" livingdevotional --include="*.swift" -r | grep "textWeb:"
```

## Files Modified Summary (WEB Example)

| File | Changes |
|------|---------|
| `scripts/convert_web.py` | New - conversion script |
| `Models/Models.swift` | Language enum, BibleVerse, DailyVerse |
| `Models/BibleData.swift` | Legacy localization helpers |
| `Data/BibleService.swift` | Folder mapping, verse loading |
| `Services/DailyVerseService.swift` | Daily verse loading |
| `Services/AI/AIService.swift` | findVerseForPrayer() |
| `Views/SaveVerseSheet.swift` | Preview BibleVerse |
| `Views/ReadingView.swift` | Temporary verse creation |
| `Views/PrayerFlowView.swift` | DailyVerse creation |
| `Features/Home/HomeView.swift` | ViewBuilder fix (if needed) |

## Total: 10+ files need updates for each new translation

---

*Created after adding WEB (World English Bible) translation - January 2026*
