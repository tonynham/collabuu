import Foundation
import SwiftUI

@MainActor
class InfluencerEditProfileViewModel: ObservableObject {
    // Personal Information
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    
    // Profile Details
    @Published var bio: String = ""
    @Published var location: String = ""
    @Published var website: String = ""
    
    // Social Media
    @Published var instagramHandle: String = ""
    @Published var tiktokHandle: String = ""
    @Published var youtubeHandle: String = ""
    @Published var twitterHandle: String = ""
    
    // Profile Image
    @Published var profileImageUrl: String?
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker: Bool = false
    
    // Categories and Pricing
    @Published var selectedCategories: Set<String> = []
    @Published var priceRange: String = ""
    @Published var availableCategories: [String] = []
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSaveSuccess: Bool = false
    @Published var hasUnsavedChanges: Bool = false
    
    private let apiService = APIService.shared
    private var originalProfile: InfluencerProfile?
    
    init() {
        loadProfile()
        loadAvailableCategories()
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await apiService.getInfluencerProfile()
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
                    print("Error loading influencer profile: \(error)")
                    
                    // Load sample data as fallback
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func populateFields(from profile: InfluencerProfile) {
        firstName = profile.firstName
        lastName = profile.lastName
        username = profile.username
        email = profile.contactEmail
        bio = profile.bio
        location = profile.location ?? ""
        website = profile.website ?? ""
        profileImageUrl = profile.profileImageUrl
        
        // Social media handles
        instagramHandle = profile.instagramHandle ?? ""
        tiktokHandle = profile.tiktokHandle ?? ""
        youtubeHandle = profile.youtubeHandle ?? ""
        
        // Categories and pricing
        selectedCategories = Set(profile.categories)
        priceRange = profile.priceRange ?? ""
    }
    
    private func loadSampleDataAsFallback() {
        firstName = "Sample"
        lastName = "Influencer"
        username = "sampleinfluencer"
        email = "sample@example.com"
        bio = "Sample influencer bio for development purposes"
        location = "San Francisco, CA"
        website = "https://sampleinfluencer.com"
        
        instagramHandle = "@sampleinfluencer"
        tiktokHandle = "@sampleinfluencer"
        youtubeHandle = "sampleinfluencer"
        
        selectedCategories = ["Lifestyle", "Tech"]
        priceRange = "$100-500"
        
        isLoading = false
        hasUnsavedChanges = false
    }
    
    private func loadAvailableCategories() {
        availableCategories = [
            "Lifestyle", "Fashion", "Beauty", "Tech", "Food", "Travel",
            "Fitness", "Gaming", "Music", "Art", "Business", "Education",
            "Health", "Sports", "Entertainment", "Photography"
        ]
    }
    
    func saveProfile() {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedProfile = createUpdatedProfile()
                let savedProfile = try await apiService.updateInfluencerProfile(updatedProfile)
                
                await MainActor.run {
                    self.originalProfile = savedProfile
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
    
    private func createUpdatedProfile() -> InfluencerProfile {
        return InfluencerProfile(
            id: originalProfile?.id ?? UUID().uuidString,
            userId: originalProfile?.userId ?? UUID().uuidString,
            username: username,
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            profileImageUrl: profileImageUrl,
            followersCount: originalProfile?.followersCount ?? 0,
            postsCount: originalProfile?.postsCount ?? 0,
            engagementRate: originalProfile?.engagementRate ?? 0.0,
            isVerified: originalProfile?.isVerified ?? false,
            location: location.isEmpty ? nil : location,
            website: website.isEmpty ? nil : website,
            contactEmail: email,
            instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle,
            tiktokHandle: tiktokHandle.isEmpty ? nil : tiktokHandle,
            youtubeHandle: youtubeHandle.isEmpty ? nil : youtubeHandle,
            categories: Array(selectedCategories),
            priceRange: priceRange.isEmpty ? nil : priceRange,
            isActive: originalProfile?.isActive ?? true,
            availableCredits: originalProfile?.availableCredits ?? 0,
            activeCampaigns: originalProfile?.activeCampaigns ?? 0,
            totalVisits: originalProfile?.totalVisits ?? 0,
            createdAt: originalProfile?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "First name is required"
            isValid = false
        }
        
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Last name is required"
            isValid = false
        }
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Username is required"
            isValid = false
        }
        
        if !email.isEmpty && !isValidEmail(email) {
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
    
    func uploadProfileImage() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                let imageUrl = try await apiService.uploadInfluencerProfileImage(image)
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
    
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        checkForChanges()
    }
    
    func checkForChanges() {
        guard let originalProfile = originalProfile else {
            hasUnsavedChanges = false
            return
        }
        
        let currentProfile = createUpdatedProfile()
        hasUnsavedChanges = !areProfilesEqual(currentProfile, originalProfile)
    }
    
    private func areProfilesEqual(_ profile1: InfluencerProfile, _ profile2: InfluencerProfile) -> Bool {
        return profile1.firstName == profile2.firstName &&
               profile1.lastName == profile2.lastName &&
               profile1.username == profile2.username &&
               profile1.contactEmail == profile2.contactEmail &&
               profile1.bio == profile2.bio &&
               profile1.location == profile2.location &&
               profile1.website == profile2.website &&
               profile1.instagramHandle == profile2.instagramHandle &&
               profile1.tiktokHandle == profile2.tiktokHandle &&
               profile1.youtubeHandle == profile2.youtubeHandle &&
               Set(profile1.categories) == Set(profile2.categories) &&
               profile1.priceRange == profile2.priceRange
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
    
    var displayName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var formattedUsername: String {
        return username.hasPrefix("@") ? username : "@\(username)"
    }
} 