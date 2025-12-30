// BibleMind iOS - Bible Data
// Converted from TypeScript bible-data.ts

import Foundation

// MARK: - Bible Books Data

struct BibleData {
    
    // Complete list of Bible books with chapter counts
    static let books: [BibleBook] = [
        // Old Testament
        BibleBook(name: "Genesis", testament: .old, chapters: 50, hasData: true),
        BibleBook(name: "Exodus", testament: .old, chapters: 40, hasData: true),
        BibleBook(name: "Leviticus", testament: .old, chapters: 27, hasData: true),
        BibleBook(name: "Numbers", testament: .old, chapters: 36, hasData: true),
        BibleBook(name: "Deuteronomy", testament: .old, chapters: 34, hasData: true),
        BibleBook(name: "Joshua", testament: .old, chapters: 24, hasData: true),
        BibleBook(name: "Judges", testament: .old, chapters: 21, hasData: true),
        BibleBook(name: "Ruth", testament: .old, chapters: 4, hasData: true),
        BibleBook(name: "1 Samuel", testament: .old, chapters: 31, hasData: true),
        BibleBook(name: "2 Samuel", testament: .old, chapters: 24, hasData: true),
        BibleBook(name: "1 Kings", testament: .old, chapters: 22, hasData: true),
        BibleBook(name: "2 Kings", testament: .old, chapters: 25, hasData: true),
        BibleBook(name: "1 Chronicles", testament: .old, chapters: 29, hasData: true),
        BibleBook(name: "2 Chronicles", testament: .old, chapters: 36, hasData: true),
        BibleBook(name: "Ezra", testament: .old, chapters: 10, hasData: true),
        BibleBook(name: "Nehemiah", testament: .old, chapters: 13, hasData: true),
        BibleBook(name: "Esther", testament: .old, chapters: 10, hasData: true),
        BibleBook(name: "Job", testament: .old, chapters: 42, hasData: true),
        BibleBook(name: "Psalms", testament: .old, chapters: 150, hasData: true),
        BibleBook(name: "Proverbs", testament: .old, chapters: 31, hasData: true),
        BibleBook(name: "Ecclesiastes", testament: .old, chapters: 12, hasData: true),
        BibleBook(name: "Song of Solomon", testament: .old, chapters: 8, hasData: true),
        BibleBook(name: "Isaiah", testament: .old, chapters: 66, hasData: true),
        BibleBook(name: "Jeremiah", testament: .old, chapters: 52, hasData: true),
        BibleBook(name: "Lamentations", testament: .old, chapters: 5, hasData: true),
        BibleBook(name: "Ezekiel", testament: .old, chapters: 48, hasData: true),
        BibleBook(name: "Daniel", testament: .old, chapters: 12, hasData: true),
        BibleBook(name: "Hosea", testament: .old, chapters: 14, hasData: true),
        BibleBook(name: "Joel", testament: .old, chapters: 3, hasData: true),
        BibleBook(name: "Amos", testament: .old, chapters: 9, hasData: true),
        BibleBook(name: "Obadiah", testament: .old, chapters: 1, hasData: true),
        BibleBook(name: "Jonah", testament: .old, chapters: 4, hasData: true),
        BibleBook(name: "Micah", testament: .old, chapters: 7, hasData: true),
        BibleBook(name: "Nahum", testament: .old, chapters: 3, hasData: true),
        BibleBook(name: "Habakkuk", testament: .old, chapters: 3, hasData: true),
        BibleBook(name: "Zephaniah", testament: .old, chapters: 3, hasData: true),
        BibleBook(name: "Haggai", testament: .old, chapters: 2, hasData: true),
        BibleBook(name: "Zechariah", testament: .old, chapters: 14, hasData: true),
        BibleBook(name: "Malachi", testament: .old, chapters: 4, hasData: true),
        
        // New Testament
        BibleBook(name: "Matthew", testament: .new, chapters: 28, hasData: true),
        BibleBook(name: "Mark", testament: .new, chapters: 16, hasData: true),
        BibleBook(name: "Luke", testament: .new, chapters: 24, hasData: true),
        BibleBook(name: "John", testament: .new, chapters: 21, hasData: true),
        BibleBook(name: "Acts", testament: .new, chapters: 28, hasData: true),
        BibleBook(name: "Romans", testament: .new, chapters: 16, hasData: true),
        BibleBook(name: "1 Corinthians", testament: .new, chapters: 16, hasData: true),
        BibleBook(name: "2 Corinthians", testament: .new, chapters: 13, hasData: true),
        BibleBook(name: "Galatians", testament: .new, chapters: 6, hasData: true),
        BibleBook(name: "Ephesians", testament: .new, chapters: 6, hasData: true),
        BibleBook(name: "Philippians", testament: .new, chapters: 4, hasData: true),
        BibleBook(name: "Colossians", testament: .new, chapters: 4, hasData: true),
        BibleBook(name: "1 Thessalonians", testament: .new, chapters: 5, hasData: true),
        BibleBook(name: "2 Thessalonians", testament: .new, chapters: 3, hasData: true),
        BibleBook(name: "1 Timothy", testament: .new, chapters: 6, hasData: true),
        BibleBook(name: "2 Timothy", testament: .new, chapters: 4, hasData: true),
        BibleBook(name: "Titus", testament: .new, chapters: 3, hasData: true),
        BibleBook(name: "Philemon", testament: .new, chapters: 1, hasData: true),
        BibleBook(name: "Hebrews", testament: .new, chapters: 13, hasData: true),
        BibleBook(name: "James", testament: .new, chapters: 5, hasData: true),
        BibleBook(name: "1 Peter", testament: .new, chapters: 5, hasData: true),
        BibleBook(name: "2 Peter", testament: .new, chapters: 3, hasData: true),
        BibleBook(name: "1 John", testament: .new, chapters: 5, hasData: true),
        BibleBook(name: "2 John", testament: .new, chapters: 1, hasData: true),
        BibleBook(name: "3 John", testament: .new, chapters: 1, hasData: true),
        BibleBook(name: "Jude", testament: .new, chapters: 1, hasData: true),
        BibleBook(name: "Revelation", testament: .new, chapters: 22, hasData: true),
    ]
    
    // Book ID mapping for Bible API
    static let bookIdMap: [String: String] = [
        "Genesis": "GEN",
        "Exodus": "EXO",
        "Leviticus": "LEV",
        "Numbers": "NUM",
        "Deuteronomy": "DEU",
        "Joshua": "JOS",
        "Judges": "JDG",
        "Ruth": "RUT",
        "1 Samuel": "1SA",
        "2 Samuel": "2SA",
        "1 Kings": "1KI",
        "2 Kings": "2KI",
        "1 Chronicles": "1CH",
        "2 Chronicles": "2CH",
        "Ezra": "EZR",
        "Nehemiah": "NEH",
        "Esther": "EST",
        "Job": "JOB",
        "Psalms": "PSA",
        "Proverbs": "PRO",
        "Ecclesiastes": "ECC",
        "Song of Solomon": "SNG",
        "Isaiah": "ISA",
        "Jeremiah": "JER",
        "Lamentations": "LAM",
        "Ezekiel": "EZK",
        "Daniel": "DAN",
        "Hosea": "HOS",
        "Joel": "JOL",
        "Amos": "AMO",
        "Obadiah": "OBA",
        "Jonah": "JON",
        "Micah": "MIC",
        "Nahum": "NAM",
        "Habakkuk": "HAB",
        "Zephaniah": "ZEP",
        "Haggai": "HAG",
        "Zechariah": "ZEC",
        "Malachi": "MAL",
        "Matthew": "MAT",
        "Mark": "MRK",
        "Luke": "LUK",
        "John": "JHN",
        "Acts": "ACT",
        "Romans": "ROM",
        "1 Corinthians": "1CO",
        "2 Corinthians": "2CO",
        "Galatians": "GAL",
        "Ephesians": "EPH",
        "Philippians": "PHP",
        "Colossians": "COL",
        "1 Thessalonians": "1TH",
        "2 Thessalonians": "2TH",
        "1 Timothy": "1TI",
        "2 Timothy": "2TI",
        "Titus": "TIT",
        "Philemon": "PHM",
        "Hebrews": "HEB",
        "James": "JAS",
        "1 Peter": "1PE",
        "2 Peter": "2PE",
        "1 John": "1JN",
        "2 John": "2JN",
        "3 John": "3JN",
        "Jude": "JUD",
        "Revelation": "REV",
    ]
    
    // Chinese book name mapping
    static let chineseBookNames: [String: String] = [
        // Old Testament
        "Genesis": "創世記",
        "Exodus": "出埃及記",
        "Leviticus": "利未記",
        "Numbers": "民數記",
        "Deuteronomy": "申命記",
        "Joshua": "約書亞記",
        "Judges": "士師記",
        "Ruth": "路得記",
        "1 Samuel": "撒母耳記上",
        "2 Samuel": "撒母耳記下",
        "1 Kings": "列王紀上",
        "2 Kings": "列王紀下",
        "1 Chronicles": "歷代志上",
        "2 Chronicles": "歷代志下",
        "Ezra": "以斯拉記",
        "Nehemiah": "尼希米記",
        "Esther": "以斯帖記",
        "Job": "約伯記",
        "Psalms": "詩篇",
        "Proverbs": "箴言",
        "Ecclesiastes": "傳道書",
        "Song of Solomon": "雅歌",
        "Isaiah": "以賽亞書",
        "Jeremiah": "耶利米書",
        "Lamentations": "耶利米哀歌",
        "Ezekiel": "以西結書",
        "Daniel": "但以理書",
        "Hosea": "何西阿書",
        "Joel": "約珥書",
        "Amos": "阿摩司書",
        "Obadiah": "俄巴底亞書",
        "Jonah": "約拿書",
        "Micah": "彌迦書",
        "Nahum": "那鴻書",
        "Habakkuk": "哈巴谷書",
        "Zephaniah": "西番雅書",
        "Haggai": "哈該書",
        "Zechariah": "撒迦利亞書",
        "Malachi": "瑪拉基書",
        // New Testament
        "Matthew": "馬太福音",
        "Mark": "馬可福音",
        "Luke": "路加福音",
        "John": "約翰福音",
        "Acts": "使徒行傳",
        "Romans": "羅馬書",
        "1 Corinthians": "哥林多前書",
        "2 Corinthians": "哥林多後書",
        "Galatians": "加拉太書",
        "Ephesians": "以弗所書",
        "Philippians": "腓立比書",
        "Colossians": "歌羅西書",
        "1 Thessalonians": "帖撒羅尼迦前書",
        "2 Thessalonians": "帖撒羅尼迦後書",
        "1 Timothy": "提摩太前書",
        "2 Timothy": "提摩太後書",
        "Titus": "提多書",
        "Philemon": "腓利門書",
        "Hebrews": "希伯來書",
        "James": "雅各書",
        "1 Peter": "彼得前書",
        "2 Peter": "彼得後書",
        "1 John": "約翰一書",
        "2 John": "約翰二書",
        "3 John": "約翰三書",
        "Jude": "猶大書",
        "Revelation": "啟示錄",
    ]
    
    // MARK: - Helper Methods
    
    /// Get book by name
    static func book(named name: String) -> BibleBook? {
        books.first { $0.name == name }
    }
    
    /// Get book ID for API calls
    static func bookId(for bookName: String) -> String? {
        bookIdMap[bookName]
    }
    
    /// Get Old Testament books
    static var oldTestamentBooks: [BibleBook] {
        books.filter { $0.testament == .old }
    }
    
    /// Get New Testament books
    static var newTestamentBooks: [BibleBook] {
        books.filter { $0.testament == .new }
    }
    
    /// Get localized book name based on language
    static func localizedBookName(_ bookName: String, language: Language) -> String {
        switch language {
        case .cuv, .cu1:
            return chineseBookNames[bookName] ?? bookName
        case .niv, .none:
            return bookName
        }
    }
    
    /// Get localized testament name
    static func localizedTestamentName(_ testament: BibleBook.Testament, language: Language) -> String {
        switch language {
        case .cuv, .cu1:
            return testament.displayName
        case .niv, .none:
            return testament.englishName
        }
    }
}

// MARK: - BibleBook Extension for Localization

extension BibleBook {
    /// Get localized name
    func localizedName(for language: Language) -> String {
        BibleData.localizedBookName(name, language: language)
    }
    
    /// Get API book ID
    var apiBookId: String? {
        BibleData.bookId(for: name)
    }
}


