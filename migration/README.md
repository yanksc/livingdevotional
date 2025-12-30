# BibleMind iOS Migration Reference

This folder contains reference files from the Next.js web app to help with the iOS Swift/SwiftUI conversion.

## 📁 Folder Structure

```
migration/
├── README.md                    # This file
├── models/
│   └── types.ts                 # TypeScript type definitions → Swift structs/enums
├── data/
│   └── bible-data.ts            # Bible books metadata, ID maps, localization
├── api/
│   ├── explain-verse/           # AI verse explanation endpoint
│   ├── find-related-verses/     # AI related verses endpoint
│   ├── ask-question/            # AI Q&A endpoint
│   ├── bible-search/            # AI-powered search endpoint
│   ├── summarize-chapter/       # AI chapter summary endpoint
│   └── verse-of-the-day/        # Daily verse endpoint
├── database/
│   ├── 001_create_bible_schema.sql
│   ├── 005_enable_rls_for_user_tables.sql
│   ├── 006_create_bookmarks_table.sql
│   ├── 007_verse_of_the_day_schema.sql
│   ├── 008_add_more_curated_verses.sql
│   ├── 009_create_conversation_history.sql
│   └── 010_create_daily_checkins_table.sql
├── components/
│   ├── verse-display.tsx        # Main verse rendering with AI panel
│   ├── verse-ai-panel.tsx       # AI feature panel (explain, related, Q&A)
│   ├── bible-search-dialog.tsx  # Search modal UI
│   ├── checkin-calendar.tsx     # Week/month calendar view
│   ├── settings-drawer.tsx      # Language settings
│   ├── navigation-drawer.tsx    # Book/chapter navigation
│   ├── bottom-navigation.tsx    # Tab bar navigation
│   ├── book-selector.tsx        # Book list by testament
│   ├── chapter-selector.tsx     # Chapter grid
│   ├── chapter-navigation.tsx   # Prev/next chapter nav
│   ├── verse-chat-display.tsx   # AI conversation display
│   ├── verse-link.tsx           # Clickable verse references
│   ├── markdown-renderer.tsx    # Markdown to UI
│   └── reading-header.tsx       # Reading view header
├── hooks/
│   ├── use-verse-explanation.ts # Explanation AI logic
│   ├── use-related-verses.ts    # Related verses AI logic
│   ├── use-verse-question.ts    # Q&A AI logic
│   ├── use-bookmark.ts          # Bookmark CRUD logic
│   └── use-chapter-summary.ts   # Chapter summary AI logic
├── lib/
│   ├── verse-cache.ts           # In-memory verse caching
│   ├── verse-reference-parser.ts # Parse "John 3:16" references
│   ├── bible-json-loader.ts     # Load Bible JSON from API
│   ├── actions/
│   │   ├── ai-verse-actions.ts  # Server actions for AI
│   │   ├── bookmark-actions.ts  # Bookmark server actions
│   │   ├── checkin-actions.ts   # Check-in server actions
│   │   ├── conversation-actions.ts # Conversation history
│   │   └── verse-of-day-actions.ts # VOTD actions
│   └── utils/
│       └── conversation-storage.ts # Conversation persistence
└── pages/
    ├── home-page.tsx            # Main home screen
    ├── profile-page.tsx         # User profile with tabs
    ├── reading-view.tsx         # Bible reading view
    ├── login-page.tsx           # Login screen
    └── signup-page.tsx          # Sign up screen
```

---

## 🔄 TypeScript → Swift Conversion Guide

### Data Models (types.ts)

| TypeScript | Swift |
|------------|-------|
| `interface` | `struct` (Codable) |
| `type` alias | `typealias` |
| `enum` string union | `enum: String, Codable` |
| `T \| null` | `T?` (Optional) |
| `string` | `String` |
| `number` | `Int` or `Double` |
| `boolean` | `Bool` |
| `Date` (string) | `Date` with ISO8601 decoder |

#### Example Conversion:

**TypeScript:**
```typescript
export interface BibleVerse {
  id: string
  book: string
  chapter: number
  verse_number: number
  text_niv: string
  text_cuv: string
  text_cu1: string
  testament: string
}

export type Language = "niv" | "cuv" | "cu1" | "none"
```

**Swift:**
```swift
struct BibleVerse: Codable, Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textNiv: String
    let textCuv: String
    let textCu1: String
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textNiv = "text_niv"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
    }
}

enum Language: String, Codable, CaseIterable {
    case niv = "niv"
    case cuv = "cuv"
    case cu1 = "cu1"
    case none = "none"
}
```

---

## 📱 Component → SwiftUI View Mapping

| React Component | SwiftUI View |
|-----------------|--------------|
| `page.tsx` | `View` with `NavigationStack` |
| `useState` | `@State` |
| `useEffect` | `.onAppear` / `.task` |
| `props` | View parameters |
| `children` | `@ViewBuilder` content |
| `onClick` | `.onTapGesture` / `Button` |
| `className` | View modifiers |
| `map()` render | `ForEach` |
| `condition && jsx` | `if` statement |
| Sheet/Drawer | `.sheet()` modifier |
| Modal | `.fullScreenCover()` |

---

## 🗄️ Database Schema Reference

### Key Tables:

1. **bible_verses** - All 66 books, all verses, 3 translations
2. **user_preferences** - Language settings per user
3. **reading_progress** - Last read book/chapter per user
4. **verse_bookmarks** - Saved verses with notes
5. **curated_verses** - Verse of the day pool
6. **verse_of_the_day** - Selected daily verse
7. **verse_explanation_history** - AI explanation chat history
8. **verse_question_history** - AI Q&A chat history
9. **daily_checkins** - Reading streak tracking

### Supabase Swift SDK:

```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "YOUR_URL")!,
    supabaseKey: "YOUR_KEY"
)

// Query example
let verses: [BibleVerse] = try await client
    .from("bible_verses")
    .select()
    .eq("book", value: "John")
    .eq("chapter", value: 3)
    .order("verse_number")
    .execute()
    .value
```

---

## 🤖 AI API Integration

### OpenAI Streaming Pattern:

**Web (TypeScript):**
```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4o-mini",
  messages,
  stream: true,
})

for await (const chunk of stream) {
  const text = chunk.choices[0]?.delta?.content
  // Update UI with streaming text
}
```

**iOS (Swift):**
```swift
// Using OpenAI Swift package or URLSession with async streams
func streamExplanation(for verse: BibleVerse) async throws -> AsyncStream<String> {
    // Create streaming request to your backend API
    // Backend proxies to OpenAI (keeps API key secure)
    let url = URL(string: "\(baseURL)/api/ai/explain-verse")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(ExplainRequest(verse: verse))
    
    return AsyncStream { continuation in
        Task {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            for try await byte in bytes.lines {
                continuation.yield(byte)
            }
            continuation.finish()
        }
    }
}
```

---

## 🔐 Authentication Migration

### Web (Supabase + Google):
```typescript
supabase.auth.signInWithOAuth({ provider: "google" })
```

### iOS (Sign in with Apple + Supabase):
```swift
import AuthenticationServices

// 1. Apple Sign In
func signInWithApple() async throws -> ASAuthorizationAppleIDCredential {
    // Use ASAuthorizationController
}

// 2. Exchange with Supabase
func authenticateWithSupabase(credential: ASAuthorizationAppleIDCredential) async throws {
    try await supabase.auth.signInWithIdToken(
        credentials: .init(
            provider: .apple,
            idToken: String(data: credential.identityToken!, encoding: .utf8)!
        )
    )
}
```

---

## 🎨 UI Patterns Reference

### Color Theme (from globals.css):
```swift
extension Color {
    static let appPrimary = Color(hex: "#3B82F6")    // Blue
    static let appAccent = Color(hex: "#10B981")     // Green
    static let appBackground = Color(hex: "#FFFFFF")
    static let appMuted = Color(hex: "#6B7280")
}
```

### Gradients:
```swift
let primaryGradient = LinearGradient(
    colors: [.appPrimary, .appAccent],
    startPoint: .leading,
    endPoint: .trailing
)
```

---

## 📋 Feature Checklist for iOS

### Phase 1: Core Reading
- [ ] Bible data models
- [ ] Book/chapter navigation
- [ ] Verse display with dual language
- [ ] Language settings
- [ ] Splash screen

### Phase 2: Authentication
- [ ] Sign in with Apple
- [ ] Email/password option
- [ ] Guest mode
- [ ] Supabase integration

### Phase 3: Home Screen
- [ ] Verse of the day
- [ ] Continue reading
- [ ] Feature cards

### Phase 4: AI Features
- [ ] Verse explanation (streaming)
- [ ] Related verses
- [ ] Q&A with suggestions
- [ ] Smart search
- [ ] Chapter summary

### Phase 5: Bookmarks
- [ ] Add/remove bookmarks
- [ ] Notes on bookmarks
- [ ] Bookmark list view

### Phase 6: Check-in
- [ ] Auto check-in on read
- [ ] Streak tracking
- [ ] Week/month calendar

### Phase 7: Polish
- [ ] Dark mode
- [ ] Accessibility
- [ ] Offline support
- [ ] Widgets

---

## 🔗 External APIs Used

1. **Bible Content API**: `https://bible.helloao.org/api/`
   - Format: `/{translation}/{bookId}/{chapter}.json`
   - Translations: `BSB` (English), `cmn_cuv` (Chinese)

2. **OpenAI API**: `https://api.openai.com/v1/chat/completions`
   - Model: `gpt-4o-mini`
   - Used for: Explanation, related verses, Q&A, search

3. **Supabase**: Your Supabase project URL
   - Auth, Database, Real-time (optional)

---

## 📝 Notes

- All Chinese text uses Traditional Chinese (Taiwan locale: `zh-TW`)
- Book names have English and Chinese versions (see `bible-data.ts`)
- AI prompts are in Chinese for Chinese UI responses
- Conversation history is per-verse, per-user
- Check-in uses local date (not UTC) for accurate day counting

---

## 🚀 Getting Started with iOS Project

1. Create new Xcode project (iOS App, SwiftUI, Swift)
2. Add packages:
   - `supabase-swift` (Supabase)
   - `swift-markdown` (Markdown rendering)
3. Copy Bible data JSON files to app bundle
4. Set up Supabase project with Apple Auth provider
5. Start with Phase 1 models and views

Good luck with the iOS conversion! 🙏


