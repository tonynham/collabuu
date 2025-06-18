import Foundation
import SwiftUI

@MainActor
class BusinessEditProfileViewModel: ObservableObject {
    // Basic Business Information
    @Published var businessName: String = ""
    @Published var businessCategory: String = ""
    @Published var businessDescription: String = ""
    
    // Contact Details
    @Published var businessEmail: String = ""
    @Published var phoneNumber: String = ""
    @Published var website: String = ""
    @Published var businessAddress: String = ""
    
    // Business Details
    @Published var foundedYear: String = ""
    @Published var employeeCount: String = ""
    @Published var businessHours: String = ""
    
    // Social Media Links
    @Published var instagramHandle: String = ""
    @Published var facebookPage: String = ""
    @Published var twitterHandle: String = ""
    @Published var linkedinPage: String = ""
    
    // Business Settings
    @Published var isPublicProfile: Bool = true
    @Published var allowDirectMessages: Bool = true
    @Published var showBusinessHours: Bool = true
    @Published var showContactInfo: Bool = true
    
    // Profile Image
    @Published var profileImageUrl: String?
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker: Bool = false
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSaveSuccess: Bool = false
    @Published var hasUnsavedChanges: Bool = false
    
    private let apiService = APIService.shared
    private var originalProfile: BusinessProfile?
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await apiService.getBusinessProfile()
                await MainActor.run {
                    self.populateFields(from: profile)
                    self.originalProfile = profile
                    self.hasUnsavedChanges = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Error loading business profile: \(error)")
                    
                    // Load sample data as fallback
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func populateFields(from profile: BusinessProfile) {
        businessName = profile.businessName
        businessCategory = profile.category.rawValue
        businessDescription = profile.description
        businessEmail = profile.email
        phoneNumber = profile.phoneNumber
        website = profile.website ?? ""
        businessAddress = profile.address
        profileImageUrl = profile.logoUrl
        
        // Social media links
        if let socialLinks = profile.socialMediaLinks {
            instagramHandle = socialLinks.instagram ?? ""
            facebookPage = socialLinks.facebook ?? ""
            twitterHandle = socialLinks.twitter ?? ""
            linkedinPage = socialLinks.linkedin ?? ""
        }
        
        // Business hours
        if let hours = profile.businessHours {
            businessHours = formatBusinessHours(hours)
        }
    }
    
    private func loadSampleDataAsFallback() {
        businessName = "Sample Business"
        businessCategory = "Restaurant"
        businessDescription = "A sample business for development purposes"
        businessEmail = "business@example.com"
        phoneNumber = "+1 (555) 123-4567"
        website = "https://samplebusiness.com"
        businessAddress = "123 Main St, City, State 12345"
        foundedYear = "2020"
        employeeCount = "5-10"
        businessHours = "Mon-Fri: 9:00 AM - 6:00 PM"
        
        isLoading = false
        hasUnsavedChanges = false
    }
    
    func saveProfile() {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedProfile = createUpdatedProfile()
                try await apiService.updateBusinessProfile(updatedProfile)
                
                await MainActor.run {
                    self.originalProfile = updatedProfile
                    self.hasUnsavedChanges = false
                    self.isLoading = false
                    self.showingSaveSuccess = true
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.showingSaveSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createUpdatedProfile() -> BusinessProfile {
        let socialLinks = SocialMediaLinks(
            instagram: instagramHandle.isEmpty ? nil : instagramHandle,
            facebook: facebookPage.isEmpty ? nil : facebookPage,
            twitter: twitterHandle.isEmpty ? nil : twitterHandle,
            tiktok: nil,
            linkedin: linkedinPage.isEmpty ? nil : linkedinPage
        )
        
        let hours = parseBusinessHours(businessHours)
        
        return BusinessProfile(
            id: originalProfile?.id ?? UUID().uuidString,
            businessName: businessName,
            category: BusinessCategory(rawValue: businessCategory) ?? .other,
            description: businessDescription,
            address: businessAddress,
            phoneNumber: phoneNumber,
            email: businessEmail,
            website: website.isEmpty ? nil : website,
            socialMediaLinks: socialLinks,
            businessHours: hours,
            imageUrls: originalProfile?.imageUrls ?? [],
            logoUrl: profileImageUrl,
            isVerified: originalProfile?.isVerified ?? false,
            rating: originalProfile?.rating ?? 0.0,
            totalReviews: originalProfile?.totalReviews ?? 0,
            createdAt: originalProfile?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        if businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Business name is required"
            isValid = false
        }
        
        if businessCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Business category is required"
            isValid = false
        }
        
        if !businessEmail.isEmpty && !isValidEmail(businessEmail) {
            errorMessage = "Please enter a valid email address"
            isValid = false
        }
        
        if !website.isEmpty && !isValidURL(website) {
            errorMessage = "Please enter a valid website URL"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    private func formatBusinessHours(_ hours: BusinessHours) -> String {
        return "Mon-Fri: \(hours.monday ?? "Closed")"
    }
    
    private func parseBusinessHours(_ hoursString: String) -> BusinessHours? {
        // Simple parsing - in production, you'd want more sophisticated parsing
        return BusinessHours(
            monday: hoursString.isEmpty ? nil : hoursString,
            tuesday: hoursString.isEmpty ? nil : hoursString,
            wednesday: hoursString.isEmpty ? nil : hoursString,
            thursday: hoursString.isEmpty ? nil : hoursString,
            friday: hoursString.isEmpty ? nil : hoursString,
            saturday: hoursString.isEmpty ? nil : hoursString,
            sunday: hoursString.isEmpty ? nil : hoursString
        )
    }
    
    func uploadProfileImage() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                let imageUrl = try await apiService.uploadBusinessProfileImage(image)
                await MainActor.run {
                    self.profileImageUrl = imageUrl
                    self.hasUnsavedChanges = true
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
    
    func checkForChanges() {
        guard let originalProfile = originalProfile else {
            hasUnsavedChanges = false
            return
        }
        
        let currentProfile = createUpdatedProfile()
        hasUnsavedChanges = !areProfilesEqual(currentProfile, originalProfile)
    }
    
    private func areProfilesEqual(_ profile1: BusinessProfile, _ profile2: BusinessProfile) -> Bool {
        return profile1.businessName == profile2.businessName &&
               profile1.category == profile2.category &&
               profile1.description == profile2.description &&
               profile1.email == profile2.email &&
               profile1.phoneNumber == profile2.phoneNumber &&
               profile1.website == profile2.website &&
               profile1.address == profile2.address
    }
    
    func discardChanges() {
        guard let originalProfile = originalProfile else { return }
        populateFields(from: originalProfile)
        hasUnsavedChanges = false
        selectedImage = nil
    }
    
    func dismissSaveSuccess() {
        showingSaveSuccess = false
    }
} 