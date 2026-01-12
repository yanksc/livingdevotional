# How to Add a New Bible Translation

## Step 1: Copy Translation Folder

Copy your downloaded translation folder directly into `BibleData.bundle/`:

```bash
# Example: Adding ESV translation
cp -r /path/to/downloaded/esv livingdevotional/Resources/BibleData.bundle/
```

**Required structure:**
```
BibleData.bundle/
  └── {translation_code}/     # e.g., "esv", "kjv", "niv"
      └── {bookId}/           # e.g., "GEN", "MAT", "REV"
          └── {chapter}.json  # e.g., "1.json", "2.json"
```

**JSON format** (each chapter file should be):
```json
[
  {
    "verse": 1,
    "text": "Verse text here..."
  },
  {
    "verse": 2,
    "text": "Verse text here..."
  }
]
```

## Step 2: Update Code

The current implementation requires code changes in 3 files:

### 2.1 Update `Language` enum (`livingdevotional/Models/Models.swift`)

Add your new translation case:
```swift
enum Language: String, Codable, CaseIterable, Identifiable {
    case bsb = "bsb"
    case cuv = "cuv"
    case cu1 = "cu1"
    case esv = "esv"  // ← Add your new translation
    case none = "none"
    
    var displayName: String {
        switch self {
        case .bsb: return "English (BSB)"
        case .cuv: return "中文和合本 (CUV)"
        case .cu1: return "新标点和合本"
        case .esv: return "English Standard Version"  // ← Add display name
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        case .bsb: return "Berean Standard Bible"
        case .cuv: return "Chinese Union Version"
        case .cu1: return "Chinese Union Version with New Punctuation"
        case .esv: return "English Standard Version"  // ← Add description
        case .none: return "僅顯示主要語言"
        }
    }
}
```

### 2.2 Update `BibleVerse` struct (`livingdevotional/Models/Models.swift`)

Add a new text field:
```swift
struct BibleVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textEsv: String  // ← Add new field
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textEsv = "text_esv"  // ← Add coding key
    }
    
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .esv: return textEsv  // ← Add case
        case .none: return ""
        }
    }
}
```

### 2.3 Update `BibleService` (`livingdevotional/Data/BibleService.swift`)

Add your translation to the switch statement:
```swift
let translationFolder: String
switch translation {
case .bsb:
    translationFolder = "bsb"
case .cuv:
    translationFolder = "cuv"
case .cu1:
    translationFolder = "cu1"
case .esv:  // ← Add your translation
    translationFolder = "esv"
case .none:
    throw BibleServiceError.fileNotFound(...)
}
```

And update the verse creation to include your new field:
```swift
BibleVerse(
    id: "\(bookId)-\(chapter)-\(verseJson.verse)",
    book: book,
    chapter: chapter,
    verseNumber: verseJson.verse,
    textBsb: translation == .bsb ? verseJson.text : "",
    textCuv: translation == .cuv ? verseJson.text : "",
    textCu1: translation == .cu1 ? verseJson.text : "",
    textEsv: translation == .esv ? verseJson.text : "",  // ← Add this
    testament: BibleData.book(named: book)?.testament.rawValue ?? ""
)
```

### 2.4 Update `DailyVerse` struct (if used)

In `livingdevotional/Models/Models.swift`, add the field to `DailyVerse`:
```swift
struct DailyVerse: Codable {
    // ... existing fields ...
    let textEsv: String  // ← Add
    
    enum CodingKeys: String, CodingKey {
        // ... existing keys ...
        case textEsv = "text_esv"  // ← Add
    }
    
    func text(for language: Language) -> String {
        switch language {
        // ... existing cases ...
        case .esv: return textEsv  // ← Add
        case .none: return ""
        }
    }
}
```

## Step 3: Add to Git

After copying the folder and updating code:

```bash
git add livingdevotional/Resources/BibleData.bundle/{translation_code}
git add livingdevotional/Models/Models.swift
git add livingdevotional/Data/BibleService.swift
git commit -m "Add {Translation Name} translation support"
```

## Notes

⚠️ **Current Limitation:** The current implementation uses hardcoded fields for each translation. This means:
- Each new translation requires code changes
- The `BibleVerse` struct grows with each translation
- This approach doesn't scale well for many translations

💡 **Future Improvement:** Consider refactoring to use a dictionary-based approach:
```swift
struct BibleVerse {
    let translations: [String: String]  // ["bsb": "...", "cuv": "...", "esv": "..."]
    
    func text(for language: Language) -> String {
        return translations[language.rawValue] ?? ""
    }
}
```

This would make adding new translations much easier - just copy the folder and add the enum case!





