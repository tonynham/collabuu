import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: InfluencerProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var showingLogoutAlert = false
    @Published var showingWithdrawCredits = false
    
    private let apiService = APIService.shared
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedProfile = try await apiService.getInfluencerProfile()
                await MainActor.run {
                    self.profile = fetchedProfile
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading profile: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.profile = InfluencerProfile(
            id: "1",
            userId: "user1",
            username: "debuginfluencer",
            firstName: "Debug",
            lastName: "Influencer",
            bio: "Sample influencer bio for development",
            profileImageUrl: nil,
            followersCount: 15000,
            postsCount: 245,
            engagementRate: 4.2,
            isVerified: false,
            location: "San Francisco, CA",
            website: "https://debuginfluencer.com",
            contactEmail: "debug@example.com",
            instagramHandle: "@debuginfluencer",
            tiktokHandle: "@debuginfluencer",
            youtubeHandle: "debuginfluencer",
            categories: ["Lifestyle", "Tech", "Food"],
            priceRange: "$100-500",
            isActive: true,
            availableCredits: 250,
            activeCampaigns: 3,
            totalVisits: 1250,
            createdAt: Date(),
            updatedAt: Date()
        )
        self.isLoading = false
    }
    
    func updateProfile(_ updatedProfile: InfluencerProfile) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updated = try await apiService.updateInfluencerProfile(updatedProfile)
                await MainActor.run {
                    self.profile = updated
                    self.isEditing = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        Task {
            do {
                try await apiService.logout()
                // Navigation back to login will be handled automatically by the auth state change
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error signing out: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshProfile() {
        loadProfile()
    }
    
    func withdrawCredits(amount: Int) {
        Task {
            do {
                try await apiService.withdrawInfluencerCredits(amount: amount)
                // Refresh profile to get updated credit balance
                loadProfile()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to withdraw credits: \(error.localizedDescription)"
                }
            }
        }
    }
}

 