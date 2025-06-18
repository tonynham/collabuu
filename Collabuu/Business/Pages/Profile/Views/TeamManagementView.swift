import SwiftUI

struct TeamManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TeamManagementViewModel()
    @State private var emailText = "example@company.com"
    @State private var selectedRole: TeamRole = .editor
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Team Management Sections
                    VStack(spacing: AppSpacing.lg) {
                        inviteNewMemberSection
                        currentTeamSection
                    }
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.backgroundSecondary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Team Management")
                        .titleLarge(AppColors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Profile") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.secondary)
                }
            }
        }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .standardizedAlert(
            isPresented: $viewModel.showingInviteSuccess,
            config: StandardizedAlertConfig(
                title: "Invitation Sent",
                message: viewModel.inviteSuccessMessage,
                primaryButton: StandardizedAlertConfig.AlertButton(
                    title: "OK",
                    action: { viewModel.dismissInviteSuccess() }
                )
            )
        )
        .standardizedAlert(
            isPresented: $viewModel.showingRemoveConfirmation,
            config: StandardizedAlertConfig(
                title: "Remove Team Member",
                message: "Are you sure you want to remove \(viewModel.memberToRemove?.name ?? "this member") from your team?",
                primaryButton: StandardizedAlertConfig.AlertButton(
                    title: "Remove",
                    style: .destructive,
                    action: { viewModel.removeMember() }
                ),
                secondaryButton: StandardizedAlertConfig.AlertButton(
                    title: "Cancel",
                    action: { viewModel.cancelRemoveMember() }
                )
            )
        )
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.secondary.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.3")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                )
            
            VStack(spacing: AppSpacing.sm) {
                Text("Team Management")
                    .headlineMedium(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Invite team members to help manage your business and campaigns")
                    .bodyLarge(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppSpacing.lg)
    }
    
    private var inviteNewMemberSection: some View {
        teamCard(
            title: "Invite New Team Member",
            icon: "plus.message",
            description: "Add team members to help manage your business"
        ) {
            VStack(spacing: AppSpacing.md) {
                // Email Address Field
                StandardizedFormField(
                    title: "Email Address",
                    text: $emailText,
                    placeholder: "example@company.com",
                    keyboardType: .emailAddress,
                    isRequired: true,
                    leadingIcon: "envelope"
                )
                
                // Role Selection
                StandardizedDropdown(
                    title: "Role",
                    selection: $selectedRole,
                    options: TeamRole.allCases,
                    isRequired: true
                )
                
                StandardizedButton(
                    title: "Send Invitation",
                    action: {
                        viewModel.sendInvitation(email: emailText, role: selectedRole)
                        emailText = "example@company.com" // Reset form
                    },
                    style: .secondary,
                    size: .large,
                    isLoading: viewModel.isLoading,
                    isDisabled: emailText.isEmpty || emailText == "example@company.com",
                    leadingIcon: "paperplane.fill"
                )
            }
        }
    }
    
    private var currentTeamSection: some View {
        teamCard(
            title: "Current Team",
            icon: "person.3.sequence",
            description: "Manage your team members and their roles"
        ) {
            if viewModel.teamMembers.isEmpty {
                emptyState
            } else {
                teamMembersList
            }
        }
    }
    
    private var emptyState: some View {
        StandardizedEmptyState(
            icon: "person.3.sequence",
            title: "No Team Members Yet",
            message: "Invite team members to help manage your business and campaigns"
        )
        .frame(minHeight: 200)
    }
    
    private var teamMembersList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.teamMembers.enumerated()), id: \.element.id) { index, member in
                TeamMemberRow(
                    member: member,
                    onRemove: { viewModel.confirmRemoveMember(member) },
                    onChangeRole: { newRole in viewModel.updateMemberRole(member, newRole: newRole) }
                )
                
                if index < viewModel.teamMembers.count - 1 {
                    Divider()
                        .padding(.leading, 56) // Align with content
                }
            }
        }
    }
    
    private func teamCard<Content: View>(
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

// MARK: - Team Member Row
struct TeamMemberRow: View {
    let member: TeamMember
    let onRemove: () -> Void
    let onChangeRole: (TeamRole) -> Void
    @State private var showingActionSheet = false
    @State private var showingRoleSelection = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.secondary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text(member.initials)
                    .titleMedium()
                    .foregroundColor(AppColors.secondary)
            }
            
            // Member Info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(member.name)
                    .titleMedium()
                    .foregroundColor(AppColors.textPrimary)
                
                Text(member.email)
                    .bodyMedium()
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(member.role.displayName)
                        .labelMedium()
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("•")
                        .labelMedium()
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(member.status.displayName)
                        .labelMedium()
                        .foregroundColor(statusColor(for: member.status))
                }
            }
            
            Spacer()
            
            // More Options
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .titleMedium()
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(AppColors.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Team Member Actions"),
                message: Text(member.name),
                buttons: [
                    .default(Text("Change Role")) {
                        showingRoleSelection = true
                    },
                    .destructive(Text("Remove from Team")) {
                        onRemove()
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingRoleSelection) {
            RoleSelectionSheet(
                currentRole: member.role,
                onRoleSelected: { newRole in
                    onChangeRole(newRole)
                    showingRoleSelection = false
                }
            )
        }
    }
    
    private func statusColor(for status: MemberStatus) -> Color {
        switch status {
        case .active: return AppColors.success
        case .pending: return AppColors.warning
        case .inactive: return AppColors.textTertiary
        case .suspended: return AppColors.error
        }
    }
}

// MARK: - Role Selection Sheet
struct RoleSelectionSheet: View {
    let currentRole: TeamRole
    let onRoleSelected: (TeamRole) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.md) {
                    Text("Select Role")
                        .headlineMedium()
                    
                    Text("Choose the appropriate role for this team member")
                        .bodyLarge()
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.lg)
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(TeamRole.allCases, id: \.self) { role in
                        Button(action: {
                            onRoleSelected(role)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(role.displayName)
                                        .titleMedium()
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(role.description)
                                        .bodyMedium()
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if role == currentRole {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.secondary)
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                                    .fill(role == currentRole ? AppColors.secondary.opacity(0.1) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                                            .stroke(role == currentRole ? AppColors.secondary : AppColors.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .navigationTitle("Change Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension TeamRole {
    var description: String {
        switch self {
        case .admin:
            return "Full access to all business features and settings"
        case .manager:
            return "Can manage campaigns and team members"
        case .member:
            return "Can view campaigns and basic business information"
        }
    }
}

#Preview {
    NavigationView {
        TeamManagementView()
    }
} 