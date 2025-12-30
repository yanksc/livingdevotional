"use client"

import { Button } from "@/components/ui/button"
import { BookOpen, Languages, User, Home } from "lucide-react"
import { getLocalizedBookName } from "@/lib/bible-data"
import type { Language } from "@/lib/types"
import Link from "next/link"
import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import type { User as SupabaseUser } from "@supabase/supabase-js"

interface ReadingHeaderProps {
  book: string
  chapter: number
  onOpenNavigation: () => void
  onOpenSettings: () => void
  primaryLanguage?: Language
}

export function ReadingHeader({
  book,
  chapter,
  onOpenNavigation,
  onOpenSettings,
  primaryLanguage = "niv",
}: ReadingHeaderProps) {
  const localizedBookName = getLocalizedBookName(book, primaryLanguage)
  const [user, setUser] = useState<SupabaseUser | null>(null)

  useEffect(() => {
    const supabase = createClient()

    supabase.auth.getUser().then(({ data: { user } }) => {
      setUser(user)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [])

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-gradient-to-r from-white/95 via-blue-50/90 to-white/95 backdrop-blur-md supports-[backdrop-filter]:bg-white/80 shadow-sm">
      <div className="flex items-center justify-between px-4 py-3">
        <Button variant="ghost" size="icon" onClick={onOpenNavigation} className="hover:bg-primary/10">
          <BookOpen className="h-5 w-5 text-primary" />
          <span className="sr-only">Open navigation</span>
        </Button>

        <div className="text-center">
          <h1 className="text-lg font-semibold gradient-text">
            {localizedBookName} {chapter}
          </h1>
        </div>

        <div className="flex items-center gap-2">
          <Link href="/">
            <Button variant="ghost" size="icon" className="hover:bg-primary/10">
              <Home className="h-5 w-5 text-primary" />
              <span className="sr-only">Home</span>
            </Button>
          </Link>
          <Button variant="ghost" size="icon" onClick={onOpenSettings} className="hover:bg-primary/10">
            <Languages className="h-5 w-5 text-primary" />
            <span className="sr-only">Open language settings</span>
          </Button>
          <Link href={user ? "/profile" : "/auth/login"}>
            <Button variant="ghost" size="icon" className="hover:bg-primary/10">
              <User className="h-5 w-5 text-primary" />
              <span className="sr-only">{user ? "Profile" : "Login"}</span>
            </Button>
          </Link>
        </div>
      </div>
    </header>
  )
}
