"use client"

import { useState } from "react"
import type { BibleBook, Language } from "@/lib/types"
import { BookSelector } from "./book-selector"
import { ChapterSelector } from "./chapter-selector"
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet"

interface NavigationDrawerProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onNavigate: (book: string, chapter: number) => void
  currentBook?: string
  currentChapter?: number
  primaryLanguage?: Language
}

export function NavigationDrawer({
  open,
  onOpenChange,
  onNavigate,
  currentBook,
  currentChapter,
  primaryLanguage = "cuv",
}: NavigationDrawerProps) {
  const [selectedBook, setSelectedBook] = useState<BibleBook | null>(null)

  const handleSelectBook = (book: BibleBook) => {
    if (book.hasData) {
      setSelectedBook(book)
    }
  }

  const handleSelectChapter = (chapter: number) => {
    if (selectedBook) {
      onNavigate(selectedBook.name, chapter)
      onOpenChange(false)
      setSelectedBook(null)
    }
  }

  const handleBack = () => {
    setSelectedBook(null)
  }

  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen) {
      setSelectedBook(null)
    }
    onOpenChange(newOpen)
  }

  return (
    <Sheet open={open} onOpenChange={handleOpenChange}>
      <SheetContent side="left" className="w-full sm:max-w-md p-0 pt-12">
        <SheetHeader className="sr-only">
          <SheetTitle>{selectedBook ? "Select Chapter" : "Select Book"}</SheetTitle>
        </SheetHeader>
        {selectedBook ? (
          <ChapterSelector
            book={selectedBook}
            onSelectChapter={handleSelectChapter}
            onBack={handleBack}
            selectedChapter={currentChapter}
            primaryLanguage={primaryLanguage}
          />
        ) : (
          <BookSelector onSelectBook={handleSelectBook} selectedBook={currentBook} primaryLanguage={primaryLanguage} />
        )}
      </SheetContent>
    </Sheet>
  )
}
