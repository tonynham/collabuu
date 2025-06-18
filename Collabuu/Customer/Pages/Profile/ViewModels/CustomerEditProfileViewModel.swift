import SwiftUI
import Foundation

@MainActor
class CustomerEditProfileViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var dateOfBirth = Date()
    @Published var bio = ""
    @Published var location = ""
    @Published var profileImage: UIImage?
    @Published var interests: [String] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSuccessAlert = false
    @Published var showingImagePicker = false
    @Published var originalProfile: CustomerProfile?
    
    // Privacy Settings
    @Published var profileVisibility = ProfileVisibility.publicProfile
    @Published var allowMessageFromBusinesses = true
    @Published var showEmailToBusinesses = false
    
    private let apiService = APIService.shared
    
    enum ProfileVisibility: String, CaseIterable {
        case publicProfile = "public"
        case privateProfile = "private"
        
        var displayName: String {
            switch self {
            case .publicProfile: return "Public"
            case .privateProfile: return "Private"
            }
        }
    }
    
    let availableInterests = [
        "Food & Dining",
        "Fashion & Style",
        "Fitness & Health",
        "Technology",
        "Travel",
        "Entertainment",
        "Home & Garden",
        "Beauty & Skincare",
        "Sports",
        "Music",
        "Books & Reading",
        "Arts & Crafts",
        "Photography",
        "Gaming",
        "Automotive"
    ]
    
    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await apiService.getCustomerProfile()
                await MainActor.run {
                    self.populateFields(with: profile)
                    self.originalProfile = profile
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
        let sampleProfile = CustomerProfile(
            id: "customer-1",
            email: "customer@example.com",
            firstName: "Debug",
            lastName: "Customer",
            phoneNumber: "+1 555-0123",
            profileImageUrl: nil,
            loyaltyPoints: 150,
            from: Date()
        )
        populateFields(with: sampleProfile)
        originalProfile = sampleProfile
        isLoading = false
    }
    
    private func populateFields(with profile: CustomerProfile) {
        firstName = profile.firstName
        lastName = profile.lastName
        email = profile.email
        phoneNumber = profile.phoneNumber ?? ""
        // Additional fields would be populated here if they exist in the profile model
    }
    
    func saveProfile() {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        guard let originalProfile = originalProfile else {
            errorMessage = "No profile data loaded"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedProfile = CustomerProfile(
                    id: originalProfile.id,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    profileImageUrl: originalProfile.profileImageUrl, // Image upload would be handled separately
                    loyaltyPoints: originalProfile.loyaltyPoints,
                    from: originalProfile.from
                )
                
                let savedProfile = try await apiService.updateCustomerProfile(updatedProfile)
                
                await MainActor.run {
                    self.originalProfile = savedProfile
                    self.isLoading = false
                    self.showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func selectProfileImage() {
        showingImagePicker = true
    }
    
    func uploadProfileImage(_ image: UIImage) {
        isLoading = true
        
        Task {
            do {
                // Convert image to data for upload
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run {
                        self.errorMessage = "Failed to process image"
                        self.isLoading = false
                    }
                    return
                }
                
                let imageUrl = try await apiService.uploadProfileImage(imageData)
                
                await MainActor.run {
                    self.profileImage = image
                    // Update the profile with new image URL
                    if var profile = self.originalProfile {
                        profile.profileImageUrl = imageUrl
                        self.originalProfile = profile
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.removeAll { $0 == interest }
        } else {
            interests.append(interest)
        }
    }
    
    func resetForm() {
        firstName = ""
        lastName = ""
        email = ""
        phoneNumber = ""
        dateOfBirth = Date()
        bio = ""
        location = ""
        profileImage = nil
        interests = []
        profileVisibility = .publicProfile
        allowMessageFromBusinesses = true
        showEmailToBusinesses = false
        originalProfile = nil
        errorMessage = nil
        showingSuccessAlert = false
    }
    
    func cancelEditing() {
        guard let originalProfile = originalProfile else { return }
        populateFields(with: originalProfile)
        errorMessage = nil
    }
    
    var hasUnsavedChanges: Bool {
        guard let originalProfile = originalProfile else { return false }
        
        return firstName != originalProfile.firstName ||
               lastName != originalProfile.lastName ||
               email != originalProfile.email ||
               phoneNumber != (originalProfile.phoneNumber ?? "")
    }
} 