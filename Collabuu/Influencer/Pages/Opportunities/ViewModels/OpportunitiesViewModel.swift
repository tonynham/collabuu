import Foundation
import SwiftUI

@MainActor
class OpportunitiesViewModel: ObservableObject {
    @Published var opportunities: [CampaignOpportunity] = []
    @Published var filters = OpportunityFilters()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingApplicationSuccess = false
    
    private let apiService = APIService.shared
    
    init() {
        loadOpportunities()
    }
    
    func loadOpportunities() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedOpportunities = try await apiService.getOpportunities()
                await MainActor.run {
                    self.opportunities = fetchedOpportunities
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading opportunities: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    func applyToOpportunity(_ opportunity: CampaignOpportunity) {
        Task {
            do {
                try await apiService.applyToOpportunity(opportunity.id)
                await MainActor.run {
                    // Update the opportunity to show as applied
                    if let index = self.opportunities.firstIndex(where: { $0.id == opportunity.id }) {
                        self.opportunities[index] = CampaignOpportunity(
                            id: opportunity.id,
                            title: opportunity.title,
                            businessName: opportunity.businessName,
                            businessId: opportunity.businessId,
                            description: opportunity.description,
                            paymentType: opportunity.paymentType,
                            availableSpots: opportunity.availableSpots - 1,
                            totalSpots: opportunity.totalSpots,
                            allottedCredits: opportunity.allottedCredits,
                            periodStart: opportunity.periodStart,
                            periodEnd: opportunity.periodEnd,
                            imageUrl: opportunity.imageUrl,
                            hasApplied: true,
                            applicationDeadline: opportunity.applicationDeadline,
                            requirements: opportunity.requirements,
                            categories: opportunity.categories,
                            targetAudience: opportunity.targetAudience,
                            status: opportunity.status,
                            createdAt: opportunity.createdAt
                        )
                    }
                    self.showingApplicationSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func applyFilters(_ newFilters: OpportunityFilters) {
        filters = newFilters
        loadOpportunities()
    }
    
    func refreshOpportunities() {
        loadOpportunities()
    }
    
    func clearFilters() {
        filters = OpportunityFilters()
        loadOpportunities()
    }
    
    private func loadSampleDataAsFallback() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        opportunities = [
            CampaignOpportunity(
                id: "1",
                title: "Summer Menu Launch",
                businessName: "Bella Vista Restaurant",
                businessId: "bella_vista_001",
                description: "Help us promote our new summer menu featuring fresh seasonal ingredients and Mediterranean-inspired dishes. Perfect for food influencers!",
                paymentType: .payPerCustomer,
                availableSpots: 3,
                totalSpots: 5,
                allottedCredits: 450,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 8, day: 31)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 14, to: currentDate) ?? currentDate,
                requirements: ["Must have 1K+ food-focused followers", "Post at least 2 times per week", "Include #BellaVistaSummer"],
                categories: ["Restaurant", "Food & Dining"],
                targetAudience: "Food enthusiasts aged 25-45",
                status: .active,
                createdAt: currentDate
            ),
            CampaignOpportunity(
                id: "2",
                title: "Fitness Challenge Kickoff",
                businessName: "PowerHouse Gym",
                businessId: "powerhouse_gym_002",
                description: "Join our 30-day fitness transformation challenge and inspire others to start their fitness journey with exclusive member perks.",
                paymentType: .fixedRate,
                availableSpots: 2,
                totalSpots: 3,
                allottedCredits: 800,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 15)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 15)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 10, to: currentDate) ?? currentDate,
                requirements: ["Active fitness content creator", "Must complete 30-day challenge", "Weekly progress posts required"],
                categories: ["Fitness", "Health & Wellness"],
                targetAudience: "Fitness enthusiasts and beginners",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -2, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "3",
                title: "Artisan Coffee Discovery",
                businessName: "Roasted Bliss Coffee Co.",
                businessId: "roasted_bliss_003",
                description: "Discover and share the perfect cup with our new single-origin coffee collection. Help coffee lovers find their new favorite brew.",
                paymentType: .giftCards,
                availableSpots: 4,
                totalSpots: 6,
                allottedCredits: 300,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 9, day: 30)) ?? currentDate,
                imageUrl: nil,
                hasApplied: true,
                applicationDeadline: calendar.date(byAdding: .day, value: 21, to: currentDate) ?? currentDate,
                requirements: ["Coffee enthusiast", "Share brewing tips and reviews", "Tag @RoastedBliss in posts"],
                categories: ["Coffee", "Food & Beverage"],
                targetAudience: "Coffee aficionados and morning ritual enthusiasts",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -5, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "4",
                title: "Tech Innovation Showcase",
                businessName: "TechFlow Solutions",
                businessId: "techflow_004",
                description: "Showcase how our productivity apps can transform daily workflows. Perfect for tech reviewers and productivity enthusiasts.",
                paymentType: .payPerClick,
                availableSpots: 5,
                totalSpots: 8,
                allottedCredits: 1200,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 10)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 31)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 8, to: currentDate) ?? currentDate,
                requirements: ["Tech content creator", "Demonstrate app features", "Include affiliate link"],
                categories: ["Technology", "Productivity"],
                targetAudience: "Professionals and productivity seekers",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "5",
                title: "Sustainable Fashion Week",
                businessName: "EcoStyle Boutique",
                businessId: "ecostyle_005",
                description: "Promote sustainable fashion choices with our eco-friendly clothing line. Help spread awareness about ethical fashion practices.",
                paymentType: .products,
                availableSpots: 6,
                totalSpots: 10,
                allottedCredits: 600,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 7, day: 15)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 8, day: 15)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 25, to: currentDate) ?? currentDate,
                requirements: ["Fashion/lifestyle influencer", "Sustainability advocate", "Style 3+ outfits", "Use #EcoStyleChallenge"],
                categories: ["Fashion", "Sustainability"],
                targetAudience: "Eco-conscious fashion lovers",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -3, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "6",
                title: "Local Pet Grooming Grand Opening",
                businessName: "Pampered Paws Spa",
                businessId: "pampered_paws_006",
                description: "Help us celebrate our grand opening! Show off your furry friends' makeovers and spread the word about our premium pet grooming services.",
                paymentType: .payPerCustomer,
                availableSpots: 1,
                totalSpots: 4,
                allottedCredits: 320,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 20)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                requirements: ["Pet owner/lover", "Before & after photos", "Share grooming experience"],
                categories: ["Pets", "Local Business"],
                targetAudience: "Pet owners in the local area",
                status: .active,
                createdAt: calendar.date(byAdding: .hour, value: -6, to: currentDate) ?? currentDate
            )
        ]
    }
}

class OpportunityService {
    func fetchOpportunities(filters: OpportunityFilters) async throws -> [CampaignOpportunity] {
        // Return the same sample data that's loaded in the ViewModel
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return [
            CampaignOpportunity(
                id: "1",
                title: "Summer Menu Launch",
                businessName: "Bella Vista Restaurant",
                businessId: "bella_vista_001",
                description: "Help us promote our new summer menu featuring fresh seasonal ingredients and Mediterranean-inspired dishes. Perfect for food influencers!",
                paymentType: .payPerCustomer,
                availableSpots: 3,
                totalSpots: 5,
                allottedCredits: 450,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 8, day: 31)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 14, to: currentDate) ?? currentDate,
                requirements: ["Must have 1K+ food-focused followers", "Post at least 2 times per week", "Include #BellaVistaSummer"],
                categories: ["Restaurant", "Food & Dining"],
                targetAudience: "Food enthusiasts aged 25-45",
                status: .active,
                createdAt: currentDate
            ),
            CampaignOpportunity(
                id: "2",
                title: "Fitness Challenge Kickoff",
                businessName: "PowerHouse Gym",
                businessId: "powerhouse_gym_002",
                description: "Join our 30-day fitness transformation challenge and inspire others to start their fitness journey with exclusive member perks.",
                paymentType: .fixedRate,
                availableSpots: 2,
                totalSpots: 3,
                allottedCredits: 800,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 15)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 15)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 10, to: currentDate) ?? currentDate,
                requirements: ["Active fitness content creator", "Must complete 30-day challenge", "Weekly progress posts required"],
                categories: ["Fitness", "Health & Wellness"],
                targetAudience: "Fitness enthusiasts and beginners",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -2, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "3",
                title: "Artisan Coffee Discovery",
                businessName: "Roasted Bliss Coffee Co.",
                businessId: "roasted_bliss_003",
                description: "Discover and share the perfect cup with our new single-origin coffee collection. Help coffee lovers find their new favorite brew.",
                paymentType: .giftCards,
                availableSpots: 4,
                totalSpots: 6,
                allottedCredits: 300,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 9, day: 30)) ?? currentDate,
                imageUrl: nil,
                hasApplied: true,
                applicationDeadline: calendar.date(byAdding: .day, value: 21, to: currentDate) ?? currentDate,
                requirements: ["Coffee enthusiast", "Share brewing tips and reviews", "Tag @RoastedBliss in posts"],
                categories: ["Coffee", "Food & Beverage"],
                targetAudience: "Coffee aficionados and morning ritual enthusiasts",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -5, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "4",
                title: "Tech Innovation Showcase",
                businessName: "TechFlow Solutions",
                businessId: "techflow_004",
                description: "Showcase how our productivity apps can transform daily workflows. Perfect for tech reviewers and productivity enthusiasts.",
                paymentType: .payPerClick,
                availableSpots: 5,
                totalSpots: 8,
                allottedCredits: 1200,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 10)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 31)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 8, to: currentDate) ?? currentDate,
                requirements: ["Tech content creator", "Demonstrate app features", "Include affiliate link"],
                categories: ["Technology", "Productivity"],
                targetAudience: "Professionals and productivity seekers",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "5",
                title: "Sustainable Fashion Week",
                businessName: "EcoStyle Boutique",
                businessId: "ecostyle_005",
                description: "Promote sustainable fashion choices with our eco-friendly clothing line. Help spread awareness about ethical fashion practices.",
                paymentType: .products,
                availableSpots: 6,
                totalSpots: 10,
                allottedCredits: 600,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 7, day: 15)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 8, day: 15)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 25, to: currentDate) ?? currentDate,
                requirements: ["Fashion/lifestyle influencer", "Sustainability advocate", "Style 3+ outfits", "Use #EcoStyleChallenge"],
                categories: ["Fashion", "Sustainability"],
                targetAudience: "Eco-conscious fashion lovers",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -3, to: currentDate) ?? currentDate
            ),
            CampaignOpportunity(
                id: "6",
                title: "Local Pet Grooming Grand Opening",
                businessName: "Pampered Paws Spa",
                businessId: "pampered_paws_006",
                description: "Help us celebrate our grand opening! Show off your furry friends' makeovers and spread the word about our premium pet grooming services.",
                paymentType: .payPerCustomer,
                availableSpots: 1,
                totalSpots: 4,
                allottedCredits: 320,
                periodStart: calendar.date(from: DateComponents(year: 2025, month: 6, day: 20)) ?? currentDate,
                periodEnd: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20)) ?? currentDate,
                imageUrl: nil,
                hasApplied: false,
                applicationDeadline: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                requirements: ["Pet owner/lover", "Before & after photos", "Share grooming experience"],
                categories: ["Pets", "Local Business"],
                targetAudience: "Pet owners in the local area",
                status: .active,
                createdAt: calendar.date(byAdding: .hour, value: -6, to: currentDate) ?? currentDate
            )
        ]
    }
    
    func applyToOpportunity(_ opportunityId: String) async throws {
        // TODO: Implement application submission to Supabase
        print("Applied to opportunity: \(opportunityId)")
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
} 