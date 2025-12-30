"use server"

import { createClient } from "@/lib/supabase/server"
import type { ChatMessage, VerseConversation } from "@/lib/types"

type ConversationType = "explanation" | "question"

// Helper to get table name based on conversation type
function getTableName(type: ConversationType): string {
  return type === "explanation" ? "verse_explanation_history" : "verse_question_history"
}

// Save a message to database (for logged-in users)
export async function saveMessageToDatabase(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
  role: "user" | "assistant" | "system",
  content: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = await createClient()

    // Check if user is authenticated
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      return { success: false, error: "User not authenticated" }
    }

    const tableName = getTableName(type)

    const { error } = await supabase.from(tableName).insert({
      user_id: user.id,
      book,
      chapter,
      verse_number: verseNumber,
      role,
      content,
    })

    if (error) {
      console.error(`Failed to save message to ${tableName}:`, error)
      return { success: false, error: error.message }
    }

    return { success: true }
  } catch (error: any) {
    console.error("Error saving message:", error)
    return { success: false, error: error.message }
  }
}

// Get conversation history from database (for logged-in users)
export async function getConversationFromDatabase(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
): Promise<ChatMessage[]> {
  try {
    const supabase = await createClient()

    // Check if user is authenticated
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      return []
    }

    const tableName = getTableName(type)

    const { data, error } = await supabase
      .from(tableName)
      .select("id, role, content, created_at")
      .eq("user_id", user.id)
      .eq("book", book)
      .eq("chapter", chapter)
      .eq("verse_number", verseNumber)
      .order("created_at", { ascending: true })

    if (error) {
      console.error(`Failed to fetch conversation from ${tableName}:`, error)
      return []
    }

    return (data || []).map((row) => ({
      id: row.id,
      role: row.role as "user" | "assistant" | "system",
      content: row.content,
      created_at: row.created_at,
    }))
  } catch (error) {
    console.error("Error fetching conversation:", error)
    return []
  }
}

// Clear conversation history from database (for logged-in users)
export async function clearConversationFromDatabase(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = await createClient()

    // Check if user is authenticated
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      return { success: false, error: "User not authenticated" }
    }

    const tableName = getTableName(type)

    const { error } = await supabase
      .from(tableName)
      .delete()
      .eq("user_id", user.id)
      .eq("book", book)
      .eq("chapter", chapter)
      .eq("verse_number", verseNumber)

    if (error) {
      console.error(`Failed to clear conversation from ${tableName}:`, error)
      return { success: false, error: error.message }
    }

    return { success: true }
  } catch (error: any) {
    console.error("Error clearing conversation:", error)
    return { success: false, error: error.message }
  }
}

// Check if user is authenticated (client-side will use this to decide storage method)
export async function isUserAuthenticated(): Promise<boolean> {
  try {
    const supabase = await createClient()
    const {
      data: { user },
    } = await supabase.auth.getUser()
    return !!user
  } catch {
    return false
  }
}

