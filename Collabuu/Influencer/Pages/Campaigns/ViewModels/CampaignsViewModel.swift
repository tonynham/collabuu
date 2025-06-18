import Foundation
import SwiftUI

@MainActor
class CampaignsViewModel: ObservableObject {
    @Published var campaigns: [AcceptedCampaign] = []
    @Published var filteredCampaigns: [AcceptedCampaign] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = CampaignFilters()
    
    private let apiService = APIService.shared
    
    init() {
        loadCampaigns()
    }
    
    func loadCampaigns() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedCampaigns = try await apiService.getInfluencerCampaigns()
                await MainActor.run {
                    self.campaigns = fetchedCampaigns
                    self.applyCurrentFilters()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading campaigns: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        // Sample campaigns for development
        self.campaigns = AcceptedCampaign.sampleCampaigns
        self.applyCurrentFilters()
        self.isLoading = false
    }
    
    func applyFilters(_ newFilters: CampaignFilters) {
        filters = newFilters
        applyCurrentFilters()
    }
    
    private func applyCurrentFilters() {
        var filtered = campaigns
        
        // Filter by status
        if !filters.selectedStatuses.isEmpty {
            filtered = filtered.filter { campaign in
                filters.selectedStatuses.contains(campaign.status)
            }
        }
        
        // Filter by payment type
        if !filters.selectedPaymentTypes.isEmpty {
            filtered = filtered.filter { campaign in
                filters.selectedPaymentTypes.contains(campaign.paymentType)
            }
        }
        
        // Filter by search text
        if !filters.searchText.isEmpty {
            filtered = filtered.filter { campaign in
                campaign.title.localizedCaseInsensitiveContains(filters.searchText) ||
                campaign.businessName.localizedCaseInsensitiveContains(filters.searchText) ||
                campaign.description.localizedCaseInsensitiveContains(filters.searchText)
            }
        }
        
        // Sort campaigns
        switch filters.sortBy {
        case .newest:
            filtered.sort { $0.acceptedAt > $1.acceptedAt }
        case .oldest:
            filtered.sort { $0.acceptedAt < $1.acceptedAt }
        case .earnings:
            filtered.sort { $0.earnedCredits > $1.earnedCredits }
        case .endDate:
            filtered.sort { $0.endDate < $1.endDate }
        }
        
        self.filteredCampaigns = filtered
    }
    
    func refreshCampaigns() {
        loadCampaigns()
    }
    
    func updateCampaignProgress(_ campaignId: String, visits: Int) async {
        do {
            try await apiService.updateCampaignProgress(campaignId: campaignId, visits: visits)
            // Refresh campaigns to get updated data
            loadCampaigns()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update campaign progress: \(error.localizedDescription)"
            }
        }
    }
}

struct CampaignFilters {
    var searchText: String = ""
    var selectedStatuses: Set<CampaignStatus> = []
    var selectedPaymentTypes: Set<CampaignPaymentType> = []
    var sortBy: CampaignSortOption = .newest
    
    var hasActiveFilters: Bool {
        return !searchText.isEmpty || 
               !selectedStatuses.isEmpty || 
               !selectedPaymentTypes.isEmpty ||
               sortBy != .newest
    }
}

enum CampaignSortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case earnings = "earnings"
    case endDate = "endDate"
    
    var displayName: String {
        switch self {
        case .newest:
            return "Newest First"
        case .oldest:
            return "Oldest First"
        case .earnings:
            return "Highest Earnings"
        case .endDate:
            return "Ending Soon"
        }
    }
} 