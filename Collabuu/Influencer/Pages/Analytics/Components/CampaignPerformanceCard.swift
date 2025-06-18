import SwiftUI

struct CampaignPerformanceCard: View {
    let campaign: InfluencerCampaignPerformance
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(campaign.campaignName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(campaign.businessName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(status: campaign.status)
                        
                        Text("$\(campaign.totalEarnings, specifier: "%.0f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Posts Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(campaign.postsCreated)/\(campaign.postsRequired)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(campaign.postsCreated), total: Double(campaign.postsRequired))
                        .progressViewStyle(LinearProgressViewStyle(tint: campaign.status == .completed ? .green : .blue))
                }
                
                // Metrics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MetricItem(
                        title: "Engagement",
                        value: "\(campaign.engagementRate, specifier: "%.1f")%",
                        icon: "heart.fill",
                        color: .pink
                    )
                    
                    MetricItem(
                        title: "Conversions",
                        value: "\(campaign.conversions)",
                        icon: "arrow.right.circle.fill",
                        color: .green
                    )
                    
                    MetricItem(
                        title: "Reach",
                        value: "\(campaign.audienceReach.formatted())",
                        icon: "eye.fill",
                        color: .blue
                    )
                }
                
                // Date Range
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(campaign.startDate.formatted(date: .abbreviated, time: .omitted)) - \(campaign.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusBadge: View {
    let status: CampaignStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(6)
    }
}

extension CampaignStatus {
    var color: Color {
        switch self {
        case .active:
            return .green
        case .completed:
            return .blue
        case .pending:
            return .orange
        case .paused:
            return .yellow
        case .cancelled:
            return .red
        }
    }
}

struct CampaignPerformanceCard_Previews: PreviewProvider {
    static var previews: some View {
        CampaignPerformanceCard(
            campaign: InfluencerCampaignPerformance(
                id: "1",
                campaignName: "Summer Fashion Collection",
                businessName: "StyleCo",
                status: .active,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                totalEarnings: 2500.00,
                impressions: 125000,
                engagementRate: 5.2,
                clicks: 3200,
                conversions: 89,
                conversionRate: 2.8,
                postsCreated: 8,
                postsRequired: 10,
                audienceReach: 98000
            ),
            onTap: {}
        )
        .padding()
    }
} 