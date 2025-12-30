import type { User } from "@supabase/supabase-js"

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

export interface BibleBook {
  name: string
  testament: "Old" | "New"
  chapters: number
  hasData: boolean
}

export type Language = "niv" | "cuv" | "cu1" | "none"

export interface UserPreferences {
  id?: string
  user_id: string
  primary_language: Language
  secondary_language: Language
  created_at?: string
  updated_at?: string
}

export interface VerseBookmark {
  id: string
  user_id: string
  book: string
  chapter: number
  verse_number: number
  verse_text: string
  note: string | null
  created_at: string
}

export interface RelatedVerse {
  reference: string
  summary: string
  relevance: string
}

export interface ReadingProgress {
  id?: string
  user_id: string
  book: string
  chapter: number
  last_verse: number
  last_read_at: string
}

export interface CuratedVerse {
  id: string
  book: string
  chapter: number
  verse_number: number
  category: string
  created_at: string
}

export interface DailyVerse {
  book: string
  chapter: number
  verse_number: number
  text_niv: string
  text_cuv: string
  text_cu1: string
  reference: string
  selected_date: string
}

export interface ChatMessage {
  id?: string
  role: "user" | "assistant" | "system"
  content: string
  created_at?: string
}

export interface VerseConversation {
  book: string
  chapter: number
  verse_number: number
  messages: ChatMessage[]
}

export interface DailyCheckIn {
  id: string
  user_id: string
  check_in_date: string
  read_count: number
  created_at: string
  updated_at: string
}

// Re-export Supabase User type for convenience
export type { User as SupabaseUser } from "@supabase/supabase-js"

// Alias type for internal use
export interface Verse extends BibleVerse {}
