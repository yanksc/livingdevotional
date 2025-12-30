import OpenAI from "openai"

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function POST(req: Request) {
  try {
    const { book, chapter, language } = await req.json()

    const prompt = `請為以下聖經章節提供簡短的摘要：

經卷：${book}
章：${chapter}

請用2-3段簡短的段落（總共約150-200字）概述這一章的內容，包括：

1. 主要主題和中心思想
2. 重要事件或教導
3. 這一章在聖經脈絡中的意義

請直接開始摘要，不需要標題或開場白。使用繁體中文（台灣用語）書寫。`

    const stream = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      stream: true,
      stream_options: { include_usage: false },
      max_tokens: 600,
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
    console.error("Failed to summarize chapter:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}





