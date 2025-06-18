import Foundation
import SwiftUI
import Supabase

@MainActor
class InfluencerNewConversationViewModel: ObservableObject {
    @Published var businesses: [BusinessProfile] = []
    @Published var filteredBusinesses: [BusinessProfile] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    @Published var selectedCategory: BusinessCategory?
    @Published var showingConversationSuccess = false
    @Published var createdConversationId: String?
    
    private let apiService = APIService.shared
    
    init() {
        loadBusinesses()
    }
    
    func loadBusinesses() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedBusinesses = try await apiService.getBusinessProfiles()
                await MainActor.run {
                    self.businesses = fetchedBusinesses
                    self.filteredBusinesses = fetchedBusinesses
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading businesses: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.businesses = [
            BusinessProfile(
                id: "business1",
                businessName: "The Coffee House",
                category: .restaurant,
                description: "Premium coffee and artisanal pastries in the heart of downtown",
                address: "123 Main St, Downtown",
                phoneNumber: "+1 (555) 123-4567",
                email: "hello@coffeehouse.com",
                website: "https://coffeehouse.com",
                socialMediaLinks: SocialMediaLinks(
                    instagram: "@coffeehouse",
                    facebook: "CoffeeHouseOfficial",
                    twitter: "@coffeehouse",
                    tiktok: "@coffeehouse"
                ),
                businessHours: BusinessHours(
                    monday: "7:00 AM - 8:00 PM",
                    tuesday: "7:00 AM - 8:00 PM",
                    wednesday: "7:00 AM - 8:00 PM",
                    thursday: "7:00 AM - 8:00 PM",
                    friday: "7:00 AM - 9:00 PM",
                    saturday: "8:00 AM - 9:00 PM",
                    sunday: "8:00 AM - 7:00 PM"
                ),
                imageUrls: [],
                logoUrl: nil,
                isVerified: true,
                rating: 4.8,
                totalReviews: 245,
                createdAt: Date(),
                updatedAt: Date()
            ),
            BusinessProfile(
                id: "business2",
                businessName: "FitZone Gym",
                category: .fitness,
                description: "State-of-the-art fitness facility with personal training",
                address: "456 Fitness Ave, Uptown",
                phoneNumber: "+1 (555) 987-6543",
                email: "info@fitzone.com",
                website: "https://fitzone.com",
                socialMediaLinks: SocialMediaLinks(
                    instagram: "@fitzonegym",
                    facebook: "FitZoneGym",
                    twitter: "@fitzone",
                    tiktok: "@fitzoneworkouts"
                ),
                businessHours: BusinessHours(
                    monday: "5:00 AM - 11:00 PM",
                    tuesday: "5:00 AM - 11:00 PM",
                    wednesday: "5:00 AM - 11:00 PM",
                    thursday: "5:00 AM - 11:00 PM",
                    friday: "5:00 AM - 10:00 PM",
                    saturday: "6:00 AM - 10:00 PM",
                    sunday: "7:00 AM - 9:00 PM"
                ),
                imageUrls: [],
                logoUrl: nil,
                isVerified: true,
                rating: 4.6,
                totalReviews: 189,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        self.filteredBusinesses = self.businesses
        self.isLoading = false
    }
    
    func searchBusinesses(query: String) {
        searchQuery = query
        applyFilters()
    }
    
    func filterByCategory(_ category: BusinessCategory?) {
        selectedCategory = category
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = businesses
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { business in
                business.businessName.localizedCaseInsensitiveContains(searchQuery) ||
                business.category.rawValue.localizedCaseInsensitiveContains(searchQuery) ||
                business.description.localizedCaseInsensitiveContains(searchQuery) ||
                business.address.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        filteredBusinesses = filtered
    }
    
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        filteredBusinesses = businesses
    }
    
    func startConversation(with business: BusinessProfile) {
        errorMessage = nil
        
        Task {
            do {
                let conversationRequest = CreateConversationRequest(
                    businessId: business.id,
                    initialMessage: "Hi! I'm interested in collaborating with \(business.businessName). I'd love to discuss potential partnership opportunities."
                )
                
                let conversation = try await apiService.createInfluencerConversation(conversationRequest)
                
                await MainActor.run {
                    self.createdConversationId = conversation.id
                    self.showingConversationSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start conversation: \(error.localizedDescription)"
                    print("Error starting conversation: \(error)")
                }
            }
        }
    }
    
    func refreshBusinesses() {
        loadBusinesses()
    }
    
    func dismissConversationSuccess() {
        showingConversationSuccess = false
        createdConversationId = nil
    }
    
    var availableCategories: [BusinessCategory] {
        Array(Set(businesses.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }
}

struct CreateConversationRequest: Codable {
    let businessId: String
    let initialMessage: String
}

        // Note: BusinessProfile and BusinessCategory are defined in Collabuu/Business/Pages/Profile/Models/BusinessProfile.swift

 