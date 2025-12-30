import { useState, useCallback, useEffect } from "react"
import type { BibleVerse, Language, ChatMessage } from "@/lib/types"
import {
  getConversationFromDatabase,
  saveMessageToDatabase,
  clearConversationFromDatabase,
  isUserAuthenticated,
} from "@/lib/actions/conversation-actions"
import {
  getFromLocalStorage,
  saveToLocalStorage,
  clearFromLocalStorage,
} from "@/lib/utils/conversation-storage"

interface UseVerseExplanationOptions {
  primaryLanguage: Language
  getPrimaryText: (verse: BibleVerse) => string
}

export function useVerseExplanation({ primaryLanguage, getPrimaryText }: UseVerseExplanationOptions) {
  const [explanation, setExplanation] = useState<string>("")
  const [conversationHistory, setConversationHistory] = useState<ChatMessage[]>([])
  const [loading, setLoading] = useState(false)
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [error, setError] = useState<string>("")
  const [currentVerse, setCurrentVerse] = useState<BibleVerse | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false)
  const [followUpPrompt, setFollowUpPrompt] = useState<string>("")

  // Check authentication status
  useEffect(() => {
    isUserAuthenticated().then(setIsAuthenticated)
  }, [])

  // Load conversation history when verse changes
  const loadHistory = useCallback(
    async (verse: BibleVerse) => {
      setLoadingHistory(true)
      try {
        let history: ChatMessage[] = []

        if (isAuthenticated) {
          // Try to load from database
          history = await getConversationFromDatabase("explanation", verse.book, verse.chapter, verse.verse_number)
        } else {
          // Load from localStorage
          history = getFromLocalStorage("explanation", verse.book, verse.chapter, verse.verse_number)
        }

        setConversationHistory(history)

        // If there's history, show the last assistant message as the explanation
        if (history.length > 0) {
          const lastAssistantMsg = [...history].reverse().find((msg) => msg.role === "assistant")
          if (lastAssistantMsg) {
            setExplanation(lastAssistantMsg.content)
          }
        }
      } catch (error) {
        console.error("Failed to load conversation history:", error)
      } finally {
        setLoadingHistory(false)
      }
    },
    [isAuthenticated]
  )

  // Save message to storage
  const saveMessage = useCallback(
    async (verse: BibleVerse, role: "user" | "assistant", content: string) => {
      const newMessage: ChatMessage = { role, content, created_at: new Date().toISOString() }
      const updatedHistory = [...conversationHistory, newMessage]

      setConversationHistory(updatedHistory)

      if (isAuthenticated) {
        await saveMessageToDatabase("explanation", verse.book, verse.chapter, verse.verse_number, role, content)
      } else {
        saveToLocalStorage("explanation", verse.book, verse.chapter, verse.verse_number, updatedHistory)
      }
    },
    [conversationHistory, isAuthenticated]
  )

  const explainVerse = useCallback(
    async (verse: BibleVerse, userPrompt?: string) => {
      setLoading(true)
      setError("")
      setCurrentVerse(verse)

      // If this is a new verse or no history exists, load history first
      if (!currentVerse || currentVerse.id !== verse.id) {
        await loadHistory(verse)
      }

      try {
        const verseText = getPrimaryText(verse)

        // If there's a user prompt, save it first
        if (userPrompt) {
          await saveMessage(verse, "user", userPrompt)
        }

        const response = await fetch("/api/ai/explain-verse", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            book: verse.book,
            chapter: verse.chapter,
            verseNumber: verse.verse_number,
            verseText,
            language: primaryLanguage,
            conversationHistory: userPrompt ? [...conversationHistory, { role: "user", content: userPrompt }] : conversationHistory,
            userPrompt,
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
          
          // Use queueMicrotask to ensure each update renders immediately
          queueMicrotask(() => {
            setExplanation(accumulatedText)
          })
          
          // Small delay to ensure visible streaming effect
          await new Promise(resolve => setTimeout(resolve, 1))
        }
        
        // Final update to ensure all text is displayed
        setExplanation(accumulatedText)

        // Save the assistant's response
        await saveMessage(verse, "assistant", accumulatedText)
        setFollowUpPrompt("")
      } catch (error: any) {
        console.error("Failed to explain verse:", error)
        if (error.message?.includes("rate_limit") || error.message?.includes("429")) {
          setError("AI 服務暫時達到使用上限，請稍後再試。")
        } else {
          setError("無法生成解釋，請稍後再試。")
        }
        setExplanation("")
        setLoading(false)
      }
    },
    [primaryLanguage, getPrimaryText, conversationHistory, saveMessage, loadHistory, currentVerse]
  )

  const clearHistory = useCallback(async () => {
    if (!currentVerse) return

    try {
      if (isAuthenticated) {
        await clearConversationFromDatabase("explanation", currentVerse.book, currentVerse.chapter, currentVerse.verse_number)
      } else {
        clearFromLocalStorage("explanation", currentVerse.book, currentVerse.chapter, currentVerse.verse_number)
      }

      setConversationHistory([])
      setExplanation("")
      setFollowUpPrompt("")
    } catch (error) {
      console.error("Failed to clear conversation history:", error)
    }
  }, [currentVerse, isAuthenticated])

  const reset = useCallback(() => {
    setExplanation("")
    setConversationHistory([])
    setError("")
    setLoading(false)
    setCurrentVerse(null)
    setFollowUpPrompt("")
  }, [])

  return {
    explanation,
    conversationHistory,
    loading,
    loadingHistory,
    error,
    followUpPrompt,
    setFollowUpPrompt,
    explainVerse,
    loadHistory,
    clearHistory,
    reset,
  }
}



