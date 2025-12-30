"use client"

import { useState, useEffect, useMemo, useCallback } from "react"
import { useRouter } from "next/navigation"
import type { BibleVerse, Language, SupabaseUser } from "@/lib/types"
import { VerseDisplay } from "@/components/verse-display"
import { ChapterNavigation } from "@/components/chapter-navigation"
import { NavigationDrawer } from "@/components/navigation-drawer"
import { SettingsDrawer } from "@/components/settings-drawer"
import { BibleSearchDialog } from "@/components/bible-search-dialog"
import { ErrorBoundary } from "@/components/error-boundary"
import { getBookId } from "@/lib/bible-data"
import { loadChapterWithLanguages } from "@/lib/bible-json-loader"
import { createClient } from "@/lib/supabase/client"
import { verseCache } from "@/lib/verse-cache"
import { recordDailyCheckIn } from "@/lib/actions/checkin-actions"
import { getLocalizedBookName } from "@/lib/bible-data"
import { Loader2, Menu, Settings, Search } from "lucide-react"
import { Button } from "@/components/ui/button"

interface ReadingViewProps {
  book: string
  chapter: number
  totalChapters: number
  hasData: boolean
}

export function ReadingView({ book, chapter, totalChapters, hasData }: ReadingViewProps) {
  const router = useRouter()
  const [navOpen, setNavOpen] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const [primaryLanguage, setPrimaryLanguage] = useState<Language>("cuv")
  const [secondaryLanguage, setSecondaryLanguage] = useState<Language>("niv")
  const [verses, setVerses] = useState<BibleVerse[]>([])
  const [loading, setLoading] = useState(true)
  const [targetVerseNumber, setTargetVerseNumber] = useState<number | null>(null)
  const [user, setUser] = useState<SupabaseUser | null>(null)
  const [showBottomNav, setShowBottomNav] = useState(true)
  const [lastScrollY, setLastScrollY] = useState(0)

  // Show loading immediately when chapter changes
  useEffect(() => {
    setLoading(true)
    setVerses([])
  }, [book, chapter])

  useEffect(() => {
    const savedPrimary = localStorage.getItem("primaryLanguage") as Language
    const savedSecondary = localStorage.getItem("secondaryLanguage") as Language
    if (savedPrimary) setPrimaryLanguage(savedPrimary)
    if (savedSecondary) setSecondaryLanguage(savedSecondary)
  }, [])

  // Memoize the user and preferences loading to avoid redundant calls
  useEffect(() => {
    let mounted = true
    const supabase = createClient()

    const loadUserAndPreferences = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser()
        
        if (!mounted) return
        setUser(user)

        if (user) {
          // Load preferences from database
          const { data: prefs } = await supabase
            .from("user_preferences")
            .select("*")
            .eq("user_id", user.id)
            .single()

          if (!mounted) return

          if (prefs) {
            setPrimaryLanguage(prefs.primary_language as Language)
            setSecondaryLanguage(prefs.secondary_language as Language)
            localStorage.setItem("primaryLanguage", prefs.primary_language)
            localStorage.setItem("secondaryLanguage", prefs.secondary_language)
          } else {
            // Create default preferences
            const savedPrimary = (localStorage.getItem("primaryLanguage") as Language) || "cuv"
            const savedSecondary = (localStorage.getItem("secondaryLanguage") as Language) || "niv"

            await supabase.from("user_preferences").insert({
              user_id: user.id,
              primary_language: savedPrimary,
              secondary_language: savedSecondary,
            })

            if (!mounted) return
            setPrimaryLanguage(savedPrimary)
            setSecondaryLanguage(savedSecondary)
          }
        } else {
          // Not logged in, use localStorage
          const savedPrimary = localStorage.getItem("primaryLanguage") as Language
          const savedSecondary = localStorage.getItem("secondaryLanguage") as Language
          if (savedPrimary) setPrimaryLanguage(savedPrimary)
          if (savedSecondary) setSecondaryLanguage(savedSecondary)
        }
      } catch (error) {
        console.error("Error loading user preferences:", error)
      }
    }

    loadUserAndPreferences()
    
    return () => {
      mounted = false
    }
  }, [])

  useEffect(() => {
    async function loadVerses() {
      setLoading(true)
      const bookId = getBookId(book)
      if (!bookId) {
        setVerses([])
        setLoading(false)
        return
      }

      // Check cache first
      const cachedVerses = verseCache.get(bookId, chapter, primaryLanguage, secondaryLanguage)
      if (cachedVerses) {
        setVerses(cachedVerses)
        setLoading(false)
        
        // Handle hash-based verse navigation
        if (typeof window !== "undefined" && window.location.hash) {
          const hash = window.location.hash
          const match = hash.match(/#verse-(\d+)/)
          if (match) {
            const verseNum = Number.parseInt(match[1], 10)
            setTargetVerseNumber(verseNum)
            setTimeout(() => {
              const element = document.querySelector(hash)
              if (element) {
                element.scrollIntoView({ behavior: "smooth", block: "center" })
              }
            }, 100)
          }
        }
        return
      }

      let loadedVerses: BibleVerse[] = []

      if (hasData) {
        // Load from JSON API with user's selected languages
        loadedVerses = await loadChapterWithLanguages(bookId, chapter, primaryLanguage, secondaryLanguage)
      }

      // Fallback to Supabase if JSON didn't return data
      if (loadedVerses.length === 0) {
        const supabase = createClient()
        const { data, error } = await supabase
          .from("bible_verses")
          .select("*")
          .ilike("book", book)
          .eq("chapter", chapter)
          .order("verse_number", { ascending: true })

        if (!error && data) {
          loadedVerses = data
        }
      }

      // Cache the loaded verses
      if (loadedVerses.length > 0) {
        verseCache.set(bookId, chapter, primaryLanguage, secondaryLanguage, loadedVerses)
      }

      setVerses(loadedVerses)
      setLoading(false)

      // Handle hash-based verse navigation
      if (typeof window !== "undefined" && window.location.hash) {
        const hash = window.location.hash
        const match = hash.match(/#verse-(\d+)/)
        if (match) {
          const verseNum = Number.parseInt(match[1], 10)
          setTargetVerseNumber(verseNum)
          setTimeout(() => {
            const element = document.querySelector(hash)
            if (element) {
              element.scrollIntoView({ behavior: "smooth", block: "center" })
            }
          }, 100)
        }
      }
    }

    loadVerses()
  }, [book, chapter, primaryLanguage, secondaryLanguage, hasData])

  // Debounce reading progress updates to avoid excessive API calls
  useEffect(() => {
    if (!user) return
    
    // Debounce the reading progress update by 2 seconds
    const timeoutId = setTimeout(async () => {
      try {
        const supabase = createClient()
        await supabase
          .from("reading_progress")
          .upsert(
            {
              user_id: user.id,
              book,
              chapter,
              last_verse: 1,
              last_read_at: new Date().toISOString(),
            },
            {
              onConflict: "user_id,book,chapter",
            },
          )
        
        // Update localStorage for quick access
        localStorage.setItem("lastBook", book)
        localStorage.setItem("lastChapter", chapter.toString())
      } catch (error) {
        console.error("Error updating reading progress:", error)
      }
    }, 2000)
    
    return () => clearTimeout(timeoutId)
  }, [book, chapter, user])

  // Record daily check-in when user reads any chapter
  useEffect(() => {
    if (!user) return

    // Get user's local date in YYYY-MM-DD format
    const localDate = getLocalDateString()

    // Record check-in silently in the background
    recordDailyCheckIn(localDate).catch((error) => {
      console.error("Error recording check-in:", error)
    })
  }, [book, chapter, user])

  // Helper function to get local date string
  const getLocalDateString = () => {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  // Auto-hide bottom nav on scroll
  useEffect(() => {
    if (!user) return // Only apply auto-hide when logged in

    let ticking = false

    const handleScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          const currentScrollY = window.scrollY

          if (currentScrollY > lastScrollY && currentScrollY > 100) {
            // Scrolling down & past threshold - hide nav
            setShowBottomNav(false)
          } else if (currentScrollY < lastScrollY) {
            // Scrolling up - show nav
            setShowBottomNav(true)
          }

          setLastScrollY(currentScrollY)
          ticking = false
        })

        ticking = true
      }
    }

    window.addEventListener("scroll", handleScroll, { passive: true })

    return () => {
      window.removeEventListener("scroll", handleScroll)
    }
  }, [lastScrollY, user])

  // Show nav on tap when hidden
  const handleTapToReveal = () => {
    if (!showBottomNav) {
      setShowBottomNav(true)
    }
  }

  const handlePrimaryLanguageChange = async (language: Language) => {
    setPrimaryLanguage(language)
    localStorage.setItem("primaryLanguage", language)

    if (user) {
      const supabase = createClient()
      await supabase.from("user_preferences").upsert(
        {
          user_id: user.id,
          primary_language: language,
          secondary_language: secondaryLanguage,
        },
        {
          onConflict: "user_id",
        },
      )
    }
  }

  const handleSecondaryLanguageChange = async (language: Language) => {
    setSecondaryLanguage(language)
    localStorage.setItem("secondaryLanguage", language)

    if (user) {
      const supabase = createClient()
      await supabase.from("user_preferences").upsert(
        {
          user_id: user.id,
          primary_language: primaryLanguage,
          secondary_language: language,
        },
        {
          onConflict: "user_id",
        },
      )
    }
  }

  const handleNavigate = (newBook: string, newChapter: number) => {
    // Immediately show loading state for navigation
    setLoading(true)
    setVerses([])
    router.push(`/read/${encodeURIComponent(newBook)}/${newChapter}`)
  }

  const handleChapterNavigate = (newChapter: number) => {
    // Immediately show loading state
    setLoading(true)
    setVerses([])
    router.push(`/read/${encodeURIComponent(book)}/${newChapter}`)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-12 w-12 animate-spin text-primary" />
          <p className="text-muted-foreground animate-pulse">
            載入 {getLocalizedBookName(book, primaryLanguage)} 第 {chapter} 章...
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col">
      {/* Minimal header with navigation and settings */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-lg border-b border-primary/10 shadow-sm">
        <div className="flex items-center justify-between px-4 py-3 max-w-3xl mx-auto">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setNavOpen(true)}
            className="gap-2 text-primary hover:bg-primary/5"
          >
            <Menu className="h-5 w-5" />
            <span className="font-semibold">{getLocalizedBookName(book, primaryLanguage)} {chapter}</span>
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setSettingsOpen(true)}
            className="text-primary hover:bg-primary/5"
          >
            <Settings className="h-5 w-5" />
          </Button>
        </div>
      </header>

      <main className="flex-1 max-w-3xl mx-auto w-full px-4 py-4">
        <ErrorBoundary>
          <VerseDisplay
            verses={verses}
            primaryLanguage={primaryLanguage}
            secondaryLanguage={secondaryLanguage}
            currentBook={book}
            currentChapter={chapter}
            targetVerseNumber={targetVerseNumber}
            onVerseSelected={() => setTargetVerseNumber(null)}
            bookId={book}
          />
        </ErrorBoundary>
      </main>

      <ChapterNavigation
        currentChapter={chapter}
        totalChapters={totalChapters}
        onNavigate={handleChapterNavigate}
        bookName={book}
        primaryLanguage={primaryLanguage}
      />

      {/* Tap to reveal area at bottom */}
      {user && !showBottomNav && (
        <div
          onClick={handleTapToReveal}
          className="fixed bottom-0 left-0 right-0 h-16 z-30 cursor-pointer"
          aria-label="Tap to reveal navigation"
        />
      )}

      {/* Control bottom nav visibility with CSS */}
      <style jsx global>{`
        .bottom-nav-container {
          transition: transform 0.3s ease-in-out;
          transform: translateY(${showBottomNav ? '0' : '100%'});
        }
      `}</style>

      <NavigationDrawer
        open={navOpen}
        onOpenChange={setNavOpen}
        onNavigate={handleNavigate}
        currentBook={book}
        currentChapter={chapter}
        primaryLanguage={primaryLanguage}
      />

      <SettingsDrawer
        open={settingsOpen}
        onOpenChange={setSettingsOpen}
        primaryLanguage={primaryLanguage}
        secondaryLanguage={secondaryLanguage}
        onPrimaryLanguageChange={handlePrimaryLanguageChange}
        onSecondaryLanguageChange={handleSecondaryLanguageChange}
      />

      <BibleSearchDialog
        open={searchOpen}
        onOpenChange={setSearchOpen}
        primaryLanguage={primaryLanguage}
        secondaryLanguage={secondaryLanguage}
      />

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
    </div>
  )
}
