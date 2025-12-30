"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { CheckInCalendar } from "@/components/checkin-calendar"
import Link from "next/link"
import { Clock, BookOpen, Bookmark, Trash2, Loader2, Calendar as CalendarIcon } from "lucide-react"
import { getLocalizedBookName } from "@/lib/bible-data"
import type { Language, SupabaseUser, UserPreferences, ReadingProgress, VerseBookmark, DailyCheckIn } from "@/lib/types"
import { deleteBookmark } from "@/lib/actions/bookmark-actions"
import { getMonthlyCheckIns, getCurrentStreak, getTotalCheckInDays } from "@/lib/actions/checkin-actions"

export default function ProfilePage() {
  const router = useRouter()
  const [user, setUser] = useState<SupabaseUser | null>(null)
  const [preferences, setPreferences] = useState<UserPreferences | null>(null)
  const [history, setHistory] = useState<ReadingProgress[]>([])
  const [bookmarks, setBookmarks] = useState<VerseBookmark[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [loadingBookmarks, setLoadingBookmarks] = useState(false)
  const [checkInData, setCheckInData] = useState<DailyCheckIn[]>([])
  const [currentStreak, setCurrentStreak] = useState(0)
  const [totalCheckInDays, setTotalCheckInDays] = useState(0)
  const [loadingCheckIns, setLoadingCheckIns] = useState(false)
  const [currentMonth, setCurrentMonth] = useState(new Date().getMonth() + 1)
  const [currentYear, setCurrentYear] = useState(new Date().getFullYear())

  useEffect(() => {
    const loadUserData = async () => {
      const supabase = createClient()
      const {
        data: { user },
        error,
      } = await supabase.auth.getUser()

      if (error || !user) {
        router.push("/auth/login")
        return
      }

      setUser(user)

      const { data: prefs } = await supabase.from("user_preferences").select("*").eq("user_id", user.id).single()
      setPreferences(prefs)
      setLoading(false)
    }

    loadUserData()
  }, [router])

  useEffect(() => {
    if (!user || history.length > 0) return

    const loadHistory = async () => {
      setLoadingHistory(true)
      const supabase = createClient()
      const { data } = await supabase
        .from("reading_progress")
        .select("*")
        .eq("user_id", user.id)
        .order("last_read_at", { ascending: false })
        .limit(50)
      setHistory(data || [])
      setLoadingHistory(false)
    }

    loadHistory()
  }, [user, history.length])

  useEffect(() => {
    if (!user || bookmarks.length > 0) return

    const loadBookmarks = async () => {
      setLoadingBookmarks(true)
      const supabase = createClient()
      const { data } = await supabase
        .from("verse_bookmarks")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
      setBookmarks(data || [])
      setLoadingBookmarks(false)
    }

    loadBookmarks()
  }, [user, bookmarks.length])

  // Load check-in data
  useEffect(() => {
    if (!user) return

    const loadCheckIns = async () => {
      setLoadingCheckIns(true)
      try {
        // Get user's local date for accurate streak calculation
        const today = new Date()
        const localDateToday = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`

        const [data, streak, total] = await Promise.all([
          getMonthlyCheckIns(currentYear, currentMonth),
          getCurrentStreak(localDateToday),
          getTotalCheckInDays(),
        ])

        setCheckInData(data)
        setCurrentStreak(streak)
        setTotalCheckInDays(total)
      } catch (error) {
        console.error("Failed to load check-in data:", error)
      } finally {
        setLoadingCheckIns(false)
      }
    }

    loadCheckIns()
  }, [user, currentYear, currentMonth])

  const primaryLanguage: Language = (preferences?.primary_language as Language) || "cuv"

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push("/")
  }

  const handleDeleteBookmark = async (bookmarkId: string) => {
    try {
      await deleteBookmark(bookmarkId)
      setBookmarks((prev) => prev.filter((b) => b.id !== bookmarkId))
    } catch (error) {
      console.error("Failed to delete bookmark:", error)
    }
  }

  const handlePreviousMonth = () => {
    if (currentMonth === 1) {
      setCurrentMonth(12)
      setCurrentYear(currentYear - 1)
    } else {
      setCurrentMonth(currentMonth - 1)
    }
  }

  const handleNextMonth = () => {
    const today = new Date()
    const isCurrentMonth = currentMonth === today.getMonth() + 1 && currentYear === today.getFullYear()
    
    // Don't allow navigating to future months
    if (isCurrentMonth) return

    if (currentMonth === 12) {
      setCurrentMonth(1)
      setCurrentYear(currentYear + 1)
    } else {
      setCurrentMonth(currentMonth + 1)
    }
  }

  const formatRelativeTime = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return "剛剛"
    if (diffMins < 60) return `${diffMins} 分鐘前`
    if (diffHours < 24) return `${diffHours} 小時前`
    if (diffDays < 7) return `${diffDays} 天前`

    return date.toLocaleDateString("zh-TW", {
      year: "numeric",
      month: "long",
      day: "numeric",
    })
  }

  const groupBookmarksByDate = (bookmarks: any[]) => {
    const groups: { [key: string]: any[] } = {}
    bookmarks?.forEach((bookmark) => {
      const date = new Date(bookmark.created_at).toLocaleDateString("zh-TW", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
      if (!groups[date]) {
        groups[date] = []
      }
      groups[date].push(bookmark)
    })
    return groups
  }

  const groupedBookmarks = groupBookmarksByDate(bookmarks)

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary/5 via-background to-accent/5 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 via-background to-accent/5 p-6 pt-4">
      <div className="max-w-2xl mx-auto space-y-6">
        <Card className="border-primary/10">
          <CardHeader>
            <CardTitle className="text-2xl bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              個人資料
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex items-center gap-4">
              <Avatar className="h-20 w-20">
                <AvatarImage src={user?.user_metadata?.avatar_url || "/placeholder.svg"} />
                <AvatarFallback className="bg-gradient-to-br from-primary/20 to-accent/20 text-2xl">
                  {user?.user_metadata?.full_name?.[0] || user?.email?.[0]?.toUpperCase()}
                </AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-xl font-semibold">{user?.user_metadata?.full_name || "使用者"}</h2>
                <p className="text-muted-foreground">{user?.email}</p>
              </div>
            </div>

            {preferences && (
              <div className="space-y-2">
                <h3 className="font-semibold">語言偏好</h3>
                <div className="text-sm text-muted-foreground">
                  <p>
                    主要語言:{" "}
                    {preferences.primary_language === "cuv"
                      ? "和合本"
                      : preferences.primary_language === "cu1"
                        ? "新标点和合本"
                        : "NIV"}
                  </p>
                  <p>
                    次要語言:{" "}
                    {preferences.secondary_language === "cuv"
                      ? "和合本"
                      : preferences.secondary_language === "cu1"
                        ? "新标点和合本"
                        : preferences.secondary_language === "niv"
                          ? "NIV"
                          : "無"}
                  </p>
                </div>
              </div>
            )}

            <div className="pt-4">
              <Button onClick={handleSignOut} variant="destructive" className="w-full">
                登出
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="border-primary/10">
          <CardContent className="pt-6">
            <Tabs defaultValue="history" className="w-full">
              <TabsList className="grid w-full grid-cols-3 mb-6">
                <TabsTrigger value="history" className="flex items-center gap-2">
                  <Clock className="h-4 w-4" />
                  閱讀歷史
                </TabsTrigger>
                <TabsTrigger value="bookmarks" className="flex items-center gap-2">
                  <Bookmark className="h-4 w-4" />
                  書籤
                </TabsTrigger>
                <TabsTrigger value="checkins" className="flex items-center gap-2">
                  <CalendarIcon className="h-4 w-4" />
                  打卡記錄
                </TabsTrigger>
              </TabsList>

              <TabsContent value="history" className="space-y-2">
                {loadingHistory ? (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin text-primary" />
                  </div>
                ) : history && history.length > 0 ? (
                  history.map((record) => (
                    <Link
                      key={record.id}
                      href={`/read/${encodeURIComponent(record.book)}/${record.chapter}`}
                      className="block"
                    >
                      <div className="p-4 rounded-lg border border-primary/10 hover:border-primary/30 hover:bg-gradient-to-r hover:from-primary/5 hover:to-accent/5 transition-all group">
                        <div className="flex items-center justify-between gap-4">
                          <div className="flex items-center gap-3 flex-1">
                            <div className="p-2 rounded-lg bg-gradient-to-br from-primary/10 to-accent/10 group-hover:from-primary/20 group-hover:to-accent/20 transition-colors">
                              <BookOpen className="h-4 w-4 text-primary" />
                            </div>
                            <div className="flex-1">
                              <p className="font-medium text-foreground group-hover:text-primary transition-colors">
                                {getLocalizedBookName(record.book, primaryLanguage)} 第 {record.chapter} 章
                              </p>
                              <p className="text-xs text-muted-foreground">{formatRelativeTime(record.last_read_at)}</p>
                            </div>
                          </div>
                          <div className="text-xs text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity">
                            點擊前往 →
                          </div>
                        </div>
                      </div>
                    </Link>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <BookOpen className="h-12 w-12 mx-auto mb-2 opacity-20" />
                    <p className="text-sm">尚無閱讀記錄</p>
                  </div>
                )}
              </TabsContent>

              <TabsContent value="bookmarks" className="space-y-4">
                {loadingBookmarks ? (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin text-primary" />
                  </div>
                ) : bookmarks && bookmarks.length > 0 ? (
                  Object.entries(groupedBookmarks).map(([date, dateBookmarks]) => (
                    <div key={date} className="space-y-2">
                      <h3 className="text-sm font-semibold text-muted-foreground px-2">{date}</h3>
                      {dateBookmarks.map((bookmark: any) => (
                        <div
                          key={bookmark.id}
                          className="p-4 rounded-lg border border-primary/10 bg-gradient-to-br from-background to-primary/5"
                        >
                          <div className="flex items-start justify-between gap-3 mb-2">
                            <Link
                              href={`/read/${encodeURIComponent(bookmark.book)}/${bookmark.chapter}#verse-${bookmark.verse_number}`}
                              className="flex-1 group"
                            >
                              <div className="flex items-center gap-2 mb-1">
                                <Bookmark className="h-4 w-4 text-primary flex-shrink-0" />
                                <p className="font-medium text-foreground group-hover:text-primary transition-colors">
                                  {getLocalizedBookName(bookmark.book, primaryLanguage)} {bookmark.chapter}:
                                  {bookmark.verse_number}
                                </p>
                              </div>
                              <p className="text-sm text-foreground/80 leading-relaxed mb-2">{bookmark.verse_text}</p>
                              {bookmark.note && (
                                <div className="bg-accent/10 border border-accent/20 rounded-md p-2 mt-2">
                                  <p className="text-xs text-muted-foreground italic">{bookmark.note}</p>
                                </div>
                              )}
                            </Link>
                            <Button
                              onClick={() => handleDeleteBookmark(bookmark.id)}
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-muted-foreground hover:text-destructive"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                          <p className="text-xs text-muted-foreground">{formatRelativeTime(bookmark.created_at)}</p>
                        </div>
                      ))}
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <Bookmark className="h-12 w-12 mx-auto mb-2 opacity-20" />
                    <p className="text-sm">尚無書籤</p>
                    <p className="text-xs mt-1">在閱讀時點擊書籤圖示來儲存經文</p>
                  </div>
                )}
              </TabsContent>

              <TabsContent value="checkins" className="space-y-4">
                {loadingCheckIns ? (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin text-primary" />
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Stats Section */}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="p-4 rounded-lg border border-primary/10 bg-gradient-to-br from-primary/5 to-accent/5">
                        <p className="text-sm text-muted-foreground mb-1">總打卡天數</p>
                        <p className="text-2xl font-bold text-primary">{totalCheckInDays}</p>
                      </div>
                      <div className="p-4 rounded-lg border border-orange-500/20 bg-gradient-to-br from-orange-50/50 to-red-50/30">
                        <p className="text-sm text-muted-foreground mb-1">當前連續</p>
                        <p className="text-2xl font-bold text-orange-500">{currentStreak} 天</p>
                      </div>
                    </div>

                    {/* Month Navigation */}
                    <div className="flex items-center justify-between">
                      <Button
                        onClick={handlePreviousMonth}
                        variant="outline"
                        size="sm"
                        className="gap-2"
                      >
                        ← 上個月
                      </Button>
                      <h3 className="text-lg font-semibold text-foreground">
                        {currentYear} 年 {currentMonth} 月
                      </h3>
                      <Button
                        onClick={handleNextMonth}
                        variant="outline"
                        size="sm"
                        className="gap-2"
                        disabled={
                          currentMonth === new Date().getMonth() + 1 &&
                          currentYear === new Date().getFullYear()
                        }
                      >
                        下個月 →
                      </Button>
                    </div>

                    {/* Calendar */}
                    <CheckInCalendar viewMode="month" checkInData={checkInData} currentStreak={currentStreak} />

                    {checkInData.length === 0 && (
                      <div className="text-center py-8 text-muted-foreground">
                        <CalendarIcon className="h-12 w-12 mx-auto mb-2 opacity-20" />
                        <p className="text-sm">本月尚無打卡記錄</p>
                        <p className="text-xs mt-1">開始閱讀聖經來記錄你的靈修之旅</p>
                      </div>
                    )}
                  </div>
                )}
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
