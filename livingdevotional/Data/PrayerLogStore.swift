// PrayerLogStore - Manages prayer logs using JSON file storage

import Foundation
import Combine

struct PrayerLog: Codable, Identifiable {
    let id: String
    let date: Date
    let topic: String // Selected topic (e.g., "worry", "gratitude", or "custom")
    let customTopicText: String? // User-entered text if topic is "custom"
    let verseReference: String // e.g., "John 3:16"
    let verseBook: String
    let verseChapter: Int
    let verseNumber: Int
    let verseText: String
    let prayerText: String
    let emotionalNeed: String? // Selected emotional need
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        topic: String,
        customTopicText: String? = nil,
        verseReference: String,
        verseBook: String,
        verseChapter: Int,
        verseNumber: Int,
        verseText: String,
        prayerText: String,
        emotionalNeed: String? = nil
    ) {
        self.id = id
        self.date = date
        self.topic = topic
        self.customTopicText = customTopicText
        self.verseReference = verseReference
        self.verseBook = verseBook
        self.verseChapter = verseChapter
        self.verseNumber = verseNumber
        self.verseText = verseText
        self.prayerText = prayerText
        self.emotionalNeed = emotionalNeed
    }
}

class PrayerLogStore: ObservableObject {
    static let shared = PrayerLogStore()
    
    @Published var logs: [PrayerLog] = []
    
    private let fileManager = FileManager.default
    private let fileName = "prayer_logs.json"
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {
        loadLogs()
    }
    
    // MARK: - CRUD Operations
    
    func addLog(_ log: PrayerLog) {
        logs.insert(log, at: 0) // Most recent first
        saveLogs()
    }
    
    func getAllLogs() -> [PrayerLog] {
        return logs
    }
    
    func getRecentLogs(limit: Int = 10) -> [PrayerLog] {
        return Array(logs.prefix(limit))
    }
    
    func getLogsByTopic(_ topic: String) -> [PrayerLog] {
        return logs.filter { $0.topic == topic }
    }
    
    func deleteLog(id: String) {
        logs.removeAll { $0.id == id }
        saveLogs()
    }
    
    // MARK: - Persistence
    
    private func loadLogs() {
        guard let url = fileURL, fileManager.fileExists(atPath: url.path) else {
            logs = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            logs = try decoder.decode([PrayerLog].self, from: data)
            
            // Sort by date descending
            logs.sort { $0.date > $1.date }
        } catch {
            print("Error loading prayer logs: \(error)")
            logs = []
        }
    }
    
    private func saveLogs() {
        guard let url = fileURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(logs)
            try data.write(to: url)
        } catch {
            print("Error saving prayer logs: \(error)")
        }
    }
}
