import Foundation
import SwiftUI

@MainActor
class BusinessMessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedConversation: Conversation?
    @Published var searchText = ""
    
    private let apiService = APIService.shared
    
    init() {
        loadConversations()
    }
    
    func loadConversations() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedConversations = try await apiService.getConversations()
                await MainActor.run {
                    self.conversations = fetchedConversations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("Error loading conversations: \(error)")
                    self.isLoading = false
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    func refreshConversations() {
        loadConversations()
    }
    
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
    }
    
    func deleteConversation(at index: Int) {
        conversations.remove(at: index)
    }
    
    func sendMessage(to conversationId: String, content: String) {
        Task {
            do {
                let _ = try await apiService.sendMessage(conversationId: conversationId, content: content)
                await MainActor.run {
                    // Refresh conversations to get updated message
                    self.loadConversations()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                // Filter by campaign title or influencer name if available
                return true // Implement filtering logic based on your Conversation model
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        // Sample conversations for development
        self.conversations = []
        self.isLoading = false
    }
} 