import Foundation
import SwiftUI

@MainActor
class BusinessInviteInfluencerViewModel: ObservableObject {
    // Search and Discovery
    @Published var searchText: String = ""
    @Published var searchResults: [InfluencerSearchResult] = []
    @Published var suggestedInfluencers: [InfluencerSearchResult] = []
    @Published var isSearching: Bool = false
    
    // Filters
    @Published var selectedCategories: Set<String> = []
    @Published var selectedTiers: Set<InfluencerTier> = []
    @Published var followerRangeMin: Int = 0
    @Published var followerRangeMax: Int = 1000000
    @Published var engagementRateMin: Double = 0.0
    @Published var engagementRateMax: Double = 10.0
    @Published var locationFilter: String = ""
    @Published var showingFilters: Bool = false
    
    // Invitation Management
    @Published var selectedInfluencers: Set<String> = []
    @Published var invitationMessage: String = ""
    @Published var campaignId: String?
    @Published var offerAmount: Double = 0.0
    @Published var offerType: OfferType = .fixed
    @Published var deliverables: [String] = []
    @Published var deadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    // Bulk Operations
    @Published var showingBulkInvite: Bool = false
    @Published var bulkInviteTemplate: InviteTemplate?
    @Published var isSendingInvites: Bool = false
    
    // Sent Invitations
    @Published var sentInvitations: [SentInvitation] = []
    @Published var invitationResponses: [InvitationResponse] = []
    @Published var showingInvitationHistory: Bool = false
    
    // Templates
    @Published var inviteTemplates: [InviteTemplate] = []
    @Published var selectedTemplate: InviteTemplate?
    @Published var showingTemplateEditor: Bool = false
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    // Detail Views
    @Published var selectedInfluencer: InfluencerSearchResult?
    @Published var showingInfluencerDetail: Bool = false
    @Published var showingInviteComposer: Bool = false
    
    private let apiService = APIService.shared
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        isLoading = true
        
        Task {
            do {
                async let suggestedTask = apiService.getSuggestedInfluencers()
                async let templatesTask = apiService.getInviteTemplates()
                async let sentInvitationsTask = apiService.getSentInvitations()
                
                let (suggested, templates, sent) = try await (
                    suggestedTask, templatesTask, sentInvitationsTask
                )
                
                await MainActor.run {
                    self.suggestedInfluencers = suggested
                    self.inviteTemplates = templates
                    self.sentInvitations = sent
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading initial data: \(error)")
                    self.loadSampleDataAsFallback()
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Search Functionality
    
    func searchInfluencers() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask?.cancel()
        isSearching = true
        
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // Debounce
                
                if Task.isCancelled { return }
                
                let results = try await apiService.searchInfluencers(
                    query: searchText,
                    categories: Array(selectedCategories),
                    tiers: Array(selectedTiers),
                    followerRange: (followerRangeMin, followerRangeMax),
                    engagementRange: (engagementRateMin, engagementRateMax),
                    location: locationFilter.isEmpty ? nil : locationFilter
                )
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = "Search failed: \(error.localizedDescription)"
                        self.isSearching = false
                    }
                }
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        searchTask?.cancel()
        isSearching = false
    }
    
    // MARK: - Filter Management
    
    func applyFilters() {
        if !searchText.isEmpty {
            searchInfluencers()
        }
        showingFilters = false
    }
    
    func clearFilters() {
        selectedCategories.removeAll()
        selectedTiers.removeAll()
        followerRangeMin = 0
        followerRangeMax = 1000000
        engagementRateMin = 0.0
        engagementRateMax = 10.0
        locationFilter = ""
    }
    
    var hasActiveFilters: Bool {
        return !selectedCategories.isEmpty ||
               !selectedTiers.isEmpty ||
               followerRangeMin > 0 ||
               followerRangeMax < 1000000 ||
               engagementRateMin > 0.0 ||
               engagementRateMax < 10.0 ||
               !locationFilter.isEmpty
    }
    
    // MARK: - Selection Management
    
    func toggleInfluencerSelection(_ influencerId: String) {
        if selectedInfluencers.contains(influencerId) {
            selectedInfluencers.remove(influencerId)
        } else {
            selectedInfluencers.insert(influencerId)
        }
    }
    
    func selectAllVisible() {
        let visibleIds = currentInfluencers.map { $0.id }
        selectedInfluencers.formUnion(visibleIds)
    }
    
    func deselectAll() {
        selectedInfluencers.removeAll()
    }
    
    var currentInfluencers: [InfluencerSearchResult] {
        return searchText.isEmpty ? suggestedInfluencers : searchResults
    }
    
    // MARK: - Invitation Sending
    
    func sendInvitation(to influencer: InfluencerSearchResult) {
        Task {
            do {
                let invitation = InvitationRequest(
                    influencerId: influencer.id,
                    campaignId: campaignId,
                    message: invitationMessage,
                    offerAmount: offerAmount,
                    offerType: offerType,
                    deliverables: deliverables,
                    deadline: deadline
                )
                
                let sentInvitation = try await apiService.sendInfluencerInvitation(invitation)
                
                await MainActor.run {
                    self.sentInvitations.append(sentInvitation)
                    self.showingInviteComposer = false
                    self.resetInvitationForm()
                    self.showSuccessMessage("Invitation sent to \(influencer.username)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func sendBulkInvitations() {
        guard !selectedInfluencers.isEmpty else { return }
        
        isSendingInvites = true
        
        Task {
            var successCount = 0
            var failureCount = 0
            
            for influencerId in selectedInfluencers {
                do {
                    let invitation = InvitationRequest(
                        influencerId: influencerId,
                        campaignId: campaignId,
                        message: invitationMessage,
                        offerAmount: offerAmount,
                        offerType: offerType,
                        deliverables: deliverables,
                        deadline: deadline
                    )
                    
                    let sentInvitation = try await apiService.sendInfluencerInvitation(invitation)
                    
                    await MainActor.run {
                        self.sentInvitations.append(sentInvitation)
                    }
                    
                    successCount += 1
                } catch {
                    failureCount += 1
                }
            }
            
            await MainActor.run {
                self.isSendingInvites = false
                self.showingBulkInvite = false
                self.selectedInfluencers.removeAll()
                self.resetInvitationForm()
                
                if failureCount == 0 {
                    self.showSuccessMessage("Successfully sent \(successCount) invitations")
                } else {
                    self.showSuccessMessage("Sent \(successCount) invitations, \(failureCount) failed")
                }
            }
        }
    }
    
    private func resetInvitationForm() {
        invitationMessage = ""
        offerAmount = 0.0
        offerType = .fixed
        deliverables = []
        deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }
    
    // MARK: - Template Management
    
    func applyTemplate(_ template: InviteTemplate) {
        invitationMessage = template.message
        offerAmount = template.defaultOfferAmount
        offerType = template.offerType
        deliverables = template.deliverables
        selectedTemplate = template
    }
    
    func saveAsTemplate() {
        let template = InviteTemplate(
            id: UUID().uuidString,
            name: "Custom Template",
            message: invitationMessage,
            defaultOfferAmount: offerAmount,
            offerType: offerType,
            deliverables: deliverables,
            createdAt: Date()
        )
        
        Task {
            do {
                let savedTemplate = try await apiService.saveInviteTemplate(template)
                
                await MainActor.run {
                    self.inviteTemplates.append(savedTemplate)
                    self.showSuccessMessage("Template saved successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save template: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Invitation History
    
    func loadInvitationHistory() {
        Task {
            do {
                async let sentTask = apiService.getSentInvitations()
                async let responsesTask = apiService.getInvitationResponses()
                
                let (sent, responses) = try await (sentTask, responsesTask)
                
                await MainActor.run {
                    self.sentInvitations = sent
                    self.invitationResponses = responses
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load invitation history: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func resendInvitation(_ invitation: SentInvitation) {
        Task {
            do {
                try await apiService.resendInvitation(invitation.id)
                
                await MainActor.run {
                    self.showSuccessMessage("Invitation resent successfully")
                    self.loadInvitationHistory()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to resend invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancelInvitation(_ invitation: SentInvitation) {
        Task {
            do {
                try await apiService.cancelInvitation(invitation.id)
                
                await MainActor.run {
                    self.sentInvitations.removeAll { $0.id == invitation.id }
                    self.showSuccessMessage("Invitation cancelled successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Detail Views
    
    func showInfluencerDetail(_ influencer: InfluencerSearchResult) {
        selectedInfluencer = influencer
        showingInfluencerDetail = true
    }
    
    func showInviteComposer(for influencer: InfluencerSearchResult) {
        selectedInfluencer = influencer
        showingInviteComposer = true
    }
    
    // MARK: - Sample Data Fallback
    
    private func loadSampleDataAsFallback() {
        // Sample Suggested Influencers
        suggestedInfluencers = [
            InfluencerSearchResult(
                id: "inf1",
                username: "@fashionista_sarah",
                displayName: "Sarah Johnson",
                profileImageUrl: nil,
                followerCount: 125000,
                engagementRate: 4.8,
                tier: .macro,
                categories: ["Fashion", "Lifestyle"],
                location: "Los Angeles, CA",
                averageViews: 45000,
                recentPosts: 12,
                collaborationRate: 89.5,
                responseTime: "2 hours",
                isVerified: true
            ),
            InfluencerSearchResult(
                id: "inf2",
                username: "@fitness_mike",
                displayName: "Mike Chen",
                profileImageUrl: nil,
                followerCount: 89000,
                engagementRate: 5.2,
                tier: .macro,
                categories: ["Fitness", "Health"],
                location: "New York, NY",
                averageViews: 32000,
                recentPosts: 18,
                collaborationRate: 92.1,
                responseTime: "1 hour",
                isVerified: true
            ),
            InfluencerSearchResult(
                id: "inf3",
                username: "@foodie_emma",
                displayName: "Emma Rodriguez",
                profileImageUrl: nil,
                followerCount: 67000,
                engagementRate: 6.1,
                tier: .micro,
                categories: ["Food", "Travel"],
                location: "Miami, FL",
                averageViews: 28000,
                recentPosts: 15,
                collaborationRate: 95.3,
                responseTime: "30 minutes",
                isVerified: false
            )
        ]
        
        // Sample Templates
        inviteTemplates = [
            InviteTemplate(
                id: "temp1",
                name: "Fashion Campaign",
                message: "Hi! We'd love to collaborate with you on our upcoming fashion campaign. Your style perfectly aligns with our brand aesthetic.",
                defaultOfferAmount: 1500.0,
                offerType: .fixed,
                deliverables: ["2 Instagram posts", "3 Instagram stories", "1 Reel"],
                createdAt: Date()
            ),
            InviteTemplate(
                id: "temp2",
                name: "Product Launch",
                message: "We're launching an exciting new product and would love your authentic review and promotion to your engaged audience.",
                defaultOfferAmount: 2000.0,
                offerType: .fixed,
                deliverables: ["1 Instagram post", "5 Instagram stories", "1 YouTube video"],
                createdAt: Date()
            )
        ]
        
        // Sample Sent Invitations
        sentInvitations = [
            SentInvitation(
                id: "sent1",
                influencerId: "inf1",
                influencerUsername: "@fashionista_sarah",
                campaignId: "camp1",
                campaignName: "Summer Collection",
                message: "Hi Sarah! We'd love to collaborate...",
                offerAmount: 1500.0,
                status: .pending,
                sentAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            ),
            SentInvitation(
                id: "sent2",
                influencerId: "inf2",
                influencerUsername: "@fitness_mike",
                campaignId: "camp2",
                campaignName: "Fitness Challenge",
                message: "Hi Mike! Your fitness content is amazing...",
                offerAmount: 2000.0,
                status: .accepted,
                sentAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            )
        ]
    }
    
    // MARK: - Utility Methods
    
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

struct InfluencerSearchResult: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let profileImageUrl: String?
    let followerCount: Int
    let engagementRate: Double
    let tier: InfluencerTier
    let categories: [String]
    let location: String
    let averageViews: Int
    let recentPosts: Int
    let collaborationRate: Double
    let responseTime: String
    let isVerified: Bool
}

enum InfluencerTier: String, Codable, CaseIterable {
    case nano = "nano"
    case micro = "micro"
    case macro = "macro"
    case mega = "mega"
    
    var displayName: String {
        switch self {
        case .nano: return "Nano (1K-10K)"
        case .micro: return "Micro (10K-100K)"
        case .macro: return "Macro (100K-1M)"
        case .mega: return "Mega (1M+)"
        }
    }
    
    var color: Color {
        switch self {
        case .nano: return .green
        case .micro: return .blue
        case .macro: return .orange
        case .mega: return .purple
        }
    }
}

struct InvitationRequest: Codable {
    let influencerId: String
    let campaignId: String?
    let message: String
    let offerAmount: Double
    let offerType: OfferType
    let deliverables: [String]
    let deadline: Date
}

enum OfferType: String, Codable, CaseIterable {
    case fixed = "fixed"
    case perPost = "per_post"
    case commission = "commission"
    case product = "product"
    
    var displayName: String {
        switch self {
        case .fixed: return "Fixed Amount"
        case .perPost: return "Per Post"
        case .commission: return "Commission"
        case .product: return "Product Only"
        }
    }
}

struct InviteTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let message: String
    let defaultOfferAmount: Double
    let offerType: OfferType
    let deliverables: [String]
    let createdAt: Date
}

struct SentInvitation: Identifiable, Codable {
    let id: String
    let influencerId: String
    let influencerUsername: String
    let campaignId: String?
    let campaignName: String?
    let message: String
    let offerAmount: Double
    let status: InvitationStatus
    let sentAt: Date
    let expiresAt: Date
}

enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        case .cancelled: return .secondary
        }
    }
}

struct InvitationResponse: Identifiable, Codable {
    let id: String
    let invitationId: String
    let influencerId: String
    let influencerUsername: String
    let status: InvitationStatus
    let responseMessage: String?
    let respondedAt: Date
} 