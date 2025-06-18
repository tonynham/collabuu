import SwiftUI
import Charts

struct InfluencerAnalyticsView: View {
    @StateObject private var viewModel = InfluencerAnalyticsViewModel()
    @State private var selectedTab: InfluencerAnalyticsTab = .overview
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Time Period Selector
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            switch selectedTab {
                            case .overview:
                                overviewContent
                            case .campaigns:
                                campaignsContent
                            case .content:
                                contentContent
                            case .audience:
                                audienceContent
                            case .goals:
                                goalsContent
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showingExportOptions = true }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { viewModel.showingFilters = true }) {
                            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: { viewModel.refreshData() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingExportOptions) {
            exportOptionsSheet
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            filtersSheet
        }
        .sheet(isPresented: $viewModel.showingGoalSettings) {
            goalSettingsSheet
        }
        .sheet(isPresented: $viewModel.showingCampaignDetail) {
            if let campaign = viewModel.selectedCampaign {
                CampaignDetailView(campaign: campaign)
            }
        }
        .sheet(isPresented: $viewModel.showingContentDetail) {
            if let content = viewModel.selectedContent {
                ContentDetailView(content: content)
            }
        }
        .overlay(
            Group {
                if viewModel.showingSuccessMessage {
                    SuccessToast(
                        message: viewModel.successMessage,
                        isShowing: $viewModel.showingSuccessMessage
                    )
                }
            }
        )
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Performance Analytics")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(period.displayName) {
                            viewModel.updateTimePeriod(period)
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedTimePeriod.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            
            // Quick Stats
            if let overview = viewModel.performanceOverview {
                HStack(spacing: 20) {
                    QuickStatView(
                        title: "Followers",
                        value: "\(overview.totalFollowers.formatted())",
                        change: overview.followersGrowth,
                        icon: "person.2.fill"
                    )
                    
                    QuickStatView(
                        title: "Engagement",
                        value: "\(overview.averageEngagementRate, specifier: "%.1f")%",
                        change: overview.engagementGrowth,
                        icon: "heart.fill"
                    )
                    
                    QuickStatView(
                        title: "Earnings",
                        value: "$\(overview.totalEarnings, specifier: "%.0f")",
                        change: overview.earningsGrowth,
                        icon: "dollarsign.circle.fill"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(InfluencerAnalyticsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Text(tab.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .medium)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(minWidth: 80)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content Views
    
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Performance Charts
            performanceChartsSection
            
            // Recent Campaign Performance
            recentCampaignsSection
            
            // Top Content
            topContentSection
        }
    }
    
    private var campaignsContent: some View {
        VStack(spacing: 20) {
            // Campaign Performance Summary
            campaignSummarySection
            
            // Campaign List
            campaignListSection
        }
    }
    
    private var contentContent: some View {
        VStack(spacing: 20) {
            // Content Performance Overview
            contentOverviewSection
            
            // Top Performing Content
            topPerformingContentSection
            
            // Content Categories
            contentCategoriesSection
        }
    }
    
    private var audienceContent: some View {
        VStack(spacing: 20) {
            // Audience Overview
            audienceOverviewSection
            
            // Demographics
            demographicsSection
            
            // Engagement Patterns
            engagementPatternsSection
        }
    }
    
    private var goalsContent: some View {
        VStack(spacing: 20) {
            // Goals Progress
            goalsProgressSection
            
            // Goal Settings Button
            Button(action: { viewModel.showingGoalSettings = true }) {
                HStack {
                    Image(systemName: "target")
                    Text("Update Goals")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Performance Charts Section
    
    private var performanceChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ChartCard(
                    title: "Engagement Rate",
                    data: viewModel.engagementChartData,
                    color: .pink,
                    format: "%.1f%%"
                )
                
                ChartCard(
                    title: "Daily Earnings",
                    data: viewModel.earningsChartData,
                    color: .green,
                    format: "$%.0f"
                )
                
                ChartCard(
                    title: "Followers Growth",
                    data: viewModel.followersChartData,
                    color: .blue,
                    format: "%.0f"
                )
                
                ChartCard(
                    title: "Impressions",
                    data: viewModel.impressionsChartData,
                    color: .orange,
                    format: "%.0f"
                )
            }
        }
    }
    
    // MARK: - Recent Campaigns Section
    
    private var recentCampaignsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Campaigns")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .campaigns
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredCampaignPerformance.prefix(3))) { campaign in
                    CampaignPerformanceCard(
                        campaign: campaign,
                        onTap: { viewModel.showCampaignDetail(campaign) }
                    )
                }
            }
        }
    }
    
    // MARK: - Top Content Section
    
    private var topContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Performing Content")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .content
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredTopContent.prefix(3))) { content in
                    ContentPerformanceCard(
                        content: content,
                        onTap: { viewModel.showContentDetail(content) }
                    )
                }
            }
        }
    }
    
    // MARK: - Campaign Summary Section
    
    private var campaignSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Campaign Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let overview = viewModel.performanceOverview {
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Active",
                        value: "\(overview.activeCampaigns)",
                        icon: "play.circle.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Completed",
                        value: "\(overview.completedCampaigns)",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                    
                    if let earnings = viewModel.earningsData {
                        MetricCard(
                            title: "Total Earnings",
                            value: "$\(earnings.totalEarnings, specifier: "%.0f")",
                            icon: "dollarsign.circle.fill",
                            color: .orange
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Campaign List Section
    
    private var campaignListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Campaigns")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu {
                    Button("All Campaigns") { viewModel.selectedCampaignFilter = "all" }
                    Button("Active") { viewModel.selectedCampaignFilter = "active" }
                    Button("Completed") { viewModel.selectedCampaignFilter = "completed" }
                    Button("Pending") { viewModel.selectedCampaignFilter = "pending" }
                } label: {
                    HStack {
                        Text(viewModel.selectedCampaignFilter.capitalized)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredCampaignPerformance) { campaign in
                    CampaignPerformanceCard(
                        campaign: campaign,
                        onTap: { viewModel.showCampaignDetail(campaign) }
                    )
                }
            }
        }
    }
    
    // MARK: - Content Overview Section
    
    private var contentOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let overview = viewModel.performanceOverview {
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Avg Performance",
                        value: "\(overview.averagePostPerformance, specifier: "%.1f")",
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                    
                    MetricCard(
                        title: "Top Category",
                        value: overview.topContentCategory,
                        icon: "tag.fill",
                        color: .pink
                    )
                    
                    MetricCard(
                        title: "Total Posts",
                        value: "\(viewModel.topPerformingContent.count)",
                        icon: "photo.fill",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Top Performing Content Section
    
    private var topPerformingContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Performing Posts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu {
                    Button("All Content") { viewModel.selectedContentFilter = "all" }
                    Button("Images") { viewModel.selectedContentFilter = "image" }
                    Button("Videos") { viewModel.selectedContentFilter = "video" }
                    Button("Stories") { viewModel.selectedContentFilter = "story" }
                } label: {
                    HStack {
                        Text(viewModel.selectedContentFilter.capitalized)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredTopContent) { content in
                    ContentPerformanceCard(
                        content: content,
                        onTap: { viewModel.showContentDetail(content) }
                    )
                }
            }
        }
    }
    
    // MARK: - Content Categories Section
    
    private var contentCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.contentCategories) { category in
                    ContentCategoryCard(category: category)
                }
            }
        }
    }
    
    // MARK: - Audience Overview Section
    
    private var audienceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audience Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let audience = viewModel.audienceInsights {
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Total Followers",
                        value: "\(audience.totalFollowers.formatted())",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Growth Rate",
                        value: "+\(audience.followersGrowth, specifier: "%.1f")%",
                        icon: "arrow.up.right",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Avg Age",
                        value: "\(audience.averageAge, specifier: "%.0f")",
                        icon: "person.fill",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Demographics Section
    
    private var demographicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Demographics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let audience = viewModel.audienceInsights {
                VStack(spacing: 16) {
                    // Gender Distribution
                    DemographicsCard(
                        title: "Gender Distribution",
                        data: audience.genderDistribution.map { ($0.gender, $0.percentage) }
                    )
                    
                    // Top Locations
                    DemographicsCard(
                        title: "Top Locations",
                        data: audience.topLocations.map { ($0.location, $0.percentage) }
                    )
                }
            }
        }
    }
    
    // MARK: - Engagement Patterns Section
    
    private var engagementPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Engagement Patterns")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let audience = viewModel.audienceInsights {
                EngagementByHourChart(data: audience.engagementByTimeOfDay)
            }
        }
    }
    
    // MARK: - Goals Progress Section
    
    private var goalsProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Goals Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.goalProgress) { goal in
                    GoalProgressCard(goal: goal)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sheet Views
    
    private var exportOptionsSheet: some View {
        NavigationView {
            ExportOptionsView(
                selectedFormat: $viewModel.exportFormat,
                isExporting: viewModel.isExporting,
                onExport: { viewModel.exportAnalytics() }
            )
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingExportOptions = false
                    }
                }
            }
        }
    }
    
    private var filtersSheet: some View {
        NavigationView {
            AnalyticsFiltersView(
                selectedCampaignFilter: $viewModel.selectedCampaignFilter,
                selectedContentFilter: $viewModel.selectedContentFilter,
                sortOption: $viewModel.sortOption
            )
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingFilters = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showingFilters = false
                    }
                }
            }
        }
    }
    
    private var goalSettingsSheet: some View {
        NavigationView {
            GoalSettingsView(
                goals: viewModel.monthlyGoals ?? InfluencerGoals(
                    engagementRateTarget: 5.0,
                    monthlyEarningsTarget: 4000.0,
                    followersTarget: 50000,
                    campaignsTarget: 4
                ),
                onSave: { goals in
                    viewModel.updateGoals(goals)
                    viewModel.showingGoalSettings = false
                }
            )
            .navigationTitle("Monthly Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingGoalSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        await MainActor.run {
            viewModel.refreshData()
        }
    }
}

// MARK: - Supporting Enums

enum InfluencerAnalyticsTab: String, CaseIterable {
    case overview = "overview"
    case campaigns = "campaigns"
    case content = "content"
    case audience = "audience"
    case goals = "goals"
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .campaigns: return "Campaigns"
        case .content: return "Content"
        case .audience: return "Audience"
        case .goals: return "Goals"
        }
    }
}

// MARK: - Preview

struct InfluencerAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        InfluencerAnalyticsView()
    }
} 