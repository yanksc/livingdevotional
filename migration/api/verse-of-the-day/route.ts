import { NextResponse } from "next/server"
import { getTodaysVerse } from "@/lib/actions/verse-of-day-actions"

/**
 * GET endpoint for verse of the day
 * Uses lazy generation - checks cache first, generates if needed
 */
export async function GET() {
  try {
    const verse = await getTodaysVerse()

    if (!verse) {
      return NextResponse.json({ error: "Failed to fetch verse of the day" }, { status: 500 })
    }

    return NextResponse.json(verse, {
      headers: {
        "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
      },
    })
  } catch (error) {
    console.error("Error in verse-of-the-day API:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

