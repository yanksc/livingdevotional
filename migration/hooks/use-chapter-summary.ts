import { useState, useCallback } from "react"
import type { Language } from "@/lib/types"

interface UseChapterSummaryOptions {
  primaryLanguage: Language
}

export function useChapterSummary({ primaryLanguage }: UseChapterSummaryOptions) {
  const [summary, setSummary] = useState<string>("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string>("")

  const summarizeChapter = useCallback(
    async (book: string, chapter: number) => {
      setLoading(true)
      setError("")
      setSummary("")

      try {
        const response = await fetch("/api/ai/summarize-chapter", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            book,
            chapter,
            language: primaryLanguage,
          }),
        })

        if (!response.ok) {
          throw new Error("Failed to get response")
        }

        const reader = response.body?.getReader()
        const decoder = new TextDecoder()

        if (!reader) {
          throw new Error("No response body")
        }

        let accumulatedText = ""
        let isFirstChunk = true

        while (true) {
          const { done, value } = await reader.read()
          if (done) break

          // Set loading to false after first chunk so we can see streaming text
          if (isFirstChunk) {
            setLoading(false)
            isFirstChunk = false
          }

          const chunk = decoder.decode(value, { stream: true })
          accumulatedText += chunk
          setSummary(accumulatedText)
        }
      } catch (error: any) {
        console.error("Failed to summarize chapter:", error)
        if (error.message?.includes("rate_limit") || error.message?.includes("429")) {
          setError("AI 服務暫時達到使用上限，請稍後再試。")
        } else {
          setError("無法生成章節摘要，請稍後再試。")
        }
        setSummary("")
        setLoading(false)
      }
    },
    [primaryLanguage]
  )

  const reset = useCallback(() => {
    setSummary("")
    setError("")
    setLoading(false)
  }, [])

  return {
    summary,
    loading,
    error,
    summarizeChapter,
    reset,
  }
}





