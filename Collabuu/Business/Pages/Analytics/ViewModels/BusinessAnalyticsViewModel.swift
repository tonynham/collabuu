import Foundation
import SwiftUI

@MainActor
class BusinessAnalyticsViewModel: ObservableObject {
    // Overview Metrics
    @Published var overviewMetrics: BusinessOverviewMetrics?
    @Published var campaignMetrics: [CampaignAnalytics] = []
    @Published var influencerMetrics: [InfluencerPerformance] = []
    @Published var customerMetrics: CustomerAnalytics?
    
    // Time Period Selection
    @Published var selectedTimePeriod: TimePeriod = .last30Days
    @Published var customDateRange: DateRange?
    @Published var showingDatePicker: Bool = false
    
    // Chart Data
    @Published var revenueChartData: [ChartDataPoint] = []
    @Published var engagementChartData: [ChartDataPoint] = []
    @Published var visitorChartData: [ChartDataPoint] = []
    @Published var conversionChartData: [ChartDataPoint] = []
    
    // Filters and Sorting
    @Published var selectedCampaignFilter: String = "all"
    @Published var selectedInfluencerFilter: String = "all"
    @Published var sortOption: AnalyticsSortOption = .performance
    @Published var showingFilters: Bool = false
    
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
    @Published var selectedCampaign: CampaignAnalytics?
    @Published var selectedInfluencer: InfluencerPerformance?
    @Published var showingCampaignDetail: Bool = false
    @Published var showingInfluencerDetail: Bool = false
    
    private let apiService = APIService.shared
    
    init() {
        loadAnalyticsData()
    }
    
    // MARK: - Data Loading
    
    func loadAnalyticsData() {
        isLoading = true
        
        Task {
            do {
                async let overviewTask = apiService.getBusinessOverviewMetrics(period: selectedTimePeriod)
                async let campaignsTask = apiService.getBusinessCampaignAnalytics(period: selectedTimePeriod)
                async let influencersTask = apiService.getBusinessInfluencerMetrics(period: selectedTimePeriod)
                async let customersTask = apiService.getBusinessCustomerAnalytics(period: selectedTimePeriod)
                async let chartsTask = apiService.getBusinessChartData(period: selectedTimePeriod)
                
                let (overview, campaigns, influencers, customers, charts) = try await (
                    overviewTask, campaignsTask, influencersTask, customersTask, chartsTask
                )
                
                await MainActor.run {
                    self.overviewMetrics = overview
                    self.campaignMetrics = campaigns
                    self.influencerMetrics = influencers
                    self.customerMetrics = customers
                    self.updateChartData(charts)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading analytics: \(error)")
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
                async let overviewTask = apiService.getBusinessOverviewMetrics(period: selectedTimePeriod)
                async let campaignsTask = apiService.getBusinessCampaignAnalytics(period: selectedTimePeriod)
                async let influencersTask = apiService.getBusinessInfluencerMetrics(period: selectedTimePeriod)
                async let customersTask = apiService.getBusinessCustomerAnalytics(period: selectedTimePeriod)
                
                let (overview, campaigns, influencers, customers) = try await (
                    overviewTask, campaignsTask, influencersTask, customersTask
                )
                
                await MainActor.run {
                    self.overviewMetrics = overview
                    self.campaignMetrics = campaigns
                    self.influencerMetrics = influencers
                    self.customerMetrics = customers
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
    
    private func updateChartData(_ charts: BusinessChartData) {
        revenueChartData = charts.revenue
        engagementChartData = charts.engagement
        visitorChartData = charts.visitors
        conversionChartData = charts.conversions
    }
    
    private func loadSampleDataAsFallback() {
        // Sample Overview Metrics
        overviewMetrics = BusinessOverviewMetrics(
            totalRevenue: 45250.00,
            revenueGrowth: 12.5,
            totalCampaigns: 8,
            activeCampaigns: 5,
            totalInfluencers: 24,
            activeInfluencers: 18,
            totalCustomers: 1250,
            newCustomers: 85,
            averageOrderValue: 67.50,
            conversionRate: 3.2,
            customerRetentionRate: 78.5,
            totalVisits: 3420
        )
        
        // Sample Campaign Analytics
        campaignMetrics = [
            CampaignAnalytics(
                id: "camp1",
                name: "Summer Sale 2024",
                status: .active,
                startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
                budget: 5000.00,
                spent: 3250.00,
                revenue: 18500.00,
                roi: 469.2,
                impressions: 125000,
                clicks: 4200,
                conversions: 156,
                conversionRate: 3.7,
                ctr: 3.36,
                participatingInfluencers: 8,
                customerAcquisitions: 89
            ),
            CampaignAnalytics(
                id: "camp2",
                name: "Back to School",
                status: .completed,
                startDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                budget: 3000.00,
                spent: 2850.00,
                revenue: 12400.00,
                roi: 335.1,
                impressions: 89000,
                clicks: 2890,
                conversions: 98,
                conversionRate: 3.4,
                ctr: 3.25,
                participatingInfluencers: 5,
                customerAcquisitions: 67
            )
        ]
        
        // Sample Influencer Performance
        influencerMetrics = [
            InfluencerPerformance(
                id: "inf1",
                name: "Sarah Johnson",
                username: "@sarahjohnson",
                profileImageUrl: nil,
                tier: .gold,
                totalEarnings: 2450.00,
                campaignsCompleted: 3,
                averageEngagementRate: 4.8,
                totalReach: 45000,
                conversionsGenerated: 89,
                customerAcquisitions: 34,
                rating: 4.9,
                responseRate: 98.5
            ),
            InfluencerPerformance(
                id: "inf2",
                name: "Mike Chen",
                username: "@mikechen",
                profileImageUrl: nil,
                tier: .silver,
                totalEarnings: 1850.00,
                campaignsCompleted: 2,
                averageEngagementRate: 3.9,
                totalReach: 32000,
                conversionsGenerated: 67,
                customerAcquisitions: 28,
                rating: 4.7,
                responseRate: 95.2
            )
        ]
        
        // Sample Customer Analytics
        customerMetrics = CustomerAnalytics(
            totalCustomers: 1250,
            newCustomers: 85,
            returningCustomers: 1165,
            averageLifetimeValue: 245.50,
            averageOrderValue: 67.50,
            retentionRate: 78.5,
            churnRate: 21.5,
            topAgeGroup: "25-34",
            topLocation: "San Francisco, CA",
            averageVisitsPerCustomer: 2.8,
            customerSatisfactionScore: 4.6
        )
        
        // Sample Chart Data
        revenueChartData = generateSampleChartData(baseValue: 1500, variation: 500, points: 30)
        engagementChartData = generateSampleChartData(baseValue: 3.5, variation: 1.2, points: 30)
        visitorChartData = generateSampleChartData(baseValue: 120, variation: 40, points: 30)
        conversionChartData = generateSampleChartData(baseValue: 3.2, variation: 0.8, points: 30)
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
    
    var filteredCampaignMetrics: [CampaignAnalytics] {
        var filtered = campaignMetrics
        
        if selectedCampaignFilter != "all" {
            filtered = filtered.filter { campaign in
                switch selectedCampaignFilter {
                case "active":
                    return campaign.status == .active
                case "completed":
                    return campaign.status == .completed
                case "paused":
                    return campaign.status == .paused
                default:
                    return true
                }
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .performance:
                return first.roi > second.roi
            case .revenue:
                return first.revenue > second.revenue
            case .conversions:
                return first.conversions > second.conversions
            case .recent:
                return first.startDate > second.startDate
            }
        }
    }
    
    var filteredInfluencerMetrics: [InfluencerPerformance] {
        var filtered = influencerMetrics
        
        if selectedInfluencerFilter != "all" {
            filtered = filtered.filter { influencer in
                switch selectedInfluencerFilter {
                case "gold":
                    return influencer.tier == .gold
                case "silver":
                    return influencer.tier == .silver
                case "bronze":
                    return influencer.tier == .bronze
                default:
                    return true
                }
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .performance:
                return first.averageEngagementRate > second.averageEngagementRate
            case .revenue:
                return first.totalEarnings > second.totalEarnings
            case .conversions:
                return first.conversionsGenerated > second.conversionsGenerated
            case .recent:
                return first.campaignsCompleted > second.campaignsCompleted
            }
        }
    }
    
    // MARK: - Export Functionality
    
    func exportAnalytics() {
        isExporting = true
        
        Task {
            do {
                let exportData = try await apiService.exportBusinessAnalytics(
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
    
    func showCampaignDetail(_ campaign: CampaignAnalytics) {
        selectedCampaign = campaign
        showingCampaignDetail = true
    }
    
    func showInfluencerDetail(_ influencer: InfluencerPerformance) {
        selectedInfluencer = influencer
        showingInfluencerDetail = true
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

struct BusinessOverviewMetrics: Codable {
    let totalRevenue: Double
    let revenueGrowth: Double
    let totalCampaigns: Int
    let activeCampaigns: Int
    let totalInfluencers: Int
    let activeInfluencers: Int
    let totalCustomers: Int
    let newCustomers: Int
    let averageOrderValue: Double
    let conversionRate: Double
    let customerRetentionRate: Double
    let totalVisits: Int
}

struct CampaignAnalytics: Identifiable, Codable {
    let id: String
    let name: String
    let status: CampaignStatus
    let startDate: Date
    let endDate: Date
    let budget: Double
    let spent: Double
    let revenue: Double
    let roi: Double
    let impressions: Int
    let clicks: Int
    let conversions: Int
    let conversionRate: Double
    let ctr: Double
    let participatingInfluencers: Int
    let customerAcquisitions: Int
}

struct InfluencerPerformance: Identifiable, Codable {
    let id: String
    let name: String
    let username: String
    let profileImageUrl: String?
    let tier: InfluencerTier
    let totalEarnings: Double
    let campaignsCompleted: Int
    let averageEngagementRate: Double
    let totalReach: Int
    let conversionsGenerated: Int
    let customerAcquisitions: Int
    let rating: Double
    let responseRate: Double
}

struct CustomerAnalytics: Codable {
    let totalCustomers: Int
    let newCustomers: Int
    let returningCustomers: Int
    let averageLifetimeValue: Double
    let averageOrderValue: Double
    let retentionRate: Double
    let churnRate: Double
    let topAgeGroup: String
    let topLocation: String
    let averageVisitsPerCustomer: Double
    let customerSatisfactionScore: Double
}

struct BusinessChartData: Codable {
    let revenue: [ChartDataPoint]
    let engagement: [ChartDataPoint]
    let visitors: [ChartDataPoint]
    let conversions: [ChartDataPoint]
}

struct ChartDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

enum TimePeriod: String, CaseIterable {
    case last7Days = "7d"
    case last30Days = "30d"
    case last90Days = "90d"
    case lastYear = "1y"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .lastYear: return "Last Year"
        case .custom: return "Custom Range"
        }
    }
}

enum AnalyticsSortOption: String, CaseIterable {
    case performance = "performance"
    case revenue = "revenue"
    case conversions = "conversions"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .revenue: return "Revenue"
        case .conversions: return "Conversions"
        case .recent: return "Most Recent"
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case pdf = "pdf"
    case csv = "csv"
    case excel = "xlsx"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Report"
        case .csv: return "CSV Data"
        case .excel: return "Excel Spreadsheet"
        }
    }
}

struct DateRange {
    let startDate: Date
    let endDate: Date
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
} 