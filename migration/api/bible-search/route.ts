import OpenAI from "openai"
import { BIBLE_BOOKS, BOOK_ID_MAP } from "@/lib/bible-data"

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

interface VerseResult {
  book: string
  chapter: number
  verse_number: number
  text_cuv: string
  text_niv: string
  reference: string
  relevance: string
}

const API_BASE_URL = "https://bible.helloao.org/api"

// Helper function to extract text from Bible API content
function extractTextFromContent(content: any[]): string {
  return content
    .map((item) => {
      if (typeof item === "string") return item
      if (typeof item === "object" && item.text) return item.text
      return ""
    })
    .filter(Boolean)
    .join(" ")
}

// Helper function to fetch a specific verse from Bible API
async function fetchVerse(
  bookId: string,
  chapter: number,
  verseNumber: number,
  language: "cuv" | "niv"
): Promise<string> {
  try {
    const translationPath = language === "niv" ? "BSB" : "cmn_cuv"
    const apiUrl = `${API_BASE_URL}/${translationPath}/${bookId}/${chapter}.json`

    const response = await fetch(apiUrl, { cache: "force-cache" })
    if (!response.ok) return ""

    const data = await response.json()

    const verseItem = data.chapter.content.find(
      (item: any) => item.type === "verse" && item.number === verseNumber
    )

    if (!verseItem || !verseItem.content) return ""

    return extractTextFromContent(verseItem.content)
  } catch (error) {
    console.error(`Error fetching verse ${bookId} ${chapter}:${verseNumber}`, error)
    return ""
  }
}

export async function POST(req: Request) {
  try {
    const { question, language = "cuv" } = await req.json()

    if (!question || question.trim().length === 0) {
      return new Response(JSON.stringify({ error: "請輸入搜尋問題" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    console.log("[Bible Search] Question:", question)

    // Step 1: Use OpenAI to suggest specific Bible verses for the question
    const suggestionPrompt = `你是一位聖經學者專家。用戶問了以下問題：

問題：「${question}」

請推薦 5 節最相關且重要的聖經經文來回答這個問題。請選擇：
1. 經典且廣為人知的經文
2. 與主題直接相關的重要經文
3. 能幫助讀者深入理解的關鍵經文

對於每一節經文，請提供：
1. 經文出處（英文書卷名 章:節，例如 "John 3:16"）
2. 相關性說明（1-2句話解釋為什麼這節經文能回答用戶的問題）

請以JSON陣列格式回應：
[
  {
    "reference": "Book Chapter:Verse",
    "relevance": "相關性說明"
  }
]

**重要**: 書卷名稱必須使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
使用繁體中文（台灣用語）書寫相關性說明。只回傳JSON陣列，不要其他文字。`

    const suggestionResponse = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: suggestionPrompt }],
      temperature: 0.3,
      max_tokens: 1000,
    })

    let suggestions: Array<{ reference: string; relevance: string }> = []
    try {
      const content = suggestionResponse.choices[0]?.message?.content || "[]"
      const cleanedContent = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim()
      suggestions = JSON.parse(cleanedContent)
      console.log("[Bible Search] AI Suggestions:", suggestions)
    } catch (e) {
      console.error("Failed to parse suggestions:", e)
      return new Response(
        JSON.stringify({
          results: [],
          message: "AI 分析失敗，請稍後再試",
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    if (suggestions.length === 0) {
      return new Response(
        JSON.stringify({
          results: [],
          message: "找不到相關經文，請試試其他問題",
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    // Step 2: Parse references and fetch actual verse text from API
    const results: VerseResult[] = []

    for (const suggestion of suggestions) {
      try {
        // Parse reference like "John 3:16" or "1 Corinthians 13:4"
        const refMatch = suggestion.reference.match(/^([\d\s]*\w+)\s+(\d+):(\d+)/)
        if (!refMatch) {
          console.warn("[Bible Search] Could not parse reference:", suggestion.reference)
          continue
        }

        const bookName = refMatch[1].trim()
        const chapter = parseInt(refMatch[2], 10)
        const verseNumber = parseInt(refMatch[3], 10)

        // Find the book in our BIBLE_BOOKS list
        const book = BIBLE_BOOKS.find((b) => b.name === bookName)
        if (!book) {
          console.warn("[Bible Search] Book not found:", bookName)
          continue
        }

        const bookId = BOOK_ID_MAP[bookName]
        if (!bookId) {
          console.warn("[Bible Search] Book ID not found for:", bookName)
          continue
        }

        console.log(`[Bible Search] Fetching ${bookName} ${chapter}:${verseNumber}`)

        // Fetch verse text in both languages
        const [textCuv, textNiv] = await Promise.all([
          fetchVerse(bookId, chapter, verseNumber, "cuv"),
          fetchVerse(bookId, chapter, verseNumber, "niv"),
        ])

        if (!textCuv && !textNiv) {
          console.warn("[Bible Search] No text found for:", suggestion.reference)
          continue
        }

        results.push({
          book: bookName,
          chapter,
          verse_number: verseNumber,
          text_cuv: textCuv || "（無法載入中文經文）",
          text_niv: textNiv || "（無法載入英文經文）",
          reference: suggestion.reference,
          relevance: suggestion.relevance,
        })

        console.log(`[Bible Search] ✓ Successfully fetched ${suggestion.reference}`)
      } catch (error) {
        console.error("[Bible Search] Error processing suggestion:", suggestion.reference, error)
      }
    }

    console.log("[Bible Search] Total results:", results.length)

    if (results.length === 0) {
      return new Response(
        JSON.stringify({
          results: [],
          message: "無法載入經文內容，請稍後再試",
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    return new Response(
      JSON.stringify({
        results,
        message: `找到 ${results.length} 節相關經文`,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    )
  } catch (error: any) {
    console.error("[Bible Search] Fatal error:", error)
    return new Response(JSON.stringify({ error: "搜尋失敗，請稍後再試" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}
