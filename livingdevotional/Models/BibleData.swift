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
    
    // Simplified Chinese book name mapping
    static let chineseSimplifiedBookNames: [String: String] = [
        // Old Testament
        "Genesis": "创世记",
        "Exodus": "出埃及记",
        "Leviticus": "利未记",
        "Numbers": "民数记",
        "Deuteronomy": "申命记",
        "Joshua": "约书亚记",
        "Judges": "士师记",
        "Ruth": "路得记",
        "1 Samuel": "撒母耳记上",
        "2 Samuel": "撒母耳记下",
        "1 Kings": "列王纪上",
        "2 Kings": "列王纪下",
        "1 Chronicles": "历代志上",
        "2 Chronicles": "历代志下",
        "Ezra": "以斯拉记",
        "Nehemiah": "尼希米记",
        "Esther": "以斯帖记",
        "Job": "约伯记",
        "Psalms": "诗篇",
        "Proverbs": "箴言",
        "Ecclesiastes": "传道书",
        "Song of Solomon": "雅歌",
        "Isaiah": "以赛亚书",
        "Jeremiah": "耶利米书",
        "Lamentations": "耶利米哀歌",
        "Ezekiel": "以西结书",
        "Daniel": "但以理书",
        "Hosea": "何西阿书",
        "Joel": "约珥书",
        "Amos": "阿摩司书",
        "Obadiah": "俄巴底亚书",
        "Jonah": "约拿书",
        "Micah": "弥迦书",
        "Nahum": "那鸿书",
        "Habakkuk": "哈巴谷书",
        "Zephaniah": "西番雅书",
        "Haggai": "哈该书",
        "Zechariah": "撒迦利亚书",
        "Malachi": "玛拉基书",
        // New Testament
        "Matthew": "马太福音",
        "Mark": "马可福音",
        "Luke": "路加福音",
        "John": "约翰福音",
        "Acts": "使徒行传",
        "Romans": "罗马书",
        "1 Corinthians": "哥林多前书",
        "2 Corinthians": "哥林多后书",
        "Galatians": "加拉太书",
        "Ephesians": "以弗所书",
        "Philippians": "腓立比书",
        "Colossians": "歌罗西书",
        "1 Thessalonians": "帖撒罗尼迦前书",
        "2 Thessalonians": "帖撒罗尼迦后书",
        "1 Timothy": "提摩太前书",
        "2 Timothy": "提摩太后书",
        "Titus": "提多书",
        "Philemon": "腓利门书",
        "Hebrews": "希伯来书",
        "James": "雅各书",
        "1 Peter": "彼得前书",
        "2 Peter": "彼得后书",
        "1 John": "约翰一书",
        "2 John": "约翰二书",
        "3 John": "约翰三书",
        "Jude": "犹大书",
        "Revelation": "启示录",
    ]
    
    // Spanish book name mapping
    static let spanishBookNames: [String: String] = [
        // Old Testament
        "Genesis": "Génesis",
        "Exodus": "Éxodo",
        "Leviticus": "Levítico",
        "Numbers": "Números",
        "Deuteronomy": "Deuteronomio",
        "Joshua": "Josué",
        "Judges": "Jueces",
        "Ruth": "Rut",
        "1 Samuel": "1 Samuel",
        "2 Samuel": "2 Samuel",
        "1 Kings": "1 Reyes",
        "2 Kings": "2 Reyes",
        "1 Chronicles": "1 Crónicas",
        "2 Chronicles": "2 Crónicas",
        "Ezra": "Esdras",
        "Nehemiah": "Nehemías",
        "Esther": "Ester",
        "Job": "Job",
        "Psalms": "Salmos",
        "Proverbs": "Proverbios",
        "Ecclesiastes": "Eclesiastés",
        "Song of Solomon": "Cantares",
        "Isaiah": "Isaías",
        "Jeremiah": "Jeremías",
        "Lamentations": "Lamentaciones",
        "Ezekiel": "Ezequiel",
        "Daniel": "Daniel",
        "Hosea": "Oseas",
        "Joel": "Joel",
        "Amos": "Amós",
        "Obadiah": "Abdías",
        "Jonah": "Jonás",
        "Micah": "Miqueas",
        "Nahum": "Nahúm",
        "Habakkuk": "Habacuc",
        "Zephaniah": "Sofonías",
        "Haggai": "Hageo",
        "Zechariah": "Zacarías",
        "Malachi": "Malaquías",
        // New Testament
        "Matthew": "Mateo",
        "Mark": "Marcos",
        "Luke": "Lucas",
        "John": "Juan",
        "Acts": "Hechos",
        "Romans": "Romanos",
        "1 Corinthians": "1 Corintios",
        "2 Corinthians": "2 Corintios",
        "Galatians": "Gálatas",
        "Ephesians": "Efesios",
        "Philippians": "Filipenses",
        "Colossians": "Colosenses",
        "1 Thessalonians": "1 Tesalonicenses",
        "2 Thessalonians": "2 Tesalonicenses",
        "1 Timothy": "1 Timoteo",
        "2 Timothy": "2 Timoteo",
        "Titus": "Tito",
        "Philemon": "Filemón",
        "Hebrews": "Hebreos",
        "James": "Santiago",
        "1 Peter": "1 Pedro",
        "2 Peter": "2 Pedro",
        "1 John": "1 Juan",
        "2 John": "2 Juan",
        "3 John": "3 Juan",
        "Jude": "Judas",
        "Revelation": "Apocalipsis",
    ]
    
    // Portuguese book name mapping
    static let portugueseBookNames: [String: String] = [
        // Old Testament
        "Genesis": "Gênesis",
        "Exodus": "Êxodo",
        "Leviticus": "Levítico",
        "Numbers": "Números",
        "Deuteronomy": "Deuteronômio",
        "Joshua": "Josué",
        "Judges": "Juízes",
        "Ruth": "Rute",
        "1 Samuel": "1 Samuel",
        "2 Samuel": "2 Samuel",
        "1 Kings": "1 Reis",
        "2 Kings": "2 Reis",
        "1 Chronicles": "1 Crônicas",
        "2 Chronicles": "2 Crônicas",
        "Ezra": "Esdras",
        "Nehemiah": "Neemias",
        "Esther": "Ester",
        "Job": "Jó",
        "Psalms": "Salmos",
        "Proverbs": "Provérbios",
        "Ecclesiastes": "Eclesiastes",
        "Song of Solomon": "Cantares",
        "Isaiah": "Isaías",
        "Jeremiah": "Jeremias",
        "Lamentations": "Lamentações",
        "Ezekiel": "Ezequiel",
        "Daniel": "Daniel",
        "Hosea": "Oséias",
        "Joel": "Joel",
        "Amos": "Amós",
        "Obadiah": "Obadias",
        "Jonah": "Jonas",
        "Micah": "Miquéias",
        "Nahum": "Naum",
        "Habakkuk": "Habacuque",
        "Zephaniah": "Sofonias",
        "Haggai": "Ageu",
        "Zechariah": "Zacarias",
        "Malachi": "Malaquias",
        // New Testament
        "Matthew": "Mateus",
        "Mark": "Marcos",
        "Luke": "Lucas",
        "John": "João",
        "Acts": "Atos",
        "Romans": "Romanos",
        "1 Corinthians": "1 Coríntios",
        "2 Corinthians": "2 Coríntios",
        "Galatians": "Gálatas",
        "Ephesians": "Efésios",
        "Philippians": "Filipenses",
        "Colossians": "Colossenses",
        "1 Thessalonians": "1 Tessalonicenses",
        "2 Thessalonians": "2 Tessalonicenses",
        "1 Timothy": "1 Timóteo",
        "2 Timothy": "2 Timóteo",
        "Titus": "Tito",
        "Philemon": "Filemom",
        "Hebrews": "Hebreus",
        "James": "Tiago",
        "1 Peter": "1 Pedro",
        "2 Peter": "2 Pedro",
        "1 John": "1 João",
        "2 John": "2 João",
        "3 John": "3 João",
        "Jude": "Judas",
        "Revelation": "Apocalipse",
    ]
    
    // MARK: - Helper Methods
    
    /// Get book by name with fuzzy matching
    /// Supports exact match, case-insensitive match, and common aliases
    static func book(named name: String) -> BibleBook? {
        // First try exact match
        if let exact = books.first(where: { $0.name == name }) {
            return exact
        }
        
        // Try normalized fuzzy match (case-insensitive, trimmed)
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let fuzzy = books.first(where: { 
            $0.name.caseInsensitiveCompare(normalized) == .orderedSame 
        }) {
            return fuzzy
        }
        
        // Try common aliases
        let aliases: [String: String] = [
            "Psalm": "Psalms",
            "Song of Songs": "Song of Solomon",
            "Songs": "Song of Solomon",
            "1John": "1 John",
            "2John": "2 John",
            "3John": "3 John",
            "1Peter": "1 Peter",
            "2Peter": "2 Peter",
            "1Samuel": "1 Samuel",
            "2Samuel": "2 Samuel",
            "1Kings": "1 Kings",
            "2Kings": "2 Kings",
            "1Chronicles": "1 Chronicles",
            "2Chronicles": "2 Chronicles",
            "1Corinthians": "1 Corinthians",
            "2Corinthians": "2 Corinthians",
            "1Thessalonians": "1 Thessalonians",
            "2Thessalonians": "2 Thessalonians",
            "1Timothy": "1 Timothy",
            "2Timothy": "2 Timothy"
        ]
        
        if let aliasedName = aliases[normalized] {
            return books.first { $0.name == aliasedName }
        }
        
        // No match found
        return nil
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
    
    /// Get localized book name based on app language
    static func localizedBookName(_ bookName: String, appLanguage: AppLanguage) -> String {
        let languageCode = appLanguage.resolvedLanguageCode()
        if languageCode == "zh-Hans" {
            return chineseSimplifiedBookNames[bookName] ?? bookName
        } else if languageCode == "zh-Hant" {
            return chineseBookNames[bookName] ?? bookName
        } else if languageCode == "es" {
            return spanishBookNames[bookName] ?? bookName
        } else if languageCode == "pt" {
            return portugueseBookNames[bookName] ?? bookName
        } else {
            return bookName
        }
    }
    
    /// Get localized testament name based on app language
    static func localizedTestamentName(_ testament: BibleBook.Testament, appLanguage: AppLanguage) -> String {
        return testament.localizedDisplayName(for: appLanguage)
    }
    
    /// Get localized "Chapter" text based on app language
    static func localizedChapterText(appLanguage: AppLanguage) -> String {
        let languageCode = appLanguage.resolvedLanguageCode()
        if languageCode == "zh-Hans" || languageCode == "zh-Hant" {
            return "第"
        } else if languageCode == "es" {
            return "Capítulo"
        } else if languageCode == "pt" {
            return "Capítulo"
        } else {
            return "Chapter"
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    /// Get localized book name based on language (legacy - uses translation to infer UI language)
    static func localizedBookName(_ bookName: String, language: Language) -> String {
        switch language {
        case .cuv, .cu1:
            return chineseBookNames[bookName] ?? bookName
        case .spa_r09:
            return spanishBookNames[bookName] ?? bookName
        case .por_blj:
            return portugueseBookNames[bookName] ?? bookName
        case .bsb, .kjv, .web, .none:
            return bookName
        }
    }
    
    /// Get localized testament name (legacy)
    static func localizedTestamentName(_ testament: BibleBook.Testament, language: Language) -> String {
        switch language {
        case .cuv, .cu1:
            return testament.displayName
        case .spa_r09:
            return testament == .old ? "Antiguo Testamento" : "Nuevo Testamento"
        case .por_blj:
            return testament == .old ? "Antigo Testamento" : "Novo Testamento"
        case .bsb, .kjv, .web, .none:
            return testament.englishName
        }
    }
    
    /// Get localized "Chapter" text (legacy)
    static func localizedChapterText(language: Language) -> String {
        switch language {
        case .cuv, .cu1:
            return "第"
        case .spa_r09:
            return "Capítulo"
        case .por_blj:
            return "Capítulo"
        case .bsb, .kjv, .web, .none:
            return "Chapter"
        }
    }
}

// MARK: - BibleBook Extension for Localization

extension BibleBook {
    /// Get localized name based on app language
    func localizedName(for appLanguage: AppLanguage) -> String {
        BibleData.localizedBookName(name, appLanguage: appLanguage)
    }
    
    /// Get localized name (legacy - uses translation to infer UI language)
    func localizedName(for language: Language) -> String {
        BibleData.localizedBookName(name, language: language)
    }
    
    /// Get API book ID
    var apiBookId: String? {
        BibleData.bookId(for: name)
    }
}

