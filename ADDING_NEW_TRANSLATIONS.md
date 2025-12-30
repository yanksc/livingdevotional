# Adding New Translations to Living Devotional

## Current Architecture

The app currently supports translations through:
1. **Language enum** - Defines available translations
2. **BibleVerse model** - Stores text for each translation
3. **BibleService** - Loads files from `BibleData.bundle/{translation}/`
4. **SettingsView** - Automatically shows all Language cases

## Steps to Add a New Translation

### Example: Adding "KJV" (King James Version)

### Step 1: Add Translation Data Files

1. **Download or prepare translation data** in the same JSON format:
   ```json
   [
     {"verse": 1, "text": "In the beginning..."},
     {"verse": 2, "text": "And the earth..."}
   ]
   ```

2. **Add to BibleData.bundle**:
   ```
   BibleData.bundle/
   ├── bsb/
   ├── cuv/
   └── kjv/          ← New folder
       ├── GEN/
       │   ├── 1.json
       │   └── ...
       └── ...
   ```

### Step 2: Update Language Enum

**File**: `livingdevotional/Models/Models.swift`

```swift
enum Language: String, Codable, CaseIterable, Identifiable {
    case bsb = "bsb"
    case cuv = "cuv"
    case cu1 = "cu1"
    case kjv = "kjv"      // ← Add new case
    case none = "none"
    
    var displayName: String {
        switch self {
        case .bsb: return "English (BSB)"
        case .cuv: return "中文和合本 (CUV)"
        case .cu1: return "新标点和合本"
        case .kjv: return "English (KJV)"  // ← Add display name
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        case .bsb: return "Berean Standard Bible"
        case .cuv: return "Chinese Union Version"
        case .cu1: return "Chinese Union Version with New Punctuation"
        case .kjv: return "King James Version"  // ← Add description
        case .none: return "僅顯示主要語言"
        }
    }
}
```

### Step 3: Update BibleVerse Model

**File**: `livingdevotional/Models/Models.swift`

Add a new property for the translation:

```swift
struct BibleVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textKjv: String      // ← Add new property
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textKjv = "text_kjv"  // ← Add coding key
    }
    
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .kjv: return textKjv  // ← Add case
        case .none: return ""
        }
    }
}
```

### Step 4: Update BibleService

**File**: `livingdevotional/Data/BibleService.swift`

Add the translation folder mapping:

```swift
let translationFolder: String
switch translation {
case .bsb:
    translationFolder = "bsb"
case .cuv:
    translationFolder = "cuv"
case .cu1:
    translationFolder = "cu1"
case .kjv:
    translationFolder = "kjv"  // ← Add mapping
case .none:
    throw BibleServiceError.fileNotFound(...)
}
```

Update the verse creation to include the new translation:

```swift
return verses.map { verseJson in
    BibleVerse(
        id: "\(bookId)-\(chapter)-\(verseJson.verse)",
        book: book,
        chapter: chapter,
        verseNumber: verseJson.verse,
        textBsb: translation == .bsb ? verseJson.text : "",
        textCuv: translation == .cuv ? verseJson.text : "",
        textCu1: translation == .cu1 ? verseJson.text : "",
        textKjv: translation == .kjv ? verseJson.text : "",  // ← Add
        testament: BibleData.book(named: book)?.testament.rawValue ?? ""
    )
}
```

Also update the dual-language merge logic in `loadVersesDualLanguage()`.

### Step 5: Update DailyVerse and SearchResult (if used)

If you use `DailyVerse` or `SearchResult` models, add the new translation property there too.

## That's It!

After these changes:
- ✅ New translation appears in Settings picker automatically (Language.allCases)
- ✅ Users can select it as primary or secondary language
- ✅ Verses load and display correctly
- ✅ Dual-language display works with the new translation

## Limitations of Current Architecture

**Current approach requires code changes** for each new translation because:
- Language enum is hardcoded
- BibleVerse has individual properties per translation
- BibleService has switch statements

## Future Improvement: Dynamic Translation Support

If you plan to add many translations, consider refactoring to:

```swift
// More flexible approach
struct BibleVerse {
    let translations: [String: String]  // ["bsb": "...", "cuv": "..."]
    
    func text(for language: Language) -> String {
        return translations[language.rawValue] ?? ""
    }
}
```

This would allow adding translations without code changes, but requires:
- Refactoring the data model
- Updating JSON loading logic
- More complex dual-language merging

## Quick Reference Checklist

- [ ] Add translation files to `BibleData.bundle/{translation}/`
- [ ] Add case to `Language` enum
- [ ] Add display name and description
- [ ] Add property to `BibleVerse` struct
- [ ] Add CodingKey for the property
- [ ] Update `text(for:)` method
- [ ] Add folder mapping in `BibleService`
- [ ] Update verse creation logic
- [ ] Update dual-language merge logic
- [ ] Test loading and display

## Example: Complete KJV Addition

See the code changes above - follow the same pattern for any new translation. The Settings UI will automatically pick it up since it uses `Language.allCases`.

