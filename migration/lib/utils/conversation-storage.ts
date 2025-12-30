// Client-side localStorage utilities for conversation history
// These functions run in the browser only

import type { ChatMessage } from "@/lib/types"

type ConversationType = "explanation" | "question"

export function getLocalStorageKey(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
): string {
  return `verse_chat_${type}_${book}_${chapter}_${verseNumber}`
}

export function saveToLocalStorage(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
  messages: ChatMessage[],
): void {
  if (typeof window === "undefined") return

  try {
    const key = getLocalStorageKey(type, book, chapter, verseNumber)
    localStorage.setItem(key, JSON.stringify(messages))
  } catch (error) {
    console.error("Failed to save to localStorage:", error)
  }
}

export function getFromLocalStorage(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
): ChatMessage[] {
  if (typeof window === "undefined") return []

  try {
    const key = getLocalStorageKey(type, book, chapter, verseNumber)
    const data = localStorage.getItem(key)
    if (!data) return []
    return JSON.parse(data) as ChatMessage[]
  } catch (error) {
    console.error("Failed to get from localStorage:", error)
    return []
  }
}

export function clearFromLocalStorage(
  type: ConversationType,
  book: string,
  chapter: number,
  verseNumber: number,
): void {
  if (typeof window === "undefined") return

  try {
    const key = getLocalStorageKey(type, book, chapter, verseNumber)
    localStorage.removeItem(key)
  } catch (error) {
    console.error("Failed to clear localStorage:", error)
  }
}

