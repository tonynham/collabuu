import SwiftUI
import Foundation

@MainActor
class BusinessCampaignDetailViewModel: ObservableObject {
    @Published var campaign: Campaign?
    @Published var campaignMetrics: CampaignMetrics?
    @Published var participatingInfluencers: [BusinessInfluencerProfile] = []
    @Published var participants: [CampaignParticipant] = []
    @Published var submittedContent: [InfluencerContent] = []
    @Published var contentPosts: [BusinessContentPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingInviteInfluencer = false
    @Published var showingContentDetails = false
    
    private let apiService = APIService.shared
    
    func loadCampaignDetails(campaign: Campaign) {
        self.campaign = campaign
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let metricsTask = loadCampaignMetrics(campaignId: campaign.id)
                async let influencersTask = loadParticipatingInfluencers(campaignId: campaign.id)
                async let contentTask = loadSubmittedContent(campaignId: campaign.id)
                async let postsTask = loadContentPosts(campaignId: campaign.id)
                
                let (metrics, influencers, content, posts) = try await (metricsTask, influencersTask, contentTask, postsTask)
                
                await MainActor.run {
                    self.campaignMetrics = metrics
                    self.participatingInfluencers = influencers.0
                    self.participants = influencers.1
                    self.submittedContent = content
                    self.contentPosts = posts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading campaign details: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadCampaignMetrics(campaignId: String) async throws -> CampaignMetrics {
        return try await apiService.getCampaignMetrics(campaignId: campaignId)
    }
    
    private func loadParticipatingInfluencers(campaignId: String) async throws -> ([BusinessInfluencerProfile], [CampaignParticipant]) {
        let influencers = try await apiService.getCampaignInfluencers(campaignId: campaignId)
        let participants = try await apiService.getCampaignParticipants(campaignId: campaignId)
        return (influencers, participants)
    }
    
    private func loadSubmittedContent(campaignId: String) async throws -> [InfluencerContent] {
        return try await apiService.getCampaignContent(campaignId: campaignId)
    }
    
    private func loadContentPosts(campaignId: String) async throws -> [BusinessContentPost] {
        return try await apiService.getCampaignPosts(campaignId: campaignId)
    }
    
    private func loadSampleDataAsFallback() {
        campaignMetrics = CampaignMetrics(
            totalCustomers: 50,
            currentCustomers: 0,
            customerPercentage: 0,
            totalInfluencerSpots: 5,
            filledInfluencerSpots: 3,
            influencerPercentage: 60,
            creditsPerCustomer: 10,
            totalCredits: 100,
            usedCredits: 0,
            creditsPercentage: 0,
            campaignDays: 30,
            visitorTrafficData: []
        )
        
        participants = [
            CampaignParticipant(
                id: "1",
                name: "Sarah Johnson",
                username: "sarahjohnson",
                profileImageUrl: nil,
                followerCount: 25,
                engagementRate: 4.2,
                status: "active"
            ),
            CampaignParticipant(
                id: "2",
                name: "Mike Chen",
                username: "mikechen",
                profileImageUrl: nil,
                followerCount: 18,
                engagementRate: 3.8,
                status: "pending"
            )
        ]
        
        participatingInfluencers = [
            BusinessInfluencerProfile(
                id: "debug-influencer-1",
                name: "Debug Influencer",
                username: "debuginfluencer",
                status: "Accepted",
                profileImageURL: nil
            )
        ]
        
        submittedContent = []
        
        contentPosts = [
            BusinessContentPost(
                id: "1",
                influencerName: "Sarah Johnson",
                influencerUsername: "sarahjohnson",
                platform: "Instagram",
                postType: "Photo",
                imageUrl: nil,
                caption: "Just tried the amazing summer menu at @restaurant! The grilled salmon was incredible 🐟✨ #sponsored #summervibes",
                likes: 1250,
                comments: 89,
                shares: 23,
                postedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            BusinessContentPost(
                id: "2",
                influencerName: "Mike Chen",
                influencerUsername: "mikechen",
                platform: "TikTok",
                postType: "Video",
                imageUrl: nil,
                caption: "POV: You discover the best hidden gem restaurant in the city 🤤 Their new summer dishes are fire! #foodie #restaurant",
                likes: 3420,
                comments: 156,
                shares: 89,
                postedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            )
        ]
        
        isLoading = false
    }
    
    func inviteInfluencer() {
        showingInviteInfluencer = true
    }
    
    func showContentDetails() {
        showingContentDetails = true
    }
    
    func showTrafficDetails() {
        // TODO: Implement traffic analytics view navigation
    }
    
    func refreshCampaignDetails() {
        guard let campaign = campaign else { return }
        loadCampaignDetails(campaign: campaign)
    }
    
    func updateCampaignStatus(_ status: String) {
        guard let campaign = campaign else { return }
        
        Task {
            do {
                try await apiService.updateCampaignStatus(campaignId: campaign.id, status: status)
                await MainActor.run {
                    self.campaign?.status = status
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update campaign status: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func approveCampaignContent(_ contentId: String) {
        Task {
            do {
                try await apiService.approveCampaignContent(contentId: contentId)
                // Refresh content after approval
                refreshCampaignDetails()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to approve content: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Models
struct CampaignMetrics {
    let totalCustomers: Int
    let currentCustomers: Int
    let customerPercentage: Int
    let totalInfluencerSpots: Int
    let filledInfluencerSpots: Int
    let influencerPercentage: Int
    let creditsPerCustomer: Int
    let totalCredits: Int
    let usedCredits: Int
    let creditsPercentage: Int
    let campaignDays: Int
    let visitorTrafficData: [TrafficData]
}

struct BusinessInfluencerProfile {
    let id: String
    let name: String
    let username: String
    let status: String
    let profileImageURL: String?
}

struct InfluencerContent {
    let id: String
    let influencerId: String
    let campaignId: String
    let contentType: String
    let contentURL: String
    let submittedAt: Date
    let status: String
}

struct TrafficData {
    let date: Date
    let visitors: Int
    let clicks: Int
    let conversions: Int
} 