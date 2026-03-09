// SupporterFullPaywallView - Standalone paywall combining feature carousel + pricing
// Used from MainTabView when usage limit is hit (not during onboarding).
// Page 1: Features + mission + CTA. Page 2: SupporterPricingView.

import SwiftUI

struct SupporterFullPaywallView: View {
    var contextualHeader: String?
    let onDismiss: () -> Void
    
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var currentPage: Int = 0
    @State private var showPricing = false
    
    private let featureCount = 8
    
    var body: some View {
        ZStack {
            if !showPricing {
                invitationContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
            
            if showPricing {
                SupporterPricingView(
                    state: nil,
                    contextualHeader: contextualHeader,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showPricing = false
                        }
                    },
                    onDismiss: onDismiss
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .trailing)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showPricing)
    }
    
    // MARK: - Page 1: Invitation Content
    
    private var invitationContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if let header = contextualHeader, !header.isEmpty {
                        Text(header)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }
                    
                    // Feature carousel
                    featureCarousel
                    
                    // Mission statement
                    missionStatementSection
                    
                    // CTA buttons
                    actionsView
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Actions (CTA + Dismiss)
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPricing = true
                }
            }) {
                Text(ctaLocalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button(action: onDismiss) {
                Text(dismissLocalized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 36)
    }
    
    private var ctaLocalized: String {
        if isChinese { return "開始免費試用" }
        if isSpanish { return "Iniciar prueba gratuita" }
        return "Start Free Trial"
    }
    
    private var dismissLocalized: String {
        if isChinese { return "之後再說" }
        if isSpanish { return "Quizás más tarde" }
        return "Not right now"
    }
    
    // MARK: - Feature Carousel
    
    private var featureCarousel: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<featureCount, id: \.self) { index in
                featurePage(for: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 420)
        .onAppear {
            // Configure page indicator colors (localized to this TabView)
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppTheme.accentColor)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppTheme.accentColor.opacity(0.3))
        }
    }
    
    // MARK: - Feature Page (Title + Description + Mockup)
    
    @ViewBuilder
    private func featurePage(for index: Int) -> some View {
        let feature = featureItems[index]
        
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
            
            // Illustrative mockup card below (extra bottom padding prevents overlap with page dots)
            featureMockup(for: index)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
        }
    }
    
    @ViewBuilder
    private func featureMockup(for index: Int) -> some View {
        switch index {
        case 0: compactJourneyMockup
        case 1: compactPrayerMockup
        case 2: compactChapterContextMockup
        case 3: compactDualLanguageMockup
        case 4: compactReadingPlanMockup
        case 5: compactAskQuestionMockup
        case 6: compactPathAnalysisMockup
        case 7: compactVerseExplainerMockup
        default: EmptyView()
        }
    }
    
    // MARK: - Mission Statement
    
    private var missionStatementSection: some View {
        VStack(spacing: 12) {
            Text(missionHeaderLocalized)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(AppTheme.onboardingText)
                .multilineTextAlignment(.center)
            
            Text(missionBodyLocalized)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }
    
    private var missionHeaderLocalized: String {
        if isChinese {
            return "支持神國度的擴展"
        }
        if isSpanish {
            return "Apoya la expansión del Reino"
        }
        return "Support God's Kingdom"
    }
    
    private var missionBodyLocalized: String {
        if isChinese {
            return "你的支持幫助我們持續開發新功能，讓世界各地更多人能夠接觸神的話語。一起將聖經帶到更多心靈中。"
        }
        if isSpanish {
            return "Tu apoyo nos ayuda a seguir desarrollando nuevas funciones y llevar la Palabra de Dios a más personas en todo el mundo. Juntos, llevamos las Escrituras a más corazones."
        }
        return "Your support helps us continue developing new features and bring God's Word to more people around the world. Together, we're bringing Scripture to more hearts."
    }
    
    // MARK: - Compact Journey Mockup
    
    private var compactJourneyMockup: some View {
        HStack(spacing: 12) {
            // Stat boxes
            ForEach(journeyStats, id: \.label) { stat in
                VStack(spacing: 4) {
                    Image(systemName: stat.icon)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.accentColor)
                    Text(stat.value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.onboardingText)
                    Text(stat.label)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accentColor.opacity(0.08))
                )
            }
        }
        .padding(16)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var journeyStats: [(icon: String, value: String, label: String)] {
        if isChinese {
            return [
                ("cross.fill", "3", "連續天"),
                ("book.fill", "12", "章節"),
                ("bookmark.fill", "5", "已收藏")
            ]
        }
        if isSpanish {
            return [
                ("cross.fill", "3", "racha"),
                ("book.fill", "12", "capítulos"),
                ("bookmark.fill", "5", "guardados")
            ]
        }
        return [
            ("cross.fill", "3", "streak"),
            ("book.fill", "12", "chapters"),
            ("bookmark.fill", "5", "saved")
        ]
    }
    
    // MARK: - Compact Prayer Mockup
    
    private var compactPrayerMockup: some View {
        VStack(spacing: 10) {
            // Verse snippet
            Text(compactPrayerVerse)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Text(compactPrayerRef)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            // Prayer preview
            Text(compactPrayerPreview)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Text("...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
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
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accentColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var compactPrayerVerse: String {
        if isChinese { return "應當一無掛慮，只要凡事藉著禱告，將你們所要的告訴神。" }
        if isSpanish { return "No se inquieten por nada; presenten sus peticiones a Dios." }
        return "Do not be anxious about anything, but present your requests to God."
    }
    
    private var compactPrayerRef: String {
        if isChinese { return "腓立比書 4:6" }
        if isSpanish { return "Filipenses 4:6" }
        return "Philippians 4:6"
    }
    
    private var compactPrayerPreview: String {
        if isChinese { return "天父，感謝祢的平安。求祢幫助放下心中的憂慮..." }
        if isSpanish { return "Padre celestial, gracias por tu paz. Ayúdame a soltar las preocupaciones..." }
        return "Heavenly Father, thank You for Your peace. Help me release every worry..."
    }
    
    // MARK: - Compact Dual Language Mockup
    
    private var compactDualLanguageMockup: some View {
        VStack(spacing: 8) {
            // Language toggle
            HStack(spacing: 0) {
                Text("EN")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentColor))
                
                Text(isChinese ? "中文" : (isSpanish ? "ES" : "中文"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentColor.opacity(0.1)))
                
                Spacer()
            }
            
            // Two verse rows
            ForEach(0..<2, id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(i + 1)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.83, green: 0.65, blue: 0.45))
                        .frame(width: 16, alignment: .trailing)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(compactDualPrimary[i])
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .foregroundColor(AppTheme.onboardingText)
                            .lineLimit(2)
                        Text(compactDualSecondary[i])
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                if i == 0 {
                    Divider().opacity(0.15)
                }
            }
        }
        .padding(14)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var compactDualPrimary: [String] {
        return [
            "The Lord is my shepherd, I shall not want.",
            "He makes me lie down in green pastures."
        ]
    }
    
    private var compactDualSecondary: [String] {
        if isSpanish {
            return [
                "El Señor es mi pastor, nada me faltará.",
                "En verdes pastos me hace descansar."
            ]
        }
        return [
            "耶和華是我的牧者，我必不致缺乏。",
            "他使我躺臥在青草地上。"
        ]
    }
    
    // MARK: - Compact Chapter Context Mockup
    
    private var compactChapterContextMockup: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accentColor)
                Text(isChinese ? "章節背景" : (isSpanish ? "Contexto" : "Chapter Context"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
                Text("Psalm 23")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppTheme.accentColor.opacity(0.1)))
            }
            
            Divider().opacity(0.3)
            
            Text(compactChapterBody)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.onboardingText.opacity(0.8))
                .lineSpacing(3)
                .lineLimit(4)
            
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 10))
                Text(isChinese ? "詢問更多" : (isSpanish ? "Preguntar más" : "Ask More"))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(AppTheme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppTheme.accentColor.opacity(0.1)))
        }
        .padding(14)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var compactChapterBody: String {
        if isChinese {
            return "詩篇23篇是大衛王所寫，是聖經中最廣為人知的篇章之一。大衛以牧羊人的比喻，描述神對他子民的看顧和引導。"
        }
        if isSpanish {
            return "El Salmo 23 fue escrito por el rey David y es uno de los pasajes más conocidos de la Biblia, describiendo el cuidado de Dios."
        }
        return "Psalm 23 was written by King David and is one of the most beloved passages in all of Scripture, describing God's intimate care and guidance."
    }
    
    // MARK: - Compact Reading Plan Mockup
    
    private var compactReadingPlanMockup: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.accentColor)
                Text(readingPlanMockTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Simulated plan cards
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.accentColor.opacity(0.15 + Double(i) * 0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(readingPlanDays[i])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.2))
                            .frame(width: CGFloat(110 + i * 15), height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.1))
                            .frame(width: CGFloat(80 + i * 10), height: 7)
                    }
                    
                    Spacer()
                    
                    if i == 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accentColor)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accentColor.opacity(0.3))
                    }
                }
                .padding(.vertical, 6)
                
                if i < 2 {
                    Divider().opacity(0.3)
                }
            }
        }
        .padding(16)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var readingPlanMockTitle: String {
        if isChinese { return "個人化閱讀計劃" }
        if isSpanish { return "Plan de lectura" }
        return "Your Reading Plan"
    }
    
    private var readingPlanDays: [String] {
        if isChinese { return ["一", "二", "三"] }
        return ["D1", "D2", "D3"]
    }
    
    // MARK: - Compact Ask Question Mockup
    
    private var compactAskQuestionMockup: some View {
        VStack(spacing: 10) {
            // Question bubble
            HStack {
                Spacer()
                Text(askQuestionBubble)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accentColor)
                    )
            }
            
            // Response
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "cross")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.accentColor)
                        Text("Living Path")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    // Simulated response lines
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.onboardingText.opacity(0.15))
                                .frame(width: CGFloat(140 - i * 25), height: 7)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.8))
                )
                Spacer()
            }
            
            // Input field mockup
            HStack {
                Text(askQuestionPlaceholder)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentColor)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.9))
                    .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(16)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var askQuestionBubble: String {
        if isChinese { return "這段經文是什麼意思？" }
        if isSpanish { return "¿Qué significa este versículo?" }
        return "What does this verse mean?"
    }
    
    private var askQuestionPlaceholder: String {
        if isChinese { return "問任何關於聖經的問題..." }
        if isSpanish { return "Pregunta sobre la Biblia..." }
        return "Ask anything about the Bible..."
    }
    
    // MARK: - Compact Path Analysis Mockup
    
    private var compactPathAnalysisMockup: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.accentColor)
                Text(pathAnalysisMockTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.onboardingText)
                Spacer()
            }
            
            // Stats row
            HStack(spacing: 10) {
                compactStatBubble(value: "12", label: pathAnalysisStatDays, icon: "flame.fill")
                compactStatBubble(value: "48", label: pathAnalysisStatChapters, icon: "book.fill")
                compactStatBubble(value: "7", label: pathAnalysisStatPrayers, icon: "cross.fill")
            }
            
            // Progress bar mockup
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pathAnalysisJourney)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.onboardingText)
                    Spacer()
                    Text("24%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.accentColor.opacity(0.15))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.accentColor)
                            .frame(width: geo.size.width * 0.24)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var pathAnalysisMockTitle: String {
        if isChinese { return "信仰旅程分析" }
        if isSpanish { return "Análisis del camino" }
        return "Your Faith Journey"
    }
    
    private var pathAnalysisStatDays: String {
        if isChinese { return "連續天" }
        if isSpanish { return "días" }
        return "day streak"
    }
    
    private var pathAnalysisStatChapters: String {
        if isChinese { return "章節" }
        if isSpanish { return "capítulos" }
        return "chapters"
    }
    
    private var pathAnalysisStatPrayers: String {
        if isChinese { return "禱告" }
        if isSpanish { return "oraciones" }
        return "prayers"
    }
    
    private var pathAnalysisJourney: String {
        if isChinese { return "新約進度" }
        if isSpanish { return "Progreso del NT" }
        return "New Testament"
    }
    
    private func compactStatBubble(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.accentColor)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.onboardingText)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.accentColor.opacity(0.08))
        )
    }
    
    // MARK: - Compact Verse Explainer Mockup
    
    private var compactVerseExplainerMockup: some View {
        VStack(spacing: 12) {
            // Verse card
            VStack(spacing: 8) {
                Text(verseExplainerQuote)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(AppTheme.onboardingText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                
                Text("— Psalm 23:1")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accentColor.opacity(0.08))
            )
            
            // Explanation area
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "cross")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.accentColor)
                    Text(verseExplainerLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Simulated explanation lines
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.onboardingText.opacity(0.12))
                            .frame(width: CGFloat(160 - i * 20), height: 7)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.8))
            )
        }
        .padding(16)
        .background(compactCardBackground)
        .overlay(compactCardBorder)
    }
    
    private var verseExplainerQuote: String {
        if isChinese { return "耶和華是我的牧者，\n我必不致缺乏。" }
        if isSpanish { return "El Señor es mi pastor,\nnada me faltará." }
        return "The Lord is my shepherd,\nI shall not want."
    }
    
    private var verseExplainerLabel: String {
        if isChinese { return "經文解析" }
        if isSpanish { return "Explicación del versículo" }
        return "Verse Explained"
    }
    
    // MARK: - Feature Data
    
    private var featureItems: [(title: String, description: String)] {
        if isChinese {
            return [
                ("你的信仰旅程", "追蹤讀經連續天數、收藏經文和靈性里程碑，一目了然。"),
                ("引導禱告", "從聖經經文和你的內心反思中，領受一段為你量身而寫的禱告。"),
                ("章節背景", "在開始閱讀之前，了解每一章的歷史、文化和寫作目的。"),
                ("雙語聖經", "以兩種語言並列閱讀聖經，加深理解或輔助語言學習。"),
                ("個人化閱讀計劃", "根據你的信仰階段和興趣，為你量身打造專屬的聖經閱讀計劃。"),
                ("隨時提問", "對任何經文有疑問？隨時提問，獲得深入淺出、扎根聖經的解答。"),
                ("信仰旅程分析", "追蹤你的讀經進度、禱告記錄，看見你信仰成長的軌跡。"),
                ("經文深度解析", "點擊任何經文，獲得歷史背景、原文含義和生活應用的完整解析。")
            ]
        }
        if isSpanish {
            return [
                ("Tu Camino Vivo", "Sigue tus rachas de lectura, versículos guardados y logros espirituales en un solo lugar."),
                ("Oración Guiada", "Recibe una oración tejida con las Escrituras y tus propias reflexiones, hecha para ti."),
                ("Contexto del Capítulo", "Conoce la historia, cultura y propósito detrás de cada capítulo antes de comenzar a leer."),
                ("Biblia Bilingüe", "Lee las Escrituras en dos idiomas lado a lado. Ideal para profundizar o aprender idiomas."),
                ("Plan de Lectura Personalizado", "Un plan de lectura bíblica adaptado a tu etapa de fe e intereses personales."),
                ("Pregunta lo que quieras", "¿Tienes preguntas sobre un versículo? Pregunta y recibe respuestas claras y fundamentadas."),
                ("Análisis de tu Camino", "Sigue tu progreso de lectura, oraciones y mira crecer tu camino de fe."),
                ("Explicador de Versículos", "Toca cualquier versículo para ver su contexto histórico, significado original y aplicación.")
            ]
        }
        return [
            ("Your Living Journey", "Track your reading streaks, saved verses, and spiritual milestones all in one place."),
            ("Guided Prayer", "Receive a prayer woven from Scripture and your own reflections, crafted to speak to where you are right now."),
            ("Chapter Context", "Understand the history, culture, and purpose behind every chapter before you begin reading."),
            ("Dual Language Bible", "Read Scripture in two languages side by side. Perfect for deepening understanding or language learning."),
            ("Personalized Reading Plan", "A reading plan crafted around your faith journey and interests, guiding you through Scripture at your own pace."),
            ("Ask Any Question", "Have questions about a verse? Ask anything and receive thoughtful, scripture-grounded answers."),
            ("Faith Journey Insights", "Track your reading progress, prayers, and watch your faith journey grow."),
            ("Verse Deep Dive", "Tap any verse for its historical context, original meaning, and life application.")
        ]
    }
    
    // MARK: - Helpers
    
    private var isChinese: Bool {
        let lang = settingsStore.appLanguage
        return lang == .chineseTraditional || lang == .chineseSimplified
    }
    
    private var isSpanish: Bool {
        settingsStore.appLanguage == .spanish
    }
    
    private var compactCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.95))
            .shadow(color: AppTheme.accentColor.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    private var compactCardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(AppTheme.accentColor.opacity(0.1), lineWidth: 1)
    }
}
