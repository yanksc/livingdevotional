import type { BibleVerse as Verse } from "./types"

interface BibleChapterContent {
  type: "verse" | "heading" | "line_break"
  number?: number
  content?: (string | { text?: string; poem?: number; lineBreak?: boolean })[]
}

interface BibleChapterData {
  translation: {
    id: string
    name: string
  }
  book: {
    id: string
    name: string
  }
  chapter: {
    number: number
    content: BibleChapterContent[]
  }
}

const API_BASE_URL = "https://bible.helloao.org/api"

function extractTextFromContent(content: (string | { text?: string; poem?: number; lineBreak?: boolean })[]): string {
  return content
    .map((item) => {
      if (typeof item === "string") return item
      if (typeof item === "object" && item.text) return item.text
      return ""
    })
    .filter(Boolean)
    .join(" ")
}

export async function loadChapterFromJSON(
  bookId: string,
  chapter: number,
  language: "niv" | "cuv" | "cu1",
): Promise<Verse[]> {
  try {
    const translationPath = language === "niv" ? "BSB" : language === "cu1" ? "cmn_cu1" : "cmn_cuv"
    const apiUrl = `${API_BASE_URL}/${translationPath}/${bookId}/${chapter}.json`

    console.log("Fetching from API:", apiUrl)

    const response = await fetch(apiUrl)
    if (!response.ok) {
      console.log("API request failed:", response.status)
      return []
    }

    const data: BibleChapterData = await response.json()

    console.log("Loaded chapter data:", {
      book: data.book.name,
      chapter: data.chapter.number,
      contentItems: data.chapter.content.length,
    })

    const verses: Verse[] = data.chapter.content
      .filter((item) => item.type === "verse" && item.number && item.content)
      .map((item) => {
        const verseText = extractTextFromContent(item.content!)
        return {
          id: `${bookId}-${chapter}-${item.number}`,
          book: data.book.name,
          chapter: data.chapter.number,
          verse_number: item.number!,
          text_niv: language === "niv" ? verseText : "",
          text_cuv: language === "cuv" ? verseText : "",
          text_cu1: language === "cu1" ? verseText : "",
          testament: "New",
        }
      })

    console.log("Extracted verses:", verses.length)
    return verses
  } catch (error) {
    console.log("Error loading chapter from API:", error)
    return []
  }
}

export async function loadChapterBilingual(bookId: string, chapter: number): Promise<Verse[]> {
  try {
    const [englishVerses, chineseVerses] = await Promise.all([
      loadChapterFromJSON(bookId, chapter, "niv"),
      loadChapterFromJSON(bookId, chapter, "cu1"),
    ])

    console.log("Loaded bilingual data:", {
      english: englishVerses.length,
      chinese: chineseVerses.length,
    })

    if (englishVerses.length === 0 && chineseVerses.length === 0) {
      return []
    }

    const mergedVerses: Verse[] = englishVerses.map((engVerse) => {
      const chiVerse = chineseVerses.find((v) => v.verse_number === engVerse.verse_number)
      return {
        ...engVerse,
        text_cuv: chiVerse?.text_cuv || "",
      }
    })

    return mergedVerses
  } catch (error) {
    console.log("Error loading bilingual chapter, will fallback to Supabase:", error)
    return []
  }
}

export async function loadChapterWithLanguages(
  bookId: string,
  chapter: number,
  primaryLanguage: "niv" | "cuv" | "cu1" | "none",
  secondaryLanguage: "niv" | "cuv" | "cu1" | "none",
): Promise<Verse[]> {
  try {
    console.log("Loading chapter with languages:", { bookId, chapter, primaryLanguage, secondaryLanguage })

    // If primary language is "none", return empty array
    if (primaryLanguage === "none") {
      return []
    }

    // Load primary language
    const primaryVerses = await loadChapterFromJSON(bookId, chapter, primaryLanguage)

    if (primaryVerses.length === 0) {
      return []
    }

    // If secondary language is "none", return only primary
    if (secondaryLanguage === "none") {
      return primaryVerses
    }

    // Load secondary language
    const secondaryVerses = await loadChapterFromJSON(bookId, chapter, secondaryLanguage)

    const mergedVerses: Verse[] = primaryVerses.map((primaryVerse) => {
      const secondaryVerse = secondaryVerses.find((v) => v.verse_number === primaryVerse.verse_number)

      return {
        ...primaryVerse,
        text_niv:
          primaryLanguage === "niv"
            ? primaryVerse.text_niv
            : secondaryLanguage === "niv"
              ? secondaryVerse?.text_niv || ""
              : "",
        text_cuv:
          primaryLanguage === "cuv"
            ? primaryVerse.text_cuv
            : secondaryLanguage === "cuv"
              ? secondaryVerse?.text_cuv || ""
              : "",
        text_cu1:
          primaryLanguage === "cu1"
            ? primaryVerse.text_cu1
            : secondaryLanguage === "cu1"
              ? secondaryVerse?.text_cu1 || ""
              : "",
      }
    })

    console.log("Merged verses:", mergedVerses.length)
    return mergedVerses
  } catch (error) {
    console.log("Error loading chapter with languages:", error)
    return []
  }
}
