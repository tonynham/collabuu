import Foundation
import SwiftUI

// MARK: - User Types
enum UserType: String, CaseIterable, Codable {
    case influencer = "influencer"
    case business = "business" 
    case customer = "customer"
    
    var displayName: String {
        switch self {
        case .influencer: return "Influencer"
        case .business: return "Business"
        case .customer: return "Customer"
        }
    }
    
    var color: Color {
        switch self {
        case .influencer: return AppColors.influencerColor
        case .business: return AppColors.businessColor
        case .customer: return AppColors.customerColor
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    let userType: String
    let firstName: String?
    let lastName: String?
    let username: String?
    let profileImageUrl: String?
    let bio: String?
    let createdAt: Date
    let updatedAt: Date?
    
    init(id: UUID, email: String, userType: String, firstName: String? = nil, lastName: String? = nil, username: String? = nil, profileImageUrl: String? = nil, bio: String? = nil, createdAt: Date) {
        self.id = id
        self.email = email
        self.userType = userType
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = nil
    }
} 