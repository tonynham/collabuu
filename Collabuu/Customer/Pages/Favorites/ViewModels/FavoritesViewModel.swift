import Foundation
import SwiftUI

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        loadFavorites()
    }
    
    func loadFavorites() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedFavorites = try await apiService.getCustomerFavorites()
                await MainActor.run {
                    self.favorites = fetchedFavorites
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading favorites: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    func addFavorite(_ campaignId: String, referralCode: String? = nil) {
        Task {
            do {
                try await apiService.addToFavorites(campaignId: campaignId)
                await MainActor.run {
                    // Reload favorites to get the updated list
                    self.loadFavorites()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func removeFavorite(_ favorite: FavoriteItem) {
        Task {
            do {
                // Note: You'll need to add this method to APIService
                // try await apiService.removeFavorite(favoriteId: favorite.id)
                await MainActor.run {
                    self.favorites.removeAll { $0.id == favorite.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func refreshFavorites() {
        loadFavorites()
    }
    
    private func loadSampleDataAsFallback() {
        // Fallback to sample data for development
        self.favorites = FavoriteItem.sampleFavorites
        self.isLoading = false
    }
}

class FavoritesService {
    func fetchFavorites() async throws -> [FavoriteItem] {
        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return sample data to show the standardized cards in action
        return FavoriteItem.sampleFavorites
    }
    
    func addFavorite(campaignId: String, referralCode: String?) async throws -> FavoriteItem {
        // TODO: Implement Supabase integration to add favorite
        throw NSError(domain: "NotImplemented", code: 0, userInfo: [NSLocalizedDescriptionKey: "Add favorite not implemented"])
    }
    
    func removeFavorite(favoriteId: String) async throws {
        // TODO: Implement Supabase integration to remove favorite
        throw NSError(domain: "NotImplemented", code: 0, userInfo: [NSLocalizedDescriptionKey: "Remove favorite not implemented"])
    }
} 