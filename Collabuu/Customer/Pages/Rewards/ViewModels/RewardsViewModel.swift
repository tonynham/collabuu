import Foundation
import SwiftUI

@MainActor
class RewardsViewModel: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var totalPoints: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingRedemptionSuccess = false
    @Published var redeemedReward: Reward?
    @Published var filteredRewards: [Reward] = []
    @Published var selectedCategory: String? {
        didSet {
            filterRewards()
        }
    }
    @Published var showOnlyAvailable: Bool = true {
        didSet {
            filterRewards()
        }
    }
    
    private let apiService = APIService.shared
    
    init() {
        loadRewards()
    }
    
    func loadRewards() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let rewardsTask = apiService.getCustomerRewards()
                async let pointsTask = apiService.getCustomerLoyaltyPoints()
                
                let (fetchedRewards, points) = try await (rewardsTask, pointsTask)
                
                await MainActor.run {
                    self.rewards = fetchedRewards
                    self.totalPoints = points
                    self.filterRewards()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading rewards: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.rewards = Reward.sampleRewards
        self.totalPoints = 275
        self.filterRewards()
        self.isLoading = false
    }
    
    private func filterRewards() {
        var filtered = rewards
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by availability
        if showOnlyAvailable {
            filtered = filtered.filter { $0.isAvailable && $0.pointsRequired <= totalPoints }
        }
        
        // Sort by points required (ascending)
        filtered.sort { $0.pointsRequired < $1.pointsRequired }
        
        self.filteredRewards = filtered
    }
    
    func redeemReward(_ reward: Reward) {
        guard reward.isAvailable && totalPoints >= reward.pointsRequired else {
            errorMessage = "Insufficient points or reward not available"
            return
        }
        
        Task {
            do {
                try await apiService.redeemCustomerReward(rewardId: reward.id, pointsUsed: reward.pointsRequired)
                
                await MainActor.run {
                    // Deduct points
                    self.totalPoints -= reward.pointsRequired
                    
                    // Show success state
                    self.redeemedReward = reward
                    self.showingRedemptionSuccess = true
                    
                    // Refresh rewards to get updated availability
                    self.loadRewards()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to redeem reward: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func dismissRedemptionSuccess() {
        showingRedemptionSuccess = false
        redeemedReward = nil
    }
    
    func refreshRewards() {
        loadRewards()
    }
    
    var categories: [String] {
        let allCategories = rewards.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    var availableRewardsCount: Int {
        rewards.filter { $0.isAvailable && $0.pointsRequired <= totalPoints }.count
    }
}

struct Reward: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let pointsRequired: Int
    let imageUrl: String?
    let isAvailable: Bool
    let businessName: String?
    let expiryDate: Date?
    let category: String?
    let originalValue: Double?
    
    // Sample data for testing
    static let sampleRewards: [Reward] = [
        Reward(
            id: "reward1",
            title: "Free Coffee",
            description: "Enjoy a free coffee of your choice. Valid for any size and any drink from our menu.",
            pointsRequired: 50,
            imageUrl: nil,
            isAvailable: true,
            businessName: "Morning Brew Cafe",
            expiryDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            category: "Food & Drink",
            originalValue: 5.99
        ),
        Reward(
            id: "reward2",
            title: "Guest Day Pass",
            description: "One-day access to all gym facilities including pool, sauna, and fitness classes.",
            pointsRequired: 100,
            imageUrl: nil,
            isAvailable: true,
            businessName: "FitLife Gym",
            expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            category: "Health & Fitness",
            originalValue: 25.00
        ),
        Reward(
            id: "reward3",
            title: "Medium Pizza",
            description: "Free medium pizza with up to 3 toppings of your choice. Perfect for a quick lunch or dinner.",
            pointsRequired: 75,
            imageUrl: nil,
            isAvailable: true,
            businessName: "Tony's Pizzeria",
            expiryDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
            category: "Food & Drink",
            originalValue: 15.99
        ),
        Reward(
            id: "reward4",
            title: "30-Minute Massage",
            description: "Relax and unwind with a professional 30-minute massage session. Choose from Swedish or deep tissue.",
            pointsRequired: 150,
            imageUrl: nil,
            isAvailable: true,
            businessName: "Zen Wellness Spa",
            expiryDate: Calendar.current.date(byAdding: .month, value: 4, to: Date()),
            category: "Health & Wellness",
            originalValue: 60.00
        ),
        Reward(
            id: "reward5",
            title: "Smoothie Pack (3)",
            description: "Three premium smoothies of your choice. Mix and match from our extensive menu of healthy options.",
            pointsRequired: 80,
            imageUrl: nil,
            isAvailable: true,
            businessName: "Green Juice Bar",
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            category: "Food & Drink",
            originalValue: 24.99
        ),
        Reward(
            id: "reward6",
            title: "VIP Membership (1 Month)",
            description: "One month of VIP access including priority booking, exclusive classes, and member perks.",
            pointsRequired: 300,
            imageUrl: nil,
            isAvailable: false, // User doesn't have enough points
            businessName: "FitLife Gym",
            expiryDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()),
            category: "Health & Fitness",
            originalValue: 99.99
        )
    ]
} 