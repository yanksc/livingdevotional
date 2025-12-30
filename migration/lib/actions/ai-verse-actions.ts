"use server"

import OpenAI from "openai"
import type { RelatedVerse, Language } from "@/lib/types"
import { validateServerEnv } from "@/lib/env"

// Validate environment variables on module load
validateServerEnv()

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function explainVerse(
  book: string,
  chapter: number,
  verseNumber: number,
  verseText: string,
  language: Language,
): Promise<string> {
  const prompt = `解釋以下經文：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

請根據這節經文的獨特性和重要性，選擇最能幫助讀者理解和應用的面向來解釋。
使用"這節經文"開頭，可能的面向包括（但不限於）：

- 當時歷史與文化背景
- 如果是比較難懂的經文的話,選擇原文字義與翻譯
- 如果是比較難懂的經文的話神學意義與教義（不用重複內文的意思）

請儘量簡短，不用重複經文的章節和內容，不用重複類似的意思，使用"這節經文..."開頭用 3-5 句話深入淺出地說明，幫助讀者不只理解經文，更能被經文觸動和轉化。使用繁體中文（台灣用語）書寫。請直接切入主題，使用"這節經文..."開頭`

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 500,
  })

  return completion.choices[0]?.message?.content || ""
}

export async function findRelatedVerses(
  book: string,
  chapter: number,
  verseNumber: number,
  verseText: string,
  language: Language,
  excludeReferences: string[] = [],
): Promise<RelatedVerse[]> {
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

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 1000,
  })

  const text = completion.choices[0]?.message?.content || ""

  try {
    // Extract JSON from the response
    const jsonMatch = text.match(/\[[\s\S]*\]/)
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0])
    }
    return []
  } catch (error) {
    console.error("Failed to parse related verses:", error)
    return []
  }
}

export async function askVerseQuestion(
  book: string,
  chapter: number,
  verseNumber: number,
  verseText: string,
  question: string,
  language: Language,
): Promise<string> {
  const prompt = `你是一位聖經學者和神學教師。讀者正在閱讀以下經文並有問題：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

讀者的問題：${question}

請用繁體中文（台灣用語）提供簡潔且有幫助的回答。你的回答應該：
1. 直接回答讀者的問題
2. 提供相關的聖經背景和上下文
3. 如果適用，引用其他相關經文
4. 保持回答清晰、易懂且具有實用性

請使用繁體中文（台灣用語）書寫。`

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 800,
  })

  return completion.choices[0]?.message?.content || ""
}

export async function generateSuggestedQuestions(
  book: string,
  chapter: number,
  verseNumber: number,
  verseText: string,
  language: Language,
): Promise<string[]> {
  const prompt = `你是一位聖經學者。針對以下經文：

經卷：${book}
章：${chapter}
節：${verseNumber}
經文：「${verseText}」

請生成 2 個簡短的問題（每個問題 7-15 個繁體中文字），這些問題應該：
1. 引發思考或探討經文的深層含義
2. 解釋經文中的特定術語或概念
3. 適合聖經初學者或尋求者

請以JSON陣列格式回應：
["問題1", "問題2"]

只回傳JSON陣列，不要其他文字。`

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 200,
  })

  const text = completion.choices[0]?.message?.content || ""

  try {
    const jsonMatch = text.match(/\[[\s\S]*\]/)
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0])
    }
    return []
  } catch (error) {
    console.error("Failed to parse suggested questions:", error)
    return []
  }
}
