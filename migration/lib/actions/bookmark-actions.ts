"use server"

import { createClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"

export async function saveBookmark(
  book: string,
  chapter: number,
  verseNumber: number,
  verseText: string,
  note: string | null = null,
) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    throw new Error("User not authenticated")
  }

  const { data, error } = await supabase
    .from("verse_bookmarks")
    .upsert(
      {
        user_id: user.id,
        book,
        chapter,
        verse_number: verseNumber,
        verse_text: verseText,
        note,
      },
      {
        onConflict: "user_id,book,chapter,verse_number",
      },
    )
    .select()
    .single()

  if (error) {
    console.error("Failed to save bookmark:", error)
    throw new Error("Failed to save bookmark")
  }

  revalidatePath("/profile")
  return data
}

export async function updateBookmarkNote(book: string, chapter: number, verseNumber: number, note: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    throw new Error("User not authenticated")
  }

  const { data, error } = await supabase
    .from("verse_bookmarks")
    .update({ note })
    .eq("user_id", user.id)
    .eq("book", book)
    .eq("chapter", chapter)
    .eq("verse_number", verseNumber)
    .select()
    .single()

  if (error) {
    console.error("Failed to update bookmark note:", error)
    throw new Error("Failed to update bookmark note")
  }

  revalidatePath("/profile")
  return data
}

export async function deleteBookmark(bookmarkId: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    throw new Error("User not authenticated")
  }

  const { error } = await supabase.from("verse_bookmarks").delete().eq("id", bookmarkId).eq("user_id", user.id)

  if (error) {
    console.error("Failed to delete bookmark:", error)
    throw new Error("Failed to delete bookmark")
  }

  revalidatePath("/profile")
}

export async function checkIfBookmarked(book: string, chapter: number, verseNumber: number) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return null
  }

  const { data } = await supabase
    .from("verse_bookmarks")
    .select("*")
    .eq("user_id", user.id)
    .eq("book", book)
    .eq("chapter", chapter)
    .eq("verse_number", verseNumber)
    .single()

  return data
}

/**
 * Batch check bookmarks for an entire chapter in a single query
 * This replaces N individual API calls with 1 query
 */
export async function checkBookmarksForChapter(book: string, chapter: number) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return []
  }

  const { data } = await supabase
    .from("verse_bookmarks")
    .select("*")
    .eq("user_id", user.id)
    .eq("book", book)
    .eq("chapter", chapter)

  return data || []
}
