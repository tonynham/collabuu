import Foundation
import SwiftUI

@MainActor
class DealsViewModel: ObservableObject {
    @Published var deals: [Deal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filteredDeals: [Deal] = []
    @Published var searchText: String = "" {
        didSet {
            filterDeals()
        }
    }
    @Published var selectedCategory: String? {
        didSet {
            filterDeals()
        }
    }
    
    private let apiService = APIService.shared
    
    init() {
        loadDeals()
    }
    
    func loadDeals() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedDeals = try await apiService.getCustomerDeals()
                await MainActor.run {
                    self.deals = fetchedDeals
                    self.filterDeals()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading deals: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.deals = Deal.sampleDeals
        self.filterDeals()
        self.isLoading = false
    }
    
    private func filterDeals() {
        var filtered = deals
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { deal in
                deal.title.localizedCaseInsensitiveContains(searchText) ||
                deal.businessName.localizedCaseInsensitiveContains(searchText) ||
                deal.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Only show active deals
        filtered = filtered.filter { $0.isActive }
        
        // Sort by expiry date (ending soon first)
        filtered.sort { $0.expiryDate < $1.expiryDate }
        
        self.filteredDeals = filtered
    }
    
    func refreshDeals() {
        loadDeals()
    }
    
    var categories: [String] {
        let allCategories = deals.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
}

struct Deal: Identifiable, Codable {
    let id: String
    let title: String
    let businessName: String
    let description: String
    let imageUrl: String?
    let creditsReward: Int
    let isActive: Bool
    let expiryDate: Date
    let category: String?
    let location: String?
    
    // Sample data for testing
    static let sampleDeals: [Deal] = [
        Deal(
            id: "deal1",
            title: "Summer Coffee Special",
            businessName: "Morning Brew Cafe",
            description: "Get 20% off all iced drinks during summer. Valid for new and existing customers. Limited time offer!",
            imageUrl: nil,
            creditsReward: 15,
            isActive: true,
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            category: "Food & Drink",
            location: "Downtown"
        ),
        Deal(
            id: "deal2",
            title: "Free Personal Training Session",
            businessName: "FitLife Gym",
            description: "Get your first personal training session absolutely free with any new membership. Start your fitness journey today!",
            imageUrl: nil,
            creditsReward: 25,
            isActive: true,
            expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            category: "Health & Fitness",
            location: "West Side"
        ),
        Deal(
            id: "deal3",
            title: "Buy One Get One Pizza",
            businessName: "Tony's Pizzeria",
            description: "Buy any large pizza and get a medium pizza absolutely free. Perfect for sharing with friends and family!",
            imageUrl: nil,
            creditsReward: 20,
            isActive: true,
            expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            category: "Food & Drink",
            location: "East Side"
        ),
        Deal(
            id: "deal4",
            title: "Spa Day Package",
            businessName: "Zen Wellness Spa",
            description: "Relax and rejuvenate with our premium spa package including massage, facial, and access to all facilities.",
            imageUrl: nil,
            creditsReward: 35,
            isActive: true,
            expiryDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            category: "Health & Wellness",
            location: "Uptown"
        ),
        Deal(
            id: "deal5",
            title: "Fresh Smoothie Bundle",
            businessName: "Green Juice Bar",
            description: "Try our signature smoothie collection with 5 different flavors. Packed with organic fruits and superfoods.",
            imageUrl: nil,
            creditsReward: 12,
            isActive: true,
            expiryDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            category: "Food & Drink",
            location: "City Center"
        )
    ]
} 