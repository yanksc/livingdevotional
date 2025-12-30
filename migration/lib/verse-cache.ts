/**
 * Simple in-memory cache for Bible verses to avoid redundant API calls
 * Uses LRU (Least Recently Used) eviction policy with a max size
 */

import type { BibleVerse } from "./types"

interface CacheEntry {
  data: BibleVerse[]
  timestamp: number
}

const MAX_CACHE_SIZE = 20 // Cache up to 20 chapters
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

class VerseCache {
  private cache: Map<string, CacheEntry> = new Map()

  private generateKey(bookId: string, chapter: number, primaryLanguage: string, secondaryLanguage: string): string {
    return `${bookId}-${chapter}-${primaryLanguage}-${secondaryLanguage}`
  }

  get(bookId: string, chapter: number, primaryLanguage: string, secondaryLanguage: string): BibleVerse[] | null {
    const key = this.generateKey(bookId, chapter, primaryLanguage, secondaryLanguage)
    const entry = this.cache.get(key)

    if (!entry) {
      return null
    }

    // Check if cache entry has expired
    if (Date.now() - entry.timestamp > CACHE_TTL) {
      this.cache.delete(key)
      return null
    }

    // Move to end (most recently used)
    this.cache.delete(key)
    this.cache.set(key, entry)

    return entry.data
  }

  set(
    bookId: string,
    chapter: number,
    primaryLanguage: string,
    secondaryLanguage: string,
    data: BibleVerse[],
  ): void {
    const key = this.generateKey(bookId, chapter, primaryLanguage, secondaryLanguage)

    // Evict oldest entry if cache is full
    if (this.cache.size >= MAX_CACHE_SIZE && !this.cache.has(key)) {
      const firstKey = this.cache.keys().next().value
      if (firstKey) {
        this.cache.delete(firstKey)
      }
    }

    this.cache.set(key, {
      data,
      timestamp: Date.now(),
    })
  }

  clear(): void {
    this.cache.clear()
  }

  invalidate(bookId: string, chapter: number): void {
    // Remove all language variants of a chapter
    const keysToDelete: string[] = []
    for (const key of this.cache.keys()) {
      if (key.startsWith(`${bookId}-${chapter}-`)) {
        keysToDelete.push(key)
      }
    }
    keysToDelete.forEach((key) => this.cache.delete(key))
  }
}

// Singleton instance
export const verseCache = new VerseCache()







