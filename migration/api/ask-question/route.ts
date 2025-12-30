import OpenAI from "openai"
import type { ChatMessage } from "@/lib/types"

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function POST(req: Request) {
  try {
    const { book, chapter, verseNumber, verseText, question, language, conversationHistory } = await req.json()

    // Build messages array for OpenAI
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = []

    // Add system message for context
    const systemMessage = `你是一位聖經學者和神學教師。你正在幫助讀者理解以下經文：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

請用繁體中文（台灣用語）提供簡潔且有幫助的回答。你的回答應該：
1. 直接回答讀者的問題
2. 提供相關的聖經背景和上下文
3. 如果適用，引用其他相關經文
4. 保持回答清晰、易懂且具有實用性`

    messages.push({ role: "system", content: systemMessage })

    // If there's conversation history, add it (excluding system messages)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      conversationHistory.forEach((msg: ChatMessage) => {
        if (msg.role !== "system") {
          messages.push({ role: msg.role, content: msg.content })
        }
      })
    }

    // Add the current question
    messages.push({ role: "user", content: question })

    const stream = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages,
      stream: true,
      stream_options: { include_usage: false },
      max_tokens: 800,
    })

    // Create a proper text stream for OpenAI responses
    const encoder = new TextEncoder()
    const readable = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of stream) {
            const text = chunk.choices[0]?.delta?.content
            if (text) {
              // Send each token immediately without buffering
              controller.enqueue(encoder.encode(text))
            }
          }
          controller.close()
        } catch (error) {
          controller.error(error)
        }
      },
    })

    return new Response(readable, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Transfer-Encoding": "chunked",
        "Cache-Control": "no-cache",
        "X-Content-Type-Options": "nosniff",
      },
    })
  } catch (error: any) {
    console.error("Failed to answer question:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}

