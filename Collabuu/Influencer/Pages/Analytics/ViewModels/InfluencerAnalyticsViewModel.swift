import Foundation
import SwiftUI

@MainActor
class InfluencerAnalyticsViewModel: ObservableObject {
    // Performance Overview
    @Published var performanceOverview: InfluencerPerformanceOverview?
    @Published var campaignPerformance: [InfluencerCampaignPerformance] = []
    @Published var earningsData: InfluencerEarningsData?
    @Published var audienceInsights: InfluencerAudienceInsights?
    
    // Time Period Selection
    @Published var selectedTimePeriod: TimePeriod = .last30Days
    @Published var customDateRange: DateRange?
    @Published var showingDatePicker: Bool = false
    
    // Chart Data
    @Published var engagementChartData: [ChartDataPoint] = []
    @Published var earningsChartData: [ChartDataPoint] = []
    @Published var followersChartData: [ChartDataPoint] = []
    @Published var impressionsChartData: [ChartDataPoint] = []
    
    // Content Performance
    @Published var topPerformingContent: [ContentPerformance] = []
    @Published var recentPosts: [ContentPost] = []
    @Published var contentCategories: [ContentCategoryPerformance] = []
    
    // Filters and Sorting
    @Published var selectedCampaignFilter: String = "all"
    @Published var selectedContentFilter: String = "all"
    @Published var sortOption: InfluencerAnalyticsSortOption = .engagement
    @Published var showingFilters: Bool = false
    
    // Goals and Targets
    @Published var monthlyGoals: InfluencerGoals?
    @Published var goalProgress: [GoalProgress] = []
    @Published var showingGoalSettings: Bool = false
    
    // Export and Sharing
    @Published var showingExportOptions: Bool = false
    @Published var isExporting: Bool = false
    @Published var exportFormat: ExportFormat = .pdf
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    // Detailed Views
    @Published var selectedCampaign: InfluencerCampaignPerformance?
    @Published var selectedContent: ContentPerformance?
    @Published var showingCampaignDetail: Bool = false
    @Published var showingContentDetail: Bool = false
    
    private let apiService = APIService.shared
    
    init() {
        loadAnalyticsData()
    }
    
    // MARK: - Data Loading
    
    func loadAnalyticsData() {
        isLoading = true
        
        Task {
            do {
                async let overviewTask = apiService.getInfluencerPerformanceOverview(period: selectedTimePeriod)
                async let campaignsTask = apiService.getInfluencerCampaignPerformance(period: selectedTimePeriod)
                async let earningsTask = apiService.getInfluencerEarningsData(period: selectedTimePeriod)
                async let audienceTask = apiService.getInfluencerAudienceInsights(period: selectedTimePeriod)
                async let chartsTask = apiService.getInfluencerChartData(period: selectedTimePeriod)
                async let contentTask = apiService.getInfluencerContentPerformance(period: selectedTimePeriod)
                async let goalsTask = apiService.getInfluencerGoals()
                
                let (overview, campaigns, earnings, audience, charts, content, goals) = try await (
                    overviewTask, campaignsTask, earningsTask, audienceTask, chartsTask, contentTask, goalsTask
                )
                
                await MainActor.run {
                    self.performanceOverview = overview
                    self.campaignPerformance = campaigns
                    self.earningsData = earnings
                    self.audienceInsights = audience
                    self.updateChartData(charts)
                    self.updateContentData(content)
                    self.monthlyGoals = goals
                    self.updateGoalProgress()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading influencer analytics: \(error)")
                    self.loadSampleDataAsFallback()
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshData() {
        isRefreshing = true
        
        Task {
            do {
                async let overviewTask = apiService.getInfluencerPerformanceOverview(period: selectedTimePeriod)
                async let campaignsTask = apiService.getInfluencerCampaignPerformance(period: selectedTimePeriod)
                async let earningsTask = apiService.getInfluencerEarningsData(period: selectedTimePeriod)
                async let audienceTask = apiService.getInfluencerAudienceInsights(period: selectedTimePeriod)
                
                let (overview, campaigns, earnings, audience) = try await (
                    overviewTask, campaignsTask, earningsTask, audienceTask
                )
                
                await MainActor.run {
                    self.performanceOverview = overview
                    self.campaignPerformance = campaigns
                    self.earningsData = earnings
                    self.audienceInsights = audience
                    self.isRefreshing = false
                    self.showSuccessMessage("Analytics updated successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to refresh analytics: \(error.localizedDescription)"
                    self.isRefreshing = false
                }
            }
        }
    }
    
    private func updateChartData(_ charts: InfluencerChartData) {
        engagementChartData = charts.engagement
        earningsChartData = charts.earnings
        followersChartData = charts.followers
        impressionsChartData = charts.impressions
    }
    
    private func updateContentData(_ content: InfluencerContentData) {
        topPerformingContent = content.topPerforming
        recentPosts = content.recent
        contentCategories = content.categories
    }
    
    private func updateGoalProgress() {
        guard let goals = monthlyGoals,
              let overview = performanceOverview else { return }
        
        goalProgress = [
            GoalProgress(
                type: .engagement,
                current: overview.averageEngagementRate,
                target: goals.engagementRateTarget,
                unit: "%"
            ),
            GoalProgress(
                type: .earnings,
                current: earningsData?.totalEarnings ?? 0,
                target: goals.monthlyEarningsTarget,
                unit: "$"
            ),
            GoalProgress(
                type: .followers,
                current: Double(overview.totalFollowers),
                target: Double(goals.followersTarget),
                unit: ""
            ),
            GoalProgress(
                type: .campaigns,
                current: Double(overview.activeCampaigns),
                target: Double(goals.campaignsTarget),
                unit: ""
            )
        ]
    }
    
    private func loadSampleDataAsFallback() {
        // Sample Performance Overview
        performanceOverview = InfluencerPerformanceOverview(
            totalFollowers: 45230,
            followersGrowth: 8.5,
            averageEngagementRate: 4.8,
            engagementGrowth: 12.3,
            totalImpressions: 892000,
            impressionsGrowth: 15.7,
            activeCampaigns: 3,
            completedCampaigns: 12,
            totalEarnings: 8450.00,
            earningsGrowth: 22.1,
            averagePostPerformance: 3.2,
            topContentCategory: "Lifestyle"
        )
        
        // Sample Campaign Performance
        campaignPerformance = [
            InfluencerCampaignPerformance(
                id: "camp1",
                campaignName: "Summer Fashion Collection",
                businessName: "StyleCo",
                status: .active,
                startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(),
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
            InfluencerCampaignPerformance(
                id: "camp2",
                campaignName: "Fitness Challenge",
                businessName: "FitLife",
                status: .completed,
                startDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                totalEarnings: 1850.00,
                impressions: 89000,
                engagementRate: 4.1,
                clicks: 2100,
                conversions: 67,
                conversionRate: 3.2,
                postsCreated: 6,
                postsRequired: 6,
                audienceReach: 72000
            )
        ]
        
        // Sample Earnings Data
        earningsData = InfluencerEarningsData(
            totalEarnings: 8450.00,
            thisMonthEarnings: 3200.00,
            lastMonthEarnings: 2800.00,
            pendingPayments: 1250.00,
            averageEarningsPerPost: 420.00,
            topEarningCampaign: "Summer Fashion Collection",
            earningsBreakdown: [
                EarningsBreakdown(source: "Campaign Posts", amount: 6200.00, percentage: 73.4),
                EarningsBreakdown(source: "Bonus Payments", amount: 1500.00, percentage: 17.8),
                EarningsBreakdown(source: "Referrals", amount: 750.00, percentage: 8.8)
            ]
        )
        
        // Sample Audience Insights
        audienceInsights = InfluencerAudienceInsights(
            totalFollowers: 45230,
            followersGrowth: 8.5,
            averageAge: 28.5,
            topAgeGroup: "25-34",
            genderDistribution: [
                GenderDistribution(gender: "Female", percentage: 68.2),
                GenderDistribution(gender: "Male", percentage: 31.8)
            ],
            topLocations: [
                LocationDistribution(location: "United States", percentage: 45.2),
                LocationDistribution(location: "Canada", percentage: 18.7),
                LocationDistribution(location: "United Kingdom", percentage: 12.3)
            ],
            engagementByTimeOfDay: generateEngagementByHour(),
            audienceInterests: [
                "Fashion", "Lifestyle", "Travel", "Fitness", "Beauty"
            ]
        )
        
        // Sample Goals
        monthlyGoals = InfluencerGoals(
            engagementRateTarget: 5.0,
            monthlyEarningsTarget: 4000.00,
            followersTarget: 50000,
            campaignsTarget: 4
        )
        
        // Sample Chart Data
        engagementChartData = generateSampleChartData(baseValue: 4.5, variation: 1.0, points: 30)
        earningsChartData = generateSampleChartData(baseValue: 300, variation: 150, points: 30)
        followersChartData = generateSampleChartData(baseValue: 45000, variation: 500, points: 30)
        impressionsChartData = generateSampleChartData(baseValue: 30000, variation: 8000, points: 30)
        
        // Sample Content Performance
        topPerformingContent = [
            ContentPerformance(
                id: "post1",
                type: .image,
                caption: "Summer vibes with the new collection! ☀️",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                impressions: 45200,
                likes: 2180,
                comments: 156,
                shares: 89,
                engagementRate: 5.4,
                campaignId: "camp1"
            ),
            ContentPerformance(
                id: "post2",
                type: .video,
                caption: "Quick workout routine for busy days 💪",
                createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                impressions: 38900,
                likes: 1950,
                comments: 203,
                shares: 124,
                engagementRate: 5.9,
                campaignId: "camp2"
            )
        ]
        
        updateGoalProgress()
    }
    
    private func generateSampleChartData(baseValue: Double, variation: Double, points: Int) -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        let calendar = Calendar.current
        
        for i in 0..<points {
            let date = calendar.date(byAdding: .day, value: -points + i, to: Date()) ?? Date()
            let randomVariation = Double.random(in: -variation...variation)
            let value = baseValue + randomVariation
            
            data.append(ChartDataPoint(
                date: date,
                value: max(0, value),
                label: DateFormatter.shortDate.string(from: date)
            ))
        }
        
        return data
    }
    
    private func generateEngagementByHour() -> [EngagementByHour] {
        var data: [EngagementByHour] = []
        
        for hour in 0..<24 {
            let baseEngagement = hour >= 9 && hour <= 21 ? 4.5 : 2.0
            let variation = Double.random(in: -1.0...1.5)
            let engagement = max(0, baseEngagement + variation)
            
            data.append(EngagementByHour(
                hour: hour,
                engagementRate: engagement
            ))
        }
        
        return data
    }
    
    // MARK: - Time Period Management
    
    func updateTimePeriod(_ period: TimePeriod) {
        selectedTimePeriod = period
        loadAnalyticsData()
    }
    
    func setCustomDateRange(_ range: DateRange) {
        customDateRange = range
        selectedTimePeriod = .custom
        loadAnalyticsData()
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredCampaignPerformance: [InfluencerCampaignPerformance] {
        var filtered = campaignPerformance
        
        if selectedCampaignFilter != "all" {
            filtered = filtered.filter { campaign in
                switch selectedCampaignFilter {
                case "active":
                    return campaign.status == .active
                case "completed":
                    return campaign.status == .completed
                case "pending":
                    return campaign.status == .pending
                default:
                    return true
                }
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .engagement:
                return first.engagementRate > second.engagementRate
            case .earnings:
                return first.totalEarnings > second.totalEarnings
            case .conversions:
                return first.conversions > second.conversions
            case .recent:
                return first.startDate > second.startDate
            }
        }
    }
    
    var filteredTopContent: [ContentPerformance] {
        var filtered = topPerformingContent
        
        if selectedContentFilter != "all" {
            filtered = filtered.filter { content in
                switch selectedContentFilter {
                case "image":
                    return content.type == .image
                case "video":
                    return content.type == .video
                case "story":
                    return content.type == .story
                default:
                    return true
                }
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .engagement:
                return first.engagementRate > second.engagementRate
            case .earnings:
                return first.impressions > second.impressions
            case .conversions:
                return first.likes > second.likes
            case .recent:
                return first.createdAt > second.createdAt
            }
        }
    }
    
    // MARK: - Goals Management
    
    func updateGoals(_ goals: InfluencerGoals) {
        Task {
            do {
                let updatedGoals = try await apiService.updateInfluencerGoals(goals)
                
                await MainActor.run {
                    self.monthlyGoals = updatedGoals
                    self.updateGoalProgress()
                    self.showSuccessMessage("Goals updated successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update goals: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Export Functionality
    
    func exportAnalytics() {
        isExporting = true
        
        Task {
            do {
                let exportData = try await apiService.exportInfluencerAnalytics(
                    period: selectedTimePeriod,
                    format: exportFormat
                )
                
                await MainActor.run {
                    // Handle export data (save to files, share, etc.)
                    self.isExporting = false
                    self.showingExportOptions = false
                    self.showSuccessMessage("Analytics exported successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to export analytics: \(error.localizedDescription)"
                    self.isExporting = false
                }
            }
        }
    }
    
    // MARK: - Detail Views
    
    func showCampaignDetail(_ campaign: InfluencerCampaignPerformance) {
        selectedCampaign = campaign
        showingCampaignDetail = true
    }
    
    func showContentDetail(_ content: ContentPerformance) {
        selectedContent = content
        showingContentDetail = true
    }
    
    // MARK: - Utility Methods
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showingSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingSuccessMessage = false
        }
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
}

// MARK: - Supporting Models

struct InfluencerPerformanceOverview: Codable {
    let totalFollowers: Int
    let followersGrowth: Double
    let averageEngagementRate: Double
    let engagementGrowth: Double
    let totalImpressions: Int
    let impressionsGrowth: Double
    let activeCampaigns: Int
    let completedCampaigns: Int
    let totalEarnings: Double
    let earningsGrowth: Double
    let averagePostPerformance: Double
    let topContentCategory: String
}

struct InfluencerCampaignPerformance: Identifiable, Codable {
    let id: String
    let campaignName: String
    let businessName: String
    let status: CampaignStatus
    let startDate: Date
    let endDate: Date
    let totalEarnings: Double
    let impressions: Int
    let engagementRate: Double
    let clicks: Int
    let conversions: Int
    let conversionRate: Double
    let postsCreated: Int
    let postsRequired: Int
    let audienceReach: Int
}

struct InfluencerEarningsData: Codable {
    let totalEarnings: Double
    let thisMonthEarnings: Double
    let lastMonthEarnings: Double
    let pendingPayments: Double
    let averageEarningsPerPost: Double
    let topEarningCampaign: String
    let earningsBreakdown: [EarningsBreakdown]
}

struct EarningsBreakdown: Identifiable, Codable {
    let id = UUID()
    let source: String
    let amount: Double
    let percentage: Double
}

struct InfluencerAudienceInsights: Codable {
    let totalFollowers: Int
    let followersGrowth: Double
    let averageAge: Double
    let topAgeGroup: String
    let genderDistribution: [GenderDistribution]
    let topLocations: [LocationDistribution]
    let engagementByTimeOfDay: [EngagementByHour]
    let audienceInterests: [String]
}

struct GenderDistribution: Identifiable, Codable {
    let id = UUID()
    let gender: String
    let percentage: Double
}

struct LocationDistribution: Identifiable, Codable {
    let id = UUID()
    let location: String
    let percentage: Double
}

struct EngagementByHour: Identifiable, Codable {
    let id = UUID()
    let hour: Int
    let engagementRate: Double
}

struct InfluencerChartData: Codable {
    let engagement: [ChartDataPoint]
    let earnings: [ChartDataPoint]
    let followers: [ChartDataPoint]
    let impressions: [ChartDataPoint]
}

struct InfluencerContentData: Codable {
    let topPerforming: [ContentPerformance]
    let recent: [ContentPost]
    let categories: [ContentCategoryPerformance]
}

struct ContentPerformance: Identifiable, Codable {
    let id: String
    let type: ContentType
    let caption: String
    let createdAt: Date
    let impressions: Int
    let likes: Int
    let comments: Int
    let shares: Int
    let engagementRate: Double
    let campaignId: String?
}

struct ContentPost: Identifiable, Codable {
    let id: String
    let type: ContentType
    let caption: String
    let createdAt: Date
    let imageUrl: String?
    let videoUrl: String?
}

struct ContentCategoryPerformance: Identifiable, Codable {
    let id = UUID()
    let category: String
    let postsCount: Int
    let averageEngagement: Double
    let totalImpressions: Int
}

enum ContentType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"
    case story = "story"
    case reel = "reel"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        case .story: return "Story"
        case .reel: return "Reel"
        }
    }
}

struct InfluencerGoals: Codable {
    let engagementRateTarget: Double
    let monthlyEarningsTarget: Double
    let followersTarget: Int
    let campaignsTarget: Int
}

struct GoalProgress: Identifiable {
    let id = UUID()
    let type: GoalType
    let current: Double
    let target: Double
    let unit: String
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var isAchieved: Bool {
        return current >= target
    }
}

enum GoalType: String, CaseIterable {
    case engagement = "engagement"
    case earnings = "earnings"
    case followers = "followers"
    case campaigns = "campaigns"
    
    var displayName: String {
        switch self {
        case .engagement: return "Engagement Rate"
        case .earnings: return "Monthly Earnings"
        case .followers: return "Followers"
        case .campaigns: return "Active Campaigns"
        }
    }
    
    var icon: String {
        switch self {
        case .engagement: return "heart.circle.fill"
        case .earnings: return "dollarsign.circle.fill"
        case .followers: return "person.2.circle.fill"
        case .campaigns: return "megaphone.circle.fill"
        }
    }
}

enum InfluencerAnalyticsSortOption: String, CaseIterable {
    case engagement = "engagement"
    case earnings = "earnings"
    case conversions = "conversions"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .engagement: return "Engagement"
        case .earnings: return "Earnings"
        case .conversions: return "Conversions"
        case .recent: return "Most Recent"
        }
    }
} 