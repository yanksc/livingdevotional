import OpenAI from "openai"
import type { ChatMessage } from "@/lib/types"

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function POST(req: Request) {
  try {
    const { book, chapter, verseNumber, verseText, language, conversationHistory, userPrompt } = await req.json()

    // Build messages array for OpenAI
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = []

    // Add system message for context
    const systemMessage = `你是一位聖經學者和神學教師。你正在幫助讀者理解以下經文：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

請用繁體中文（台灣用語）提供簡潔且有幫助的回答。`

    messages.push({ role: "system", content: systemMessage })

    // If there's conversation history, add it
    if (conversationHistory && Array.isArray(conversationHistory)) {
      conversationHistory.forEach((msg: ChatMessage) => {
        if (msg.role !== "system") {
          messages.push({ role: msg.role, content: msg.content })
        }
      })
    }

    // Add the current user prompt (either initial explanation or follow-up)
    if (userPrompt) {
      // Follow-up question/prompt
      messages.push({ role: "user", content: userPrompt })
    } else {
      // Initial explanation request
      const initialPrompt = `請根據這節經文的獨特性和重要性，選擇最能幫助讀者理解和應用的面向來解釋。
使用"這節經文"開頭，可能的面向包括（但不限於）：

- 當時歷史與文化背景
- 如果是比較難懂的經文的話,選擇原文字義與翻譯
- 如果是比較難懂的經文的話神學意義與教義（不用重複內文的意思）

請儘量簡短，不用重複經文的章節和內容，不用重複類似的意思，使用"這節經文..."開頭用 3-5 句話深入淺出地說明，幫助讀者不只理解經文，更能被經文觸動和轉化。使用繁體中文（台灣用語）書寫。請直接切入主題，使用"這節經文..."開頭`

      messages.push({ role: "user", content: initialPrompt })
    }

    const stream = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages,
      stream: true,
      stream_options: { include_usage: false },
      max_tokens: 500,
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
    console.error("Failed to explain verse:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}

