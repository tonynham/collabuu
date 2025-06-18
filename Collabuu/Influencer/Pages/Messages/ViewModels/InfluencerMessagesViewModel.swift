import Foundation
import SwiftUI

@MainActor
class InfluencerMessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var selectedConversation: Conversation?
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    @Published var showingNewConversation = false
    
    private let apiService = APIService.shared
    
    init() {
        loadMessages()
    }
    
    func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedConversations = try await apiService.getInfluencerConversations()
                await MainActor.run {
                    self.conversations = fetchedConversations
                    self.updateUnreadCount()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading messages: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        self.conversations = [
            Conversation(
                id: "conv1",
                campaignId: "campaign1",
                campaignTitle: "Summer Coffee Campaign",
                businessName: "Morning Brew Cafe",
                businessImageUrl: nil,
                lastMessage: "Thanks for your interest! We'd love to work with you.",
                lastMessageTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isRead: false,
                messageCount: 3
            ),
            Conversation(
                id: "conv2",
                campaignId: "campaign2",
                campaignTitle: "Fitness Challenge",
                businessName: "FitLife Gym",
                businessImageUrl: nil,
                lastMessage: "Please submit your content by Friday.",
                lastMessageTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRead: true,
                messageCount: 8
            )
        ]
        self.updateUnreadCount()
        self.isLoading = false
    }
    
    private func updateUnreadCount() {
        unreadCount = conversations.filter { !$0.isRead }.count
    }
    
    func refreshMessages() {
        loadMessages()
    }
    
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        
        // Mark conversation as read if it wasn't already
        if !conversation.isRead {
            markConversationAsRead(conversation.id)
        }
    }
    
    func markConversationAsRead(_ conversationId: String) {
        Task {
            do {
                try await apiService.markConversationAsRead(conversationId: conversationId)
                await MainActor.run {
                    if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                        self.conversations[index].isRead = true
                        self.updateUnreadCount()
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error marking conversation as read: \(error)")
                }
            }
        }
    }
    
    func deleteConversation(at index: Int) {
        let conversation = conversations[index]
        
        Task {
            do {
                try await apiService.deleteConversation(conversationId: conversation.id)
                await MainActor.run {
                    self.conversations.remove(at: index)
                    self.updateUnreadCount()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func sendMessage(to conversationId: String, message: String) {
        Task {
            do {
                let newMessage = Message(
                    id: UUID().uuidString,
                    conversationId: conversationId,
                    senderId: "current_user", // This would be the current influencer's ID
                    content: message,
                    timestamp: Date(),
                    isRead: false
                )
                
                try await apiService.sendMessage(newMessage)
                // Refresh conversations to get updated last message
                loadMessages()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
                }
            }
        }
    }
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.campaignTitle.localizedCaseInsensitiveContains(searchText) ||
                conversation.businessName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
} 