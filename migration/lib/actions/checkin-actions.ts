"use server"

import { createClient } from "@/lib/supabase/server"
import type { DailyCheckIn } from "@/lib/types"

/**
 * Records a daily check-in for the current user.
 * If a check-in already exists for today, it increments the read_count.
 * Otherwise, it creates a new check-in record.
 * @param localDate - The user's local date in YYYY-MM-DD format
 */
export async function recordDailyCheckIn(localDate?: string): Promise<DailyCheckIn | null> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return null
  }

  // Use provided local date or fallback (though localDate should always be provided from client)
  const today = localDate || new Date().toISOString().split("T")[0]

  try {
    // Check if check-in already exists for today
    const { data: existing } = await supabase
      .from("daily_checkins")
      .select("*")
      .eq("user_id", user.id)
      .eq("check_in_date", today)
      .single()

    if (existing) {
      // Increment read_count for today
      const { data, error } = await supabase
        .from("daily_checkins")
        .update({
          read_count: existing.read_count + 1,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id)
        .select()
        .single()

      if (error) {
        console.error("Failed to update check-in:", error)
        return null
      }

      return data
    } else {
      // Create new check-in for today
      const { data, error } = await supabase
        .from("daily_checkins")
        .insert({
          user_id: user.id,
          check_in_date: today,
          read_count: 1,
        })
        .select()
        .single()

      if (error) {
        console.error("Failed to create check-in:", error)
        return null
      }

      return data
    }
  } catch (error) {
    console.error("Error recording check-in:", error)
    return null
  }
}

/**
 * Fetches check-in data for a date range
 */
export async function getCheckInData(startDate: string, endDate: string): Promise<DailyCheckIn[]> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return []
  }

  const { data, error } = await supabase
    .from("daily_checkins")
    .select("*")
    .eq("user_id", user.id)
    .gte("check_in_date", startDate)
    .lte("check_in_date", endDate)
    .order("check_in_date", { ascending: true })

  if (error) {
    console.error("Failed to fetch check-in data:", error)
    return []
  }

  return data || []
}

/**
 * Calculates the current streak of consecutive days with check-ins
 * @param localDateToday - Optional: The user's local date today in YYYY-MM-DD format. If not provided, uses server's date.
 */
export async function getCurrentStreak(localDateToday?: string): Promise<number> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return 0
  }

  // Fetch all check-ins, ordered by date descending
  const { data, error } = await supabase
    .from("daily_checkins")
    .select("check_in_date")
    .eq("user_id", user.id)
    .order("check_in_date", { ascending: false })

  if (error || !data || data.length === 0) {
    return 0
  }

  // Use provided local date or fallback to server date
  // Note: For accurate streaks, localDateToday should always be provided from client
  const todayStr = localDateToday || new Date().toISOString().split("T")[0]
  
  // Calculate yesterday's date string
  const todayParts = todayStr.split("-")
  const todayDate = new Date(parseInt(todayParts[0]), parseInt(todayParts[1]) - 1, parseInt(todayParts[2]))
  todayDate.setDate(todayDate.getDate() - 1)
  const yesterdayStr = `${todayDate.getFullYear()}-${String(todayDate.getMonth() + 1).padStart(2, "0")}-${String(todayDate.getDate()).padStart(2, "0")}`

  // Check if there's a check-in today or yesterday
  const mostRecentDate = data[0].check_in_date
  if (mostRecentDate !== todayStr && mostRecentDate !== yesterdayStr) {
    return 0 // Streak is broken
  }

  // Count consecutive days by working backwards from most recent check-in
  let streak = 0
  let expectedDateStr = mostRecentDate

  for (const checkIn of data) {
    if (checkIn.check_in_date === expectedDateStr) {
      streak++
      // Calculate previous day
      const parts = expectedDateStr.split("-")
      const date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
      date.setDate(date.getDate() - 1)
      expectedDateStr = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`
    } else {
      break
    }
  }

  return streak
}

/**
 * Fetches all check-ins for a specific month
 * @param year - The year
 * @param month - The month (1-12)
 */
export async function getMonthlyCheckIns(year: number, month: number): Promise<DailyCheckIn[]> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return []
  }

  // Format dates without timezone conversion
  const startDateStr = `${year}-${String(month).padStart(2, "0")}-01`
  
  // Calculate last day of month
  const lastDay = new Date(year, month, 0).getDate()
  const endDateStr = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`

  const { data, error } = await supabase
    .from("daily_checkins")
    .select("*")
    .eq("user_id", user.id)
    .gte("check_in_date", startDateStr)
    .lte("check_in_date", endDateStr)
    .order("check_in_date", { ascending: true })

  if (error) {
    console.error("Failed to fetch monthly check-ins:", error)
    return []
  }

  return data || []
}

/**
 * Gets total number of check-in days for the user
 */
export async function getTotalCheckInDays(): Promise<number> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return 0
  }

  const { count, error } = await supabase
    .from("daily_checkins")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)

  if (error) {
    console.error("Failed to get total check-in days:", error)
    return 0
  }

  return count || 0
}

