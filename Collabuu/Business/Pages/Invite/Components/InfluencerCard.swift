import SwiftUI

struct InfluencerCard: View {
    let influencer: InfluencerSearchResult
    let isSelected: Bool
    let onSelect: () -> Void
    let onTap: () -> Void
    let onInvite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Selection
            HStack {
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                Spacer()
                
                TierBadge(tier: influencer.tier)
            }
            
            // Profile Section
            VStack(alignment: .leading, spacing: 8) {
                // Profile Image Placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(influencer.displayName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(influencer.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        if influencer.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(influencer.username)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(influencer.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Metrics
            VStack(spacing: 8) {
                MetricRow(
                    icon: "person.2.fill",
                    label: "Followers",
                    value: formatFollowerCount(influencer.followerCount),
                    color: .blue
                )
                
                MetricRow(
                    icon: "heart.fill",
                    label: "Engagement",
                    value: "\(influencer.engagementRate, specifier: "%.1f")%",
                    color: .pink
                )
                
                MetricRow(
                    icon: "eye.fill",
                    label: "Avg Views",
                    value: formatNumber(influencer.averageViews),
                    color: .green
                )
            }
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(influencer.categories, id: \.self) { category in
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Stats Row
            HStack(spacing: 12) {
                StatItem(
                    label: "Response",
                    value: influencer.responseTime,
                    color: .orange
                )
                
                StatItem(
                    label: "Success Rate",
                    value: "\(influencer.collaborationRate, specifier: "%.0f")%",
                    color: .green
                )
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("View Profile")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                Button(action: onInvite) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Invite")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private func formatFollowerCount(_ count: Int) -> String {
        if count >= 1000000 {
            return "\(Double(count) / 1000000, specifier: "%.1f")M"
        } else if count >= 1000 {
            return "\(Double(count) / 1000, specifier: "%.1f")K"
        } else {
            return "\(count)"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return "\(Double(number) / 1000000, specifier: "%.1f")M"
        } else if number >= 1000 {
            return "\(Double(number) / 1000, specifier: "%.1f")K"
        } else {
            return "\(number)"
        }
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TierBadge: View {
    let tier: InfluencerTier
    
    var body: some View {
        Text(tier.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tier.color.opacity(0.2))
            .foregroundColor(tier.color)
            .cornerRadius(6)
    }
}

struct InfluencerCard_Previews: PreviewProvider {
    static var previews: some View {
        InfluencerCard(
            influencer: InfluencerSearchResult(
                id: "1",
                username: "@fashionista_sarah",
                displayName: "Sarah Johnson",
                profileImageUrl: nil,
                followerCount: 125000,
                engagementRate: 4.8,
                tier: .macro,
                categories: ["Fashion", "Lifestyle"],
                location: "Los Angeles, CA",
                averageViews: 45000,
                recentPosts: 12,
                collaborationRate: 89.5,
                responseTime: "2 hours",
                isVerified: true
            ),
            isSelected: false,
            onSelect: {},
            onTap: {},
            onInvite: {}
        )
        .frame(width: 180)
        .padding()
    }
} 