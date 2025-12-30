import React from "react"
import { VerseLink } from "./verse-link"

interface MarkdownRendererProps {
  content: string
  currentBook?: string
  currentChapter?: number
}

export function MarkdownRenderer({ content, currentBook, currentChapter }: MarkdownRendererProps) {
  // Split content into blocks (paragraphs, headings, lists)
  const blocks = content.split("\n\n").filter((p) => p.trim())

  return (
    <div className="space-y-4">
      {blocks.map((block, blockIndex) => {
        // Check if it's a heading
        const headingMatch = block.match(/^(#{1,6})\s+(.+)$/)
        if (headingMatch) {
          const level = headingMatch[1].length
          const text = headingMatch[2]
          const HeadingTag = `h${level}` as keyof React.JSX.IntrinsicElements
          const sizeClasses = {
            1: "text-2xl font-bold",
            2: "text-xl font-bold",
            3: "text-lg font-semibold",
            4: "text-base font-semibold",
            5: "text-sm font-semibold",
            6: "text-sm font-medium",
          }
          return (
            <HeadingTag key={blockIndex} className={`${sizeClasses[level as keyof typeof sizeClasses]} text-primary`}>
              {renderInlineMarkdown(text, currentBook, currentChapter)}
            </HeadingTag>
          )
        }

        // Check if it's a numbered list item
        if (/^\d+\./.test(block.trim())) {
          const items = block.split(/\n(?=\d+\.)/).filter((item) => item.trim())
          return (
            <ol key={blockIndex} className="list-decimal list-inside space-y-2 text-foreground">
              {items.map((item, iIndex) => {
                const text = item.replace(/^\d+\.\s*/, "")
                return <li key={iIndex}>{renderInlineMarkdown(text, currentBook, currentChapter)}</li>
              })}
            </ol>
          )
        }

        // Check if it's a bullet list
        if (/^[-*]/.test(block.trim())) {
          const items = block.split(/\n(?=[-*])/).filter((item) => item.trim())
          return (
            <ul key={blockIndex} className="list-disc list-inside space-y-2 text-foreground">
              {items.map((item, iIndex) => {
                const text = item.replace(/^[-*]\s*/, "")
                return <li key={iIndex}>{renderInlineMarkdown(text, currentBook, currentChapter)}</li>
              })}
            </ul>
          )
        }

        // Regular paragraph
        return (
          <p key={blockIndex} className="text-foreground leading-relaxed">
            {renderInlineMarkdown(block, currentBook, currentChapter)}
          </p>
        )
      })}
    </div>
  )
}

function renderInlineMarkdown(text: string, currentBook?: string, currentChapter?: number) {
  const parts: (string | React.JSX.Element)[] = []
  let lastIndex = 0

  // Verse reference pattern: Chinese/English book name followed by chapter:verse
  const versePattern =
    /([一二三約翰彼得撒母耳列王紀歷代志哥林多帖撒羅尼迦提摩太]\s*)?([創出利民申約士路撒列王歷以尼斯伯約詩箴傳雅賽耶哀西但何珥阿俄拿彌鴻哈番該亞瑪馬可路約使羅林加弗腓西帖提多門希雅彼約猶啟][^0-9\s]{0,6}(?:記|書|篇|言|歌|傳|哀|行)?)\s+(\d+):(\d+)(?:-(\d+))?/g
  const formattingPattern = /(\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`)/g

  // Combine patterns
  const combinedPattern = new RegExp(`(${versePattern.source}|${formattingPattern.source})`, "g")

  let match
  while ((match = combinedPattern.exec(text)) !== null) {
    // Add text before match
    if (match.index > lastIndex) {
      parts.push(text.slice(lastIndex, match.index))
    }

    const fullMatch = match[0]

    // Check if it's a verse reference
    const verseMatch = fullMatch.match(versePattern)
    if (verseMatch && currentBook && currentChapter !== undefined) {
      parts.push(
        <VerseLink key={match.index} reference={fullMatch} currentBook={currentBook} currentChapter={currentChapter}>
          {fullMatch}
        </VerseLink>,
      )
    }
    // Check if it's bold
    else if (match[0].startsWith("**")) {
      const boldText = match[0].slice(2, -2)
      parts.push(
        <strong key={match.index} className="font-semibold text-primary">
          {boldText}
        </strong>,
      )
    }
    // Check if it's italic
    else if (match[0].startsWith("*")) {
      const italicText = match[0].slice(1, -1)
      parts.push(
        <em key={match.index} className="italic">
          {italicText}
        </em>,
      )
    }
    // Check if it's code
    else if (match[0].startsWith("`")) {
      const codeText = match[0].slice(1, -1)
      parts.push(
        <code key={match.index} className="bg-accent px-1 py-0.5 rounded text-sm">
          {codeText}
        </code>,
      )
    } else {
      parts.push(fullMatch)
    }

    lastIndex = combinedPattern.lastIndex
  }

  // Add remaining text
  if (lastIndex < text.length) {
    parts.push(text.slice(lastIndex))
  }

  return parts.length > 0 ? parts : text
}
