"use client"

import { useState } from "react"
import {
  getOldTestamentBooks,
  getNewTestamentBooks,
  getLocalizedBookName,
  getLocalizedTestamentName,
} from "@/lib/bible-data"
import type { BibleBook, Language } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { BookOpen, ChevronRight } from "lucide-react"

interface BookSelectorProps {
  onSelectBook: (book: BibleBook) => void
  selectedBook?: string
  primaryLanguage?: Language
}

export function BookSelector({ onSelectBook, selectedBook, primaryLanguage = "cuv" }: BookSelectorProps) {
  const [testament, setTestament] = useState<"Old" | "New">("New")

  const books = testament === "Old" ? getOldTestamentBooks() : getNewTestamentBooks()

  const oldTestamentLabel = getLocalizedTestamentName("Old", primaryLanguage)
  const newTestamentLabel = getLocalizedTestamentName("New", primaryLanguage)
  const chapterLabel = primaryLanguage === "cuv" || primaryLanguage === "cu1" ? "章" : "chapter"
  const chaptersLabel = primaryLanguage === "cuv" || primaryLanguage === "cu1" ? "章" : "chapters"

  return (
    <div className="flex flex-col h-[100dvh]">
      <div className="flex gap-2 p-4 border-b border-border/50 flex-shrink-0 bg-gradient-to-b from-background to-background/80">
        <Button
          variant={testament === "Old" ? "default" : "outline"}
          onClick={() => setTestament("Old")}
          className={`flex-1 ${
            testament === "Old"
              ? "bg-gradient-to-r from-primary via-primary/90 to-accent hover:from-primary/95 hover:via-primary/85 hover:to-accent/95 shadow-lg"
              : "hover:bg-gradient-to-r hover:from-primary/10 hover:to-accent/10"
          }`}
        >
          {oldTestamentLabel}
        </Button>
        <Button
          variant={testament === "New" ? "default" : "outline"}
          onClick={() => setTestament("New")}
          className={`flex-1 ${
            testament === "New"
              ? "bg-gradient-to-r from-primary via-primary/90 to-accent hover:from-primary/95 hover:via-primary/85 hover:to-accent/95 shadow-lg"
              : "hover:bg-gradient-to-r hover:from-primary/10 hover:to-accent/10"
          }`}
        >
          {newTestamentLabel}
        </Button>
      </div>

      {/* Book List */}
      <ScrollArea className="flex-1 overflow-y-auto">
        <div className="p-4 space-y-2 pb-20">
          {books.map((book) => (
            <button
              key={book.name}
              onClick={() => onSelectBook(book)}
              disabled={!book.hasData}
              className={`w-full flex items-center justify-between p-3 rounded-lg border transition-all ${
                book.hasData
                  ? "hover:border-primary/50 hover:bg-gradient-to-r hover:from-primary/15 hover:to-accent/15 hover:shadow-sm"
                  : "opacity-50 cursor-not-allowed"
              } ${
                selectedBook === book.name
                  ? "border-primary/70 bg-gradient-to-r from-primary/20 to-accent/20 shadow-md"
                  : "border-border/50 bg-card/50"
              }`}
            >
              <div className="flex items-center gap-3 flex-1 min-w-0">
                <BookOpen
                  className={`h-5 w-5 flex-shrink-0 ${selectedBook === book.name ? "text-primary" : "text-muted-foreground"}`}
                />
                <div
                  className={`font-medium truncate ${selectedBook === book.name ? "text-primary" : "text-foreground"}`}
                >
                  {getLocalizedBookName(book.name, primaryLanguage)}
                  <span className="text-sm text-muted-foreground ml-2">
                    {book.chapters} {book.chapters === 1 ? chapterLabel : chaptersLabel}
                  </span>
                </div>
              </div>
              {book.hasData && (
                <div className="flex items-center gap-2">
                  <ChevronRight
                    className={`h-4 w-4 ${selectedBook === book.name ? "text-primary" : "text-muted-foreground"}`}
                  />
                </div>
              )}
            </button>
          ))}
        </div>
      </ScrollArea>
    </div>
  )
}
