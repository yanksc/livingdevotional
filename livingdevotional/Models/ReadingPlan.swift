// ReadingPlan Models - Data structures for reading plans

import Foundation

// MARK: - Reading Plan Day

struct ReadingPlanDay: Codable, Identifiable, Hashable {
    let id: String
    let dayNumber: Int
    let book: String
    let chapter: Int
    let verseStart: Int?
    let verseEnd: Int?
    let description: String?
    let chapterDescription: String? // Why this chapter is worth reading
    
    init(dayNumber: Int, book: String, chapter: Int, verseStart: Int? = nil, verseEnd: Int? = nil, description: String? = nil, chapterDescription: String? = nil) {
        self.id = "\(book)-\(chapter)-\(dayNumber)"
        self.dayNumber = dayNumber
        self.book = book
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.description = description
        self.chapterDescription = chapterDescription
    }
}

// MARK: - Reading Plan

struct ReadingPlan: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let extendedDescription: String? // Extended description explaining why this plan is worth reading
    let icon: String
    let imageName: String
    let days: [ReadingPlanDay]
    let category: PlanCategory
    
    enum PlanCategory: String, Codable, Hashable {
        case book
        case topical
        case devotional
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReadingPlan, rhs: ReadingPlan) -> Bool {
        lhs.id == rhs.id
    }
    
    var duration: Int {
        days.count
    }
}

// MARK: - Reading Plan Progress

struct ReadingPlanProgress: Codable, Identifiable {
    let id: String // planId
    var currentDay: Int // 0-based, -1 means not started
    var startedAt: Date?
    var completedDays: Set<Int> // Set of completed day numbers
    var lastReadAt: Date?
    
    init(planId: String) {
        self.id = planId
        self.currentDay = -1
        self.startedAt = nil
        self.completedDays = []
        self.lastReadAt = nil
    }
    
    var isStarted: Bool {
        currentDay >= 0
    }
    
    var isCompleted: Bool {
        guard let startedAt = startedAt else { return false }
        // Consider completed if all days are done
        return !completedDays.isEmpty
    }
    
    var progressPercentage: Double {
        guard !completedDays.isEmpty else { return 0 }
        // This will be calculated based on total days in the plan
        return 0 // Placeholder, will be calculated in store
    }
}
