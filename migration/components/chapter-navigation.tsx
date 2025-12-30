"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { ChevronLeft, ChevronRight, ChevronDown } from "lucide-react"
import { ScrollArea } from "@/components/ui/scroll-area"
import type { Language } from "@/lib/types"
import { getLocalizedBookName } from "@/lib/bible-data"

interface ChapterNavigationProps {
  currentChapter: number
  totalChapters: number
  onNavigate: (chapter: number) => void
  bookName?: string
  primaryLanguage?: Language
}

export function ChapterNavigation({
  currentChapter,
  totalChapters,
  onNavigate,
  bookName,
  primaryLanguage = "cuv",
}: ChapterNavigationProps) {
  const [selectorOpen, setSelectorOpen] = useState(false)
  const hasPrevious = currentChapter > 1
  const hasNext = currentChapter < totalChapters

  const chapters = Array.from({ length: totalChapters }, (_, i) => i + 1)
  const chapterLabel = primaryLanguage === "cuv" || primaryLanguage === "cu1" ? "章節" : "Chapter"

  const localizedBookName = bookName ? getLocalizedBookName(bookName, primaryLanguage) : ""

  const handleChapterSelect = (chapter: number) => {
    onNavigate(chapter)
    setSelectorOpen(false)
  }

  return (
    <>
      <div className="sticky bottom-0 border-t border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-4 py-4 max-w-3xl mx-auto">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => onNavigate(currentChapter - 1)}
            disabled={!hasPrevious}
            className="h-12 w-12 hover:bg-primary/10"
          >
            <ChevronLeft className="h-6 w-6" />
          </Button>

          <button
            onClick={() => setSelectorOpen(true)}
            className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors px-4 py-2 rounded-md hover:bg-accent/50"
          >
            <span>
              {chapterLabel} {currentChapter} / {totalChapters}
            </span>
            <ChevronDown className="h-4 w-4" />
          </button>

          <Button
            variant="ghost"
            size="icon"
            onClick={() => onNavigate(currentChapter + 1)}
            disabled={!hasNext}
            className="h-12 w-12 hover:bg-primary/10"
          >
            <ChevronRight className="h-6 w-6" />
          </Button>
        </div>
      </div>

      <Sheet open={selectorOpen} onOpenChange={setSelectorOpen}>
        <SheetContent side="bottom" className="h-[70vh]">
          <SheetHeader>
            <SheetTitle>
              {primaryLanguage === "cuv" || primaryLanguage === "cu1" ? "選擇章節" : "Select Chapter"}
              {localizedBookName && ` - ${localizedBookName}`}
            </SheetTitle>
          </SheetHeader>
          <ScrollArea className="h-[calc(70vh-80px)] mt-4">
            <div className="grid grid-cols-5 gap-2 p-4 sm:grid-cols-6 md:grid-cols-8">
              {chapters.map((chapter) => (
                <button
                  key={chapter}
                  onClick={() => handleChapterSelect(chapter)}
                  className={`aspect-square flex items-center justify-center rounded-lg border text-base font-medium transition-all ${
                    currentChapter === chapter
                      ? "border-primary/70 bg-gradient-to-br from-primary/90 to-accent shadow-lg text-primary-foreground"
                      : "border-border bg-card hover:border-primary/50 hover:bg-gradient-to-br hover:from-primary/20 hover:to-accent/20 hover:shadow-md"
                  }`}
                >
                  {chapter}
                </button>
              ))}
            </div>
          </ScrollArea>
        </SheetContent>
      </Sheet>
    </>
  )
}
