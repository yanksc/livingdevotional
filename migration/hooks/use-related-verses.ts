import { useState, useCallback } from "react"
import type { BibleVerse, Language, RelatedVerse } from "@/lib/types"
import { findRelatedVerses } from "@/lib/actions/ai-verse-actions"

interface UseRelatedVersesOptions {
  primaryLanguage: Language
  getPrimaryText: (verse: BibleVerse) => string
}

export function useRelatedVerses({ primaryLanguage, getPrimaryText }: UseRelatedVersesOptions) {
  const [relatedVerses, setRelatedVerses] = useState<RelatedVerse[]>([])
  const [loading, setLoading] = useState(false)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState<string>("")

  const findRelated = useCallback(
    async (verse: BibleVerse) => {
      setLoading(true)
      setError("")
      try {
        const verseText = getPrimaryText(verse)
        const result = await findRelatedVerses(
          verse.book,
          verse.chapter,
          verse.verse_number,
          verseText,
          primaryLanguage
        )
        setRelatedVerses(result)
      } catch (error: any) {
        console.error("Failed to find related verses:", error)
        if (error.message?.includes("rate_limit") || error.message?.includes("429")) {
          setError("AI 服務暫時達到使用上限，請稍後再試。")
        } else {
          setError("無法找到相關經文，請稍後再試。")
        }
        setRelatedVerses([])
      } finally {
        setLoading(false)
      }
    },
    [primaryLanguage, getPrimaryText]
  )

  const loadMore = useCallback(
    async (verse: BibleVerse) => {
      setLoadingMore(true)
      setError("")
      try {
        const verseText = getPrimaryText(verse)
        const excludeReferences = relatedVerses.map((v) => v.reference)
        const result = await findRelatedVerses(
          verse.book,
          verse.chapter,
          verse.verse_number,
          verseText,
          primaryLanguage,
          excludeReferences
        )
        setRelatedVerses([...relatedVerses, ...result])
      } catch (error: any) {
        console.error("Failed to load more related verses:", error)
        if (error.message?.includes("rate_limit") || error.message?.includes("429")) {
          setError("AI 服務暫時達到使用上限，請稍後再試。")
        } else {
          setError("無法載入更多經文，請稍後再試。")
        }
      } finally {
        setLoadingMore(false)
      }
    },
    [primaryLanguage, getPrimaryText, relatedVerses]
  )

  const reset = useCallback(() => {
    setRelatedVerses([])
    setError("")
    setLoading(false)
    setLoadingMore(false)
  }, [])

  return {
    relatedVerses,
    loading,
    loadingMore,
    error,
    findRelated,
    loadMore,
    reset,
  }
}







