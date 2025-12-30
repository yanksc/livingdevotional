// Utility to parse Bible verse references from text
// Supports formats like "約翰福音 3:16", "John 3:16", "約翰福音 3:16-18"

// Reverse mapping from Chinese to English book names
const BOOK_NAMES_ZH_TO_EN: Record<string, string> = {
  創世記: "Genesis",
  出埃及記: "Exodus",
  利未記: "Leviticus",
  民數記: "Numbers",
  申命記: "Deuteronomy",
  約書亞記: "Joshua",
  士師記: "Judges",
  路得記: "Ruth",
  撒母耳記上: "1 Samuel",
  撒母耳記下: "2 Samuel",
  列王紀上: "1 Kings",
  列王紀下: "2 Kings",
  歷代志上: "1 Chronicles",
  歷代志下: "2 Chronicles",
  以斯拉記: "Ezra",
  尼希米記: "Nehemiah",
  以斯帖記: "Esther",
  約伯記: "Job",
  詩篇: "Psalms",
  箴言: "Proverbs",
  傳道書: "Ecclesiastes",
  雅歌: "Song of Solomon",
  以賽亞書: "Isaiah",
  耶利米書: "Jeremiah",
  耶利米哀歌: "Lamentations",
  以西結書: "Ezekiel",
  但以理書: "Daniel",
  何西阿書: "Hosea",
  約珥書: "Joel",
  阿摩司書: "Amos",
  俄巴底亞書: "Obadiah",
  約拿書: "Jonah",
  彌迦書: "Micah",
  那鴻書: "Nahum",
  哈巴谷書: "Habakkuk",
  西番雅書: "Zephaniah",
  哈該書: "Haggai",
  撒迦利亞書: "Zechariah",
  瑪拉基書: "Malachi",
  馬太福音: "Matthew",
  馬可福音: "Mark",
  路加福音: "Luke",
  約翰福音: "John",
  使徒行傳: "Acts",
  羅馬書: "Romans",
  哥林多前書: "1 Corinthians",
  哥林多後書: "2 Corinthians",
  加拉太書: "Galatians",
  以弗所書: "Ephesians",
  腓立比書: "Philippians",
  歌羅西書: "Colossians",
  帖撒羅尼迦前書: "1 Thessalonians",
  帖撒羅尼迦後書: "2 Thessalonians",
  提摩太前書: "1 Timothy",
  提摩太後書: "2 Timothy",
  提多書: "Titus",
  腓利門書: "Philemon",
  希伯來書: "Hebrews",
  雅各書: "James",
  彼得前書: "1 Peter",
  彼得後書: "2 Peter",
  約翰一書: "1 John",
  約翰二書: "2 John",
  約翰三書: "3 John",
  猶大書: "Jude",
  啟示錄: "Revelation",
}

export interface ParsedVerseReference {
  book: string // English book name
  chapter: number
  verse: number
  verseEnd?: number // For ranges like "3:16-18"
  originalText: string // The original reference text
}

/**
 * Parse a verse reference string into structured data
 * Supports formats:
 * - "約翰福音 3:16"
 * - "John 3:16"
 * - "約翰福音 3:16-18"
 * - "馬太福音 5:3"
 */
export function parseVerseReference(reference: string): ParsedVerseReference | null {
  // Trim whitespace
  const trimmed = reference.trim()

  // Pattern: BookName Chapter:Verse or BookName Chapter:Verse-VerseEnd
  // Supports both Chinese and English book names
  const pattern = /^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$/

  const match = trimmed.match(pattern)
  if (!match) {
    return null
  }

  const bookName = match[1].trim()
  const chapter = Number.parseInt(match[2], 10)
  const verse = Number.parseInt(match[3], 10)
  const verseEnd = match[4] ? Number.parseInt(match[4], 10) : undefined

  // Convert Chinese book name to English if needed
  const englishBookName = BOOK_NAMES_ZH_TO_EN[bookName] || bookName

  // Validate that we have a valid book name
  // (You could add more validation here if needed)
  if (!englishBookName) {
    return null
  }

  return {
    book: englishBookName,
    chapter,
    verse,
    verseEnd,
    originalText: trimmed,
  }
}

/**
 * Check if a verse reference is in the same chapter as the current context
 */
export function isSameChapter(reference: ParsedVerseReference, currentBook: string, currentChapter: number): boolean {
  return reference.book === currentBook && reference.chapter === currentChapter
}

/**
 * Generate a URL path for a verse reference
 * Format: /read/[book]/[chapter]#verse-[verse]
 */
export function getVerseUrl(reference: ParsedVerseReference): string {
  const path = `/read/${reference.book}/${reference.chapter}`
  const hash = `#verse-${reference.verse}`
  return path + hash
}

/**
 * Generate an anchor hash for a verse (for same-chapter scrolling)
 * Format: #verse-[verse]
 */
export function getVerseAnchor(verseNumber: number): string {
  return `#verse-${verseNumber}`
}
