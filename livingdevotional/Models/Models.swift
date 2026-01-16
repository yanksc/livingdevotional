// BibleMind iOS - Swift Models
// Converted from TypeScript types.ts

import Foundation

// MARK: - Verse Mode Enum

enum AIMode: String, CaseIterable {
    case insight
    case reflect
    case pray
    
    var displayName: String {
        switch self {
        case .insight: return "Context"
        case .reflect: return "Reflect"
        case .pray: return "Pray"
        }
    }
}

// MARK: - App Font Enum

enum AppFont: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case serif = "serif"
    case rounded = "rounded"
    case sourceHanSerifCN = "sourceHanSerifCN"
    case sourceHanSerifTC = "sourceHanSerifTC"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .sourceHanSerifCN: return "Source Han Serif CN"
        case .sourceHanSerifTC: return "Source Han Serif TC"
        }
    }
    
    func localizedDisplayName(appLanguage: AppLanguage) -> String {
        switch self {
        case .system: return appLanguage.localizedString("FontSystem")
        case .serif: return appLanguage.localizedString("FontSerif")
        case .rounded: return appLanguage.localizedString("FontRounded")
        case .sourceHanSerifCN: return "思源宋體 (CN)"
        case .sourceHanSerifTC: return "思源宋體 (TC)"
        }
    }
}

// MARK: - Language Enum (Bible Translation)

enum Language: String, Codable, CaseIterable, Identifiable {
    case bsb = "bsb"
    case cuv = "cuv"
    case cu1 = "cu1"
    case kjv = "kjv"
    case web = "web"
    case spa_r09 = "spa_r09"
    case por_blj = "por_blj"
    case none = "none"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bsb: return "English (BSB)"
        case .cuv: return "中文和合本 (CUV)"
        case .cu1: return "新标点和合本"
        case .kjv: return "King James Version"
        case .web: return "English (WEB)"
        case .spa_r09: return "Español (Reina-Valera 1909)"
        case .por_blj: return "Português (Bíblia Livre)"
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        case .bsb: return "Berean Standard Bible"
        case .cuv: return "Chinese Union Version"
        case .cu1: return "Chinese Union Version with New Punctuation"
        case .kjv: return "King James Version"
        case .web: return "World English Bible"
        case .spa_r09: return "Reina-Valera 1909"
        case .por_blj: return "Bíblia Livre"
        case .none: return "僅顯示主要語言"
        }
    }
}

// MARK: - AppLanguage Enum (UI Language)

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english = "en"
    case chineseTraditional = "zh-Hant"
    case chineseSimplified = "zh-Hans"
    case spanish = "es"
    case portuguese = "pt"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .chineseTraditional: return "繁體中文"
        case .chineseSimplified: return "简体中文"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        }
    }
    
    /// Resolve to a specific locale identifier, using system locale if .system
    func resolvedLocale() -> Locale {
        switch self {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .chineseTraditional:
            return Locale(identifier: "zh-Hant")
        case .chineseSimplified:
            return Locale(identifier: "zh-Hans")
        case .spanish:
            return Locale(identifier: "es")
        case .portuguese:
            return Locale(identifier: "pt")
        }
    }
    
    /// Get the resolved language code for book name localization
    func resolvedLanguageCode() -> String {
        switch self {
        case .system:
            // Use system's preferred language
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                // Detect Simplified vs Traditional Chinese
                if preferredLanguage.contains("Hans") || preferredLanguage.contains("CN") {
                    return "zh-Hans"
                }
                return "zh-Hant"
            }
            if preferredLanguage.hasPrefix("es") {
                return "es"
            }
            if preferredLanguage.hasPrefix("pt") {
                return "pt"
            }
            return "en"
        case .english:
            return "en"
        case .chineseTraditional:
            return "zh-Hant"
        case .chineseSimplified:
            return "zh-Hans"
        case .spanish:
            return "es"
        case .portuguese:
            return "pt"
        }
    }
    
    /// Localize interface strings based on app language
    func localizedString(_ key: String) -> String {
        let languageCode = resolvedLanguageCode()
        
        // Interface string mappings
        let strings: [String: [String: String]] = [
            "Home": ["en": "Home", "zh-Hant": "首頁", "zh-Hans": "首页", "es": "Inicio", "pt": "Início"],
            "Welcome": ["en": "Welcome", "zh-Hant": "歡迎", "zh-Hans": "欢迎", "es": "Bienvenido", "pt": "Bem-vindo"],
            "WelcomeSubtitle": ["en": "Start your daily devotional journey", "zh-Hant": "開始您的每日靈修之旅", "zh-Hans": "开始您的每日灵修之旅", "es": "Comienza tu viaje devocional diario", "pt": "Comece sua jornada devocional diária"],
            "VerseOfTheDay": ["en": "Verse of the Day", "zh-Hant": "今日金句", "zh-Hans": "今日金句", "es": "Versículo del Día", "pt": "Versículo do Dia"],
            "QuickActions": ["en": "Quick Actions", "zh-Hant": "快速操作", "zh-Hans": "快速操作", "es": "Acciones Rápidas", "pt": "Ações Rápidas"],
            "ContinueReading": ["en": "Continue Reading", "zh-Hant": "繼續閱讀", "zh-Hans": "继续阅读", "es": "Continuar Leyendo", "pt": "Continuar Lendo"],
            "ReadBible": ["en": "Read Bible", "zh-Hant": "讀經", "zh-Hans": "读经", "es": "Leer Biblia", "pt": "Ler Bíblia"],
            "MyNotes": ["en": "My Notes", "zh-Hant": "我的筆記", "zh-Hans": "我的笔记", "es": "Mis Notas", "pt": "Minhas Notas"],
            "ReadChapter": ["en": "Read Chapter", "zh-Hant": "閱讀章節", "zh-Hans": "阅读章节", "es": "Leer Capítulo", "pt": "Ler Capítulo"],
            "SavedNotes": ["en": "My Notes", "zh-Hant": "我的筆記", "zh-Hans": "我的笔记", "es": "Mis Notas", "pt": "Minhas Notas"],
            "ViewAll": ["en": "View All", "zh-Hant": "查看全部", "zh-Hans": "查看全部", "es": "Ver Todo", "pt": "Ver Tudo"],
            "NoRecentReading": ["en": "No recent reading", "zh-Hant": "沒有最近的閱讀記錄", "zh-Hans": "没有最近的阅读记录", "es": "No hay lectura reciente", "pt": "Nenhuma leitura recente"],
            "NoSavedVerses": ["en": "No saved verses yet", "zh-Hant": "尚未保存任何經文", "zh-Hans": "尚未保存任何经文", "es": "Aún no hay versículos guardados", "pt": "Nenhum versículo salvo ainda"],
            "UnableToLoadVerse": ["en": "Unable to load verse", "zh-Hant": "無法載入經文", "zh-Hans": "无法载入经文", "es": "No se puede cargar el versículo", "pt": "Não foi possível carregar o versículo"],
            "Loading": ["en": "Loading...", "zh-Hant": "載入中...", "zh-Hans": "载入中...", "es": "Cargando...", "pt": "Carregando..."],
            "ErrorLoadingVerses": ["en": "Error loading verses", "zh-Hant": "載入經文時發生錯誤", "zh-Hans": "载入经文时发生错误", "es": "Error al cargar versículos", "pt": "Erro ao carregar versículos"],
            "NoVersesFound": ["en": "No verses found", "zh-Hant": "找不到經文", "zh-Hans": "找不到经文", "es": "No se encontraron versículos", "pt": "Nenhum versículo encontrado"],
            "Retry": ["en": "Retry", "zh-Hant": "重試", "zh-Hans": "重试", "es": "Reintentar", "pt": "Tentar Novamente"],
            "Bible": ["en": "Bible", "zh-Hant": "聖經", "zh-Hans": "圣经", "es": "Biblia", "pt": "Bíblia"],
            "Books": ["en": "Books", "zh-Hant": "書卷", "zh-Hans": "书卷", "es": "Libros", "pt": "Livros"],
            "Chapter": ["en": "chapter", "zh-Hant": "章", "zh-Hans": "章", "es": "capítulo", "pt": "capítulo"],
            "Chapters": ["en": "chapters", "zh-Hant": "章", "zh-Hans": "章", "es": "capítulos", "pt": "capítulos"],
            "SelectBook": ["en": "Select Book", "zh-Hant": "選擇書卷", "zh-Hans": "选择书卷", "es": "Seleccionar Libro", "pt": "Selecionar Livro"],
            "Done": ["en": "Done", "zh-Hant": "完成", "zh-Hans": "完成", "es": "Hecho", "pt": "Concluído"],
            "ViewSettings": ["en": "View Settings", "zh-Hant": "檢視設定", "zh-Hans": "查看设置", "es": "Ver Configuración", "pt": "Ver Configurações"],
            "FontSize": ["en": "Font Size", "zh-Hant": "字體大小", "zh-Hans": "字体大小", "es": "Tamaño de Fuente", "pt": "Tamanho da Fonte"],
            "LineSpacing": ["en": "Line Spacing", "zh-Hant": "行距", "zh-Hans": "行距", "es": "Espaciado de Líneas", "pt": "Espaçamento entre Linhas"],
            "Language": ["en": "Language", "zh-Hant": "語言", "zh-Hans": "语言", "es": "Idioma", "pt": "Idioma"],
            "ShowSecondLanguage": ["en": "Show Second Language", "zh-Hant": "顯示第二語言", "zh-Hans": "显示第二语言", "es": "Mostrar Segundo Idioma", "pt": "Mostrar Segundo Idioma"],
            "Appearance": ["en": "Appearance", "zh-Hant": "外觀", "zh-Hans": "外观", "es": "Apariencia", "pt": "Aparência"],
            "AIExplanation": ["en": "Explanation", "zh-Hant": "解釋", "zh-Hans": "解释", "es": "Explicación", "pt": "Explicação"],
            "GeneratingExplanation": ["en": "Loading explanation...", "zh-Hant": "載入解釋中...", "zh-Hans": "载入解释中...", "es": "Cargando explicación...", "pt": "Carregando explicação..."],
            "AIInsight": ["en": "Context", "zh-Hant": "理解", "zh-Hans": "理解", "es": "Comprensión", "pt": "Compreensão"],
            "AIReflect": ["en": "Reflect", "zh-Hant": "反思", "zh-Hans": "反思", "es": "Reflexionar", "pt": "Refletir"],
            "AIPray": ["en": "Pray", "zh-Hant": "禱告", "zh-Hans": "祷告", "es": "Orar", "pt": "Orar"],
            "Font": ["en": "Font", "zh-Hant": "字體", "zh-Hans": "字体", "es": "Fuente", "pt": "Fonte"],
            "FontSystem": ["en": "System", "zh-Hant": "系統", "zh-Hans": "系统", "es": "Sistema", "pt": "Sistema"],
            "FontSerif": ["en": "Serif", "zh-Hant": "襯線", "zh-Hans": "衬线", "es": "Serif", "pt": "Serif"],
            "FontRounded": ["en": "Rounded", "zh-Hant": "圓體", "zh-Hans": "圆体", "es": "Redondeado", "pt": "Arredondado"],
            "BibleTranslation": ["en": "Bible Translation", "zh-Hant": "聖經譯本", "zh-Hans": "圣经译本", "es": "Traducción de la Biblia", "pt": "Tradução da Bíblia"],
            "PrimaryTranslation": ["en": "Primary Translation", "zh-Hant": "主要譯本", "zh-Hans": "主要译本", "es": "Traducción Principal", "pt": "Tradução Principal"],
            "SecondaryTranslation": ["en": "Secondary Translation", "zh-Hant": "次要譯本", "zh-Hans": "次要译本", "es": "Traducción Secundaria", "pt": "Tradução Secundária"],
            "ReadingSettings": ["en": "Reading Settings", "zh-Hant": "閱讀設定", "zh-Hans": "阅读设置", "es": "Configuración de Lectura", "pt": "Configurações de Leitura"],
            "ReadingHistory": ["en": "Reading History", "zh-Hant": "閱讀歷史", "zh-Hans": "阅读历史", "es": "Historial de Lectura", "pt": "Histórico de Leitura"],
            "NoReadingHistory": ["en": "No reading history", "zh-Hant": "沒有閱讀歷史", "zh-Hans": "没有阅读历史", "es": "No hay historial de lectura", "pt": "Nenhum histórico de leitura"],
            "ReadingHistoryEmptyMessage": ["en": "Your reading history will appear here as you read chapters", "zh-Hant": "當您閱讀章節時，閱讀歷史會顯示在這裡", "zh-Hans": "当您阅读章节时，阅读历史会显示在这里", "es": "Tu historial de lectura aparecerá aquí mientras lees capítulos", "pt": "Seu histórico de leitura aparecerá aqui conforme você ler capítulos"],
            "RecentHistory": ["en": "Recent History", "zh-Hant": "最近閱讀", "zh-Hans": "最近阅读", "es": "Historial Reciente", "pt": "Histórico Recente"],
            "AppLanguage": ["en": "App Language", "zh-Hant": "應用程式語言", "zh-Hans": "应用程序语言", "es": "Idioma de la Aplicación", "pt": "Idioma do Aplicativo"],
            "Profile": ["en": "Profile", "zh-Hant": "個人檔案", "zh-Hans": "个人档案", "es": "Perfil", "pt": "Perfil"],
            "NotSet": ["en": "Not Set", "zh-Hant": "未設定", "zh-Hans": "未设置", "es": "No Establecido", "pt": "Não Definido"],
            "ResetProfile": ["en": "Reset Profile", "zh-Hant": "重置個人檔案", "zh-Hans": "重置个人档案", "es": "Restablecer Perfil", "pt": "Redefinir Perfil"],
            "HistoryAndMyNotes": ["en": "History & My Notes", "zh-Hant": "歷史記錄與我的筆記", "zh-Hans": "历史记录与我的笔记", "es": "Historial y Mis Notas", "pt": "Histórico e Minhas Notas"],
            "ClearChatHistory": ["en": "Clear Chat History", "zh-Hant": "清除聊天記錄", "zh-Hans": "清除聊天记录", "es": "Borrar Historial de Chat", "pt": "Limpar Histórico de Chat"],
            "QAHistory": ["en": "Q&A History", "zh-Hant": "問答記錄", "zh-Hans": "问答记录", "es": "Historial de Preguntas y Respuestas", "pt": "Histórico de Perguntas e Respostas"],
            "PrayerRecords": ["en": "Prayer Records", "zh-Hant": "禱告記錄", "zh-Hans": "祷告记录", "es": "Registros de Oración", "pt": "Registros de Oração"],
            "Notifications": ["en": "Notifications", "zh-Hant": "通知設定", "zh-Hans": "通知设置", "es": "Notificaciones", "pt": "Notificações"],
            "EnableNotifications": ["en": "Enable Notifications", "zh-Hant": "啟用通知", "zh-Hans": "启用通知", "es": "Activar Notificaciones", "pt": "Ativar Notificações"],
            "MorningDevotional": ["en": "Morning Devotional", "zh-Hant": "早晨靈修提醒", "zh-Hans": "早晨灵修提醒", "es": "Devocional Matutino", "pt": "Devocional Matutino"],
            "PrayerReminder": ["en": "Prayer Reminder", "zh-Hant": "禱告提醒", "zh-Hans": "祷告提醒", "es": "Recordatorio de Oración", "pt": "Lembrete de Oração"],
            "StreakAlerts": ["en": "Streak Alerts", "zh-Hant": "連續紀錄提醒", "zh-Hans": "连续记录提醒", "es": "Alertas de Racha", "pt": "Alertas de Sequência"],
            "About": ["en": "About", "zh-Hant": "關於", "zh-Hans": "关于", "es": "Acerca de", "pt": "Sobre"],
            "Version": ["en": "Version", "zh-Hant": "版本", "zh-Hans": "版本", "es": "Versión", "pt": "Versão"],
            "Settings": ["en": "Settings", "zh-Hant": "設定", "zh-Hans": "设置", "es": "Configuración", "pt": "Configurações"],
            "Pray": ["en": "Pray", "zh-Hant": "禱告", "zh-Hans": "祷告", "es": "Orar", "pt": "Orar"],
            "FindVerse": ["en": "Find Verse", "zh-Hant": "搜尋經文", "zh-Hans": "搜寻经文", "es": "Buscar Versículo", "pt": "Encontrar Versículo"],
            "ViewMore": ["en": "View %d more...", "zh-Hant": "查看其他 %d 項...", "zh-Hans": "查看其他 %d 项...", "es": "Ver %d más...", "pt": "Ver %d mais..."]
        ]
        
        return strings[key]?[languageCode] ?? strings[key]?["en"] ?? key
    }
}

// MARK: - Bible Verse

struct BibleVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textKjv: String
    let textWeb: String
    let textSpa: String
    let textPor: String
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textKjv = "text_kjv"
        case textWeb = "text_web"
        case textSpa = "text_spa"
        case textPor = "text_por"
    }
    
    /// Get text for specified language
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .kjv: return textKjv
        case .web: return textWeb
        case .spa_r09: return textSpa
        case .por_blj: return textPor
        case .none: return ""
        }
    }
}

// MARK: - Bible Book

struct BibleBook: Codable, Identifiable, Hashable {
    let name: String
    let testament: Testament
    let chapters: Int
    let hasData: Bool
    
    var id: String { name }
    
    enum Testament: String, Codable {
        case old = "Old"
        case new = "New"
        
        var displayName: String {
            switch self {
            case .old: return "舊約"
            case .new: return "新約"
            }
        }
        
        var displayNameSimplified: String {
            switch self {
            case .old: return "旧约"
            case .new: return "新约"
            }
        }
        
        var englishName: String {
            switch self {
            case .old: return "Old Testament"
            case .new: return "New Testament"
            }
        }
        
        func localizedDisplayName(for appLanguage: AppLanguage) -> String {
            let languageCode = appLanguage.resolvedLanguageCode()
            switch self {
            case .old:
                if languageCode == "zh-Hant" {
                    return "舊約"
                } else if languageCode == "zh-Hans" {
                    return "旧约"
                } else if languageCode == "es" {
                    return "Antiguo Testamento"
                } else if languageCode == "pt" {
                    return "Antigo Testamento"
                } else {
                    return "Old Testament"
                }
            case .new:
                if languageCode == "zh-Hant" {
                    return "新約"
                } else if languageCode == "zh-Hans" {
                    return "新约"
                } else if languageCode == "es" {
                    return "Nuevo Testamento"
                } else if languageCode == "pt" {
                    return "Novo Testamento"
                } else {
                    return "New Testament"
                }
            }
        }
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Identifiable {
    let id: String?
    let userId: String
    var primaryLanguage: Language
    var secondaryLanguage: Language
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case primaryLanguage = "primary_language"
        case secondaryLanguage = "secondary_language"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Verse Bookmark

struct VerseBookmark: Codable, Identifiable {
    let id: String
    let userId: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let verseText: String
    var note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case book, chapter
        case verseNumber = "verse_number"
        case verseText = "verse_text"
        case note
        case createdAt = "created_at"
    }
}

// MARK: - Reading Progress

struct ReadingProgress: Codable, Identifiable {
    let id: String?
    let userId: String
    let book: String
    let chapter: Int
    let lastVerse: Int
    let lastReadAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case book, chapter
        case lastVerse = "last_verse"
        case lastReadAt = "last_read_at"
    }
}

// MARK: - Daily Verse (Verse of the Day)

struct DailyVerse: Codable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textKjv: String
    let textWeb: String
    let textSpa: String
    let textPor: String
    let reference: String
    let selectedDate: String
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textKjv = "text_kjv"
        case textWeb = "text_web"
        case textSpa = "text_spa"
        case textPor = "text_por"
        case selectedDate = "selected_date"
    }
    
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .kjv: return textKjv
        case .web: return textWeb
        case .spa_r09: return textSpa
        case .por_blj: return textPor
        case .none: return ""
        }
    }
}

// MARK: - Related Verse

struct RelatedVerse: Codable, Identifiable {
    let book: String
    let chapter: Int
    let verse: Int
    let reference: String
    let text: String
    let relevance: String
    
    var id: String { reference }
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, verse, reference, text, relevance
    }
}

// MARK: - Verse Search Response

struct VerseSearchResponse: Codable {
    let interpretation: String
    let results: [RelatedVerse]
}

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable {
    private let _id: String?
    let role: MessageRole
    let content: String
    let createdAt: Date?
    
    // Non-optional id for Identifiable conformance
    var id: String {
        _id ?? UUID().uuidString
    }
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
    
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case role, content
        case createdAt = "created_at"
    }
    
    init(id: String? = nil, role: MessageRole, content: String, createdAt: Date? = nil) {
        self._id = id ?? UUID().uuidString
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Verse Conversation

struct VerseConversation: Codable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    var messages: [ChatMessage]
    
    enum CodingKeys: String, CodingKey {
        case book, chapter
        case verseNumber = "verse_number"
        case messages
    }
}

// MARK: - Daily Check-in

struct DailyCheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let checkInDate: String
    let readCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case checkInDate = "check_in_date"
        case readCount = "read_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Search Result

struct SearchResult: Codable, Identifiable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textCuv: String
    let textBsb: String
    let reference: String
    let relevance: String
    
    var id: String { reference }
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference, relevance
        case verseNumber = "verse_number"
        case textCuv = "text_cuv"
        case textBsb = "text_bsb"
    }
}

// MARK: - Search Response

struct SearchResponse: Codable {
    let results: [SearchResult]
    let message: String
}

// MARK: - Curated Verse (for VOTD pool)

struct CuratedVerse: Codable, Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let category: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, category
        case verseNumber = "verse_number"
        case createdAt = "created_at"
    }
}

