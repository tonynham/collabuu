import SwiftUI

struct CampaignAnalyticsCard: View {
    let campaign: CampaignAnalytics
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header with campaign name and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(campaign.name)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Text("\(campaign.startDate, style: .date) - \(campaign.endDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    CampaignBadge(
                        text: campaign.status.displayName,
                        backgroundColor: campaign.status.color.opacity(0.1),
                        textColor: campaign.status.color
                    )
                }
                
                // Key Metrics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    MetricItem(
                        title: "ROI",
                        value: "\(String(format: "%.1f", campaign.roi))%",
                        icon: "chart.line.uptrend.xyaxis",
                        color: campaign.roi > 0 ? AppColors.success : AppColors.error
                    )
                    
                    MetricItem(
                        title: "Revenue",
                        value: "$\(String(format: "%.0f", campaign.revenue))",
                        icon: "dollarsign.circle",
                        color: AppColors.secondary
                    )
                    
                    MetricItem(
                        title: "Conversions",
                        value: "\(campaign.conversions)",
                        icon: "target",
                        color: AppColors.warning
                    )
                }
                
                // Progress and Performance
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Budget Progress")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.0f", campaign.spent)) / $\(String(format: "%.0f", campaign.budget))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    ProgressView(value: campaign.spent / campaign.budget)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.secondary))
                        .scaleEffect(x: 1, y: 0.8)
                    
                    HStack {
                        Text("CTR: \(String(format: "%.2f", campaign.ctr))%")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("Conv. Rate: \(String(format: "%.1f", campaign.conversionRate))%")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(campaign.participatingInfluencers) Influencers")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppSpacing.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfluencerAnalyticsCard: View {
    let influencer: InfluencerPerformance
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header with influencer info
                HStack(spacing: AppSpacing.md) {
                    // Profile Image Placeholder
                    Circle()
                        .fill(AppColors.backgroundSecondary)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(AppColors.textSecondary)
                                .font(.title3)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(influencer.name)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(influencer.username)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(AppColors.warning)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", influencer.rating))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    InfluencerTierBadge(tier: influencer.tier)
                }
                
                // Performance Metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    MetricItem(
                        title: "Earnings",
                        value: "$\(String(format: "%.0f", influencer.totalEarnings))",
                        icon: "dollarsign.circle",
                        color: AppColors.success
                    )
                    
                    MetricItem(
                        title: "Engagement",
                        value: "\(String(format: "%.1f", influencer.averageEngagementRate))%",
                        icon: "heart.circle",
                        color: AppColors.error
                    )
                    
                    MetricItem(
                        title: "Conversions",
                        value: "\(influencer.conversionsGenerated)",
                        icon: "target",
                        color: AppColors.secondary
                    )
                }
                
                // Additional Stats
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reach")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(influencer.totalReach)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Campaigns")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(influencer.campaignsCompleted)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Response Rate")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(String(format: "%.1f", influencer.responseRate))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppSpacing.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomerAnalyticsCard: View {
    let metrics: CustomerAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Customer Analytics")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            // Key Customer Metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                CustomerMetricCard(
                    title: "Total Customers",
                    value: "\(metrics.totalCustomers)",
                    subtitle: "\(metrics.newCustomers) new this period",
                    icon: "person.3.fill",
                    color: AppColors.secondary
                )
                
                CustomerMetricCard(
                    title: "Avg. Lifetime Value",
                    value: "$\(String(format: "%.0f", metrics.averageLifetimeValue))",
                    subtitle: "Avg. order: $\(String(format: "%.0f", metrics.averageOrderValue))",
                    icon: "dollarsign.circle.fill",
                    color: AppColors.success
                )
                
                CustomerMetricCard(
                    title: "Retention Rate",
                    value: "\(String(format: "%.1f", metrics.retentionRate))%",
                    subtitle: "Churn: \(String(format: "%.1f", metrics.churnRate))%",
                    icon: "arrow.clockwise.circle.fill",
                    color: AppColors.warning
                )
                
                CustomerMetricCard(
                    title: "Satisfaction Score",
                    value: "\(String(format: "%.1f", metrics.customerSatisfactionScore))",
                    subtitle: "\(String(format: "%.1f", metrics.averageVisitsPerCustomer)) avg visits",
                    icon: "star.circle.fill",
                    color: AppColors.error
                )
            }
            
            // Demographics
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Demographics")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Age Group")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(metrics.topAgeGroup)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Top Location")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(metrics.topLocation)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Supporting Components

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CustomerMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMD)
    }
}

struct InfluencerTierBadge: View {
    let tier: InfluencerTier
    
    var body: some View {
        Text(tier.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(tier.color)
            .cornerRadius(AppSpacing.radiusSM)
    }
}

extension CampaignStatus {
    var color: Color {
        switch self {
        case .active:
            return AppColors.success
        case .paused:
            return AppColors.warning
        case .completed:
            return AppColors.textSecondary
        case .draft:
            return AppColors.textTertiary
        }
    }
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .draft:
            return "Draft"
        }
    }
}

extension InfluencerTier {
    var color: Color {
        switch self {
        case .gold:
            return Color.yellow
        case .silver:
            return Color.gray
        case .bronze:
            return Color.brown
        }
    }
    
    var displayName: String {
        switch self {
        case .gold:
            return "Gold"
        case .silver:
            return "Silver"
        case .bronze:
            return "Bronze"
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        CampaignAnalyticsCard(
            campaign: CampaignAnalytics(
                id: "1",
                name: "Summer Sale 2024",
                status: .active,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                budget: 5000,
                spent: 3250,
                revenue: 18500,
                roi: 469.2,
                impressions: 125000,
                clicks: 4200,
                conversions: 156,
                conversionRate: 3.7,
                ctr: 3.36,
                participatingInfluencers: 8,
                customerAcquisitions: 89
            )
        ) { }
        
        InfluencerAnalyticsCard(
            influencer: InfluencerPerformance(
                id: "1",
                name: "Sarah Johnson",
                username: "@sarahjohnson",
                profileImageUrl: nil,
                tier: .gold,
                totalEarnings: 2450,
                campaignsCompleted: 3,
                averageEngagementRate: 4.8,
                totalReach: 45000,
                conversionsGenerated: 89,
                customerAcquisitions: 34,
                rating: 4.9,
                responseRate: 98.5
            )
        ) { }
    }
    .padding()
} 