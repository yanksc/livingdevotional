"use client"

import { useEffect, useRef } from "react"
import type { ChatMessage } from "@/lib/types"
import { MarkdownRenderer } from "./markdown-renderer"
import { User, Bot } from "lucide-react"

interface VerseChatDisplayProps {
  messages: ChatMessage[]
  currentBook: string
  currentChapter: number
  isLoading?: boolean
}

export function VerseChatDisplay({ messages, currentBook, currentChapter, isLoading }: VerseChatDisplayProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" })
    }
  }, [messages, isLoading])

  if (messages.length === 0 && !isLoading) {
    return null
  }

  return (
    <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2">
      {messages
        .filter((msg) => msg.role !== "system")
        .map((message, index) => (
          <div
            key={index}
            className={`flex gap-2 ${message.role === "user" ? "justify-end" : "justify-start"}`}
          >
            {message.role === "assistant" && (
              <div className="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center mt-1">
                <Bot className="h-3.5 w-3.5 text-primary" />
              </div>
            )}

            <div
              className={`max-w-[85%] rounded-lg p-3 ${
                message.role === "user"
                  ? "bg-primary text-primary-foreground"
                  : "bg-gradient-to-br from-primary/5 to-accent/5 border border-primary/10"
              }`}
            >
              {message.role === "user" ? (
                <p className="text-sm whitespace-pre-wrap">{message.content}</p>
              ) : (
                <div className="prose prose-sm max-w-none text-sm">
                  <MarkdownRenderer
                    content={message.content}
                    currentBook={currentBook}
                    currentChapter={currentChapter}
                  />
                </div>
              )}
            </div>

            {message.role === "user" && (
              <div className="flex-shrink-0 w-6 h-6 rounded-full bg-primary flex items-center justify-center mt-1">
                <User className="h-3.5 w-3.5 text-primary-foreground" />
              </div>
            )}
          </div>
        ))}
      <div ref={messagesEndRef} />
    </div>
  )
}

