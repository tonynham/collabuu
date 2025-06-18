import Foundation
import SwiftUI

@MainActor
class CustomerProfileViewModel: ObservableObject {
    @Published var profile: CustomerProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var showingLogoutAlert = false
    
    private let apiService = APIService.shared
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let customerProfile = try await apiService.getCustomerProfile()
                await MainActor.run {
                    self.profile = customerProfile
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading customer profile: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.profile = CustomerProfile(
            id: "customer-1",
            email: "customer@example.com",
            firstName: "Debug",
            lastName: "Customer",
            phoneNumber: "+1 555-0123",
            profileImageUrl: nil,
            loyaltyPoints: 150,
            from: Date()
        )
        self.isLoading = false
    }
    
    func updateProfile(_ updatedProfile: CustomerProfile) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updated = try await apiService.updateCustomerProfile(updatedProfile)
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
    
    func refreshProfile() {
        loadProfile()
    }
    
    func logout() {
        Task {
            do {
                try await apiService.logout()
                // Navigation back to login will be handled automatically by the auth state change
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to logout: \(error.localizedDescription)"
                }
            }
        }
    }
} 