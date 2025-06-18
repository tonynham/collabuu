import Foundation
import Combine
import SwiftUI

// MARK: - Supporting Models
struct ContentPost: Identifiable {
    let id: String
    let platform: String
    let views: Int
    let imageUrl: String?
    let caption: String
    let createdAt: Date
    let postUrl: String?
}

@MainActor
class InfluencerCampaignDetailViewModel: ObservableObject {
    @Published var campaign: AcceptedCampaign?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingContentCreation = false
    @Published var postsCreated = 0
    @Published var totalViews = 0
    @Published var engagementRate = 0.0
    @Published var totalEarnings = 0.0
    @Published var contentPosts: [ContentPost] = []
    
    // Visitor Chart Data
    @Published var visitorData: [Double] = []
    @Published var visitorLabels: [String] = []
    
    // Social Media Link Submission
    @Published var socialMediaLink: String = ""
    @Published var isSubmittingLink: Bool = false
    
    // Unique Code Sharing
    @Published var campaignDeepLink: String = ""
    @Published var showingSubmissionSuccess = false
    @Published var showingShareSheet = false
    @Published var copiedToClipboard = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    func loadCampaignDetails(_ campaign: AcceptedCampaign) {
        self.campaign = campaign
        isLoading = true
        errorMessage = nil
        
        // Generate deep link
        self.campaignDeepLink = "https://collabuu.com/campaign/\(campaign.campaignCode)"
        
        Task {
            do {
                async let performanceTask = loadPerformanceData(for: campaign)
                async let visitorTask = loadVisitorChartData(for: campaign)
                async let contentTask = loadContentPosts(for: campaign)
                
                let (_, _, _) = try await (performanceTask, visitorTask, contentTask)
                
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading campaign details: \(error)")
                    
                    // Fallback to sample data
                    self.loadSampleDataAsFallback(for: campaign)
                }
            }
        }
    }
    
    private func loadPerformanceData(for campaign: AcceptedCampaign) async throws {
        let performance = try await apiService.getCampaignPerformance(campaignId: campaign.id)
        
        await MainActor.run {
            self.postsCreated = performance.postsCreated
            self.totalViews = performance.totalViews
            self.engagementRate = performance.engagementRate
            self.totalEarnings = performance.totalEarnings
        }
    }
    
    private func loadVisitorChartData(for campaign: AcceptedCampaign) async throws {
        let chartData = try await apiService.getCampaignVisitorData(campaignId: campaign.id)
        
        await MainActor.run {
            self.visitorData = chartData.data
            self.visitorLabels = chartData.labels
        }
    }
    
    private func loadContentPosts(for campaign: AcceptedCampaign) async throws {
        let posts = try await apiService.getCampaignContentPosts(campaignId: campaign.id)
        
        await MainActor.run {
            self.contentPosts = posts
        }
    }
    
    private func loadSampleDataAsFallback(for campaign: AcceptedCampaign) {
        // Sample performance data
        self.postsCreated = 2
        self.totalViews = campaign.currentVisits * 10
        self.engagementRate = 4.2
        self.totalEarnings = Double(campaign.earnedCredits)
        
        // Sample visitor chart data
        let calendar = Calendar.current
        let endDate = Date()
        var data: [Double] = []
        var labels: [String] = []
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                labels.append(formatter.string(from: date))
                
                let baseVisitors = Double(campaign.currentVisits) / 7.0
                let variation = Double.random(in: 0.5...1.5)
                data.append(max(0, baseVisitors * variation))
            }
        }
        
        self.visitorData = data
        self.visitorLabels = labels
        
        // Sample content posts
        self.contentPosts = [
            ContentPost(
                id: "post1",
                platform: "Instagram",
                views: 1250,
                imageUrl: nil,
                caption: "Amazing experience with \(campaign.businessName)! #sponsored",
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                postUrl: "https://instagram.com/p/sample"
            ),
            ContentPost(
                id: "post2",
                platform: "TikTok",
                views: 3400,
                imageUrl: nil,
                caption: "Check out this incredible place! Use my code \(campaign.campaignCode)",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                postUrl: "https://tiktok.com/@user/video/sample"
            )
        ]
        
        self.isLoading = false
    }
    
    func submitSocialMediaLink() {
        guard !socialMediaLink.isEmpty, let campaign = campaign else { return }
        
        isSubmittingLink = true
        errorMessage = nil
        
        Task {
            do {
                let contentSubmission = ContentSubmission(
                    campaignId: campaign.id,
                    platform: determinePlatform(from: socialMediaLink),
                    postUrl: socialMediaLink,
                    caption: "Check out this amazing content!",
                    submittedAt: Date()
                )
                
                let submittedContent = try await apiService.submitCampaignContent(contentSubmission)
                
                await MainActor.run {
                    self.contentPosts.append(submittedContent)
                    self.postsCreated += 1
                    self.socialMediaLink = ""
                    self.isSubmittingLink = false
                    self.showingSubmissionSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to submit content: \(error.localizedDescription)"
                    self.isSubmittingLink = false
                }
            }
        }
    }
    
    private func determinePlatform(from url: String) -> String {
        if url.contains("instagram.com") {
            return "Instagram"
        } else if url.contains("tiktok.com") {
            return "TikTok"
        } else if url.contains("youtube.com") || url.contains("youtu.be") {
            return "YouTube"
        } else if url.contains("twitter.com") || url.contains("x.com") {
            return "Twitter/X"
        } else {
            return "Social Media"
        }
    }
    
    func copyCodeToClipboard() {
        guard let campaign = campaign else { return }
        
        UIPasteboard.general.string = campaign.campaignCode
        copiedToClipboard = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.copiedToClipboard = false
        }
    }
    
    func copyLinkToClipboard() {
        UIPasteboard.general.string = campaignDeepLink
        copiedToClipboard = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.copiedToClipboard = false
        }
    }
    
    func shareCampaign() {
        guard let campaign = campaign else { return }
        showingShareSheet = true
    }
    
    var shareText: String {
        guard let campaign = campaign else { return "" }
        return "Check out this amazing campaign from \(campaign.businessName)! Use my code \(campaign.campaignCode) or visit \(campaignDeepLink)"
    }
    
    func refreshProgress() {
        guard let campaign = campaign else { return }
        
        Task {
            do {
                let updatedCampaign = try await apiService.getInfluencerCampaignDetails(campaignId: campaign.id)
                await MainActor.run {
                    self.campaign = updatedCampaign
                    // Reload all data with updated campaign
                    self.loadCampaignDetails(updatedCampaign)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to refresh progress: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Campaign Actions
    func updateCampaignStatus(_ status: String) {
        guard let campaign = campaign else { return }
        
        Task {
            do {
                try await apiService.updateInfluencerCampaignStatus(campaignId: campaign.id, status: status)
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
    
    func contactBusiness() {
        guard let campaign = campaign else { return }
        
        Task {
            do {
                try await apiService.createInfluencerBusinessConversation(campaignId: campaign.id)
                // Navigate to messages or show success
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to contact business: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func dismissSubmissionSuccess() {
        showingSubmissionSuccess = false
    }
}

struct ContentSubmission: Codable {
    let campaignId: String
    let platform: String
    let postUrl: String
    let caption: String
    let submittedAt: Date
}
} 