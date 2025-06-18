import SwiftUI

struct CustomerNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CustomerNotificationSettingsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header Section
                headerSection
                
                // Notification Sections
                VStack(spacing: AppSpacing.lg) {
                    pushNotificationsSection
                    dealNotificationsSection
                    messageNotificationsSection
                    accountNotificationsSection
                    marketingNotificationsSection
                }
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.backgroundSecondary)
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.hasUnsavedChanges {
                    Button("Save") {
                        viewModel.saveSettings()
                    }
                    .disabled(viewModel.isLoading)
                }
                
                Menu {
                    Button("Reset to Defaults") {
                        viewModel.resetToDefaults()
                    }
                    
                    if viewModel.hasUnsavedChanges {
                        Button("Discard Changes") {
                            viewModel.discardChanges()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.loadSettings()
        }
        .onChange(of: viewModel.pushNotificationsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.newDealAlertsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.favoriteBusinessUpdatesEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.dealAlertsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.dealExpiryRemindersEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.messageNotificationsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.businessResponsesEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.accountNotificationsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.securityAlertsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.pointsUpdatesEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.marketingNotificationsEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.weeklyDigestEnabled) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.specialOffersEnabled) { _ in viewModel.checkForChanges() }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .overlay(
            Group {
                if viewModel.showingSaveSuccess {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Settings saved")
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
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingSaveSuccess)
                }
            }
        )
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.secondary.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "bell.circle")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                )
            
            VStack(spacing: AppSpacing.sm) {
                Text("Notification Settings")
                    .headlineMedium(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Manage your notification preferences")
                    .bodyLarge(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppSpacing.lg)
    }
    
    private var pushNotificationsSection: some View {
        notificationCard(
            title: "Push Notifications",
            icon: "bell.circle",
            description: "Control all push notifications to your device"
        ) {
            VStack(spacing: AppSpacing.md) {
                CustomerNotificationToggleRow(
                    title: "Enable Push Notifications",
                    description: "Receive notifications on your device",
                    icon: "bell.badge",
                    isOn: $viewModel.pushNotificationsEnabled,
                    isMasterToggle: true
                )
                
                if !viewModel.pushNotificationsEnabled {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.warning)
                        
                        Text("Other notification settings are disabled while push notifications are off")
                            .bodySmall(AppColors.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.warning.opacity(0.1))
                    .cornerRadius(AppSpacing.radiusSM)
                }
            }
        }
    }
    
    private var dealNotificationsSection: some View {
        notificationCard(
            title: "Deal Alerts",
            icon: "tag.circle",
            description: "Stay updated on new deals and special offers"
        ) {
            VStack(spacing: AppSpacing.md) {
                CustomerNotificationToggleRow(
                    title: "New Deal Alerts",
                    description: "Get notified when new deals are available",
                    icon: "sparkles",
                    isOn: $viewModel.newDealAlertsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Favorite Business Updates",
                    description: "Notifications from your favorite businesses",
                    icon: "heart.circle",
                    isOn: $viewModel.favoriteBusinessUpdatesEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Deal Alerts",
                    description: "Get notified about deals and special offers",
                    icon: "tag.circle",
                    isOn: $viewModel.dealAlertsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Deal Expiry Reminders",
                    description: "Get reminded before your deals expire",
                    icon: "clock.circle",
                    isOn: $viewModel.dealExpiryRemindersEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
            }
        }
    }
    
    private var messageNotificationsSection: some View {
        notificationCard(
            title: "Message Notifications",
            icon: "message.circle",
            description: "Receive notifications about messages"
        ) {
            VStack(spacing: AppSpacing.md) {
                CustomerNotificationToggleRow(
                    title: "Enable Message Notifications",
                    description: "Receive notifications about messages",
                    icon: "message.circle",
                    isOn: $viewModel.messageNotificationsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Business Responses",
                    description: "Get notified when businesses respond to you",
                    icon: "bubble.left.and.bubble.right",
                    isOn: $viewModel.businessResponsesEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
            }
        }
    }
    
    private var accountNotificationsSection: some View {
        notificationCard(
            title: "Account Notifications",
            icon: "person.circle",
            description: "Receive notifications about your account"
        ) {
            VStack(spacing: AppSpacing.md) {
                CustomerNotificationToggleRow(
                    title: "Enable Account Notifications",
                    description: "Receive notifications about your account",
                    icon: "person.circle",
                    isOn: $viewModel.accountNotificationsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Security Alerts",
                    description: "Get notified about security-related events",
                    icon: "shield.circle",
                    isOn: $viewModel.securityAlertsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Points Updates",
                    description: "Get notified when you earn or redeem points",
                    icon: "star.circle",
                    isOn: $viewModel.pointsUpdatesEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
            }
        }
    }
    
    private var marketingNotificationsSection: some View {
        notificationCard(
            title: "Marketing Updates",
            icon: "megaphone.circle",
            description: "Receive marketing updates and promotions"
        ) {
            VStack(spacing: AppSpacing.md) {
                CustomerNotificationToggleRow(
                    title: "Enable Marketing Updates",
                    description: "Receive marketing updates and promotions",
                    icon: "megaphone.circle",
                    isOn: $viewModel.marketingNotificationsEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Weekly Digest",
                    description: "Get a weekly summary of deals and activities",
                    icon: "calendar.circle",
                    isOn: $viewModel.weeklyDigestEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
                
                CustomerNotificationToggleRow(
                    title: "Special Offers",
                    description: "Receive exclusive offers and promotions",
                    icon: "gift.circle",
                    isOn: $viewModel.specialOffersEnabled,
                    isDisabled: !viewModel.pushNotificationsEnabled
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func notificationCard<Content: View>(
        title: String,
        icon: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .titleMedium(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .bodyMedium(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
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

struct CustomerNotificationToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    let isMasterToggle: Bool
    let isDisabled: Bool
    
    init(
        title: String,
        description: String,
        icon: String,
        isOn: Binding<Bool>,
        isMasterToggle: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._isOn = isOn
        self.isMasterToggle = isMasterToggle
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDisabled ? AppColors.textTertiary : AppColors.secondary)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .bodyLarge(isDisabled ? AppColors.textTertiary : AppColors.textPrimary)
                    .fontWeight(isMasterToggle ? .semibold : .medium)
                
                Text(description)
                    .bodyMedium(isDisabled ? AppColors.textTertiary : AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .disabled(isDisabled)
        }
        .padding(.vertical, AppSpacing.xs)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

#Preview {
    CustomerNotificationSettingsView()
} 