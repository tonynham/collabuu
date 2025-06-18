import SwiftUI

struct ContentPerformanceCard: View {
    let content: ContentPerformance
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            ContentTypeIcon(type: content.type)
                            
                            Text(content.type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(content.caption)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(content.engagementRate, specifier: "%.1f")%")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                        
                        Text("Engagement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Metrics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ContentMetricItem(
                        title: "Impressions",
                        value: content.impressions.formatted(),
                        icon: "eye.fill",
                        color: .blue
                    )
                    
                    ContentMetricItem(
                        title: "Likes",
                        value: content.likes.formatted(),
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    ContentMetricItem(
                        title: "Comments",
                        value: content.comments.formatted(),
                        icon: "bubble.left.fill",
                        color: .green
                    )
                    
                    ContentMetricItem(
                        title: "Shares",
                        value: content.shares.formatted(),
                        icon: "arrowshape.turn.up.right.fill",
                        color: .orange
                    )
                }
                
                // Footer
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(content.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let campaignId = content.campaignId {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "megaphone.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Campaign")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentMetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContentTypeIcon: View {
    let type: ContentType
    
    var body: some View {
        Image(systemName: type.icon)
            .font(.caption)
            .foregroundColor(type.color)
            .frame(width: 16, height: 16)
    }
}

extension ContentType {
    var icon: String {
        switch self {
        case .image:
            return "photo.fill"
        case .video:
            return "video.fill"
        case .story:
            return "circle.fill"
        case .reel:
            return "play.rectangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .image:
            return .blue
        case .video:
            return .red
        case .story:
            return .purple
        case .reel:
            return .orange
        }
    }
}

struct ContentPerformanceCard_Previews: PreviewProvider {
    static var previews: some View {
        ContentPerformanceCard(
            content: ContentPerformance(
                id: "1",
                type: .image,
                caption: "Summer vibes with the new collection! ☀️ #fashion #summer",
                createdAt: Date(),
                impressions: 45200,
                likes: 2180,
                comments: 156,
                shares: 89,
                engagementRate: 5.4,
                campaignId: "camp1"
            ),
            onTap: {}
        )
        .padding()
    }
} 