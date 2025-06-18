import Foundation
import SwiftUI

@MainActor
class BusinessNewConversationViewModel: ObservableObject {
    @Published var influencers: [InfluencerProfile] = []
    @Published var filteredInfluencers: [InfluencerProfile] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    @Published var selectedCampaign: Campaign?
    @Published var availableCampaigns: [Campaign] = []
    @Published var conversationCreated = false
    @Published var createdConversationId: String?
    
    private let apiService = APIService.shared
    
    init() {
        loadInfluencers()
        loadAvailableCampaigns()
    }
    
    func loadInfluencers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedInfluencers = try await apiService.getAvailableInfluencers()
                await MainActor.run {
                    self.influencers = fetchedInfluencers
                    self.filteredInfluencers = fetchedInfluencers
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading influencers: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.influencers = [
            InfluencerProfile(
                id: "inf1",
                userId: "user1",
                username: "foodie_sarah",
                firstName: "Sarah",
                lastName: "Johnson",
                bio: "Food enthusiast and lifestyle blogger",
                profileImageUrl: nil,
                followersCount: 15000,
                postsCount: 245,
                engagementRate: 4.2,
                isVerified: false,
                location: "San Francisco, CA",
                website: "https://sarahjohnson.com",
                contactEmail: "sarah@example.com",
                instagramHandle: "@foodie_sarah",
                tiktokHandle: "@foodie_sarah",
                youtubeHandle: "foodie_sarah",
                categories: ["Food", "Lifestyle"],
                priceRange: "$100-500",
                isActive: true,
                availableCredits: 250,
                activeCampaigns: 3,
                totalVisits: 1250,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        self.filteredInfluencers = self.influencers
        self.isLoading = false
    }
    
    func loadAvailableCampaigns() {
        Task {
            do {
                let campaigns = try await apiService.getBusinessCampaigns()
                await MainActor.run {
                    self.availableCampaigns = campaigns.filter { $0.status == "active" || $0.status == "draft" }
                }
            } catch {
                await MainActor.run {
                    print("Error loading campaigns: \(error)")
                }
            }
        }
    }
    
    func searchInfluencers(query: String) {
        searchQuery = query
        
        if query.isEmpty {
            filteredInfluencers = influencers
        } else {
            filteredInfluencers = influencers.filter { influencer in
                influencer.username.localizedCaseInsensitiveContains(query) ||
                (influencer.bio?.localizedCaseInsensitiveContains(query) ?? false) ||
                influencer.firstName.localizedCaseInsensitiveContains(query) ||
                influencer.lastName.localizedCaseInsensitiveContains(query) ||
                influencer.categories.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }
    
    func startConversation(with influencer: InfluencerProfile, initialMessage: String = "") {
        guard let selectedCampaign = selectedCampaign else {
            errorMessage = "Please select a campaign first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let conversationRequest = NewConversationRequest(
                    influencerId: influencer.id,
                    campaignId: selectedCampaign.id,
                    initialMessage: initialMessage.isEmpty ? "Hi! I'd like to discuss a collaboration opportunity for my campaign '\(selectedCampaign.title)'." : initialMessage
                )
                
                let conversation = try await apiService.createBusinessConversation(conversationRequest)
                
                await MainActor.run {
                    self.conversationCreated = true
                    self.createdConversationId = conversation.id
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start conversation: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func inviteInfluencerToCampaign(_ influencer: InfluencerProfile) {
        guard let selectedCampaign = selectedCampaign else {
            errorMessage = "Please select a campaign first"
            return
        }
        
        Task {
            do {
                try await apiService.inviteInfluencerToCampaign(
                    campaignId: selectedCampaign.id,
                    influencerId: influencer.id
                )
                
                await MainActor.run {
                    // Show success message or update UI
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send invitation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshData() {
        loadInfluencers()
        loadAvailableCampaigns()
    }
    
    func resetConversationState() {
        conversationCreated = false
        createdConversationId = nil
        errorMessage = nil
    }
}

struct NewConversationRequest: Codable {
    let influencerId: String
    let campaignId: String
    let initialMessage: String
} 