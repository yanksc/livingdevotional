"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Search, Loader2, BookOpen, Sparkles, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { getLocalizedBookName } from "@/lib/bible-data"
import type { Language } from "@/lib/types"

interface VerseResult {
  book: string
  chapter: number
  verse_number: number
  text_cuv: string
  text_niv: string
  reference: string
  relevance: string
}

interface SearchResponse {
  results: VerseResult[]
  message: string
}

interface BibleSearchDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  primaryLanguage?: Language
  secondaryLanguage?: Language
}

export function BibleSearchDialog({
  open,
  onOpenChange,
  primaryLanguage = "cuv",
  secondaryLanguage = "niv",
}: BibleSearchDialogProps) {
  const [question, setQuestion] = useState("")
  const [searching, setSearching] = useState(false)
  const [results, setResults] = useState<VerseResult[]>([])
  const [message, setMessage] = useState("")
  const router = useRouter()

  const handleSearch = async () => {
    if (!question.trim()) return

    setSearching(true)
    setResults([])
    setMessage("")

    try {
      const response = await fetch("/api/ai/bible-search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question, language: primaryLanguage }),
      })

      if (!response.ok) {
        throw new Error("搜尋失敗")
      }

      const data: SearchResponse = await response.json()
      setResults(data.results || [])
      setMessage(data.message || "")
    } catch (error) {
      console.error("Search error:", error)
      setMessage("搜尋失敗，請稍後再試")
    } finally {
      setSearching(false)
    }
  }

  const handleVerseClick = (book: string, chapter: number) => {
    router.push(`/read/${encodeURIComponent(book)}/${chapter}`)
    onOpenChange(false)
  }

  const getVerseText = (verse: VerseResult) => {
    if (primaryLanguage === "niv") return verse.text_niv
    if (primaryLanguage === "cuv") return verse.text_cuv
    return verse.text_cuv
  }

  const getSecondaryVerseText = (verse: VerseResult) => {
    if (secondaryLanguage === "none") return null
    if (secondaryLanguage === "niv") return verse.text_niv
    if (secondaryLanguage === "cuv") return verse.text_cuv
    return null
  }

  const getLocalizedReference = (verse: VerseResult) => {
    const localizedBook = getLocalizedBookName(verse.book, primaryLanguage)
    return `${localizedBook} ${verse.chapter}:${verse.verse_number}`
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4 animate-in fade-in">
      <div className="bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-6 border-b bg-gradient-to-br from-primary/5 to-accent/5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg gradient-primary">
                <Search className="h-5 w-5 text-white" />
              </div>
              <div>
                <h2 className="text-xl font-bold gradient-text">聖經智能搜尋</h2>
                <p className="text-sm text-muted-foreground">提問任何聖經相關的問題</p>
              </div>
            </div>
            <Button variant="ghost" size="icon" onClick={() => onOpenChange(false)}>
              <X className="h-5 w-5" />
            </Button>
          </div>

          {/* Search Input */}
          <div className="flex gap-2">
            <Input
              placeholder="例如：如何面對困難？什麼是愛？神的應許是什麼？"
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              className="flex-1 border-primary/30 focus:border-primary"
              disabled={searching}
            />
            <Button onClick={handleSearch} disabled={searching || !question.trim()} className="gradient-primary gap-2">
              {searching ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span className="hidden sm:inline">搜尋中...</span>
                </>
              ) : (
                <>
                  <Search className="h-4 w-4" />
                  <span className="hidden sm:inline">搜尋</span>
                </>
              )}
            </Button>
          </div>
        </div>

        {/* Results */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {/* Results List */}
          {results.length > 0 && (
            <div className="space-y-3">
              <h3 className="text-sm font-semibold text-foreground">找到 {results.length} 節相關經文</h3>
              {results.map((verse, idx) => (
                <Card
                  key={idx}
                  className="border-primary/20 hover:border-primary/40 hover:shadow-lg transition-all cursor-pointer group"
                  onClick={() => handleVerseClick(verse.book, verse.chapter)}
                >
                  <CardContent className="p-4 space-y-3">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white bg-primary rounded px-2 py-0.5">#{idx + 1}</span>
                          <span className="text-sm font-bold text-primary">{getLocalizedReference(verse)}</span>
                        </div>
                        <p className="text-sm leading-relaxed text-foreground">{getVerseText(verse)}</p>
                        {getSecondaryVerseText(verse) && secondaryLanguage !== "none" && (
                          <p className="text-xs leading-relaxed text-muted-foreground italic border-l-2 border-primary/20 pl-3">
                            {getSecondaryVerseText(verse)}
                          </p>
                        )}
                      </div>
                      <BookOpen className="h-4 w-4 text-primary/50 group-hover:text-primary transition-colors flex-shrink-0" />
                    </div>
                    {verse.relevance && (
                      <div className="pt-2 border-t border-primary/10">
                        <p className="text-xs text-muted-foreground flex items-start gap-2">
                          <Sparkles className="h-3 w-3 mt-0.5 flex-shrink-0 text-accent" />
                          <span>{verse.relevance}</span>
                        </p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Message */}
          {message && results.length === 0 && !searching && (
            <div className="text-center py-12">
              <div className="p-4 rounded-full bg-muted/50 w-16 h-16 mx-auto mb-4 flex items-center justify-center">
                <Search className="h-8 w-8 text-muted-foreground" />
              </div>
              <p className="text-muted-foreground">{message}</p>
              <p className="text-xs text-muted-foreground mt-2">試試更改搜尋詞彙或使用不同的關鍵字</p>
            </div>
          )}

          {/* Initial State */}
          {!searching && results.length === 0 && !message && (
            <div className="text-center py-12 space-y-4">
              <div className="p-4 rounded-full bg-gradient-to-br from-primary/10 to-accent/10 w-20 h-20 mx-auto flex items-center justify-center">
                <Search className="h-10 w-10 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold text-foreground mb-2">開始你的聖經探索之旅</h3>
                <p className="text-sm text-muted-foreground">在上方輸入問題，我們會為你找到最相關的經文</p>
              </div>
              <div className="space-y-2 max-w-md mx-auto">
                <p className="text-xs font-semibold text-muted-foreground text-left">試試這些問題：</p>
                <div className="space-y-2">
                  {[
                    "如何面對生活中的困難？",
                    "什麼是真正的愛？",
                    "神對我的人生有什麼計劃？",
                    "如何獲得內心的平安？",
                  ].map((example, idx) => (
                    <button
                      key={idx}
                      onClick={() => setQuestion(example)}
                      className="w-full text-left px-4 py-2 rounded-lg bg-muted/50 hover:bg-muted text-sm text-foreground hover:text-primary transition-colors"
                    >
                      {example}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Loading State */}
          {searching && (
            <div className="text-center py-12">
              <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto mb-4" />
              <p className="text-muted-foreground">正在搜尋相關經文...</p>
              <p className="text-xs text-muted-foreground mt-2">AI 正在分析你的問題</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

