import { useState, useCallback, useEffect } from "react"
import type { BibleVerse, Language, ChatMessage } from "@/lib/types"
import { generateSuggestedQuestions } from "@/lib/actions/ai-verse-actions"
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

interface UseVerseQuestionOptions {
  primaryLanguage: Language
  getPrimaryText: (verse: BibleVerse) => string
}

export function useVerseQuestion({ primaryLanguage, getPrimaryText }: UseVerseQuestionOptions) {
  const [question, setQuestion] = useState<string>("")
  const [answer, setAnswer] = useState<string>("")
  const [conversationHistory, setConversationHistory] = useState<ChatMessage[]>([])
  const [suggestedQuestions, setSuggestedQuestions] = useState<string[]>([])
  const [loading, setLoading] = useState(false)
  const [loadingSuggestions, setLoadingSuggestions] = useState(false)
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [error, setError] = useState<string>("")
  const [currentVerse, setCurrentVerse] = useState<BibleVerse | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false)

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
          history = await getConversationFromDatabase("question", verse.book, verse.chapter, verse.verse_number)
        } else {
          // Load from localStorage
          history = getFromLocalStorage("question", verse.book, verse.chapter, verse.verse_number)
        }

        setConversationHistory(history)

        // If there's history, show the last Q&A pair
        if (history.length > 0) {
          const lastUserMsg = [...history].reverse().find((msg) => msg.role === "user")
          const lastAssistantMsg = [...history].reverse().find((msg) => msg.role === "assistant")

          if (lastUserMsg) {
            setQuestion(lastUserMsg.content)
          }
          if (lastAssistantMsg) {
            setAnswer(lastAssistantMsg.content)
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
        await saveMessageToDatabase("question", verse.book, verse.chapter, verse.verse_number, role, content)
      } else {
        saveToLocalStorage("question", verse.book, verse.chapter, verse.verse_number, updatedHistory)
      }
    },
    [conversationHistory, isAuthenticated]
  )

  const generateSuggestions = useCallback(
    async (verse: BibleVerse) => {
      setLoadingSuggestions(true)
      setError("")
      setSuggestedQuestions([])

      try {
        const verseText = getPrimaryText(verse)
        const questions = await generateSuggestedQuestions(
          verse.book,
          verse.chapter,
          verse.verse_number,
          verseText,
          primaryLanguage
        )
        setSuggestedQuestions(questions)
      } catch (error) {
        console.error("Failed to generate suggested questions:", error)
      } finally {
        setLoadingSuggestions(false)
      }
    },
    [primaryLanguage, getPrimaryText]
  )

  const askQuestion = useCallback(
    async (verse: BibleVerse, customQuestion?: string) => {
      const questionToAsk = customQuestion || question
      if (!questionToAsk.trim()) return

      setLoading(true)
      setError("")
      setAnswer("")
      setCurrentVerse(verse)

      // If this is a new verse or no history exists, load history first
      if (!currentVerse || currentVerse.id !== verse.id) {
        await loadHistory(verse)
      }

      try {
        const verseText = getPrimaryText(verse)

        // Save the user's question
        await saveMessage(verse, "user", questionToAsk)

        const response = await fetch("/api/ai/ask-question", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            book: verse.book,
            chapter: verse.chapter,
            verseNumber: verse.verse_number,
            verseText,
            question: questionToAsk,
            language: primaryLanguage,
            conversationHistory: [...conversationHistory, { role: "user", content: questionToAsk }],
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
            setAnswer(accumulatedText)
          })
          
          // Small delay to ensure visible streaming effect
          await new Promise(resolve => setTimeout(resolve, 1))
        }
        
        // Final update to ensure all text is displayed
        setAnswer(accumulatedText)

        // Save the assistant's answer
        await saveMessage(verse, "assistant", accumulatedText)

        if (customQuestion) {
          setQuestion(customQuestion)
        }

        // Clear the question input for next question
        setQuestion("")
      } catch (error: any) {
        console.error("Failed to answer question:", error)
        if (error.message?.includes("rate_limit") || error.message?.includes("429")) {
          setError("AI 服務暫時達到使用上限，請稍後再試。")
        } else {
          setError("無法生成回答，請稍後再試。")
        }
        setAnswer("")
        setLoading(false)
      }
    },
    [primaryLanguage, getPrimaryText, question, conversationHistory, saveMessage, loadHistory, currentVerse]
  )

  const clearHistory = useCallback(async () => {
    if (!currentVerse) return

    try {
      if (isAuthenticated) {
        await clearConversationFromDatabase("question", currentVerse.book, currentVerse.chapter, currentVerse.verse_number)
      } else {
        clearFromLocalStorage("question", currentVerse.book, currentVerse.chapter, currentVerse.verse_number)
      }

      setConversationHistory([])
      setAnswer("")
      setQuestion("")
    } catch (error) {
      console.error("Failed to clear conversation history:", error)
    }
  }, [currentVerse, isAuthenticated])

  const reset = useCallback(() => {
    setQuestion("")
    setAnswer("")
    setConversationHistory([])
    setSuggestedQuestions([])
    setError("")
    setLoading(false)
    setLoadingSuggestions(false)
    setCurrentVerse(null)
  }, [])

  return {
    question,
    answer,
    conversationHistory,
    suggestedQuestions,
    loading,
    loadingSuggestions,
    loadingHistory,
    error,
    setQuestion,
    generateSuggestions,
    askQuestion,
    loadHistory,
    clearHistory,
    reset,
  }
}



