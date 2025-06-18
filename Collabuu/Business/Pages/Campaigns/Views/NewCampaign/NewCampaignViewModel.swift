import SwiftUI
import Foundation

@MainActor
class NewCampaignViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var paymentType: BusinessCampaignPaymentType = .payPerCustomer
    @Published var requirements: String = ""
    @Published var selectedImage: UIImage?
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var isPublic: Bool = true
    @Published var targetCustomers: Int = 100
    @Published var influencerSpots: Int = 5
    @Published var creditCost: Int = 100
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var campaignCreated: Bool = false
    
    private let apiService = APIService.shared
    
    var isFormValid: Bool {
        !title.isEmpty && 
        !description.isEmpty && 
        targetCustomers > 0 && 
        influencerSpots > 0 && 
        creditCost > 0 &&
        endDate > startDate
    }
    
    func createCampaign() {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields correctly."
            showingError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let campaign = Campaign(
                    id: UUID().uuidString,
                    title: title,
                    subtitle: generateSubtitle(),
                    paymentType: paymentType.rawValue,
                    influencerCount: 0,
                    status: "draft",
                    periodStart: startDate,
                    periodEnd: endDate,
                    visits: 0,
                    credits: creditCost,
                    imageURL: nil,
                    description: description,
                    campaignType: mapPaymentTypeToCampaignType(),
                    visibility: isPublic ? "public" : "private",
                    requirements: requirements,
                    targetCustomers: targetCustomers,
                    influencerSpots: influencerSpots,
                    creditsPerAction: calculateCreditsPerAction(),
                    totalCredits: creditCost
                )
                
                let createdCampaign = try await apiService.createCampaign(campaign)
                
                await MainActor.run {
                    self.campaignCreated = true
                    self.resetForm()
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to create campaign: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func mapPaymentTypeToCampaignType() -> String {
        switch paymentType {
        case .payPerCustomer:
            return "pay_per_customer"
        case .payPerClick, .payPerView:
            return "pay_per_post"
        case .fixedRate:
            return "media_event"
        }
    }
    
    private func calculateCreditsPerAction() -> Int {
        return creditCost / max(targetCustomers, 1)
    }
    
    private func generateSubtitle() -> String {
        switch paymentType {
        case .payPerCustomer:
            return "Earn when customers visit through your content"
        case .payPerClick:
            return "Earn for every click on your content"
        case .payPerView:
            return "Earn for every view of your content"
        case .fixedRate:
            return "Fixed payment for campaign completion"
        }
    }
    
    private func resetForm() {
        title = ""
        description = ""
        paymentType = .payPerCustomer
        requirements = ""
        selectedImage = nil
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        isPublic = true
        targetCustomers = 100
        influencerSpots = 5
        creditCost = 100
        campaignCreated = false
        errorMessage = nil
        showingError = false
    }
} 