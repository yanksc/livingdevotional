// SupporterService - RevenueCat wrapper for subscription management

import Foundation
import RevenueCat
import Combine

/// Entitlement and product identifiers (must match RevenueCat dashboard + App Store Connect)
enum SupporterIdentifiers {
    static let entitlementId = "supporter"
    static let monthlyProductId = "supporter_monthly_499"
    static let annualProductId = "supporter_annual_4999"
}

/// RevenueCat wrapper singleton for supporter subscription management
final class SupporterService: NSObject, ObservableObject {
    static let shared = SupporterService()
    
    // MARK: - Published State
    
    @Published private(set) var isSupporter: Bool = false
    @Published private(set) var monthlyPackage: Package?
    @Published private(set) var annualPackage: Package?
    @Published private(set) var isLoadingOfferings: Bool = false
    @Published private(set) var offeringsError: Error?
    
    // MARK: - Configuration
    
    private var isConfigured = false
    private var isPurchasesConfigured = false
    
    /// Configure RevenueCat SDK. Call once at app launch.
    func configure() {
        guard !isConfigured else { return }
        
        let apiKey = Self.revenueCatAPIKey
        guard !apiKey.isEmpty else {
            #if DEBUG
            print("⚠️ REVENUECAT_APPLE_API_KEY not set. Supporter features will be unavailable.")
            #endif
            isConfigured = true
            return
        }
        
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        isConfigured = true
        isPurchasesConfigured = true
        
        Task { @MainActor in
            await refreshStatus()
            await fetchOfferings()
        }
    }
    
    private static var revenueCatAPIKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_APPLE_API_KEY") as? String,
           !key.isEmpty {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_APPLE_API_KEY"],
           !key.isEmpty {
            return key
        }
        return ""
    }
    
    // MARK: - Offerings
    
    /// Fetch current offerings (monthly + annual packages)
    func fetchOfferings() async {
        guard isPurchasesConfigured else { return }
        
        await MainActor.run { isLoadingOfferings = true }
        await MainActor.run { offeringsError = nil }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            await MainActor.run {
                monthlyPackage = offerings.current?.monthly
                annualPackage = offerings.current?.annual
                isLoadingOfferings = false
                offeringsError = nil
            }
        } catch {
            let nsError = error as NSError
            let isNoAccountError = nsError.domain == "ASDErrorDomain" && nsError.code == 509
            
            await MainActor.run {
                monthlyPackage = nil
                annualPackage = nil
                isLoadingOfferings = false
                // Don't surface "no active account" as an error — it's expected
                // when no Apple ID is signed in (e.g. Simulator)
                offeringsError = isNoAccountError ? nil : error
            }
            
            #if DEBUG
            if isNoAccountError {
                print("SupporterService: No active App Store account — offerings unavailable (expected in Simulator)")
            }
            #endif
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a package. Returns customerInfo on success.
    func purchase(package: Package) async throws -> CustomerInfo {
        guard isPurchasesConfigured else {
            throw NSError(domain: "SupporterService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchases not configured"])
        }
        let result = try await Purchases.shared.purchase(package: package)
        
        await MainActor.run {
            isSupporter = result.customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true
        }
        
        return result.customerInfo
    }
    
    // MARK: - Restore
    
    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        guard isPurchasesConfigured else {
            throw NSError(domain: "SupporterService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchases not configured"])
        }
        let customerInfo = try await Purchases.shared.restorePurchases()
        
        await MainActor.run {
            isSupporter = customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true
        }
        
        return customerInfo
    }
    
    // MARK: - Status
    
    /// Refresh subscription status from RevenueCat
    func refreshStatus() async {
        guard isPurchasesConfigured else { return }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            await MainActor.run {
                isSupporter = customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true
            }
        } catch {
            // Non-fatal - status will be updated when user makes a purchase or restores
            #if DEBUG
            let nsError = error as NSError
            if nsError.domain == "ASDErrorDomain" && nsError.code == 509 {
                print("SupporterService: No active App Store account — status unavailable (expected in Simulator)")
            } else {
                print("SupporterService: refreshStatus failed: \(error)")
            }
            #endif
        }
    }
}

// MARK: - PurchasesDelegate

extension SupporterService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let isActive = customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true
        
        Task { @MainActor in
            self.isSupporter = isActive
        }
    }
}
