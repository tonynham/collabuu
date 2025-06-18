import Foundation
import Combine

@MainActor
class OpportunityDetailViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var applicationSubmitted = false
    @Published var errorMessage: String?
    @Published var opportunity: CampaignOpportunity?
    @Published var isLoading = false
    @Published var businessProfile: BusinessProfile?
    @Published var similarOpportunities: [CampaignOpportunity] = []
    @Published var showingApplicationSuccess = false
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadOpportunityDetails(opportunityId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let opportunityTask = apiService.getOpportunityDetails(opportunityId: opportunityId)
                async let businessTask = loadBusinessProfile(for: opportunityId)
                async let similarTask = apiService.getSimilarOpportunities(opportunityId: opportunityId)
                
                let (fetchedOpportunity, business, similar) = try await (opportunityTask, businessTask, similarTask)
                
                await MainActor.run {
                    self.opportunity = fetchedOpportunity
                    self.businessProfile = business
                    self.similarOpportunities = similar
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading opportunity details: \(error)")
                }
            }
        }
    }
    
    private func loadBusinessProfile(for opportunityId: String) async throws -> BusinessProfile? {
        // Get business profile associated with the opportunity
        return try await apiService.getOpportunityBusinessProfile(opportunityId: opportunityId)
    }
    
    func submitApplication(for opportunity: CampaignOpportunity, message: String = "") {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let application = OpportunityApplication(
                    opportunityId: opportunity.id,
                    message: message,
                    submittedAt: Date()
                )
                
                try await apiService.submitOpportunityApplication(application)
                
                await MainActor.run {
                    self.isSubmitting = false
                    self.applicationSubmitted = true
                    self.showingApplicationSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to submit application: \(error.localizedDescription)"
                    self.isSubmitting = false
                }
            }
        }
    }
    
    func resetApplicationState() {
        applicationSubmitted = false
        errorMessage = nil
        isSubmitting = false
        showingApplicationSuccess = false
    }
    
    func refreshOpportunity() {
        guard let opportunity = opportunity else { return }
        loadOpportunityDetails(opportunityId: opportunity.id)
    }
    
    func bookmarkOpportunity(_ opportunity: CampaignOpportunity) {
        Task {
            do {
                try await apiService.bookmarkOpportunity(opportunityId: opportunity.id)
                // Opportunity bookmarked successfully
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to bookmark opportunity: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func shareOpportunity(_ opportunity: CampaignOpportunity) -> String {
        // Generate shareable link for the opportunity
        return "https://collabuu.com/opportunities/\(opportunity.id)"
    }
}

struct OpportunityApplication: Codable {
    let opportunityId: String
    let message: String
    let submittedAt: Date
} 