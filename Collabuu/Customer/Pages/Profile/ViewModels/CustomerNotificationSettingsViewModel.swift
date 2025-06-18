import SwiftUI
import Foundation

@MainActor
class CustomerNotificationSettingsViewModel: ObservableObject {
    // Push Notifications
    @Published var pushNotificationsEnabled = true
    
    // Deal Notifications
    @Published var newDealAlertsEnabled = true
    @Published var favoriteBusinessUpdatesEnabled = true
    @Published var dealAlertsEnabled = true
    @Published var dealExpiryRemindersEnabled = true
    
    // Message Notifications
    @Published var messageNotificationsEnabled = true
    @Published var businessResponsesEnabled = true
    
    // Account Notifications
    @Published var accountNotificationsEnabled = true
    @Published var securityAlertsEnabled = true
    @Published var pointsUpdatesEnabled = true
    
    // Marketing Notifications
    @Published var marketingNotificationsEnabled = false
    @Published var weeklyDigestEnabled = false
    @Published var specialOffersEnabled = false
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSaveSuccess = false
    @Published var hasUnsavedChanges = false
    
    private let apiService = APIService.shared
    private var originalSettings: NotificationSettings?
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let settings = try await apiService.getCustomerNotificationSettings()
                await MainActor.run {
                    self.applySettings(settings)
                    self.originalSettings = settings
                    self.hasUnsavedChanges = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading notification settings: \(error)")
                    
                    // Use default settings as fallback
                    self.loadDefaultSettings()
                }
            }
        }
    }
    
    private func applySettings(_ settings: NotificationSettings) {
        pushNotificationsEnabled = settings.pushNotificationsEnabled
        newDealAlertsEnabled = settings.newDealAlertsEnabled
        favoriteBusinessUpdatesEnabled = settings.favoriteBusinessUpdatesEnabled
        dealAlertsEnabled = settings.dealAlertsEnabled
        dealExpiryRemindersEnabled = settings.dealExpiryRemindersEnabled
        messageNotificationsEnabled = settings.messageNotificationsEnabled
        businessResponsesEnabled = settings.businessResponsesEnabled
        accountNotificationsEnabled = settings.accountNotificationsEnabled
        securityAlertsEnabled = settings.securityAlertsEnabled
        pointsUpdatesEnabled = settings.pointsUpdatesEnabled
        marketingNotificationsEnabled = settings.marketingNotificationsEnabled
        weeklyDigestEnabled = settings.weeklyDigestEnabled
        specialOffersEnabled = settings.specialOffersEnabled
    }
    
    private func loadDefaultSettings() {
        pushNotificationsEnabled = true
        newDealAlertsEnabled = true
        favoriteBusinessUpdatesEnabled = true
        dealAlertsEnabled = true
        dealExpiryRemindersEnabled = true
        messageNotificationsEnabled = true
        businessResponsesEnabled = true
        accountNotificationsEnabled = true
        securityAlertsEnabled = true
        pointsUpdatesEnabled = true
        marketingNotificationsEnabled = false
        weeklyDigestEnabled = false
        specialOffersEnabled = false
        
        originalSettings = currentSettings
        hasUnsavedChanges = false
        isLoading = false
    }
    
    func saveSettings() {
        guard hasUnsavedChanges else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let settings = currentSettings
                try await apiService.updateCustomerNotificationSettings(settings)
                
                await MainActor.run {
                    self.originalSettings = settings
                    self.hasUnsavedChanges = false
                    self.isLoading = false
                    self.showingSaveSuccess = true
                    
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.showingSaveSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to save settings: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func resetToDefaults() {
        pushNotificationsEnabled = true
        newDealAlertsEnabled = true
        favoriteBusinessUpdatesEnabled = true
        dealAlertsEnabled = true
        dealExpiryRemindersEnabled = true
        messageNotificationsEnabled = true
        businessResponsesEnabled = true
        accountNotificationsEnabled = true
        securityAlertsEnabled = true
        pointsUpdatesEnabled = true
        marketingNotificationsEnabled = false
        weeklyDigestEnabled = false
        specialOffersEnabled = false
        
        checkForChanges()
    }
    
    func discardChanges() {
        guard let originalSettings = originalSettings else { return }
        applySettings(originalSettings)
        hasUnsavedChanges = false
    }
    
    func checkForChanges() {
        guard let originalSettings = originalSettings else {
            hasUnsavedChanges = false
            return
        }
        
        hasUnsavedChanges = currentSettings != originalSettings
    }
    
    var currentSettings: NotificationSettings {
        NotificationSettings(
            pushNotificationsEnabled: pushNotificationsEnabled,
            newDealAlertsEnabled: newDealAlertsEnabled,
            favoriteBusinessUpdatesEnabled: favoriteBusinessUpdatesEnabled,
            dealAlertsEnabled: dealAlertsEnabled,
            dealExpiryRemindersEnabled: dealExpiryRemindersEnabled,
            messageNotificationsEnabled: messageNotificationsEnabled,
            businessResponsesEnabled: businessResponsesEnabled,
            accountNotificationsEnabled: accountNotificationsEnabled,
            securityAlertsEnabled: securityAlertsEnabled,
            pointsUpdatesEnabled: pointsUpdatesEnabled,
            marketingNotificationsEnabled: marketingNotificationsEnabled,
            weeklyDigestEnabled: weeklyDigestEnabled,
            specialOffersEnabled: specialOffersEnabled
        )
    }
}

struct NotificationSettings: Codable, Equatable {
    let pushNotificationsEnabled: Bool
    let newDealAlertsEnabled: Bool
    let favoriteBusinessUpdatesEnabled: Bool
    let dealAlertsEnabled: Bool
    let dealExpiryRemindersEnabled: Bool
    let messageNotificationsEnabled: Bool
    let businessResponsesEnabled: Bool
    let accountNotificationsEnabled: Bool
    let securityAlertsEnabled: Bool
    let pointsUpdatesEnabled: Bool
    let marketingNotificationsEnabled: Bool
    let weeklyDigestEnabled: Bool
    let specialOffersEnabled: Bool
}
} 