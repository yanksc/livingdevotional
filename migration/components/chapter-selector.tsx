"use client"

import type { BibleBook, Language } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ArrowLeft } from "lucide-react"
import { getLocalizedBookName } from "@/lib/bible-data"

interface ChapterSelectorProps {
  book: BibleBook
  onSelectChapter: (chapter: number) => void
  onBack: () => void
  selectedChapter?: number
  primaryLanguage?: Language
}

export function ChapterSelector({
  book,
  onSelectChapter,
  onBack,
  selectedChapter,
  primaryLanguage = "cuv",
}: ChapterSelectorProps) {
  const chapters = Array.from({ length: book.chapters }, (_, i) => i + 1)

  const localizedBookName = getLocalizedBookName(book.name, primaryLanguage)
  const selectChapterLabel =
    primaryLanguage === "cuv" || primaryLanguage === "cu1" ? "選擇章節閱讀" : "Select a chapter to read"
  const comingSoonMessage =
    primaryLanguage === "cuv" || primaryLanguage === "cu1"
      ? "此書卷即將推出。目前僅提供約翰福音。"
      : "This book is coming soon. Currently only the Gospel of John is available."

  return (
    <div className="flex flex-col h-[100dvh]">
      {/* Header */}
      <div className="flex items-center gap-3 p-4 border-b border-border flex-shrink-0 bg-gradient-to-r from-background via-primary/5 to-accent/5">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h2 className="font-semibold text-lg">{localizedBookName}</h2>
          <p className="text-sm text-muted-foreground">{selectChapterLabel}</p>
        </div>
      </div>

      {/* Chapter Grid */}
      <ScrollArea className="flex-1 overflow-y-auto">
        <div className="p-4 pb-20">
          <div className="grid grid-cols-4 gap-3 sm:grid-cols-5 md:grid-cols-6">
            {chapters.map((chapter) => (
              <button
                key={chapter}
                onClick={() => onSelectChapter(chapter)}
                disabled={!book.hasData}
                className={`aspect-square flex items-center justify-center rounded-lg border text-lg font-medium transition-all ${
                  selectedChapter === chapter
                    ? "border-primary/70 bg-gradient-to-br from-primary/90 to-accent shadow-lg text-primary-foreground"
                    : book.hasData
                      ? "border-border bg-card hover:border-primary/50 hover:bg-gradient-to-br hover:from-primary/15 hover:to-accent/15 hover:shadow-md"
                      : "border-border bg-muted text-muted-foreground cursor-not-allowed opacity-50"
                }`}
              >
                {chapter}
              </button>
            ))}
          </div>
          {!book.hasData && (
            <div className="mt-6 p-4 rounded-lg bg-gradient-to-r from-muted to-muted/80 text-center border border-border/50">
              <p className="text-sm text-muted-foreground">{comingSoonMessage}</p>
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
