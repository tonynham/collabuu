import Foundation
import SwiftUI

@MainActor
class BusinessProfileViewModel: ObservableObject {
    @Published var businessName: String = ""
    @Published var businessCategory: String = ""
    @Published var availableCredits: Int = 0
    @Published var estimatedVisits: Int = 0
    
    // Business Details
    @Published var businessDescription: String = ""
    @Published var businessAddress: String = ""
    @Published var businessPhone: String = ""
    @Published var businessEmail: String = ""
    @Published var businessHours: String = ""
    @Published var website: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        loadProfileData()
    }
    
    func loadProfileData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await apiService.getBusinessProfile()
                await MainActor.run {
                    self.updateProfile(with: profile)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading profile: \(error)")
                }
            }
        }
    }
    
    func updateProfile(with profile: BusinessProfile) {
        businessName = profile.businessName
        businessCategory = profile.category
        availableCredits = profile.availableCredits
        estimatedVisits = profile.estimatedVisits
        businessDescription = profile.description
        businessAddress = profile.address
        businessPhone = profile.phone
        businessEmail = profile.email
        businessHours = profile.hours
        website = profile.website ?? ""
    }
    
    func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedProfile = BusinessProfile(
                    id: "", // Will be set by backend
                    userId: "",
                    businessName: businessName,
                    category: businessCategory,
                    description: businessDescription,
                    address: businessAddress,
                    phone: businessPhone,
                    email: businessEmail,
                    hours: businessHours,
                    availableCredits: availableCredits,
                    estimatedVisits: estimatedVisits,
                    website: website,
                    logoUrl: nil,
                    isVerified: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                let savedProfile = try await apiService.updateBusinessProfile(updatedProfile)
                await MainActor.run {
                    self.updateProfile(with: savedProfile)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        Task {
            do {
                try await apiService.signOut()
                // Navigation back to login will be handled automatically by the auth state change
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to logout: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshProfile() {
        loadProfileData()
    }
}

class BusinessProfileService {
    func fetchBusinessProfile() async throws -> BusinessProfile {
        // TODO: Implement Supabase integration to fetch real profile data
        // For now, return sample data matching the screenshot
        return BusinessProfile(
            id: "1",
            userId: "user1",
            businessName: "Debug Business",
            category: "Restaurant",
            description: "Test business profile",
            address: "",
            phone: "",
            email: "",
            hours: "",
            availableCredits: 0,
            estimatedVisits: 0,
            website: "",
            logoUrl: nil,
            isVerified: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
} 