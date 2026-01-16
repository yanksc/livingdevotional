// AICacheStore - Manages cached AI responses for verses

import Foundation
import Combine

struct AICacheEntry: Codable {
    let verseId: String
    let mode: String
    let content: String
    let timestamp: Date
}

class AICacheStore: ObservableObject {
    static let shared = AICacheStore()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "aiResponseCache"
    private var cache: [String: AICacheEntry] = [:]
    
    private init() {
        loadCache()
    }
    
    // Generate cache key from verse ID, mode, and app language
    private func cacheKey(verseId: String, mode: AIMode, appLanguage: AppLanguage) -> String {
        return "\(verseId)_\(mode.rawValue)_\(appLanguage.rawValue)"
    }
    
    // Load cache from UserDefaults
    private func loadCache() {
        guard let data = userDefaults.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([String: AICacheEntry].self, from: data) else {
            cache = [:]
            return
        }
        cache = decoded
    }
    
    // Save cache to UserDefaults
    private func saveCache() {
        if let encoded = try? JSONEncoder().encode(cache) {
            userDefaults.set(encoded, forKey: cacheKey)
        }
    }
    
    // Get cached response for a verse, mode, and app language
    func getCachedResponse(verseId: String, mode: AIMode, appLanguage: AppLanguage) -> String? {
        let key = cacheKey(verseId: verseId, mode: mode, appLanguage: appLanguage)
        return cache[key]?.content
    }
    
    // Cache a response for a verse, mode, and app language
    func cacheResponse(verseId: String, mode: AIMode, appLanguage: AppLanguage, content: String) {
        let key = cacheKey(verseId: verseId, mode: mode, appLanguage: appLanguage)
        let entry = AICacheEntry(
            verseId: verseId,
            mode: mode.rawValue,
            content: content,
            timestamp: Date()
        )
        cache[key] = entry
        saveCache()
    }
    
    // Clear cache for a specific verse, mode, and app language
    func clearCache(verseId: String, mode: AIMode, appLanguage: AppLanguage) {
        let key = cacheKey(verseId: verseId, mode: mode, appLanguage: appLanguage)
        cache.removeValue(forKey: key)
        saveCache()
    }
    
    // Clear all cache
    func clearAllCache() {
        cache.removeAll()
        saveCache()
    }
    
    // MARK: - Chapter-level caching
    
    // Generate cache key for chapter context/summary
    private func chapterCacheKey(book: String, chapter: Int, mode: String, appLanguage: AppLanguage) -> String {
        return "chapter_\(book)_\(chapter)_\(mode)_\(appLanguage.rawValue)"
    }
    
    // Get cached chapter content
    func getCachedChapterContent(book: String, chapter: Int, mode: String, appLanguage: AppLanguage) -> String? {
        let key = chapterCacheKey(book: book, chapter: chapter, mode: mode, appLanguage: appLanguage)
        return cache[key]?.content
    }
    
    // Cache chapter content
    func cacheChapterContent(book: String, chapter: Int, mode: String, appLanguage: AppLanguage, content: String) {
        let key = chapterCacheKey(book: book, chapter: chapter, mode: mode, appLanguage: appLanguage)
        let entry = AICacheEntry(
            verseId: "\(book)_\(chapter)",
            mode: mode,
            content: content,
            timestamp: Date()
        )
        cache[key] = entry
        saveCache()
    }
}
