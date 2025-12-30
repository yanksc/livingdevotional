import { useState, useEffect, useCallback } from "react"
import type { BibleVerse } from "@/lib/types"
import { saveBookmark, checkBookmarksForChapter, updateBookmarkNote } from "@/lib/actions/bookmark-actions"

interface UseBookmarkOptions {
  bookId: string
  currentChapter: number
  verses: BibleVerse[]
  getPrimaryText: (verse: BibleVerse) => string
}

export function useBookmark({ bookId, currentChapter, verses, getPrimaryText }: UseBookmarkOptions) {
  const [bookmarkedVerses, setBookmarkedVerses] = useState<Set<string>>(new Set())
  const [bookmarkData, setBookmarkData] = useState<Map<string, { note: string | null }>>(new Map())
  const [bookmarkNote, setBookmarkNote] = useState("")
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string>("")
  const [showLoginPrompt, setShowLoginPrompt] = useState(false)

  // Load bookmarks for the current chapter
  useEffect(() => {
    if (verses.length === 0) return

    // Debounce bookmark check to avoid rapid consecutive calls
    const timeoutId = setTimeout(async () => {
      try {
        // Batch check all bookmarks for the chapter in a single query
        const allBookmarks = await checkBookmarksForChapter(bookId, currentChapter)

        const bookmarked = new Set<string>()
        const bookmarkInfo = new Map<string, { note: string | null }>()

        // Create a map for O(1) lookup
        const bookmarkMap = new Map(allBookmarks.map((b) => [b.verse_number, b]))

        for (const verse of verses) {
          const bookmark = bookmarkMap.get(verse.verse_number)
          if (bookmark) {
            bookmarked.add(verse.id)
            bookmarkInfo.set(verse.id, { note: bookmark.note })
          }
        }

        setBookmarkedVerses(bookmarked)
        setBookmarkData(bookmarkInfo)
      } catch (error) {
        console.error("Error checking bookmarks:", error)
      }
    }, 300) // 300ms debounce

    return () => clearTimeout(timeoutId)
  }, [verses, bookId, currentChapter])

  const toggleBookmark = useCallback(
    async (verse: BibleVerse) => {
      const isBookmarked = bookmarkedVerses.has(verse.id)

      if (isBookmarked) {
        // If already bookmarked, load the existing note
        const existingNote = bookmarkData.get(verse.id)?.note || ""
        setBookmarkNote(existingNote)
        return { isBookmarked: true, note: existingNote }
      } else {
        // Create new bookmark
        setSaving(true)
        setError("")
        try {
          const verseText = getPrimaryText(verse)
          await saveBookmark(bookId, verse.chapter, verse.verse_number, verseText, null)
          setBookmarkedVerses((prev) => new Set(prev).add(verse.id))
          setBookmarkData((prev) => new Map(prev).set(verse.id, { note: null }))
          setBookmarkNote("")
          return { isBookmarked: false, note: "" }
        } catch (error: any) {
          console.error("Failed to save bookmark:", error)
          if (error.message?.includes("not authenticated")) {
            setShowLoginPrompt(true)
          } else {
            setError("無法儲存書籤，請稍後再試。")
          }
          throw error
        } finally {
          setSaving(false)
        }
      }
    },
    [bookmarkedVerses, bookmarkData, bookId, getPrimaryText]
  )

  const saveNote = useCallback(
    async (verse: BibleVerse) => {
      setSaving(true)
      setError("")
      try {
        await updateBookmarkNote(bookId, verse.chapter, verse.verse_number, bookmarkNote.trim())
        setBookmarkData((prev) => new Map(prev).set(verse.id, { note: bookmarkNote.trim() }))
      } catch (error) {
        console.error("Failed to update bookmark note:", error)
        setError("無法更新筆記，請稍後再試。")
        throw error
      } finally {
        setSaving(false)
      }
    },
    [bookId, bookmarkNote]
  )

  const isBookmarked = useCallback(
    (verseId: string) => {
      return bookmarkedVerses.has(verseId)
    },
    [bookmarkedVerses]
  )

  return {
    bookmarkedVerses,
    bookmarkData,
    bookmarkNote,
    saving,
    error,
    showLoginPrompt,
    setBookmarkNote,
    setShowLoginPrompt,
    toggleBookmark,
    saveNote,
    isBookmarked,
  }
}







