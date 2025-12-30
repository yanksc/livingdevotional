import OpenAI from "openai"

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function POST(req: Request) {
  try {
    const { book, chapter, verseNumber, verseText, language, excludeReferences = [] } = await req.json()

    const excludeList =
      excludeReferences.length > 0 ? `\n\n**已經顯示過的經文（請排除）：**\n${excludeReferences.join(", ")}` : ""

    const prompt = `你是一位聖經學者。針對以下經文：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

請找出 3 節最相關且重要的聖經經文，讀者應該與此經文一起研讀。

**重要規則：**
1. **不要**列出同一章（${book} ${chapter}章）的經文，因為讀者已經在閱讀該章節
2. 優先選擇：
   - 經典且廣為人知的經文
   - 與主題直接相關的重要經文
   - 能幫助讀者更深入理解的關鍵經文
3. 按照相關性和重要性排序（最相關的放在前面）${excludeList}

對於每一節相關經文，請提供：
1. 經文出處（經卷 章:節）
2. 簡短引文或摘要（1句話）
3. 相關性說明（1句話解釋為什麼讀者應該一起研讀這兩段經文）

請以JSON陣列格式回應，結構如下：
[
  {
    "reference": "經卷 章:節",
    "summary": "簡短引文或摘要",
    "relevance": "相關性說明"
  }
]

使用繁體中文（台灣用語）書寫。只回傳JSON陣列，不要其他文字。`

    const stream = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      stream: true,
      stream_options: { include_usage: false },
      max_tokens: 1000,
    })

    // For JSON responses, we need to stream the text chunks
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
    console.error("Failed to find related verses:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}

