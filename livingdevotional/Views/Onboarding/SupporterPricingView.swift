// SupporterPricingView - Pricing sub-view within Step 11 (Supporter Invitation)
// Also used when usage limit is hit (standalone sheet with contextual header).

import SwiftUI
import RevenueCat

struct SupporterPricingView: View {
    /// Onboarding context. When nil, used as standalone paywall (e.g. usage limit hit).
    var state: OnboardingState?
    /// Override header when in standalone mode. e.g. "You've reached today's limit"
    var contextualHeader: String?
    let onBack: (() -> Void)?
    let onDismiss: () -> Void
    
    @ObservedObject private var supporterService = SupporterService.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    @State private var selectedPlan: PlanOption = .annual
    @State private var visibleOptionIndices: Set<Int> = []
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var restoreMessage: String?
    @State private var hasFetchedOfferings = false
    
    enum PlanOption {
        case monthly
        case annual
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 28)
                    
                    headerView
                    trialCalloutView
                    planCardsView
                    commitmentLineView
                    autoRenewalView
                    ctaButton
                    dismissButton
                }
                .padding(.horizontal, 24)
            }
            
            legalRowView
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            
            if onBack != nil {
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            fetchOfferingsIfNeeded()
            animatePlanCards()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        Text(headerLocalized)
            .font(.system(size: 26, weight: .regular, design: .serif))
            .foregroundColor(AppTheme.onboardingText)
            .multilineTextAlignment(.center)
            .padding(.bottom, 8)
    }
    
    private var headerLocalized: String {
        if let override = contextualHeader, !override.isEmpty { return override }
        if isChinese { return "選擇你的支持方式" }
        if isSpanish { return "Elige tu apoyo" }
        return "Choose Your Support"
    }
    
    private var isChinese: Bool {
        let lang = state?.resolvedLanguage ?? appLanguageResolved
        return lang == .chineseTraditional || lang == .chineseSimplified
    }
    
    private var isSpanish: Bool {
        let lang = state?.resolvedLanguage ?? appLanguageResolved
        return lang == .spanish
    }
    
    private var appLanguageResolved: AppLanguage {
        let code = settingsStore.appLanguage.resolvedLanguageCode()
        if code.hasPrefix("zh") { return code.contains("Hans") ? .chineseSimplified : .chineseTraditional }
        if code == "es" { return .spanish }
        return .english
    }
    
    // MARK: - Trial Callout
    
    private var trialCalloutView: some View {
        Text(trialLocalized)
            .font(.system(size: 17, weight: .regular, design: .serif))
            .foregroundColor(AppTheme.onboardingText.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)
    }
    
    private var trialLocalized: String {
        if isChinese { return "免費試用 7 天" }
        if isSpanish { return "Comienza con 7 días gratis" }
        return "Start with 7 days free"
    }
    
    // MARK: - Plan Cards
    
    private var planCardsView: some View {
        VStack(spacing: 12) {
            planCard(
                title: monthlyTitleLocalized,
                price: monthlyPriceString,
                isSelected: selectedPlan == .monthly,
                index: 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedPlan = .monthly
                }
            }
            
            planCard(
                title: annualTitleLocalized,
                price: annualPriceString,
                badge: savingsBadgeLocalized,
                isSelected: selectedPlan == .annual,
                index: 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedPlan = .annual
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    private func planCard(
        title: String,
        price: String,
        badge: String? = nil,
        isSelected: Bool,
        index: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accentColor.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(price)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.onboardingText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.95))
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.accentColor.opacity(0.05))
                    }
                }
                .shadow(color: AppTheme.accentColor.opacity(0.15), radius: 20, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(visibleOptionIndices.contains(index) ? 1 : 0)
    }
    
    private var monthlyTitleLocalized: String {
        if isChinese { return "每月支持" }
        if isSpanish { return "Apoyo Mensual" }
        return "Monthly Supporter"
    }
    
    private var annualTitleLocalized: String {
        if isChinese { return "年度支持" }
        if isSpanish { return "Apoyo Anual" }
        return "Annual Supporter"
    }
    
    private var monthlyPriceString: String {
        guard let package = supporterService.monthlyPackage else {
            return "$4.99/month"
        }
        return "\(package.storeProduct.localizedPriceString)/month"
    }
    
    private var annualPriceString: String {
        guard let package = supporterService.annualPackage else {
            return "$49.99/year"
        }
        return "\(package.storeProduct.localizedPriceString)/year"
    }
    
    private var savingsBadgeLocalized: String {
        if isChinese { return "省 17%" }
        if isSpanish { return "Ahorra 17%" }
        return "Save 17%"
    }
    
    // MARK: - Commitment Line
    
    private var commitmentLineView: some View {
        Text(commitmentLocalized)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(AppTheme.secondaryText)
            .multilineTextAlignment(.center)
            .padding(.bottom, 8)
    }
    
    private var commitmentLocalized: String {
        let pricePart: String
        switch selectedPlan {
        case .monthly:
            pricePart = supporterService.monthlyPackage?.storeProduct.localizedPriceString ?? "$4.99"
            if isChinese { return "免費 7 天，之後 \(pricePart)/月。隨時取消。" }
            if isSpanish { return "Gratis por 7 días, luego \(pricePart)/mes. Cancela cuando quieras." }
            return "Free for 7 days, then \(pricePart)/month. Cancel anytime."
        case .annual:
            pricePart = supporterService.annualPackage?.storeProduct.localizedPriceString ?? "$49.99"
            if isChinese { return "免費 7 天，之後 \(pricePart)/年。隨時取消。" }
            if isSpanish { return "Gratis por 7 días, luego \(pricePart)/año. Cancela cuando quieras." }
            return "Free for 7 days, then \(pricePart)/year. Cancel anytime."
        }
    }
    
    // MARK: - Auto-Renewal
    
    private var autoRenewalView: some View {
        Text(autoRenewalLocalized)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(AppTheme.secondaryText)
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)
    }
    
    private var autoRenewalLocalized: String {
        if isChinese { return "訂閱將自動續訂。可隨時在設定中取消。" }
        if isSpanish { return "La suscripción se renueva automáticamente. Cancela en cualquier momento en Configuración." }
        return "Subscription automatically renews. Cancel anytime in Settings."
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        VStack(spacing: 8) {
            Button(action: startPurchase) {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text(ctaLocalized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(AppTheme.buttonGradient)
                .cornerRadius(12)
                .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isPurchasing || selectedPackage == nil)
            .opacity((isPurchasing || selectedPackage == nil) ? 0.7 : 1)
            
            if let error = purchaseError {
                Text(error)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if let message = restoreMessage {
                Text(message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.accentColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 12)
    }
    
    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly: return supporterService.monthlyPackage
        case .annual: return supporterService.annualPackage
        }
    }
    
    private var ctaLocalized: String {
        if isChinese { return "開始免費試用" }
        if isSpanish { return "Iniciar prueba gratuita" }
        return "Start Free Trial"
    }
    
    private func startPurchase() {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        purchaseError = nil
        restoreMessage = nil
        
        Task {
            do {
                _ = try await supporterService.purchase(package: package)
                await MainActor.run {
                    state?.didSupport = true
                    SettingsStore.shared.hasSeenOnboardingPaywall = true
                    isPurchasing = false
                    purchaseError = nil
                    if let state = state {
                        withAnimation { state.goNext() }
                    } else {
                        onDismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    if (error as NSError).domain == "RevenueCat" && (error as NSError).code == 2 {
                        // User cancelled - don't show error
                        purchaseError = nil
                    } else {
                        purchaseError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Dismiss
    
    private var dismissButton: some View {
        Button(action: {
            SettingsStore.shared.hasSeenOnboardingPaywall = true
            onDismiss()
        }) {
            Text(dismissLocalized)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.vertical, 8)
        }
        .padding(.bottom, 24)
    }
    
    private var dismissLocalized: String {
        if isChinese { return "之後再說" }
        if isSpanish { return "Quizás más tarde" }
        return "Not right now"
    }
    
    // MARK: - Legal Row
    
    private var legalRowView: some View {
        HStack(spacing: 4) {
            Button(action: restoreTapped) {
                Text(restoreLocalized)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Text(" | ")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryText)
            
            Link(termsLocalized, destination: URL(string: "https://livingpathapp.com/terms")!)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(" | ")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryText)
            
            Link(privacyLocalized, destination: URL(string: "https://livingpathapp.com/privacy-policy")!)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(" | ")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryText)
            
            Link(contactUsLocalized, destination: URL(string: "mailto:livingpathapp@gmail.com")!)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var restoreLocalized: String {
        if isChinese { return "恢復購買" }
        if isSpanish { return "Restaurar compras" }
        return "Restore Purchases"
    }
    
    private var termsLocalized: String {
        if isChinese { return "使用條款" }
        if isSpanish { return "Términos de uso" }
        return "Terms of Use"
    }
    
    private var privacyLocalized: String {
        if isChinese { return "隱私政策" }
        if isSpanish { return "Política de privacidad" }
        return "Privacy Policy"
    }
    
    private var contactUsLocalized: String {
        if isChinese { return "聯絡我們" }
        if isSpanish { return "Contacto" }
        return "Contact Us"
    }
    
    private func restoreTapped() {
        restoreMessage = nil
        purchaseError = nil
        
        Task {
            do {
                let customerInfo = try await supporterService.restorePurchases()
                await MainActor.run {
                    if customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true {
                        restoreMessage = isChinese ? "已恢復" : (isSpanish ? "Restaurado" : "Restored")
                        state?.didSupport = true
                        SettingsStore.shared.hasSeenOnboardingPaywall = true
                        if let state = state {
                            withAnimation { state.goNext() }
                        } else {
                            onDismiss()
                        }
                    } else {
                        restoreMessage = isChinese ? "沒有找到可恢復的購買" : (isSpanish ? "No se encontraron compras para restaurar" : "No purchases to restore")
                    }
                }
            } catch {
                await MainActor.run {
                    restoreMessage = isChinese ? "恢復失敗" : (isSpanish ? "Error al restaurar" : "Restore failed")
                }
            }
        }
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button(action: { onBack?() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text(backLocalized)
                    .font(.system(size: 15, weight: .regular))
            }
            .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    private var backLocalized: String {
        if isChinese { return "上一步" }
        if isSpanish { return "Atrás" }
        return "Back"
    }
    
    // MARK: - Helpers
    
    private func fetchOfferingsIfNeeded() {
        guard !hasFetchedOfferings else { return }
        hasFetchedOfferings = true
        Task {
            await supporterService.fetchOfferings()
        }
    }
    
    private func animatePlanCards() {
        for i in 0..<2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * OnboardingDesign.optionStaggerDelay) {
                withAnimation(.easeOut(duration: 0.8)) {
                    _ = visibleOptionIndices.insert(i)
                }
            }
        }
    }
}
