"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { NavigationDrawer } from "@/components/navigation-drawer"
import { BibleSearchDialog } from "@/components/bible-search-dialog"
import { CheckInCalendar } from "@/components/checkin-calendar"
import { BookOpen, User, Sparkles, Calendar, Search } from "lucide-react"
import Link from "next/link"
import { createClient } from "@/lib/supabase/client"
import { getCheckInData, getCurrentStreak } from "@/lib/actions/checkin-actions"
import { getLocalizedBookName } from "@/lib/bible-data"
import type { SupabaseUser, Language, DailyVerse, DailyCheckIn } from "@/lib/types"

export default function HomePage() {
  const [navOpen, setNavOpen] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const [user, setUser] = useState<SupabaseUser | null>(null)
  const [hasLastReading, setHasLastReading] = useState(false)
  const [lastBook, setLastBook] = useState<string>("")
  const [lastChapter, setLastChapter] = useState<number>(0)
  const [verseOfTheDay, setVerseOfTheDay] = useState<DailyVerse | null>(null)
  const [primaryLanguage, setPrimaryLanguage] = useState<Language>("cuv")
  const [secondaryLanguage, setSecondaryLanguage] = useState<Language>("niv")
  const [loadingVerse, setLoadingVerse] = useState(true)
  const [checkInData, setCheckInData] = useState<DailyCheckIn[]>([])
  const [currentStreak, setCurrentStreak] = useState(0)
  const [loadingCheckIn, setLoadingCheckIn] = useState(false)
  const router = useRouter()

  // Fetch verse of the day
  useEffect(() => {
    const fetchVerseOfTheDay = async () => {
      try {
        const response = await fetch("/api/verse-of-the-day")
        if (response.ok) {
          const data = await response.json()
          setVerseOfTheDay(data)
        }
      } catch (error) {
        console.error("Failed to fetch verse of the day:", error)
      } finally {
        setLoadingVerse(false)
      }
    }

    fetchVerseOfTheDay()
  }, [])

  // Load user data and preferences
  useEffect(() => {
    const supabase = createClient()

    supabase.auth.getUser().then(async ({ data: { user } }) => {
      setUser(user)

      if (user) {
        // Load user preferences
        const { data: prefs } = await supabase
          .from("user_preferences")
          .select("*")
          .eq("user_id", user.id)
          .single()

        if (prefs) {
          setPrimaryLanguage(prefs.primary_language as Language)
          setSecondaryLanguage(prefs.secondary_language as Language)
        }

        // Load reading progress
        const { data: progress } = await supabase
          .from("reading_progress")
          .select("*")
          .eq("user_id", user.id)
          .order("last_read_at", { ascending: false })
          .limit(1)
          .single()

        if (progress) {
          setLastBook(progress.book)
          setLastChapter(progress.chapter)
          localStorage.setItem("lastBook", progress.book)
          localStorage.setItem("lastChapter", progress.chapter.toString())
          setHasLastReading(true)
        }
      } else {
        // Not logged in, check localStorage for preferences and progress
        const savedPrimary = localStorage.getItem("primaryLanguage") as Language
        const savedSecondary = localStorage.getItem("secondaryLanguage") as Language
        if (savedPrimary) setPrimaryLanguage(savedPrimary)
        if (savedSecondary) setSecondaryLanguage(savedSecondary)

        const lastBookStorage = localStorage.getItem("lastBook")
        const lastChapterStorage = localStorage.getItem("lastChapter")
        if (lastBookStorage && lastChapterStorage) {
          setLastBook(lastBookStorage)
          setLastChapter(parseInt(lastChapterStorage))
          setHasLastReading(true)
        }
      }
    })
  }, [])

  // Load check-in data when user is logged in
  useEffect(() => {
    if (!user) {
      setCheckInData([])
      setCurrentStreak(0)
      return
    }

    const loadCheckInData = async () => {
      setLoadingCheckIn(true)
      try {
        // Get last 7 days for week view using local timezone
        const today = new Date()
        const sevenDaysAgo = new Date(today)
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6)

        // Format dates in local timezone (YYYY-MM-DD)
        const getLocalDateString = (date: Date) => {
          const year = date.getFullYear()
          const month = String(date.getMonth() + 1).padStart(2, "0")
          const day = String(date.getDate()).padStart(2, "0")
          return `${year}-${month}-${day}`
        }

        const startDate = getLocalDateString(sevenDaysAgo)
        const endDate = getLocalDateString(today)

        const [data, streak] = await Promise.all([
          getCheckInData(startDate, endDate),
          getCurrentStreak(endDate), // Pass local date for accurate streak calculation
        ])

        setCheckInData(data)
        setCurrentStreak(streak)
      } catch (error) {
        console.error("Failed to load check-in data:", error)
      } finally {
        setLoadingCheckIn(false)
      }
    }

    loadCheckInData()
  }, [user])

  const handleNavigate = (book: string, chapter: number) => {
    router.push(`/read/${encodeURIComponent(book)}/${chapter}`)
  }

  const handleStartReading = () => {
    if (lastBook && lastChapter) {
      router.push(`/read/${encodeURIComponent(lastBook)}/${lastChapter}`)
    } else {
      setNavOpen(true)
    }
  }

  const handleVerseClick = () => {
    if (verseOfTheDay) {
      router.push(`/read/${encodeURIComponent(verseOfTheDay.book)}/${verseOfTheDay.chapter}`)
    }
  }

  const getVerseText = (verse: DailyVerse) => {
    if (primaryLanguage === "niv") return verse.text_niv
    if (primaryLanguage === "cuv") return verse.text_cuv
    if (primaryLanguage === "cu1") return verse.text_cu1
    return verse.text_cuv
  }

  const getSecondaryVerseText = (verse: DailyVerse) => {
    if (secondaryLanguage === "none") return null
    if (secondaryLanguage === "niv") return verse.text_niv
    if (secondaryLanguage === "cuv") return verse.text_cuv
    if (secondaryLanguage === "cu1") return verse.text_cu1
    return null
  }

  return (
    <div className="min-h-screen flex flex-col p-4 sm:p-6 bg-gradient-to-br from-white via-blue-50/30 to-cyan-50/40 relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 -left-20 w-96 h-96 bg-gradient-to-br from-primary/20 to-accent/20 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-gradient-to-br from-accent/20 to-secondary/20 rounded-full blur-3xl animate-pulse delay-1000" />
      </div>

      {/* Logo/Title Section */}
      <div className="relative z-10 flex items-center gap-3 mb-8 pt-2">
        <div className="p-3 rounded-xl gradient-primary shadow-lg shadow-primary/20">
          <BookOpen className="h-6 w-6 text-white" />
        </div>
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold gradient-text">BibleMind</h1>
        </div>
        {!user && (
          <Link href="/auth/login" className="ml-auto">
            <Button variant="outline" size="sm" className="gap-2 border-primary/30 hover:bg-primary/5 bg-white/50">
              <User className="h-4 w-4" />
              <span className="hidden sm:inline">登入</span>
            </Button>
          </Link>
        )}
      </div>

      {/* Main Content */}
      <div className="relative z-10 flex-1 max-w-5xl w-full mx-auto space-y-6">
        {/* Verse of the Day Widget - Primary */}
        <Card className="overflow-hidden border-2 border-primary/20 shadow-xl hover:shadow-2xl transition-shadow cursor-pointer group p-0">
          <div className="bg-gradient-to-br from-primary/10 via-accent/5 to-transparent p-6 sm:p-8 h-full">
            <div className="flex items-center gap-2 mb-4">
              <Calendar className="h-5 w-5 text-primary" />
              <h2 className="text-lg sm:text-xl font-semibold text-foreground">今日金句</h2>
              <Sparkles className="h-4 w-4 text-accent ml-auto" />
            </div>

            {loadingVerse ? (
              <div className="space-y-3 animate-pulse">
                <div className="h-4 bg-primary/10 rounded w-3/4"></div>
                <div className="h-4 bg-primary/10 rounded w-full"></div>
                <div className="h-4 bg-primary/10 rounded w-5/6"></div>
              </div>
            ) : verseOfTheDay ? (
              <div onClick={handleVerseClick} className="space-y-4">
                <div className="space-y-3">
                  <p className="text-lg sm:text-2xl leading-relaxed text-foreground font-medium">
                    {getVerseText(verseOfTheDay)}
                  </p>
                  {getSecondaryVerseText(verseOfTheDay) && secondaryLanguage !== "none" && (
                    <p className="text-sm sm:text-base leading-relaxed text-muted-foreground italic border-l-2 border-primary/30 pl-4">
                      {getSecondaryVerseText(verseOfTheDay)}
                    </p>
                  )}
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-primary/10">
                  <p className="text-sm font-semibold text-primary">
                    {getLocalizedBookName(verseOfTheDay.book, primaryLanguage)} {verseOfTheDay.chapter}:
                    {verseOfTheDay.verse_number}
                  </p>
                  <p className="text-xs text-muted-foreground group-hover:text-primary transition-colors">
                    點擊閱讀完整章節 →
                  </p>
                </div>
              </div>
            ) : (
              <p className="text-muted-foreground">無法載入今日金句，請稍後再試。</p>
            )}
          </div>
        </Card>

        {/* Bible Search Widget - Featured (desktop view) */}
        <Card className="border-2 border-accent/30 hover:border-accent/50 transition-all hover:shadow-xl bg-gradient-to-br from-accent/5 via-white to-primary/5 hidden sm:block">
          <CardContent className="p-6 sm:p-8">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-accent to-primary shadow-lg">
                  <Search className="h-6 w-6 text-white" />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-foreground">聖經智能搜尋</h2>
                  <p className="text-sm text-muted-foreground">問任何問題，找到相關經文</p>
                </div>
              </div>
              <Sparkles className="h-5 w-5 text-accent animate-pulse" />
            </div>
            <p className="text-sm text-muted-foreground mb-4">
              使用 AI 技術理解你的問題，從聖經中找出最相關的經文答案。無論是尋求指引、安慰或智慧，都能快速找到你需要的經文。
            </p>
            <Button onClick={() => setSearchOpen(true)} className="w-full gradient-primary hover:opacity-90 gap-2 h-12 text-base">
              <Search className="h-5 w-5" />
              開始搜尋經文
            </Button>
          </CardContent>
        </Card>

        {/* Daily Check-in Widget - Only show for logged in users */}
        {user && (
          <Card className="border-2 border-orange-500/20 hover:border-orange-500/30 transition-all hover:shadow-xl bg-gradient-to-br from-orange-50/50 via-white to-red-50/30">
            <CardContent className="p-6 sm:p-8">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h2 className="text-xl font-bold text-foreground mb-1">每日打卡</h2>
                  <p className="text-sm text-muted-foreground">保持閱讀習慣，累積靈修記錄</p>
                </div>
              </div>
              {loadingCheckIn ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
              ) : (
                <CheckInCalendar viewMode="week" checkInData={checkInData} currentStreak={currentStreak} />
              )}
            </CardContent>
          </Card>
        )}

        {/* Secondary Widgets Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
          {/* Continue Reading Widget */}
          {hasLastReading && (
            <Card className="border border-primary/20 hover:border-primary/40 transition-all hover:shadow-lg">
              <CardContent className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-foreground mb-1">繼續閱讀</h3>
                    <p className="text-sm text-muted-foreground">
                      {getLocalizedBookName(lastBook, primaryLanguage)} {lastChapter}
                    </p>
                  </div>
                  <BookOpen className="h-5 w-5 text-primary" />
                </div>
                <Button onClick={handleStartReading} className="w-full gradient-primary hover:opacity-90">
                  繼續閱讀
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Start Reading Widget */}
          {!hasLastReading && (
            <Card className="border border-primary/20 hover:border-primary/40 transition-all hover:shadow-lg">
              <CardContent className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-foreground mb-1">開始閱讀</h3>
                    <p className="text-sm text-muted-foreground">選擇章節開始你的靈修之旅</p>
                  </div>
                  <BookOpen className="h-5 w-5 text-primary" />
                </div>
                <Button onClick={() => setNavOpen(true)} className="w-full gradient-primary hover:opacity-90">
                  選擇章節
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Login Widget - Only show for non-logged-in users */}
          {!user && (
            <Card className="border border-accent/20 hover:border-accent/40 transition-all hover:shadow-lg">
              <CardContent className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-foreground mb-1">登入帳號</h3>
                    <p className="text-sm text-muted-foreground">同步你的閱讀進度</p>
                  </div>
                  <User className="h-5 w-5 text-accent" />
                </div>
                <Link href="/auth/login" className="block">
                  <Button variant="outline" className="w-full border-accent/30 hover:bg-accent/5">
                    立即登入
                  </Button>
                </Link>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Features Section - Compact */}
        <div className="pt-6">
          <h3 className="text-center text-sm font-semibold text-muted-foreground mb-4">平台特色</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="p-4 rounded-xl bg-white/50 border border-primary/10 text-center">
              <p className="text-xs font-medium text-foreground">🌐 雙語對照閱讀</p>
            </div>
            <div className="p-4 rounded-xl bg-white/50 border border-accent/10 text-center">
              <p className="text-xs font-medium text-foreground">✨ AI 智能解析</p>
            </div>
            <div className="p-4 rounded-xl bg-white/50 border border-blue-500/10 text-center">
              <p className="text-xs font-medium text-foreground">📱 跨設備同步</p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="relative z-10 mt-8 pb-4">
        <div className="text-center">
          <p className="text-xs text-muted-foreground/80">
            made with love <span className="text-red-500 inline-block animate-pulse">♥</span> by{" "}
            <span className="gradient-text font-semibold">Yenkai Huang</span>
          </p>
        </div>
      </footer>

      {/* Floating Action Button for Search (mobile only, shown when logged in) */}
      {user && (
        <button
          onClick={() => setSearchOpen(true)}
          className="fixed bottom-20 right-6 z-40 p-4 rounded-full gradient-primary shadow-2xl hover:shadow-primary/50 transition-all hover:scale-110 active:scale-95 sm:hidden"
          aria-label="搜尋經文"
        >
          <Search className="h-6 w-6 text-white" />
        </button>
      )}

      <NavigationDrawer open={navOpen} onOpenChange={setNavOpen} onNavigate={handleNavigate} />
      <BibleSearchDialog
        open={searchOpen}
        onOpenChange={setSearchOpen}
        primaryLanguage={primaryLanguage}
        secondaryLanguage={secondaryLanguage}
      />
    </div>
  )
}
