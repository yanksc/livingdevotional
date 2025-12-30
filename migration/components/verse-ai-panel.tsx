"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Sparkles, BookOpen, X, Loader2, MessageCircleQuestion } from "lucide-react"
import type { BibleVerse, Language, RelatedVerse } from "@/lib/types"
import { getLocalizedBookName } from "@/lib/bible-data"
import { parseVerseReference } from "@/lib/verse-reference-parser"
import { MarkdownRenderer } from "./markdown-renderer"
import { Textarea } from "@/components/ui/textarea"

interface VerseAIPanelProps {
  verse: BibleVerse
  primaryLanguage: Language
  onClose: () => void
}

export function VerseAIPanel({ verse, primaryLanguage, onClose }: VerseAIPanelProps) {
  const [activeTab, setActiveTab] = useState<"explain" | "related" | "question">("explain")
  const [explanation, setExplanation] = useState<string>("")
  const [relatedVerses, setRelatedVerses] = useState<RelatedVerse[]>([])
  const [loadingMore, setLoadingMore] = useState(false)
  const [question, setQuestion] = useState<string>("")
  const [answer, setAnswer] = useState<string>("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string>("")

  const verseText = primaryLanguage === "niv" ? verse.text_niv : verse.text_cuv

  const displayedRelatedVerses = relatedVerses.slice(0, 3)

  // Helper function to localize verse references
  const localizeReference = (reference: string): string => {
    const parsed = parseVerseReference(reference)
    if (!parsed) return reference // If parsing fails, return original
    
    const localizedBook = getLocalizedBookName(parsed.book, primaryLanguage)
    if (parsed.verseEnd) {
      return `${localizedBook} ${parsed.chapter}:${parsed.verse}-${parsed.verseEnd}`
    }
    return `${localizedBook} ${parsed.chapter}:${parsed.verse}`
  }

  const handleExplain = async () => {
    setLoading(true)
    setActiveTab("explain")
    setError("")
    setExplanation("")
    
    try {
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
  }

  const handleFindRelated = async () => {
    setLoading(true)
    setActiveTab("related")
    setError("")
    setRelatedVerses([])
    
    try {
      const response = await fetch("/api/ai/find-related-verses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          book: verse.book,
          chapter: verse.chapter,
          verseNumber: verse.verse_number,
          verseText,
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
      
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        
        const chunk = decoder.decode(value, { stream: true })
        accumulatedText += chunk
      }

      // Parse the accumulated JSON response
      const lines = accumulatedText.split("\n").filter(line => line.trim())
      let jsonText = ""
      for (const line of lines) {
        if (line.startsWith("0:")) {
          const content = line.slice(2).trim()
          if (content) {
            try {
              const parsed = JSON.parse(content)
              if (typeof parsed === "string") {
                jsonText += parsed
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }

      // Remove markdown code blocks if present
      jsonText = jsonText.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim()
      const result = JSON.parse(jsonText)
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
  }

  const handleAskQuestion = async () => {
    if (!question.trim()) return

    setLoading(true)
    setError("")
    setAnswer("")
    
    try {
      const response = await fetch("/api/ai/ask-question", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          book: verse.book,
          chapter: verse.chapter,
          verseNumber: verse.verse_number,
          verseText,
          question,
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
        
        // Use queueMicrotask to ensure each update renders immediately
        queueMicrotask(() => {
          setAnswer(accumulatedText)
        })
        
        // Small delay to ensure visible streaming effect
        await new Promise(resolve => setTimeout(resolve, 1))
      }
      
      // Final update to ensure all text is displayed
      setAnswer(accumulatedText)
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
  }

  const handleLoadMoreRelated = async () => {
    setLoadingMore(true)
    setError("")
    
    try {
      const excludeReferences = relatedVerses.map((v) => v.reference)
      
      const response = await fetch("/api/ai/find-related-verses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          book: verse.book,
          chapter: verse.chapter,
          verseNumber: verse.verse_number,
          verseText,
          language: primaryLanguage,
          excludeReferences,
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
      
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        
        const chunk = decoder.decode(value, { stream: true })
        accumulatedText += chunk
      }

      // Parse the accumulated JSON response
      const lines = accumulatedText.split("\n").filter(line => line.trim())
      let jsonText = ""
      for (const line of lines) {
        if (line.startsWith("0:")) {
          const content = line.slice(2).trim()
          if (content) {
            try {
              const parsed = JSON.parse(content)
              if (typeof parsed === "string") {
                jsonText += parsed
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }

      // Remove markdown code blocks if present
      jsonText = jsonText.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim()
      const result = JSON.parse(jsonText)
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
  }

  return (
    <div className="fixed inset-0 z-50 bg-background/95 backdrop-blur-sm">
      <div className="container max-w-2xl mx-auto h-full flex flex-col p-4">
        {/* Header */}
        <div className="flex items-center justify-between py-4 border-b border-border">
          <div>
            <h2 className="text-lg font-semibold text-foreground">
              {getLocalizedBookName(verse.book, primaryLanguage)} {verse.chapter}:{verse.verse_number}
            </h2>
            <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{verseText}</p>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2 py-4">
          <Button
            variant={activeTab === "explain" ? "default" : "outline"}
            size="sm"
            onClick={handleExplain}
            disabled={loading}
            className="flex-1"
          >
            <Sparkles className="h-4 w-4 mr-2" />
            解釋經文
          </Button>
          <Button
            variant={activeTab === "related" ? "default" : "outline"}
            size="sm"
            onClick={handleFindRelated}
            disabled={loading}
            className="flex-1"
          >
            <BookOpen className="h-4 w-4 mr-2" />
            相關經文
          </Button>
          <Button
            variant={activeTab === "question" ? "default" : "outline"}
            size="sm"
            onClick={() => setActiveTab("question")}
            disabled={loading}
            className="flex-1"
          >
            <MessageCircleQuestion className="h-4 w-4 mr-2" />
            提問
          </Button>
        </div>

        {error && (
          <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3 mb-4">
            <p className="text-sm text-destructive">{error}</p>
          </div>
        )}

        {/* Content */}
        <div className="flex-1 overflow-y-auto pb-4">
          {loading ? (
            <div className="flex items-center justify-center h-full">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : activeTab === "explain" && explanation ? (
            <div className="bg-accent/30 rounded-lg p-4">
              <MarkdownRenderer content={explanation} />
            </div>
          ) : activeTab === "related" && relatedVerses.length > 0 ? (
            <div className="space-y-4">
              {relatedVerses.map((related, index) => (
                <div key={index} className="bg-accent/30 rounded-lg p-4">
                  <h3 className="font-semibold text-primary mb-2">{localizeReference(related.reference)}</h3>
                  <p className="text-sm text-muted-foreground mb-2 italic">{related.summary}</p>
                  <div className="text-sm">
                    <MarkdownRenderer content={related.relevance} />
                  </div>
                </div>
              ))}
              <Button
                variant="outline"
                onClick={handleLoadMoreRelated}
                disabled={loadingMore}
                className="w-full bg-transparent"
              >
                {loadingMore ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    載入更多經文中...
                  </>
                ) : (
                  "顯示更多相關經文"
                )}
              </Button>
            </div>
          ) : activeTab === "question" ? (
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium text-foreground mb-2 block">請輸入您的問題：</label>
                <Textarea
                  value={question}
                  onChange={(e) => setQuestion(e.target.value)}
                  placeholder="例如：這段經文在當時的背景是什麼？"
                  className="min-h-[100px] resize-none"
                  disabled={loading}
                />
              </div>
              <Button onClick={handleAskQuestion} disabled={loading || !question.trim()} className="w-full">
                {loading ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    回答中...
                  </>
                ) : (
                  "提交問題"
                )}
              </Button>
              {answer && (
                <div className="bg-accent/30 rounded-lg p-4 mt-4">
                  <h3 className="font-semibold text-primary mb-2">回答：</h3>
                  <MarkdownRenderer content={answer} />
                </div>
              )}
            </div>
          ) : (
            <div className="flex items-center justify-center h-full text-muted-foreground text-sm">
              請選擇上方選項來探索此經文
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
