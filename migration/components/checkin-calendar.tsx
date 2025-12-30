"use client"

import { useMemo } from "react"
import { Flame, Calendar, Check } from "lucide-react"
import type { DailyCheckIn } from "@/lib/types"
import { cn } from "@/lib/utils"

interface CheckInCalendarProps {
  viewMode: "week" | "month"
  checkInData: DailyCheckIn[]
  currentStreak: number
  className?: string
}

export function CheckInCalendar({ viewMode, checkInData, currentStreak, className }: CheckInCalendarProps) {
  // Create a map of date -> read_count for quick lookup
  const checkInMap = useMemo(() => {
    const map = new Map<string, number>()
    checkInData.forEach((checkIn) => {
      map.set(checkIn.check_in_date, checkIn.read_count)
    })
    return map
  }, [checkInData])

  if (viewMode === "week") {
    return <WeekView checkInMap={checkInMap} currentStreak={currentStreak} className={className} />
  }

  return <MonthView checkInMap={checkInMap} currentStreak={currentStreak} className={className} />
}

interface WeekViewProps {
  checkInMap: Map<string, number>
  currentStreak: number
  className?: string
}

function WeekView({ checkInMap, currentStreak, className }: WeekViewProps) {
  const weekDays = useMemo(() => {
    const days = []
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // Helper to get local date string without timezone conversion
    const getLocalDateString = (date: Date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, "0")
      const day = String(date.getDate()).padStart(2, "0")
      return `${year}-${month}-${day}`
    }

    // Build array of dates with check-in status
    const datesWithCheckIns: { date: Date; dateStr: string; hasCheckIn: boolean }[] = []
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(date.getDate() - i)
      const dateStr = getLocalDateString(date)
      const hasCheckIn = checkInMap.has(dateStr)
      datesWithCheckIns.push({ date, dateStr, hasCheckIn })
    }

    // Calculate streak position for each day (counting backwards from today)
    let streakCount = currentStreak
    const streakPositions = new Map<string, number>()
    
    for (let i = datesWithCheckIns.length - 1; i >= 0; i--) {
      const { dateStr, hasCheckIn } = datesWithCheckIns[i]
      if (hasCheckIn && streakCount > 0) {
        streakPositions.set(dateStr, streakCount)
        streakCount--
      } else if (!hasCheckIn) {
        break // Streak is broken
      }
    }

    // Build final day objects
    for (let i = 0; i < datesWithCheckIns.length; i++) {
      const { date, dateStr, hasCheckIn } = datesWithCheckIns[i]
      const dayName = date.toLocaleDateString("zh-TW", { weekday: "short" })
      const dayNum = date.getDate()
      const streakPosition = streakPositions.get(dateStr) || 0

      days.push({
        date: dateStr,
        dayName,
        dayNum,
        hasCheckIn,
        streakPosition,
        isToday: i === datesWithCheckIns.length - 1,
      })
    }

    return days
  }, [checkInMap, currentStreak])

  return (
    <div className={cn("space-y-4", className)}>
      {/* Streak Display */}
      <div className="flex items-center gap-3 justify-center">
        <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-orange-500/10 to-red-500/10 border border-orange-500/20">
          <Flame className="h-5 w-5 text-orange-500" />
          <div className="flex items-baseline gap-1">
            <span className="text-2xl font-bold text-orange-500">{currentStreak}</span>
            <span className="text-sm text-muted-foreground">天連續</span>
          </div>
        </div>
      </div>

      {/* Week Grid */}
      <div className="grid grid-cols-7 gap-2">
        {weekDays.map((day) => (
          <div
            key={day.date}
            className={cn(
              "flex flex-col items-center justify-center p-3 rounded-lg border transition-all relative",
              day.isToday ? "border-primary bg-primary/5" : "border-border bg-background",
              day.hasCheckIn && "ring-2 ring-green-500/30 bg-green-50/50"
            )}
          >
            <div className="text-xs text-muted-foreground mb-1">{day.dayName}</div>
            <div className="text-sm font-medium mb-2">{day.dayNum}</div>
            {day.hasCheckIn ? (
              <div className="flex flex-col items-center gap-1">
                <div className="h-6 w-6 rounded-full bg-green-500 flex items-center justify-center">
                  <Check className="h-4 w-4 text-white" />
                </div>
                {day.streakPosition > 0 && (
                  <div className="text-xs font-bold text-orange-500">#{day.streakPosition}</div>
                )}
              </div>
            ) : (
              <div className="h-6 w-6 rounded-full border-2 border-muted-foreground/20"></div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

interface MonthViewProps {
  checkInMap: Map<string, number>
  currentStreak: number
  className?: string
}

function MonthView({ checkInMap, currentStreak, className }: MonthViewProps) {
  const monthData = useMemo(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const year = today.getFullYear()
    const month = today.getMonth()

    // Helper to get local date string without timezone conversion
    const getLocalDateString = (date: Date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, "0")
      const day = String(date.getDate()).padStart(2, "0")
      return `${year}-${month}-${day}`
    }

    // First day of the month
    const firstDay = new Date(year, month, 1)
    const startingDayOfWeek = firstDay.getDay() // 0 = Sunday

    // Last day of the month
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()

    // Build array of all days with check-in status
    const allDays: { day: number; date: Date; dateStr: string; hasCheckIn: boolean; isToday: boolean }[] = []
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      const dateStr = getLocalDateString(date)
      const hasCheckIn = checkInMap.has(dateStr)
      const isToday = day === today.getDate() && month === today.getMonth() && year === today.getFullYear()
      
      allDays.push({ day, date, dateStr, hasCheckIn, isToday })
    }

    // Calculate streak positions (counting backwards from today or most recent check-in)
    let streakCount = 0
    const streakPositions = new Map<string, number>()
    
    // Find the most recent check-in day (could be today or earlier)
    let lastCheckInIndex = -1
    for (let i = allDays.length - 1; i >= 0; i--) {
      if (allDays[i].hasCheckIn) {
        lastCheckInIndex = i
        break
      }
    }

    // Only calculate streaks if we have check-ins and current streak > 0
    if (lastCheckInIndex >= 0 && currentStreak > 0) {
      streakCount = currentStreak
      for (let i = lastCheckInIndex; i >= 0; i--) {
        if (allDays[i].hasCheckIn && streakCount > 0) {
          streakPositions.set(allDays[i].dateStr, streakCount)
          streakCount--
        } else if (!allDays[i].hasCheckIn) {
          break
        }
      }
    }

    // Build calendar grid
    const days = []

    // Add empty cells for days before the first of the month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null)
    }

    // Add all days of the month with streak info
    for (const dayData of allDays) {
      days.push({
        day: dayData.day,
        date: dayData.dateStr,
        hasCheckIn: dayData.hasCheckIn,
        streakPosition: streakPositions.get(dayData.dateStr) || 0,
        isToday: dayData.isToday,
      })
    }

    return {
      days,
      monthName: today.toLocaleDateString("zh-TW", { year: "numeric", month: "long" }),
    }
  }, [checkInMap, currentStreak])

  const weekDayNames = ["日", "一", "二", "三", "四", "五", "六"]

  return (
    <div className={cn("space-y-4", className)}>
      {/* Streak Display */}
      <div className="flex items-center gap-3 justify-center">
        <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-orange-500/10 to-red-500/10 border border-orange-500/20">
          <Flame className="h-5 w-5 text-orange-500" />
          <div className="flex items-baseline gap-1">
            <span className="text-2xl font-bold text-orange-500">{currentStreak}</span>
            <span className="text-sm text-muted-foreground">天連續</span>
          </div>
        </div>
      </div>

      {/* Month Header */}
      <div className="flex items-center justify-center gap-2 mb-2">
        <Calendar className="h-4 w-4 text-primary" />
        <h3 className="text-lg font-semibold text-foreground">{monthData.monthName}</h3>
      </div>

      {/* Weekday Headers */}
      <div className="grid grid-cols-7 gap-1 mb-2">
        {weekDayNames.map((name) => (
          <div key={name} className="text-center text-xs font-medium text-muted-foreground p-2">
            {name}
          </div>
        ))}
      </div>

      {/* Calendar Grid */}
      <div className="grid grid-cols-7 gap-1">
        {monthData.days.map((dayData, index) => {
          if (!dayData) {
            return <div key={`empty-${index}`} className="aspect-square" />
          }

          return (
            <div
              key={dayData.date}
              className={cn(
                "aspect-square flex flex-col items-center justify-center p-1 rounded-lg border transition-all relative",
                dayData.isToday ? "border-primary bg-primary/5 ring-2 ring-primary/20" : "border-border bg-background",
                dayData.hasCheckIn && !dayData.isToday && "border-green-500/50 bg-green-50/50"
              )}
            >
              <div className="text-xs font-medium mb-1">{dayData.day}</div>
              {dayData.hasCheckIn ? (
                <div className="flex flex-col items-center gap-0.5">
                  <div className="h-5 w-5 rounded-full bg-green-500 flex items-center justify-center">
                    <Check className="h-3 w-3 text-white" />
                  </div>
                  {dayData.streakPosition > 0 && (
                    <div className="text-[10px] font-bold text-orange-500">#{dayData.streakPosition}</div>
                  )}
                </div>
              ) : (
                <div className="h-5 w-5 rounded-full border border-muted-foreground/10"></div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

