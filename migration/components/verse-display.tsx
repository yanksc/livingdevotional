"use client"

import { useState, useEffect, useMemo, useCallback } from "react"
import type { BibleVerse, Language } from "@/lib/types"
import { cn } from "@/lib/utils"
import { getLocalizedBookName } from "@/lib/bible-data"
import { Button } from "@/components/ui/button"
import {
  Sparkles,
  BookOpen,
  MessageCircleQuestion,
  Loader2,
  ChevronDown,
  ChevronUp,
  ExternalLink,
  Bookmark,
  BookmarkCheck,
  Trash2,
  Send,
} from "lucide-react"
import { MarkdownRenderer } from "./markdown-renderer"
import { Textarea } from "@/components/ui/textarea"
import { VerseLink } from "./verse-link"
import { Label } from "@/components/ui/label"
import { VerseChatDisplay } from "./verse-chat-display"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { useRouter } from "next/navigation"
import { useVerseExplanation } from "@/hooks/use-verse-explanation"
import { useRelatedVerses } from "@/hooks/use-related-verses"
import { useVerseQuestion } from "@/hooks/use-verse-question"
import { useBookmark } from "@/hooks/use-bookmark"
import { useChapterSummary } from "@/hooks/use-chapter-summary"

interface VerseDisplayProps {
  verses: BibleVerse[]
  primaryLanguage: Language
  secondaryLanguage: Language
  currentBook: string
  currentChapter: number
  targetVerseNumber?: number | null
  onVerseSelected?: () => void
  bookId: string // Add bookId prop (English name from URL)
}

export function VerseDisplay({
  verses,
  primaryLanguage,
  secondaryLanguage,
  currentBook,
  currentChapter,
  targetVerseNumber,
  onVerseSelected,
  bookId, // Receive bookId prop
}: VerseDisplayProps) {
  const [selectedVerseId, setSelectedVerseId] = useState<string | null>(null)
  const [expandedVerseId, setExpandedVerseId] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<"explain" | "related" | "question" | "bookmark">("explain")
  const [chapterSummaryExpanded, setChapterSummaryExpanded] = useState(false)
  
  const router = useRouter()

  // Memoize text getter functions to avoid recreating them on every render
  const getPrimaryText = useCallback((verse: BibleVerse) => {
    if (primaryLanguage === "niv") return verse.text_niv
    if (primaryLanguage === "cu1") return verse.text_cu1
    return verse.text_cuv
  }, [primaryLanguage])

  const getSecondaryText = useCallback((verse: BibleVerse) => {
    if (secondaryLanguage === "niv") return verse.text_niv
    if (secondaryLanguage === "cu1") return verse.text_cu1
    return verse.text_cuv
  }, [secondaryLanguage])

  // Custom hooks for feature logic
  const explanationHook = useVerseExplanation({ primaryLanguage, getPrimaryText })
  const relatedVersesHook = useRelatedVerses({ primaryLanguage, getPrimaryText })
  const questionHook = useVerseQuestion({ primaryLanguage, getPrimaryText })
  const bookmarkHook = useBookmark({ bookId, currentChapter, verses, getPrimaryText })
  const chapterSummaryHook = useChapterSummary({ primaryLanguage })

  const handleVerseClick = (verseId: string) => {
    if (selectedVerseId === verseId) {
      setSelectedVerseId(null)
      setExpandedVerseId(null)
    } else {
      setSelectedVerseId(verseId)
      setExpandedVerseId(null)
      // Reset all hook states
      explanationHook.reset()
      relatedVersesHook.reset()
      questionHook.reset()
      onVerseSelected?.()
    }
  }

  const handleExplain = async (verse: BibleVerse) => {
    setActiveTab("explain")
    setExpandedVerseId(verse.id)
    
    // Load history first if not already loaded
    if (explanationHook.conversationHistory.length === 0) {
      await explanationHook.loadHistory(verse)
    }
    
    // Only generate new explanation if no history exists
    if (explanationHook.conversationHistory.length === 0) {
      await explanationHook.explainVerse(verse)
    }
  }
  
  const handleFollowUpExplanation = async (verse: BibleVerse) => {
    if (!explanationHook.followUpPrompt.trim()) return
    await explanationHook.explainVerse(verse, explanationHook.followUpPrompt)
  }

  const handleFindRelated = async (verse: BibleVerse) => {
    setActiveTab("related")
    setExpandedVerseId(verse.id)
    await relatedVersesHook.findRelated(verse)
  }

  const handleQuestion = async (verse: BibleVerse) => {
    setActiveTab("question")
    setExpandedVerseId(verse.id)
    
    // Load history first if not already loaded
    if (questionHook.conversationHistory.length === 0) {
      await questionHook.loadHistory(verse)
    }
    
    // Generate suggestions if no history exists
    if (questionHook.conversationHistory.length === 0 && questionHook.suggestedQuestions.length === 0) {
      await questionHook.generateSuggestions(verse)
    }
  }

  const handleAskQuestion = async (verse: BibleVerse, customQuestion?: string) => {
    await questionHook.askQuestion(verse, customQuestion)
  }

  const handleLoadMoreRelated = async (verse: BibleVerse) => {
    await relatedVersesHook.loadMore(verse)
  }

  const handleBookmark = async (verse: BibleVerse) => {
    try {
      const result = await bookmarkHook.toggleBookmark(verse)
      setActiveTab("bookmark")
      setExpandedVerseId(verse.id)
    } catch (error) {
      // Error handling is done in the hook
    }
  }

  const handleSaveBookmarkNote = async (verse: BibleVerse) => {
    try {
      await bookmarkHook.saveNote(verse)
    } catch (error) {
      // Error handling is done in the hook
    }
  }

  const handleToggleChapterSummary = async () => {
    if (!chapterSummaryExpanded) {
      // Expanding - fetch summary if not already loaded
      setChapterSummaryExpanded(true)
      if (!chapterSummaryHook.summary && !chapterSummaryHook.loading) {
        await chapterSummaryHook.summarizeChapter(currentBook, currentChapter)
      }
    } else {
      // Collapsing
      setChapterSummaryExpanded(false)
    }
  }

  const showSecondary = useMemo(() => secondaryLanguage !== "none", [secondaryLanguage])

  useEffect(() => {
    if (targetVerseNumber && verses.length > 0) {
      const targetVerse = verses.find((v) => v.verse_number === targetVerseNumber)
      if (targetVerse) {
        setSelectedVerseId(targetVerse.id)
        setExpandedVerseId(null)
        explanationHook.reset()
        relatedVersesHook.reset()
        questionHook.reset()
        onVerseSelected?.()
      }
    }
  }, [targetVerseNumber, verses, onVerseSelected, explanationHook, relatedVersesHook, questionHook])

  useEffect(() => {
    const handleSelectVerse = (e: CustomEvent) => {
      const verseNumber = e.detail.verseNumber
      const targetVerse = verses.find((v) => v.verse_number === verseNumber)
      if (targetVerse) {
        setSelectedVerseId(targetVerse.id)
        setExpandedVerseId(null)
        explanationHook.reset()
        relatedVersesHook.reset()
        questionHook.reset()
      }
    }

    window.addEventListener("selectVerse", handleSelectVerse as EventListener)
    return () => {
      window.removeEventListener("selectVerse", handleSelectVerse as EventListener)
    }
  }, [verses, explanationHook, relatedVersesHook, questionHook])

  // Aggregate loading and error states from all hooks
  const loading = explanationHook.loading || relatedVersesHook.loading || questionHook.loading
  const error = explanationHook.error || relatedVersesHook.error || questionHook.error || bookmarkHook.error

  return (
    <>
      <AlertDialog open={bookmarkHook.showLoginPrompt} onOpenChange={bookmarkHook.setShowLoginPrompt}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>需要登入</AlertDialogTitle>
            <AlertDialogDescription>
              您需要登入才能使用書籤功能。登入後，您可以在不同裝置間同步您的書籤和筆記。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>取消</AlertDialogCancel>
            <AlertDialogAction onClick={() => router.push("/auth/login")}>前往登入</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Chapter Summary Section */}
      <div className="mb-4">
        <Button
          variant="outline"
          onClick={handleToggleChapterSummary}
          disabled={chapterSummaryHook.loading}
          className="w-full justify-between text-sm font-medium"
        >
          <span className="flex items-center gap-2">
            <BookOpen className="h-4 w-4" />
            章節摘要
          </span>
          {chapterSummaryHook.loading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : chapterSummaryExpanded ? (
            <ChevronUp className="h-4 w-4" />
          ) : (
            <ChevronDown className="h-4 w-4" />
          )}
        </Button>

        {chapterSummaryExpanded && (
          <div className="mt-2 bg-gradient-to-br from-background to-primary/5 border border-primary/10 rounded-lg p-4 shadow-sm">
            {chapterSummaryHook.error && (
              <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-2 mb-3">
                <p className="text-xs text-destructive">{chapterSummaryHook.error}</p>
              </div>
            )}

            {chapterSummaryHook.loading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
              </div>
            ) : chapterSummaryHook.summary ? (
              <div className="prose prose-sm max-w-none text-sm leading-relaxed">
                <MarkdownRenderer
                  content={chapterSummaryHook.summary}
                  currentBook={currentBook}
                  currentChapter={currentChapter}
                />
              </div>
            ) : null}
          </div>
        )}
      </div>

      <div className="space-y-1.5">
        {verses.map((verse) => {
          const isSelected = selectedVerseId === verse.id
          const isExpanded = expandedVerseId === verse.id
          const isBookmarked = bookmarkHook.isBookmarked(verse.id)

          return (
            <div key={verse.id}>
              {/* Verse Content */}
              <div
                id={`verse-${verse.verse_number}`}
                className={cn(
                  "group relative cursor-pointer rounded-lg p-1 sm:p-1.5 transition-all",
                  "hover:bg-gradient-to-r hover:from-primary/10 hover:to-accent/10",
                  isSelected && "bg-gradient-to-r from-primary/15 to-accent/15 shadow-sm",
                )}
                onClick={() => handleVerseClick(verse.id)}
              >
                <div className="flex gap-0.5 sm:gap-1">
                  <div className="flex items-center gap-1 w-5 sm:w-6 flex-shrink-0">
                    <span className="inline-block text-sm font-medium text-muted-foreground select-none">
                      {verse.verse_number}
                    </span>
                    {isBookmarked && <BookmarkCheck className="h-3 w-3 text-primary/60 flex-shrink-0" />}
                  </div>

                  <div className="flex-1">
                    <div className="verse-text text-[15px] sm:text-base font-normal text-foreground leading-snug">
                      {getPrimaryText(verse)}
                    </div>

                    {showSecondary && (
                      <div className="mt-0.5">
                        <span className="verse-text text-[13px] sm:text-sm text-muted-foreground leading-snug">
                          {getSecondaryText(verse)}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                {isSelected && (
                  <div className="mt-2 pt-2 flex flex-col items-center gap-2">
                    <div className="w-16 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
                    <div className="flex gap-2 w-full">
                      <Button
                        variant={activeTab === "explain" && isExpanded ? "default" : "outline"}
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleExplain(verse)
                        }}
                        disabled={loading}
                        className="flex-1 text-xs"
                      >
                        <Sparkles className="h-3 w-3 mr-1" />
                        解釋經文
                      </Button>
                      <Button
                        variant={activeTab === "related" && isExpanded ? "default" : "outline"}
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleFindRelated(verse)
                        }}
                        disabled={loading}
                        className="flex-1 text-xs"
                      >
                        <BookOpen className="h-3 w-3 mr-1" />
                        相關經文
                      </Button>
                      <Button
                        variant={activeTab === "question" && isExpanded ? "default" : "outline"}
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleQuestion(verse)
                        }}
                        disabled={loading}
                        className="flex-1 text-xs"
                      >
                        <MessageCircleQuestion className="h-3 w-3 mr-1" />
                        提問
                      </Button>
                      <Button
                        variant={activeTab === "bookmark" && isExpanded ? "default" : "outline"}
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleBookmark(verse)
                        }}
                        disabled={bookmarkHook.saving}
                        className={cn("text-xs px-2", isBookmarked && "text-primary border-primary")}
                      >
                        {bookmarkHook.saving ? (
                          <Loader2 className="h-3 w-3 animate-spin" />
                        ) : isBookmarked ? (
                          <BookmarkCheck className="h-3 w-3" />
                        ) : (
                          <Bookmark className="h-3 w-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                )}
              </div>

              {isExpanded && (
                <div className="mt-2 mb-3 mx-1 sm:mx-2 bg-gradient-to-br from-background to-primary/5 border border-primary/10 rounded-lg p-3 shadow-sm">
                  {error && (
                    <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-2 mb-3">
                      <p className="text-xs text-destructive">{error}</p>
                    </div>
                  )}

                  {loading ? (
                    <div className="flex items-center justify-center py-8">
                      <Loader2 className="h-6 w-6 animate-spin text-primary" />
                    </div>
                  ) : activeTab === "explain" ? (
                    <div className="space-y-3">
                      {/* Display conversation history */}
                      {explanationHook.conversationHistory.length > 0 && (
                        <div className="mb-3">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-xs font-medium text-muted-foreground">對話記錄</span>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={async (e) => {
                                e.stopPropagation()
                                await explanationHook.clearHistory()
                              }}
                              className="h-6 px-2 text-xs text-destructive hover:text-destructive"
                            >
                              <Trash2 className="h-3 w-3 mr-1" />
                              清除對話
                            </Button>
                          </div>
                          <VerseChatDisplay
                            messages={explanationHook.conversationHistory}
                            currentBook={currentBook}
                            currentChapter={currentChapter}
                            isLoading={explanationHook.loading}
                          />
                        </div>
                      )}

                      {/* Show current explanation if streaming */}
                      {explanationHook.loading && explanationHook.explanation && (
                        <div className="bg-gradient-to-br from-primary/5 to-accent/5 border border-primary/10 rounded-lg p-3">
                          <div className="prose prose-sm max-w-none text-sm">
                            <MarkdownRenderer
                              content={explanationHook.explanation}
                              currentBook={currentBook}
                              currentChapter={currentChapter}
                            />
                          </div>
                        </div>
                      )}

                      {/* Follow-up input */}
                      {explanationHook.conversationHistory.length > 0 && !explanationHook.loading && (
                        <div className="space-y-2">
                          <label className="text-xs font-medium text-foreground">繼續討論：</label>
                          <div className="flex gap-2">
                            <Textarea
                              value={explanationHook.followUpPrompt}
                              onChange={(e) => explanationHook.setFollowUpPrompt(e.target.value)}
                              placeholder="例如：可以更詳細說明嗎？或 這如何應用在現代生活？"
                              className="min-h-[60px] text-sm resize-none flex-1"
                              disabled={explanationHook.loading}
                              onClick={(e) => e.stopPropagation()}
                              onKeyDown={(e) => {
                                if (e.key === "Enter" && !e.shiftKey) {
                                  e.preventDefault()
                                  handleFollowUpExplanation(verse)
                                }
                              }}
                            />
                            <Button
                              onClick={(e) => {
                                e.stopPropagation()
                                handleFollowUpExplanation(verse)
                              }}
                              disabled={explanationHook.loading || !explanationHook.followUpPrompt.trim()}
                              size="sm"
                              className="self-end px-3"
                            >
                              <Send className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                      )}
                    </div>
                  ) : activeTab === "related" && relatedVersesHook.relatedVerses.length > 0 ? (
                    <div className="space-y-3">
                      {relatedVersesHook.relatedVerses.map((related, index) => (
                        <div
                          key={index}
                          className="bg-gradient-to-br from-primary/5 to-accent/5 border border-primary/10 rounded-lg p-3 relative"
                        >
                          <div className="flex items-start justify-between gap-2 mb-1">
                            <VerseLink
                              reference={related.reference}
                              currentBook={currentBook}
                              currentChapter={currentChapter}
                            >
                              <h4 className="font-semibold text-primary text-sm hover:text-primary/80 transition-colors">
                                {related.reference}
                              </h4>
                            </VerseLink>
                            <VerseLink
                              reference={related.reference}
                              currentBook={currentBook}
                              currentChapter={currentChapter}
                            >
                              <ExternalLink className="h-4 w-4 text-primary hover:text-primary/80 transition-colors flex-shrink-0 cursor-pointer" />
                            </VerseLink>
                          </div>
                          <p className="text-xs text-muted-foreground mb-2 italic">{related.summary}</p>
                          <div className="text-xs prose prose-sm max-w-none">
                            <MarkdownRenderer
                              content={related.relevance}
                              currentBook={currentBook}
                              currentChapter={currentChapter}
                            />
                          </div>
                        </div>
                      ))}
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleLoadMoreRelated(verse)
                        }}
                        disabled={relatedVersesHook.loadingMore}
                        className="w-full text-xs"
                      >
                        {relatedVersesHook.loadingMore ? (
                          <>
                            <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                            載入更多...
                          </>
                        ) : (
                          <>
                            <ChevronDown className="h-3 w-3 mr-1" />
                            顯示更多相關經文
                          </>
                        )}
                      </Button>
                    </div>
                  ) : activeTab === "question" ? (
                    <div className="space-y-3">
                      {/* Display conversation history */}
                      {questionHook.conversationHistory.length > 0 && (
                        <div className="mb-3">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-xs font-medium text-muted-foreground">問答記錄</span>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={async (e) => {
                                e.stopPropagation()
                                await questionHook.clearHistory()
                              }}
                              className="h-6 px-2 text-xs text-destructive hover:text-destructive"
                            >
                              <Trash2 className="h-3 w-3 mr-1" />
                              清除對話
                            </Button>
                          </div>
                          <VerseChatDisplay
                            messages={questionHook.conversationHistory}
                            currentBook={currentBook}
                            currentChapter={currentChapter}
                            isLoading={questionHook.loading}
                          />
                        </div>
                      )}

                      {/* Show current answer if streaming */}
                      {questionHook.loading && questionHook.answer && (
                        <div className="bg-gradient-to-br from-primary/5 to-accent/5 border border-primary/10 rounded-lg p-3">
                          <div className="prose prose-sm max-w-none text-sm">
                            <MarkdownRenderer
                              content={questionHook.answer}
                              currentBook={currentBook}
                              currentChapter={currentChapter}
                            />
                          </div>
                        </div>
                      )}

                      {/* Suggested questions (only show if no history) */}
                      {questionHook.conversationHistory.length === 0 && questionHook.loadingSuggestions ? (
                        <div className="flex items-center justify-center py-4">
                          <Loader2 className="h-4 w-4 animate-spin text-primary mr-2" />
                          <span className="text-xs text-muted-foreground">生成建議問題中...</span>
                        </div>
                      ) : (
                        questionHook.conversationHistory.length === 0 &&
                        questionHook.suggestedQuestions.length > 0 && (
                          <div className="space-y-2">
                            <Label className="text-xs font-medium text-muted-foreground">建議問題：</Label>
                            <div className="flex flex-col gap-2">
                              {questionHook.suggestedQuestions.map((q, index) => (
                                <Button
                                  key={index}
                                  variant="outline"
                                  size="sm"
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    handleAskQuestion(verse, q)
                                  }}
                                  disabled={loading}
                                  className="text-xs justify-start h-auto py-2 px-3 whitespace-normal text-left"
                                >
                                  {q}
                                </Button>
                              ))}
                            </div>
                          </div>
                        )
                      )}

                      {/* Question input */}
                      <div>
                        <label className="text-xs font-medium text-foreground mb-1.5 block">
                          {questionHook.conversationHistory.length > 0 ? "繼續提問：" : "輸入您的問題："}
                        </label>
                        <div className="flex gap-2">
                          <Textarea
                            value={questionHook.question}
                            onChange={(e) => questionHook.setQuestion(e.target.value)}
                            placeholder="例如：這段經文在當時的背景是什麼？"
                            className="min-h-[60px] text-sm resize-none flex-1"
                            disabled={loading}
                            onClick={(e) => e.stopPropagation()}
                            onKeyDown={(e) => {
                              if (e.key === "Enter" && !e.shiftKey) {
                                e.preventDefault()
                                handleAskQuestion(verse)
                              }
                            }}
                          />
                          <Button
                            onClick={(e) => {
                              e.stopPropagation()
                              handleAskQuestion(verse)
                            }}
                            disabled={loading || !questionHook.question.trim()}
                            size="sm"
                            className="self-end px-3"
                          >
                            <Send className="h-3 w-3" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  ) : activeTab === "bookmark" ? (
                    <div className="space-y-3">
                      <div className="bg-primary/5 border border-primary/10 rounded-lg p-3">
                        <div className="flex items-center gap-2 mb-2">
                          <BookmarkCheck className="h-4 w-4 text-primary" />
                          <span className="text-xs font-medium text-primary">書籤已儲存</span>
                        </div>
                        <p className="text-xs text-muted-foreground">
                          {getLocalizedBookName(verse.book, primaryLanguage)} {verse.chapter}:{verse.verse_number}
                        </p>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-foreground mb-1.5 block">個人筆記（選填）：</label>
                        <Textarea
                          value={bookmarkHook.bookmarkNote}
                          onChange={(e) => bookmarkHook.setBookmarkNote(e.target.value)}
                          placeholder="輸入您的想法、感動或提醒..."
                          className="min-h-[100px] text-sm resize-none"
                          disabled={bookmarkHook.saving}
                          onClick={(e) => e.stopPropagation()}
                        />
                      </div>
                      <Button
                        onClick={(e) => {
                          e.stopPropagation()
                          handleSaveBookmarkNote(verse)
                        }}
                        disabled={bookmarkHook.saving}
                        size="sm"
                        className="w-full text-xs"
                      >
                        {bookmarkHook.saving ? (
                          <>
                            <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                            儲存中...
                          </>
                        ) : (
                          "儲存筆記"
                        )}
                      </Button>
                    </div>
                  ) : null}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </>
  )
}
