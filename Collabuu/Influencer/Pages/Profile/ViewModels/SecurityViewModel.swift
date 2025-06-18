import Foundation
import SwiftUI

@MainActor
class SecurityViewModel: ObservableObject {
    // Two-Factor Authentication
    @Published var twoFactorEnabled: Bool = false
    @Published var showingTwoFactorSetup: Bool = false
    @Published var showingBackupCodes: Bool = false
    
    // Password & Authentication
    @Published var showingChangePassword: Bool = false
    @Published var lastPasswordChange: Date?
    
    // Account Security
    @Published var loginNotificationsEnabled: Bool = true
    @Published var showingLoginHistory: Bool = false
    @Published var showingActiveSessions: Bool = false
    @Published var activeSessions: [LoginSession] = []
    @Published var recentLogins: [LoginActivity] = []
    
    // Privacy Settings
    @Published var profileVisibilityEnabled: Bool = true
    @Published var analyticsEnabled: Bool = true
    @Published var marketingEmailsEnabled: Bool = false
    
    // Data Privacy
    @Published var showingDownloadConfirmation: Bool = false
    @Published var showingDeleteConfirmation: Bool = false
    @Published var dataDownloadInProgress: Bool = false
    
    // Confirmation Dialogs
    @Published var showingSignOutConfirmation: Bool = false
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    private let apiService = APIService.shared
    
    // Computed Properties
    var showChangePassword: Bool {
        get { showingChangePassword }
        set { showingChangePassword = newValue }
    }
    
    var showBackupCodes: Bool {
        get { showingBackupCodes }
        set { showingBackupCodes = newValue }
    }
    
    var showLoginHistory: Bool {
        get { showingLoginHistory }
        set { showingLoginHistory = newValue }
    }
    
    var showActiveSessions: Bool {
        get { showingActiveSessions }
        set { showingActiveSessions = newValue }
    }
    
    init() {
        loadSecuritySettings()
    }
    
    func loadSecuritySettings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let settingsTask = apiService.getSecuritySettings()
                async let sessionsTask = apiService.getActiveSessions()
                async let loginHistoryTask = apiService.getLoginHistory()
                
                let (settings, sessions, loginHistory) = try await (settingsTask, sessionsTask, loginHistoryTask)
                
                await MainActor.run {
                    self.populateSettings(from: settings)
                    self.activeSessions = sessions
                    self.recentLogins = loginHistory
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load security settings: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Error loading security settings: \(error)")
                    
                    // Load sample data as fallback
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func populateSettings(from settings: SecuritySettings) {
        twoFactorEnabled = settings.twoFactorEnabled
        loginNotificationsEnabled = settings.loginNotificationsEnabled
        profileVisibilityEnabled = settings.profileVisibilityEnabled
        analyticsEnabled = settings.analyticsEnabled
        marketingEmailsEnabled = settings.marketingEmailsEnabled
        lastPasswordChange = settings.lastPasswordChange
    }
    
    private func loadSampleDataAsFallback() {
        twoFactorEnabled = false
        loginNotificationsEnabled = true
        profileVisibilityEnabled = true
        analyticsEnabled = true
        marketingEmailsEnabled = false
        lastPasswordChange = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        
        activeSessions = [
            LoginSession(
                id: "1",
                deviceName: "iPhone 15 Pro",
                location: "San Francisco, CA",
                ipAddress: "192.168.1.1",
                lastActive: Date(),
                isCurrent: true
            ),
            LoginSession(
                id: "2",
                deviceName: "MacBook Pro",
                location: "San Francisco, CA",
                ipAddress: "192.168.1.2",
                lastActive: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isCurrent: false
            )
        ]
        
        recentLogins = [
            LoginActivity(
                id: "1",
                deviceName: "iPhone 15 Pro",
                location: "San Francisco, CA",
                timestamp: Date(),
                wasSuccessful: true
            ),
            LoginActivity(
                id: "2",
                deviceName: "MacBook Pro",
                location: "San Francisco, CA",
                timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                wasSuccessful: true
            )
        ]
        
        isLoading = false
    }
    
    func toggleTwoFactor() {
        if twoFactorEnabled {
            // Disable 2FA
            disableTwoFactor()
        } else {
            // Show setup flow
            showingTwoFactorSetup = true
        }
    }
    
    private func disableTwoFactor() {
        Task {
            do {
                try await apiService.disableTwoFactor()
                await MainActor.run {
                    self.twoFactorEnabled = false
                    self.showSuccessMessage("Two-factor authentication disabled")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to disable two-factor authentication: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateSecuritySetting<T>(_ keyPath: WritableKeyPath<SecurityViewModel, T>, value: T) {
        self[keyPath: keyPath] = value
        saveSecuritySettings()
    }
    
    private func saveSecuritySettings() {
        Task {
            do {
                let settings = SecuritySettings(
                    twoFactorEnabled: twoFactorEnabled,
                    loginNotificationsEnabled: loginNotificationsEnabled,
                    profileVisibilityEnabled: profileVisibilityEnabled,
                    analyticsEnabled: analyticsEnabled,
                    marketingEmailsEnabled: marketingEmailsEnabled,
                    lastPasswordChange: lastPasswordChange
                )
                
                try await apiService.updateSecuritySettings(settings)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save security settings: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func signOutAllDevices() {
        showingSignOutConfirmation = true
    }
    
    func confirmSignOutAllDevices() {
        Task {
            do {
                try await apiService.signOutAllDevices()
                await MainActor.run {
                    self.showSuccessMessage("Signed out of all devices")
                    self.loadSecuritySettings() // Refresh sessions
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to sign out all devices: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func downloadAccountData() {
        showingDownloadConfirmation = true
    }
    
    func confirmDownloadAccountData() {
        dataDownloadInProgress = true
        
        Task {
            do {
                try await apiService.requestDataDownload()
                await MainActor.run {
                    self.dataDownloadInProgress = false
                    self.showSuccessMessage("Data download request submitted. Check your email for the download link.")
                }
            } catch {
                await MainActor.run {
                    self.dataDownloadInProgress = false
                    self.errorMessage = "Failed to request data download: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteAccount() {
        showingDeleteConfirmation = true
    }
    
    func confirmDeleteAccount() {
        Task {
            do {
                try await apiService.deleteAccount()
                // Account deletion will trigger logout automatically
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func revokeSession(_ sessionId: String) {
        Task {
            do {
                try await apiService.revokeSession(sessionId: sessionId)
                await MainActor.run {
                    self.activeSessions.removeAll { $0.id == sessionId }
                    self.showSuccessMessage("Session revoked successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to revoke session: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showingSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingSuccessMessage = false
        }
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
}

// MARK: - Supporting Models

struct SecuritySettings: Codable {
    let twoFactorEnabled: Bool
    let loginNotificationsEnabled: Bool
    let profileVisibilityEnabled: Bool
    let analyticsEnabled: Bool
    let marketingEmailsEnabled: Bool
    let lastPasswordChange: Date?
}

struct LoginSession: Identifiable, Codable {
    let id: String
    let deviceName: String
    let location: String
    let ipAddress: String
    let lastActive: Date
    let isCurrent: Bool
    
    var formattedLastActive: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActive, relativeTo: Date())
    }
}

struct LoginActivity: Identifiable, Codable {
    let id: String
    let deviceName: String
    let location: String
    let timestamp: Date
    let wasSuccessful: Bool
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
} 