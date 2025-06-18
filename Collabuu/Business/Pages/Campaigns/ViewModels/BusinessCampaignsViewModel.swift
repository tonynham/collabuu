import SwiftUI
import Combine

@MainActor
class BusinessCampaignsViewModel: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var originalCampaigns: [Campaign] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = BusinessCampaignFilters()
    @Published var selectedTimeRange: TimeRange = .last30Days
    
    // Performance Metrics
    @Published var totalCampaigns: Int = 0
    @Published var activeCampaigns: Int = 0
    @Published var customerVisits: Int = 0
    @Published var activeInfluencers: Int = 0
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCampaigns()
    }
    
    // MARK: - Data Loading
    func loadCampaigns() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedCampaigns = try await apiService.getBusinessCampaigns()
                await MainActor.run {
                    self.originalCampaigns = fetchedCampaigns
                    self.campaigns = fetchedCampaigns
                    self.updatePerformanceMetrics()
                    self.applyCurrentFilters()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading campaigns: \(error)")
                    
                    // Fallback to sample data for development
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        // Sample campaigns for development/testing
        let calendar = Calendar.current
        let currentDate = Date()
        
        let sampleCampaigns = [
            Campaign(
                id: "1",
                title: "Test1",
                subtitle: "Test1",
                paymentType: "Pay Per Customer",
                influencerCount: 0,
                status: "Active",
                periodStart: calendar.date(byAdding: .day, value: -10, to: currentDate) ?? currentDate,
                periodEnd: calendar.date(byAdding: .day, value: 20, to: currentDate) ?? currentDate,
                visits: 0,
                credits: 100
            ),
            Campaign(
                id: "2",
                title: "Summer Collection",
                subtitle: "Promote our latest summer products",
                paymentType: "Pay Per Customer",
                influencerCount: 5,
                status: "Active",
                periodStart: calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate,
                periodEnd: calendar.date(byAdding: .month, value: 3, to: currentDate) ?? currentDate,
                visits: 45,
                credits: 200
            )
        ]
        
        self.originalCampaigns = sampleCampaigns
        self.campaigns = sampleCampaigns
        self.updatePerformanceMetrics()
    }
    
    private func updatePerformanceMetrics() {
        totalCampaigns = originalCampaigns.count
        activeCampaigns = originalCampaigns.filter { $0.status == "Active" }.count
        customerVisits = originalCampaigns.reduce(0) { $0 + $1.visits }
        activeInfluencers = originalCampaigns.reduce(0) { $0 + $1.influencerCount }
    }
    
    // MARK: - Filter Functions
    func applyFilters(_ newFilters: BusinessCampaignFilters) {
        filters = newFilters
        applyCurrentFilters()
    }
    
    private func applyCurrentFilters() {
        var filtered = originalCampaigns
        
        // Filter by status
        if !filters.selectedStatuses.isEmpty {
            filtered = filtered.filter { campaign in
                filters.selectedStatuses.contains(BusinessCampaignStatus(rawValue: campaign.status) ?? .active)
            }
        }
        
        // Filter by payment type
        if !filters.selectedPaymentTypes.isEmpty {
            filtered = filtered.filter { campaign in
                // Map campaign payment type strings to enum values
                let paymentTypeEnum: BusinessCampaignPaymentType
                switch campaign.paymentType {
                case "Pay Per Customer":
                    paymentTypeEnum = .payPerCustomer
                case "Pay Per Click":
                    paymentTypeEnum = .payPerClick
                case "Pay Per View":
                    paymentTypeEnum = .payPerView
                case "Fixed Rate":
                    paymentTypeEnum = .fixedRate
                default:
                    paymentTypeEnum = .payPerCustomer
                }
                return filters.selectedPaymentTypes.contains(paymentTypeEnum)
            }
        }
        
        // Filter by search text
        if !filters.searchText.isEmpty {
            filtered = filtered.filter { campaign in
                campaign.title.localizedCaseInsensitiveContains(filters.searchText) ||
                campaign.subtitle.localizedCaseInsensitiveContains(filters.searchText)
            }
        }
        
        // Sort campaigns
        switch filters.sortBy {
        case .newest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            filtered.sort { $0.createdAt < $1.createdAt }
        case .visits:
            filtered.sort { $0.visits > $1.visits }
        case .endDate:
            filtered.sort { $0.periodEnd < $1.periodEnd }
        }
        
        self.campaigns = filtered
    }
    
    func clearFilters() {
        filters = BusinessCampaignFilters()
        campaigns = originalCampaigns
    }
    
    // MARK: - Campaign Actions
    func createNewCampaign() {
        // TODO: Navigate to campaign creation
    }
    
    func editCampaign(_ campaign: Campaign) {
        // TODO: Navigate to campaign editing
    }
    
    func deleteCampaign(_ campaign: Campaign) {
        originalCampaigns.removeAll { $0.id == campaign.id }
        campaigns.removeAll { $0.id == campaign.id }
        updatePerformanceMetrics()
    }
    
    func toggleCampaignStatus(_ campaign: Campaign) {
        guard let index = originalCampaigns.firstIndex(where: { $0.id == campaign.id }) else { return }
        
        let newStatus = campaign.status == "Active" ? "Paused" : "Active"
        originalCampaigns[index] = Campaign(
            id: campaign.id,
            title: campaign.title,
            subtitle: campaign.subtitle,
            paymentType: campaign.paymentType,
            influencerCount: campaign.influencerCount,
            status: newStatus,
            period: campaign.period,
            periodStart: campaign.periodStart,
            periodEnd: campaign.periodEnd,
            visits: campaign.visits,
            credits: campaign.credits,
            imageURL: campaign.imageURL,
            createdAt: campaign.createdAt,
            updatedAt: Date()
        )
        
        updatePerformanceMetrics()
        applyCurrentFilters()
    }
    
    // MARK: - Data Fetching (Future Implementation)
    func loadCampaigns() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement API call to fetch campaigns
        // When implementing real API, add try-catch block here
        
        updatePerformanceMetrics()
        isLoading = false
    }
    
    func refreshData() async {
        await loadCampaigns()
    }
}

// MARK: - Filter Models
struct BusinessCampaignFilters {
    var searchText: String = ""
    var selectedStatuses: Set<BusinessCampaignStatus> = []
    var selectedPaymentTypes: Set<BusinessCampaignPaymentType> = []
    var sortBy: BusinessCampaignSortOption = .newest
    
    var hasActiveFilters: Bool {
        return !searchText.isEmpty || 
               !selectedStatuses.isEmpty || 
               !selectedPaymentTypes.isEmpty ||
               sortBy != .newest
    }
}

enum BusinessCampaignStatus: String, CaseIterable {
    case draft = "Draft"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .draft: return .orange
        case .active: return .green
        case .paused: return .yellow
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

enum BusinessCampaignSortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case visits = "visits"
    case endDate = "endDate"
    
    var displayName: String {
        switch self {
        case .newest:
            return "Newest First"
        case .oldest:
            return "Oldest First"
        case .visits:
            return "Most Visits"
        case .endDate:
            return "Ending Soon"
        }
    }
} 