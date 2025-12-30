# How to Add New Translations

## Overview

The app architecture supports adding new translations, but requires code changes in a few places. Here's the complete process:

## Current Architecture

- **Language Enum**: Defines available translations (bsb, cuv, cu1, none)
- **BibleVerse Model**: Has individual properties for each translation (textBsb, textCuv, textCu1)
- **BibleService**: Maps Language enum to folder names and loads JSON files
- **SettingsView**: Automatically shows all Language cases in pickers

## Step-by-Step: Adding a New Translation

### Example: Adding KJV (King James Version)

#### 1. Add Translation Data Files

Place translation files in the same structure:
```
BibleData.bundle/
└── kjv/              ← New translation folder
    ├── GEN/
    │   ├── 1.json
    │   ├── 2.json
    │   └── ...
    ├── EXO/
    └── ...
```

**JSON Format** (same as existing):
```json
[
  {"verse": 1, "text": "In the beginning God created..."},
  {"verse": 2, "text": "And the earth was without form..."}
]
```

#### 2. Update Language Enum

**File**: `livingdevotional/Models/Models.swift`

```swift
enum Language: String, Codable, CaseIterable, Identifiable {
    case bsb = "bsb"
    case cuv = "cuv"
    case cu1 = "cu1"
    case kjv = "kjv"      // ← ADD THIS
    case none = "none"
    
    var displayName: String {
        switch self {
        // ... existing cases ...
        case .kjv: return "English (KJV)"  // ← ADD THIS
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        // ... existing cases ...
        case .kjv: return "King James Version"  // ← ADD THIS
        case .none: return "僅顯示主要語言"
        }
    }
}
```

#### 3. Update BibleVerse Model

**File**: `livingdevotional/Models/Models.swift`

Add property and update methods:

```swift
struct BibleVerse: Codable, Identifiable, Hashable {
    // ... existing properties ...
    let textKjv: String      // ← ADD THIS
    
    enum CodingKeys: String, CodingKey {
        // ... existing keys ...
        case textKjv = "text_kjv"  // ← ADD THIS
    }
    
    func text(for language: Language) -> String {
        switch language {
        // ... existing cases ...
        case .kjv: return textKjv  // ← ADD THIS
        case .none: return ""
        }
    }
}
```

#### 4. Update BibleService

**File**: `livingdevotional/Data/BibleService.swift`

**A. Add folder mapping:**
```swift
let translationFolder: String
switch translation {
case .bsb: translationFolder = "bsb"
case .cuv: translationFolder = "cuv"
case .cu1: translationFolder = "cu1"
case .kjv: translationFolder = "kjv"  // ← ADD THIS
case .none: throw BibleServiceError.fileNotFound(...)
}
```

**B. Update verse creation (2 places):**
```swift
// In loadVerses() method
BibleVerse(
    // ... existing properties ...
    textKjv: translation == .kjv ? verseJson.text : "",  // ← ADD THIS
    // ...
)

// In loadVersesDualLanguage() merge logic
textKjv: primaryVerse.textKjv.isEmpty ? secondaryVerse.textKjv : primaryVerse.textKjv,  // ← ADD THIS
```

#### 5. Update Other Models (if used)

If you use `DailyVerse` or `SearchResult`, add the property there too.

## That's It!

After these changes:
- ✅ New translation appears automatically in Settings (Language.allCases)
- ✅ Users can select it as primary/secondary language
- ✅ Verses load and display correctly
- ✅ Dual-language display works

## Quick Checklist

- [ ] Add translation folder to `BibleData.bundle/{translation}/`
- [ ] Add case to `Language` enum
- [ ] Add `displayName` and `description`
- [ ] Add property to `BibleVerse` (e.g., `textKjv`)
- [ ] Add CodingKey
- [ ] Update `text(for:)` method
- [ ] Add folder mapping in `BibleService`
- [ ] Update verse creation (2 places in BibleService)
- [ ] Update dual-language merge logic
- [ ] Test!

## Architecture Limitation

**Current approach requires code changes** because:
- Language enum is hardcoded
- BibleVerse has individual properties per translation
- BibleService uses switch statements

**This is fine for 3-5 translations** but becomes tedious for many.

## Future: Dynamic Translation Support

If you plan to add 10+ translations, consider refactoring to a dictionary-based approach:

```swift
struct BibleVerse {
    let translations: [String: String]  // ["bsb": "...", "cuv": "...", "kjv": "..."]
    
    func text(for language: Language) -> String {
        return translations[language.rawValue] ?? ""
    }
}
```

This would allow adding translations without code changes, but requires:
- Refactoring the data model
- Updating JSON loading/merging logic
- Handling missing translations gracefully

## Summary

**For now**: Follow the 5-step process above. It's straightforward and works well for a reasonable number of translations.

**For future**: If you need many translations, we can refactor to a more flexible architecture.

