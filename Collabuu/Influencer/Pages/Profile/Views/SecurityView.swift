import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SecurityViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header Section
                headerSection
                
                // Security Sections
                VStack(spacing: AppSpacing.lg) {
                    passwordAuthenticationSection
                    accountSecuritySection
                    privacySettingsSection
                    loginSessionsSection
                    dataPrivacySection
                }
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.backgroundSecondary)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $viewModel.showingTwoFactorSetup) {
            TwoFactorSetupView()
        }
        .sheet(isPresented: $viewModel.showingBackupCodes) {
            BackupCodesView()
        }
        .sheet(isPresented: $viewModel.showingLoginHistory) {
            LoginHistoryView()
        }
        .sheet(isPresented: $viewModel.showingActiveSessions) {
            ActiveSessionsView()
        }
        .confirmationDialog("Sign Out All Devices", isPresented: $viewModel.showingSignOutConfirmation) {
            Button("Sign Out All", role: .destructive) {
                viewModel.confirmSignOutAllDevices()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will sign you out of all devices except this one. You'll need to sign in again on those devices.")
        }
        .confirmationDialog("Download Account Data", isPresented: $viewModel.showingDownloadConfirmation) {
            Button("Download Data") {
                viewModel.confirmDownloadAccountData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We'll prepare your data and send a download link to your email address.")
        }
        .confirmationDialog("Delete Account", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Delete Account", role: .destructive) {
                viewModel.confirmDeleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .overlay(
            Group {
                if viewModel.showingSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(viewModel.successMessage)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.green)
                        .cornerRadius(AppSpacing.radiusMD)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingSuccessMessage)
                }
            }
        )
        .onAppear {
            viewModel.loadSecuritySettings()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.secondary.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "lock.shield")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                )
            
            VStack(spacing: AppSpacing.sm) {
                Text("Security Settings")
                    .headlineMedium(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Manage your privacy and security settings")
                    .bodyLarge(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppSpacing.lg)
    }
    
    private var passwordAuthenticationSection: some View {
        securityCard(
            title: "Password & Authentication",
            icon: "key",
            description: "Manage your login credentials and authentication"
        ) {
            VStack(spacing: AppSpacing.md) {
                SecurityActionRow(
                    title: "Change Password",
                    description: "Update your account password",
                    icon: "lock.rotation",
                    actionType: .navigation
                ) {
                    viewModel.showChangePassword = true
                }
                
                SecurityToggleRow(
                    title: "Two-Factor Authentication",
                    description: "Add an extra layer of security to your account",
                    icon: "person.badge.shield.checkmark",
                    isOn: $viewModel.twoFactorEnabled,
                    isRecommended: !viewModel.twoFactorEnabled
                ) {
                    viewModel.toggleTwoFactor()
                }
                
                SecurityActionRow(
                    title: "Backup Codes",
                    description: "Generate backup codes for account recovery",
                    icon: "qrcode",
                    actionType: .navigation,
                    isDisabled: !viewModel.twoFactorEnabled
                ) {
                    viewModel.showBackupCodes = true
                }
            }
        }
    }
    
    private var accountSecuritySection: some View {
        securityCard(
            title: "Account Security",
            icon: "person.badge.shield.checkmark",
            description: "Monitor and control account access"
        ) {
            VStack(spacing: AppSpacing.md) {
                SecurityToggleRow(
                    title: "Login Notifications",
                    description: "Get notified when someone logs into your account",
                    icon: "bell.badge",
                    isOn: $viewModel.loginNotificationsEnabled
                )
                
                SecurityActionRow(
                    title: "Login History",
                    description: "View recent login activity and locations",
                    icon: "clock.arrow.circlepath",
                    actionType: .navigation
                ) {
                    viewModel.showLoginHistory = true
                }
                
                SecurityActionRow(
                    title: "Active Sessions",
                    description: "Manage devices logged into your account",
                    icon: "desktopcomputer",
                    actionType: .navigation
                ) {
                    viewModel.showActiveSessions = true
                }
                
                SecurityActionRow(
                    title: "Sign Out All Devices",
                    description: "Sign out from all devices except this one",
                    icon: "power",
                    actionType: .destructive,
                    showChevron: false
                ) {
                    viewModel.showingSignOutConfirmation = true
                }
            }
        }
    }
    
    private var privacySettingsSection: some View {
        securityCard(
            title: "Privacy Settings",
            icon: "eye.slash",
            description: "Control your privacy and data sharing preferences"
        ) {
            VStack(spacing: AppSpacing.md) {
                SecurityToggleRow(
                    title: "Profile Visibility",
                    description: "Make your profile visible to businesses",
                    icon: "eye",
                    isOn: $viewModel.profileVisibilityEnabled
                )
                
                SecurityToggleRow(
                    title: "Analytics Sharing",
                    description: "Share anonymous usage data to improve the app",
                    icon: "chart.bar",
                    isOn: $viewModel.analyticsEnabled
                )
                
                SecurityToggleRow(
                    title: "Marketing Communications",
                    description: "Receive marketing emails and offers",
                    icon: "envelope.badge",
                    isOn: $viewModel.marketingEnabled
                )
            }
        }
    }
    
    private var loginSessionsSection: some View {
        securityCard(
            title: "Login & Sessions",
            icon: "timer",
            description: "Manage how long you stay logged in"
        ) {
            VStack(spacing: AppSpacing.md) {
                SecurityToggleRow(
                    title: "Stay Logged In",
                    description: "Keep me logged in for faster access",
                    icon: "checkmark.circle",
                    isOn: $viewModel.stayLoggedInEnabled
                )
                
                SecurityToggleRow(
                    title: "Automatic Lock",
                    description: "Lock the app when backgrounded for security",
                    icon: "lock.app.dashed",
                    isOn: $viewModel.automaticLockEnabled
                )
                
                if viewModel.automaticLockEnabled {
                    HStack {
                        Text("Lock after:")
                            .bodyMedium(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(SecurityViewModel.LockTimeout.allCases, id: \.self) { timeout in
                                Button(timeout.displayName) {
                                    viewModel.selectedLockTimeout = timeout
                                }
                            }
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Text(viewModel.selectedLockTimeout.displayName)
                                    .bodyMedium(AppColors.textPrimary)
                                    .fontWeight(.medium)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.sm)
                }
            }
        }
    }
    
    private var dataPrivacySection: some View {
        securityCard(
            title: "Data & Privacy",
            icon: "doc.badge.gearshape",
            description: "Manage your data and privacy preferences"
        ) {
            VStack(spacing: AppSpacing.md) {
                SecurityActionRow(
                    title: "Download My Data",
                    description: "Request a copy of your personal data",
                    icon: "square.and.arrow.down",
                    actionType: .navigation
                ) {
                    viewModel.requestDataDownload()
                }
                
                SecurityActionRow(
                    title: "Privacy Policy",
                    description: "Read our privacy policy and terms",
                    icon: "doc.text",
                    actionType: .navigation
                ) {
                    viewModel.showPrivacyPolicy = true
                }
                
                SecurityActionRow(
                    title: "Delete Account",
                    description: "Permanently delete your account and data",
                    icon: "trash",
                    actionType: .destructive,
                    showChevron: false
                ) {
                    viewModel.showDeleteAccount = true
                }
            }
        }
    }
    
    private func securityCard<Content: View>(
        title: String,
        icon: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .titleMedium(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .bodySmall(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Content
            content()
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Security Action Row

struct SecurityActionRow: View {
    let title: String
    let description: String
    let icon: String
    let actionType: ActionType
    let isDisabled: Bool
    let showChevron: Bool
    let action: () -> Void
    
    enum ActionType {
        case navigation, destructive
        
        var textColor: Color {
            switch self {
            case .navigation: return AppColors.textPrimary
            case .destructive: return AppColors.error
            }
        }
        
        var iconColor: Color {
            switch self {
            case .navigation: return AppColors.secondary
            case .destructive: return AppColors.error
            }
        }
    }
    
    init(
        title: String,
        description: String,
        icon: String,
        actionType: ActionType = .navigation,
        isDisabled: Bool = false,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.actionType = actionType
        self.isDisabled = isDisabled
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDisabled ? AppColors.textTertiary : actionType.iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .bodyLarge(isDisabled ? AppColors.textTertiary : actionType.textColor)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .bodySmall(isDisabled ? AppColors.textTertiary : AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Security Toggle Row

struct SecurityToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    let isRecommended: Bool
    
    init(
        title: String,
        description: String,
        icon: String,
        isOn: Binding<Bool>,
        isRecommended: Bool = false
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._isOn = isOn
        self.isRecommended = isRecommended
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(title)
                        .bodyLarge(AppColors.textPrimary)
                        .fontWeight(.medium)
                    
                    if isRecommended {
                        Text("Recommended")
                            .labelSmall(AppColors.success)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(AppColors.success.opacity(0.1))
                            .cornerRadius(AppSpacing.radiusXS)
                    }
                }
                
                Text(description)
                    .bodySmall(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.secondary))
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - View Model

@MainActor
class SecurityViewModel: ObservableObject {
    // Password & Authentication
    @Published var twoFactorEnabled = false
    @Published var showChangePassword = false
    @Published var showingChangePassword = false
    @Published var showBackupCodes = false
    @Published var showingBackupCodes = false
    
    // Account Security
    @Published var loginNotificationsEnabled = true
    @Published var showLoginHistory = false
    @Published var showingLoginHistory = false
    @Published var showActiveSessions = false
    @Published var showingActiveSessions = false
    
    // Privacy Settings
    @Published var profileVisibilityEnabled = true
    @Published var analyticsEnabled = true
    @Published var marketingEnabled = false
    
    // Login & Sessions
    @Published var stayLoggedInEnabled = true
    @Published var automaticLockEnabled = false
    @Published var selectedLockTimeout: LockTimeout = .immediate
    
    // Data & Privacy
    @Published var showPrivacyPolicy = false
    @Published var showDeleteAccount = false
    @Published var showingSignOutConfirmation = false
    @Published var showingDownloadConfirmation = false
    @Published var showingDeleteConfirmation = false
    @Published var showingTwoFactorSetup = false
    
    enum LockTimeout: String, CaseIterable {
        case immediate = "immediate"
        case oneMinute = "1_minute"
        case fiveMinutes = "5_minutes"
        case fifteenMinutes = "15_minutes"
        case oneHour = "1_hour"
        
        var displayName: String {
            switch self {
            case .immediate: return "Immediately"
            case .oneMinute: return "1 minute"
            case .fiveMinutes: return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .oneHour: return "1 hour"
            }
        }
    }
    
    func loadSecuritySettings() {
        // TODO: Load security settings from UserDefaults or API
    }
    
    func signOutAllDevices() {
        // TODO: Implement sign out all devices
        print("Signing out all devices...")
    }
    
    func requestDataDownload() {
        showingDownloadConfirmation = true
    }
    
    func downloadAccountData() {
        // TODO: Implement data download request
        print("Requesting data download...")
    }
    
    func deleteAccount() {
        // TODO: Implement account deletion
        print("Deleting account...")
    }
}

#Preview {
    SecurityView()
} 