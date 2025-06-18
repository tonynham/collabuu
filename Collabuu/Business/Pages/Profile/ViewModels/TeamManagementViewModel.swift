import Foundation
import SwiftUI

@MainActor
class TeamManagementViewModel: ObservableObject {
    @Published var teamMembers: [TeamMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingInviteSuccess = false
    @Published var inviteSuccessMessage = ""
    @Published var showingRemoveConfirmation = false
    @Published var memberToRemove: TeamMember?
    @Published var pendingInvitations: [TeamInvitation] = []
    
    private let apiService = APIService.shared
    
    init() {
        loadTeamMembers()
        loadPendingInvitations()
    }
    
    func loadTeamMembers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let members = try await apiService.getBusinessTeamMembers()
                await MainActor.run {
                    self.teamMembers = members
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading team members: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    func loadPendingInvitations() {
        Task {
            do {
                let invitations = try await apiService.getBusinessTeamInvitations()
                await MainActor.run {
                    self.pendingInvitations = invitations
                }
            } catch {
                await MainActor.run {
                    print("Error loading pending invitations: \(error)")
                    // Fallback to empty array
                    self.pendingInvitations = []
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.teamMembers = [
            TeamMember(
                id: "member1",
                userId: "user1",
                name: "John Smith",
                email: "john@business.com",
                role: .admin,
                status: .active,
                invitedAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                joinedAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
            ),
            TeamMember(
                id: "member2",
                userId: "user2",
                name: "Sarah Johnson",
                email: "sarah@business.com",
                role: .manager,
                status: .active,
                invitedAt: Calendar.current.date(byAdding: .week, value: -3, to: Date()) ?? Date(),
                joinedAt: Calendar.current.date(byAdding: .week, value: -3, to: Date()) ?? Date()
            )
        ]
        
        self.pendingInvitations = [
            TeamInvitation(
                id: "inv1",
                email: "mike@business.com",
                role: .member,
                invitedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            )
        ]
        
        self.isLoading = false
    }
    
    func sendInvitation(email: String, role: TeamRole) {
        guard !email.isEmpty, isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // Check if email is already invited or a member
        if teamMembers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "This email is already a team member"
            return
        }
        
        if pendingInvitations.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "An invitation has already been sent to this email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let invitation = TeamInvitationRequest(
                    email: email,
                    role: role
                )
                
                try await apiService.sendBusinessTeamInvitation(invitation)
                
                await MainActor.run {
                    self.inviteSuccessMessage = "Invitation sent to \(email)"
                    self.showingInviteSuccess = true
                    self.isLoading = false
                    
                    // Refresh data to show pending invitation
                    self.loadPendingInvitations()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send invitation: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func confirmRemoveMember(_ member: TeamMember) {
        memberToRemove = member
        showingRemoveConfirmation = true
    }
    
    func removeMember() {
        guard let member = memberToRemove else { return }
        
        Task {
            do {
                try await apiService.removeBusinessTeamMember(memberId: member.id)
                await MainActor.run {
                    self.teamMembers.removeAll { $0.id == member.id }
                    self.memberToRemove = nil
                    self.showingRemoveConfirmation = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove team member: \(error.localizedDescription)"
                    self.showingRemoveConfirmation = false
                }
            }
        }
    }
    
    func cancelRemoveMember() {
        memberToRemove = nil
        showingRemoveConfirmation = false
    }
    
    func updateMemberRole(_ member: TeamMember, newRole: TeamRole) {
        Task {
            do {
                try await apiService.updateBusinessTeamMemberRole(memberId: member.id, role: newRole)
                await MainActor.run {
                    if let index = self.teamMembers.firstIndex(where: { $0.id == member.id }) {
                        self.teamMembers[index] = TeamMember(
                            id: member.id,
                            userId: member.userId,
                            name: member.name,
                            email: member.email,
                            role: newRole,
                            status: member.status,
                            invitedAt: member.invitedAt,
                            joinedAt: member.joinedAt
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update member role: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func resendInvitation(_ invitation: TeamInvitation) {
        Task {
            do {
                try await apiService.resendBusinessTeamInvitation(invitationId: invitation.id)
                await MainActor.run {
                    self.inviteSuccessMessage = "Invitation resent to \(invitation.email)"
                    self.showingInviteSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to resend invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancelInvitation(_ invitation: TeamInvitation) {
        Task {
            do {
                try await apiService.cancelBusinessTeamInvitation(invitationId: invitation.id)
                await MainActor.run {
                    self.pendingInvitations.removeAll { $0.id == invitation.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshData() {
        loadTeamMembers()
        loadPendingInvitations()
    }
    
    func dismissInviteSuccess() {
        showingInviteSuccess = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct TeamInvitationRequest: Codable {
    let email: String
    let role: TeamRole
}

struct TeamInvitation: Identifiable, Codable {
    let id: String
    let email: String
    let role: TeamRole
    let invitedAt: Date
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeRemaining: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: expiresAt, relativeTo: Date())
    }
} 