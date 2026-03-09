// FeaturePreviewView - Step 10: Swipeable feature carousel before paywall
// Shows 8 feature previews: Journey, Prayer, Chapter Context, Dual Language,
// Reading Plan, Ask Questions, Faith Journey Insights, Verse Explainer

import SwiftUI

struct FeaturePreviewView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var currentPage: Int = 0
    @State private var showContent = false
    
    private let featureCount = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Swipeable feature pages
            TabView(selection: $currentPage) {
                ForEach(0..<featureCount, id: \.self) { index in
                    featurePage(for: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // "Swipe to explore" hint below the page dots
            Text(subtitleLocalized)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                .padding(.bottom, 12)
            
            // Bottom navigation
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Make page indicator dots green
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppTheme.accentColor)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppTheme.accentColor.opacity(0.3))
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }
        }
    }
    
    private var subtitleLocalized: String {
        if state.isChinese { return "左右滑動瀏覽所有功能" }
        if state.isSpanish { return "Desliza para ver todas las funciones" }
        return "Swipe to explore all features"
    }
    
    // MARK: - Feature Pages
    
    @ViewBuilder
    private func featurePage(for index: Int) -> some View {
        if index < features.count {
        let feature = features[index]
        
        VStack(spacing: 4) {
            // Feature title + description on top
            VStack(spacing: 8) {
                Text(feature.title)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(AppTheme.accentColor)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 32)
            .padding(.bottom, 4)
            
            // Illustrative mockup card below
            featureMockup(for: index)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
        }
        }
    }
    
    // MARK: - Feature Mockups (SwiftUI illustrations)
    
    @ViewBuilder
    private func featureMockup(for index: Int) -> some View {
        switch index {
        case 0: journeyViewMockup
        case 1: prayerHelperMockup
        case 2: chapterContextMockup
        case 3: dualLanguageMockup
        case 4: readingPlanMockup
        case 5: askQuestionMockup
        case 6: pathAnalysisMockup
        case 7: verseExplainerMockup
        default: EmptyView()
        }
    }
    
    // MARK: - Mockup Card Background Helper
    
    private func mockupCardBackground() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.95))
            .shadow(color: AppTheme.accentColor.opacity(0.18), radius: 20, x: 0, y: 8)
    }
    
    private func mockupCardBorder() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 1.5)
    }
    
    // MARK: - Page 0: Journey View Mockup
    
    private var journeyViewMockup: some View {
        let displayName = state.name.isEmpty ? "Friend" : state.name
        
        return VStack(spacing: 16) {
            // Greeting row
            HStack(spacing: 10) {
                Image(systemName: "cross")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(journeyGreeting(displayName))
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(AppTheme.onboardingText)
                    Text(journeyDate)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
            }
            
            // Encouragement card
            VStack(alignment: .leading, spacing: 6) {
                Text(journeyEncouragement(displayName))
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.onboardingText.opacity(0.85))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentColor.opacity(0.08))
            )
            
            // Stats row
            HStack(spacing: 10) {
                journeyStatBox(value: "3", label: journeyStatStreak, icon: "cross.fill")
                journeyStatBox(value: "12", label: journeyStatChapters, icon: "book.fill")
                journeyStatBox(value: "5", label: journeyStatSaved, icon: "bookmark.fill")
            }
            
            // Recommended verse snippet
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.accentColor)
                    .frame(width: 3, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(journeyVerseSnippet)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundColor(AppTheme.onboardingText.opacity(0.7))
                        .lineLimit(1)
                    Text("Psalm 119:105")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.accentColor)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private func journeyGreeting(_ name: String) -> String {
        if state.isChinese { return "早安，\(name)" }
        if state.isSpanish { return "Buenos días, \(name)" }
        return "Good morning, \(name)"
    }
    
    private var journeyDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private func journeyEncouragement(_ name: String) -> String {
        if state.isChinese {
            return "\(name)，你渴望更深認識聖經的心很美。繼續走在這條路上，每一步都有恩典。"
        }
        if state.isSpanish {
            return "\(name), tu deseo de conocer las Escrituras es hermoso. Cada paso en este camino trae gracia."
        }
        return "\(name), your heart for understanding Scripture is beautiful. Keep walking this path, grace meets you at every step."
    }
    
    private var journeyStatStreak: String {
        if state.isChinese { return "連續天" }
        if state.isSpanish { return "racha" }
        return "streak"
    }
    
    private var journeyStatChapters: String {
        if state.isChinese { return "章節" }
        if state.isSpanish { return "capítulos" }
        return "chapters"
    }
    
    private var journeyStatSaved: String {
        if state.isChinese { return "已收藏" }
        if state.isSpanish { return "guardados" }
        return "saved"
    }
    
    private var journeyVerseSnippet: String {
        if state.isChinese { return "你的話是我腳前的燈，是我路上的光。" }
        if state.isSpanish { return "Tu palabra es una lámpara a mis pies..." }
        return "Your word is a lamp to my feet and a light to my path."
    }
    
    private func journeyStatBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.accentColor)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.onboardingText)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.accentColor.opacity(0.08))
        )
    }
    
    // MARK: - Page 1: Prayer Helper Mockup
    
    private var prayerHelperMockup: some View {
        VStack(spacing: 0) {
            // Dark serene prayer card
            VStack(spacing: 16) {
                // Verse card inside prayer
                VStack(spacing: 8) {
                    Text(prayerVerse)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Text(prayerVerseRef)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                
                // Prayer text preview
                VStack(alignment: .leading, spacing: 6) {
                    Text(prayerPreviewText)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(5)
                    
                    Text("...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Amen indicator
                HStack {
                    Spacer()
                    Text("Amen")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.30, blue: 0.27),
                                Color(red: 0.16, green: 0.22, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accentColor.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    private var prayerVerse: String {
        if state.isChinese {
            return "應當一無掛慮，只要凡事藉著禱告、\n祈求和感謝，將你們所要的告訴神。"
        }
        if state.isSpanish {
            return "No se inquieten por nada; más bien,\nen toda ocasión, con oración y ruego,\npresenten sus peticiones a Dios."
        }
        return "Do not be anxious about anything,\nbut in every situation, by prayer and petition,\npresent your requests to God."
    }
    
    private var prayerVerseRef: String {
        if state.isChinese { return "腓立比書 4:6" }
        if state.isSpanish { return "Filipenses 4:6" }
        return "Philippians 4:6"
    }
    
    private var prayerPreviewText: String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        if state.isChinese {
            return "天父，感謝祢的平安。求祢幫助\(name)放下心中的憂慮，學會在禱告中將一切交託給祢"
        }
        if state.isSpanish {
            return "Padre celestial, gracias por tu paz. Ayuda a \(name)soltar las preocupaciones y aprender a entregártelo todo en oración"
        }
        return "Heavenly Father, thank You for Your peace. Help \(name)release every worry and learn to bring everything to You in prayer"
    }
    
    // MARK: - Page 2: Chapter Context Mockup
    
    private var chapterContextMockup: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.accentColor)
                Text(chapterContextTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
                
                // Chapter label
                Text("Psalm 23")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor.opacity(0.1))
                    )
            }
            
            Divider().opacity(0.3)
            
            // Context text
            Text(chapterContextBody)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.onboardingText.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer().frame(height: 6)
            
            // Ask More button
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 12))
                Text(chapterContextAskMore)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(AppTheme.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppTheme.accentColor.opacity(0.1))
            )
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private var chapterContextTitle: String {
        if state.isChinese { return "章節背景" }
        if state.isSpanish { return "Contexto del Capítulo" }
        return "Chapter Context"
    }
    
    private var chapterContextBody: String {
        if state.isChinese {
            return "詩篇23篇是大衛王所寫，是聖經中最廣為人知的篇章之一。大衛以牧羊人的比喻，描述神對他子民無微不至的看顧和引導。這首詩寫於大衛經歷許多患難之後，表達了他對神深厚的信靠..."
        }
        if state.isSpanish {
            return "El Salmo 23 fue escrito por el rey David y es uno de los pasajes más conocidos de la Biblia. Usando la metáfora de un pastor, David describe el cuidado y la guía de Dios para su pueblo. Este salmo fue escrito tras muchas pruebas..."
        }
        return "Psalm 23 was written by King David and is one of the most beloved passages in all of Scripture. Using the metaphor of a shepherd, David describes God's intimate care and guidance for His people. Written after David endured many trials, this psalm expresses deep trust..."
    }
    
    private var chapterContextAskMore: String {
        if state.isChinese { return "詢問更多" }
        if state.isSpanish { return "Preguntar más" }
        return "Ask More"
    }
    
    // MARK: - Page 3: Dual Language Mockup
    
    private var dualLanguageMockup: some View {
        VStack(spacing: 14) {
            // Language toggle header
            HStack(spacing: 0) {
                Text("EN")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.accentColor)
                    )
                
                Text(dualLangSecondaryLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.accentColor.opacity(0.1))
                    )
                
                Spacer()
                
                Text("Psalm 23")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Divider().opacity(0.3)
            
            // Verse rows (mimicking real ReadingView dual-language layout)
            ForEach(0..<3, id: \.self) { i in
                dualLanguageVerseRow(
                    number: "\(i + 1)",
                    primary: dualLangPrimaryVerses[i],
                    secondary: dualLangSecondaryVerses[i]
                )
                
                if i < 2 {
                    Divider().opacity(0.15)
                }
            }
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private func dualLanguageVerseRow(number: String, primary: String, secondary: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Verse number
            Text(number)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.83, green: 0.65, blue: 0.45)) // warm sand
                .frame(width: 20, alignment: .trailing)
                .padding(.top, 2)
            
            // Primary + secondary text
            VStack(alignment: .leading, spacing: 8) {
                Text(primary)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.onboardingText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(secondary)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var dualLangSecondaryLabel: String {
        if state.isChinese { return "中文" }
        if state.isSpanish { return "ES" }
        return "中文"
    }
    
    private var dualLangPrimaryVerses: [String] {
        return [
            "The Lord is my shepherd, I shall not want.",
            "He makes me lie down in green pastures, he leads me beside quiet waters.",
            "He restores my soul. He guides me along the right paths for his name's sake."
        ]
    }
    
    private var dualLangSecondaryVerses: [String] {
        if state.isChinese || (!state.isSpanish) {
            return [
                "耶和華是我的牧者，我必不致缺乏。",
                "他使我躺臥在青草地上，領我在可安歇的水邊。",
                "他使我的靈魂甦醒，為自己的名引導我走義路。"
            ]
        }
        return [
            "El Señor es mi pastor, nada me faltará.",
            "En verdes pastos me hace descansar, junto a aguas tranquilas me conduce.",
            "Me infunde nuevas fuerzas. Me guía por sendas de justicia por amor a su nombre."
        ]
    }
    
    // MARK: - Page 4: Reading Plan Mockup (existing)
    
    private var readingPlanMockup: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.accentColor)
                Text(readingPlanMockTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Simulated plan cards
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.accentColor.opacity(0.15 + Double(i) * 0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(readingPlanDays[i])
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.2))
                            .frame(width: CGFloat(120 + i * 20), height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.1))
                            .frame(width: CGFloat(90 + i * 10), height: 8)
                    }
                    
                    Spacer()
                    
                    if i == 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.accentColor)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(AppTheme.accentColor.opacity(0.3))
                    }
                }
                .padding(.vertical, 8)
                
                if i < 2 {
                    Divider().opacity(0.3)
                }
            }
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private var readingPlanMockTitle: String {
        if state.isChinese { return "個人化閱讀計劃" }
        if state.isSpanish { return "Plan de lectura" }
        return "Your Reading Plan"
    }
    
    private var readingPlanDays: [String] {
        if state.isChinese { return ["一", "二", "三"] }
        return ["D1", "D2", "D3"]
    }
    
    // MARK: - Page 5: Ask Questions Mockup (updated)
    
    private var askQuestionMockup: some View {
        VStack(spacing: 12) {
            // Question bubble
            HStack {
                Spacer()
                Text(askQuestionBubble)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.accentColor)
                    )
            }
            
            // Response
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "cross")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.accentColor)
                        Text("Living Path")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    // Simulated response lines
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.onboardingText.opacity(0.15))
                                .frame(width: CGFloat(180 - i * 30), height: 8)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.8))
                )
                Spacer()
            }
            
            // Input field mockup
            HStack {
                Text(askQuestionPlaceholder)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accentColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private var askQuestionBubble: String {
        if state.isChinese { return "這段經文是什麼意思？" }
        if state.isSpanish { return "¿Qué significa este versículo?" }
        return "What does this verse mean?"
    }
    
    private var askQuestionPlaceholder: String {
        if state.isChinese { return "問任何關於聖經的問題..." }
        if state.isSpanish { return "Pregunta sobre la Biblia..." }
        return "Ask anything about the Bible..."
    }
    
    // MARK: - Page 6: Path Analysis Mockup (updated)
    
    private var pathAnalysisMockup: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.accentColor)
                Text(pathAnalysisMockTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
            }
            
            // Stats row
            HStack(spacing: 16) {
                statBubble(value: "12", label: pathAnalysisStatDays, icon: "flame.fill")
                statBubble(value: "48", label: pathAnalysisStatChapters, icon: "book.fill")
                statBubble(value: "7", label: pathAnalysisStatPrayers, icon: "cross.fill")
            }
            
            // Progress bar mockup
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(pathAnalysisJourney)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.onboardingText)
                    Spacer()
                    Text("24%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accentColor.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accentColor)
                            .frame(width: geo.size.width * 0.24)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private var pathAnalysisMockTitle: String {
        if state.isChinese { return "信仰旅程分析" }
        if state.isSpanish { return "Análisis del camino" }
        return "Your Faith Journey"
    }
    
    private var pathAnalysisStatDays: String {
        if state.isChinese { return "連續天" }
        if state.isSpanish { return "días" }
        return "day streak"
    }
    
    private var pathAnalysisStatChapters: String {
        if state.isChinese { return "章節" }
        if state.isSpanish { return "capítulos" }
        return "chapters"
    }
    
    private var pathAnalysisStatPrayers: String {
        if state.isChinese { return "禱告" }
        if state.isSpanish { return "oraciones" }
        return "prayers"
    }
    
    private var pathAnalysisJourney: String {
        if state.isChinese { return "新約進度" }
        if state.isSpanish { return "Progreso del NT" }
        return "New Testament"
    }
    
    private func statBubble(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentColor)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.onboardingText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.accentColor.opacity(0.08))
        )
    }
    
    // MARK: - Page 7: Verse Explainer Mockup (updated)
    
    private var verseExplainerMockup: some View {
        VStack(spacing: 16) {
            // Verse card
            VStack(spacing: 10) {
                Text(verseExplainerQuote)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(AppTheme.onboardingText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("— Psalm 23:1")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentColor.opacity(0.08))
            )
            
            // Explanation area
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cross")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.accentColor)
                    Text(verseExplainerLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Simulated explanation lines
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.12))
                            .frame(width: CGFloat(200 - i * 25), height: 8)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.8))
            )
        }
        .padding(20)
        .background(mockupCardBackground())
        .overlay(mockupCardBorder())
    }
    
    private var verseExplainerQuote: String {
        if state.isChinese { return "耶和華是我的牧者，\n我必不致缺乏。" }
        if state.isSpanish { return "El Señor es mi pastor,\nnada me faltará." }
        return "The Lord is my shepherd,\nI shall not want."
    }
    
    private var verseExplainerLabel: String {
        if state.isChinese { return "經文解析" }
        if state.isSpanish { return "Explicación del versículo" }
        return "Verse Explained"
    }
    
    // MARK: - Feature Data (8 items, no AI references)
    
    private var features: [FeatureItem] {
        let name = state.name.isEmpty ? "" : state.name
        
        if state.isChinese {
            return [
                FeatureItem(title: "你的信仰旅程", description: "\(name)，你的旅程獨一無二。追蹤讀經連續天數、收藏經文和靈性里程碑，一目了然。"),
                FeatureItem(title: "引導禱告", description: "從聖經經文和你的內心反思中，領受一段為你量身而寫的禱告。"),
                FeatureItem(title: "章節背景", description: "在開始閱讀之前，了解每一章的歷史、文化和寫作目的。"),
                FeatureItem(title: "雙語聖經", description: "以兩種語言並列閱讀聖經，加深理解或輔助語言學習。"),
                FeatureItem(title: "個人化閱讀計劃", description: "根據你的信仰階段和興趣，為你量身打造專屬的聖經閱讀計劃。"),
                FeatureItem(title: "隨時提問", description: "對任何經文有疑問？隨時提問，獲得深入淺出、扎根聖經的解答。"),
                FeatureItem(title: "信仰旅程分析", description: "追蹤你的讀經進度、禱告記錄，看見你信仰成長的軌跡。"),
                FeatureItem(title: "經文深度解析", description: "點擊任何經文，獲得歷史背景、原文含義和生活應用的完整解析。")
            ]
        } else if state.isSpanish {
            return [
                FeatureItem(title: "Tu Camino Vivo", description: "\(name), tu camino es único. Sigue tus rachas de lectura, versículos guardados y logros espirituales en un solo lugar."),
                FeatureItem(title: "Oración Guiada", description: "Recibe una oración tejida con las Escrituras y tus propias reflexiones, hecha para ti."),
                FeatureItem(title: "Contexto del Capítulo", description: "Conoce la historia, cultura y propósito detrás de cada capítulo antes de comenzar a leer."),
                FeatureItem(title: "Biblia Bilingüe", description: "Lee las Escrituras en dos idiomas lado a lado. Ideal para profundizar o aprender idiomas."),
                FeatureItem(title: "Plan de Lectura Personalizado", description: "Un plan de lectura bíblica adaptado a tu etapa de fe e intereses personales."),
                FeatureItem(title: "Pregunta lo que quieras", description: "¿Tienes preguntas sobre un versículo? Pregunta y recibe respuestas claras y fundamentadas."),
                FeatureItem(title: "Análisis de tu Camino", description: "Sigue tu progreso de lectura, oraciones y mira crecer tu camino de fe."),
                FeatureItem(title: "Explicador de Versículos", description: "Toca cualquier versículo para ver su contexto histórico, significado original y aplicación.")
            ]
        } else {
            return [
                FeatureItem(title: "Your Living Journey", description: "\(name), your journey is uniquely yours. Track your reading streaks, saved verses, and spiritual milestones all in one place."),
                FeatureItem(title: "Guided Prayer", description: "Receive a prayer woven from Scripture and your own reflections, crafted to speak to where you are right now."),
                FeatureItem(title: "Chapter Context", description: "Understand the history, culture, and purpose behind every chapter before you begin reading."),
                FeatureItem(title: "Dual Language Bible", description: "Read Scripture in two languages side by side. Perfect for deepening understanding or language learning."),
                FeatureItem(title: "Personalized Reading Plan", description: "A reading plan crafted around your faith journey and interests, guiding you through Scripture at your own pace."),
                FeatureItem(title: "Ask Any Question", description: "Have questions about a verse? Ask anything and receive thoughtful, scripture-grounded answers."),
                FeatureItem(title: "Faith Journey Insights", description: "Track your reading progress, prayers, and watch your faith journey grow."),
                FeatureItem(title: "Verse Deep Dive", description: "Tap any verse for its historical context, original meaning, and life application.")
            ]
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.goNext()
            }
        }) {
            Text(continueLocalized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(AppTheme.buttonGradient)
                .cornerRadius(OnboardingDesign.buttonCornerRadius)
        }
    }
    
    private var continueLocalized: String {
        if state.isChinese { return "繼續" }
        if state.isSpanish { return "Continuar" }
        return "Continue"
    }
}

// MARK: - Feature Item Model

private struct FeatureItem {
    let title: String
    let description: String
}
