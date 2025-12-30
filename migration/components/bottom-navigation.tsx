"use client"

import { usePathname, useRouter } from "next/navigation"
import { Home, BookOpen, User } from "lucide-react"
import { cn } from "@/lib/utils"

export function BottomNavigation() {
  const pathname = usePathname()
  const router = useRouter()

  const isActive = (path: string) => {
    if (path === "/") {
      return pathname === "/"
    }
    return pathname.startsWith(path)
  }

  const navItems = [
    {
      label: "首頁",
      icon: Home,
      path: "/",
      active: isActive("/") && pathname === "/",
    },
    {
      label: "閱讀",
      icon: BookOpen,
      path: "/read",
      active: pathname.startsWith("/read"),
    },
    {
      label: "我的",
      icon: User,
      path: "/profile",
      active: pathname.startsWith("/profile"),
    },
  ]

  const handleNavigation = (path: string) => {
    // For "Read" tab, navigate to last reading or show book selector
    if (path === "/read") {
      const lastBook = localStorage.getItem("lastBook")
      const lastChapter = localStorage.getItem("lastChapter")
      if (lastBook && lastChapter) {
        router.push(`/read/${encodeURIComponent(lastBook)}/${lastChapter}`)
      } else {
        router.push("/read/Genesis/1")
      }
    } else {
      router.push(path)
    }
  }

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-lg border-t border-primary/10 shadow-lg bottom-nav-container">
      <div className="safe-area-inset-bottom">
        <div className="flex items-center justify-around h-16 max-w-lg mx-auto px-2">
          {navItems.map((item) => {
            const Icon = item.icon
            return (
              <button
                key={item.path}
                onClick={() => handleNavigation(item.path)}
                className={cn(
                  "flex flex-col items-center justify-center gap-1 px-6 py-2 rounded-xl transition-all duration-200 min-w-[80px]",
                  item.active
                    ? "text-white"
                    : "text-muted-foreground hover:text-primary"
                )}
              >
                <div
                  className={cn(
                    "p-2 rounded-xl transition-all duration-200",
                    item.active
                      ? "gradient-primary shadow-lg shadow-primary/30 scale-110"
                      : "bg-transparent"
                  )}
                >
                  <Icon className="h-5 w-5" />
                </div>
                <span
                  className={cn(
                    "text-xs font-medium transition-all duration-200",
                    item.active
                      ? "gradient-text font-semibold"
                      : ""
                  )}
                >
                  {item.label}
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </nav>
  )
}

