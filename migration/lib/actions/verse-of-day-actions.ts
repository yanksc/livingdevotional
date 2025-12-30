"use server"

import { createClient } from "@/lib/supabase/server"
import type { DailyVerse } from "@/lib/types"
import { loadChapterFromJSON } from "@/lib/bible-json-loader"
import { getBookId } from "@/lib/bible-data"

/**
 * Get today's verse with lazy generation
 * - Checks cache first for today's date
 * - If not found, randomly selects from curated verses
 * - Fetches verse text from Bible API (supports any translation)
 * - Caches the result for the current day
 */
export async function getTodaysVerse(): Promise<DailyVerse | null> {
  const supabase = await createClient()

  try {
    // Step 1: Check if we have a cached verse for today
    const { data: cachedVerse, error: cacheError } = await supabase
      .from("daily_verse_cache")
      .select("*")
      .eq("selected_date", new Date().toISOString().split("T")[0])
      .single()

    if (cachedVerse && !cacheError) {
      // Cache hit! Fetch the verse text from API
      const verseData = await fetchVerseFromAPI(
        cachedVerse.book,
        cachedVerse.chapter,
        cachedVerse.verse_number
      )

      if (verseData) {
        return {
          ...verseData,
          reference: `${cachedVerse.book} ${cachedVerse.chapter}:${cachedVerse.verse_number}`,
          selected_date: cachedVerse.selected_date,
        }
      }
    }

    // Step 2: Cache miss - select a new verse from curated verses
    const selectedReference = await selectFromCuratedVerses()
    if (!selectedReference) {
      console.error("No curated verses available")
      return null
    }

    // Step 3: Fetch the verse text from API
    const verseData = await fetchVerseFromAPI(
      selectedReference.book,
      selectedReference.chapter,
      selectedReference.verse_number
    )

    if (!verseData) {
      console.error("Failed to fetch verse from API")
      return null
    }

    // Step 4: Cache the selected verse reference for today
    const today = new Date().toISOString().split("T")[0]
    const { error: insertError } = await supabase.from("daily_verse_cache").insert({
      selected_date: today,
      book: selectedReference.book,
      chapter: selectedReference.chapter,
      verse_number: selectedReference.verse_number,
    })

    if (insertError) {
      console.error("Failed to cache daily verse:", insertError)
      // Continue anyway - we still have the verse data
    }

    // Step 5: Return the newly selected verse
    return {
      ...verseData,
      reference: `${selectedReference.book} ${selectedReference.chapter}:${selectedReference.verse_number}`,
      selected_date: today,
    }
  } catch (error) {
    console.error("Error getting today's verse:", error)
    return null
  }
}

/**
 * Fetch a specific verse from the Bible API in all supported languages
 */
async function fetchVerseFromAPI(
  book: string,
  chapter: number,
  verseNumber: number
): Promise<Omit<DailyVerse, "reference" | "selected_date"> | null> {
  try {
    const bookId = getBookId(book)
    if (!bookId) {
      console.error("Invalid book name:", book)
      return null
    }

    // Fetch the chapter in all three languages
    const [nivVerses, cuvVerses, cu1Verses] = await Promise.all([
      loadChapterFromJSON(bookId, chapter, "niv"),
      loadChapterFromJSON(bookId, chapter, "cuv"),
      loadChapterFromJSON(bookId, chapter, "cu1"),
    ])

    // Find the specific verse in each language
    const nivVerse = nivVerses.find((v) => v.verse_number === verseNumber)
    const cuvVerse = cuvVerses.find((v) => v.verse_number === verseNumber)
    const cu1Verse = cu1Verses.find((v) => v.verse_number === verseNumber)

    if (!nivVerse && !cuvVerse && !cu1Verse) {
      console.error("Verse not found in any translation")
      return null
    }

    return {
      book,
      chapter,
      verse_number: verseNumber,
      text_niv: nivVerse?.text_niv || "",
      text_cuv: cuvVerse?.text_cuv || "",
      text_cu1: cu1Verse?.text_cu1 || "",
    }
  } catch (error) {
    console.error("Error fetching verse from API:", error)
    return null
  }
}

/**
 * Randomly select a verse reference from the curated verses pool
 * Returns only the reference (book, chapter, verse_number)
 */
async function selectFromCuratedVerses(): Promise<{
  book: string
  chapter: number
  verse_number: number
} | null> {
  const supabase = await createClient()

  try {
    // Get all curated verses
    const { data: curatedVerses, error: curatedError } = await supabase
      .from("curated_verses")
      .select("book, chapter, verse_number")
      .limit(200)

    if (curatedError || !curatedVerses || curatedVerses.length === 0) {
      console.error("Error fetching curated verses:", curatedError)
      return null
    }

    // Pick a random verse from the list
    const randomIndex = Math.floor(Math.random() * curatedVerses.length)
    return curatedVerses[randomIndex]
  } catch (error) {
    console.error("Error selecting from curated verses:", error)
    return null
  }
}

/**
 * Utility function to get all curated verses (for admin purposes)
 */
export async function getAllCuratedVerses() {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from("curated_verses")
    .select("*")
    .order("category", { ascending: true })
    .order("book", { ascending: true })
    .order("chapter", { ascending: true })
    .order("verse_number", { ascending: true })

  if (error) {
    console.error("Error fetching curated verses:", error)
    return []
  }

  return data || []
}

/**
 * Utility function to clean up old cache entries
 * Keeps only the last 30 days of cached verses
 */
export async function cleanupOldCacheEntries() {
  const supabase = await createClient()

  const thirtyDaysAgo = new Date()
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
  const cutoffDate = thirtyDaysAgo.toISOString().split("T")[0]

  const { error } = await supabase.from("daily_verse_cache").delete().lt("selected_date", cutoffDate)

  if (error) {
    console.error("Error cleaning up old cache entries:", error)
    return false
  }

  return true
}

