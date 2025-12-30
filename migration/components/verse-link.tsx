"use client"

import type React from "react"

import Link from "next/link"
import { parseVerseReference, isSameChapter, getVerseUrl, getVerseAnchor } from "@/lib/verse-reference-parser"

interface VerseLinkProps {
  reference: string
  currentBook: string
  currentChapter: number
  children: React.ReactNode
}

export function VerseLink({ reference, currentBook, currentChapter, children }: VerseLinkProps) {
  const parsed = parseVerseReference(reference)

  if (!parsed) {
    // If we can't parse it, just return the text
    return <span>{children}</span>
  }

  const sameCh = isSameChapter(parsed, currentBook, currentChapter)

  if (sameCh) {
    // Same chapter - use anchor link with smooth scroll
    const anchor = getVerseAnchor(parsed.verse)
    return (
      <a
        href={anchor}
        onClick={(e) => {
          e.preventDefault()
          e.stopPropagation()
          const element = document.querySelector(anchor)
          if (element) {
            element.scrollIntoView({ behavior: "smooth", block: "center" })
            // Add a highlight effect
            element.classList.add("verse-highlight")
            setTimeout(() => {
              element.classList.remove("verse-highlight")
            }, 2000)
            window.dispatchEvent(
              new CustomEvent("selectVerse", {
                detail: { verseNumber: parsed.verse },
              }),
            )
          }
        }}
        className="text-primary hover:text-primary/80 underline decoration-primary/30 hover:decoration-primary/60 transition-colors cursor-pointer font-medium"
      >
        {children}
      </a>
    )
  }

  // Different chapter - use Next.js Link
  const url = getVerseUrl(parsed)
  return (
    <Link
      href={url}
      onClick={(e) => e.stopPropagation()}
      className="text-primary hover:text-primary/80 underline decoration-primary/30 hover:decoration-primary/60 transition-colors font-medium"
    >
      {children}
    </Link>
  )
}
