import SwiftUI
import Charts

struct BusinessAnalyticsView: View {
    @StateObject private var viewModel = BusinessAnalyticsViewModel()
    @State private var selectedTab: AnalyticsTab = .overview
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time Period Selector
                timePeriodSelector
                
                // Tab Selector
                tabSelector
                
                // Content
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .campaigns:
                            campaignsContent
                        case .influencers:
                            influencersContent
                        case .customers:
                            customersContent
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
                .refreshable {
                    viewModel.refreshData()
                }
            }
            .background(AppColors.backgroundSecondary)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showingFilters = true }) {
                            Label("Filters", systemImage: "line.3.horizontal.decrease")
                        }
                        
                        Button(action: { viewModel.showingExportOptions = true }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { viewModel.refreshData() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            AnalyticsFiltersView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingExportOptions) {
            AnalyticsExportView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingCampaignDetail) {
            if let campaign = viewModel.selectedCampaign {
                CampaignAnalyticsDetailView(campaign: campaign)
            }
        }
        .sheet(isPresented: $viewModel.showingInfluencerDetail) {
            if let influencer = viewModel.selectedInfluencer {
                InfluencerAnalyticsDetailView(influencer: influencer)
            }
        }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .overlay(
            Group {
                if viewModel.showingSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(viewModel.successMessage)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.green)
                        .cornerRadius(AppSpacing.radiusMD)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingSuccessMessage)
                }
            }
        )
    }
    
    // MARK: - View Components
    
    private var timePeriodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        if period == .custom {
                            viewModel.showingDatePicker = true
                        } else {
                            viewModel.updateTimePeriod(period)
                        }
                    }) {
                        Text(period.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedTimePeriod == period ? .white : AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                viewModel.selectedTimePeriod == period ? 
                                AppColors.secondary : Color.clear
                            )
                            .cornerRadius(AppSpacing.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                                    .stroke(AppColors.border, lineWidth: 1)
                                    .opacity(viewModel.selectedTimePeriod == period ? 0 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.vertical, AppSpacing.sm)
        .background(Color.white)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: AppSpacing.xs) {
                        Text(tab.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AppColors.secondary : AppColors.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.secondary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .background(Color.white)
    }
    
    // MARK: - Content Views
    
    private var overviewContent: some View {
        VStack(spacing: AppSpacing.lg) {
            if viewModel.isLoading {
                ProgressView("Loading analytics...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Key Metrics Cards
                overviewMetricsCards
                
                // Revenue Chart
                revenueChartCard
                
                // Performance Charts Grid
                performanceChartsGrid
                
                // Quick Insights
                quickInsightsCard
            }
        }
    }
    
    private var overviewMetricsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            if let metrics = viewModel.overviewMetrics {
                MetricCard(
                    title: "Total Revenue",
                    value: "$\(String(format: "%.0f", metrics.totalRevenue))",
                    change: "+\(String(format: "%.1f", metrics.revenueGrowth))%",
                    changeType: .positive,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Active Campaigns",
                    value: "\(metrics.activeCampaigns)",
                    subtitle: "of \(metrics.totalCampaigns) total",
                    icon: "megaphone.fill"
                )
                
                MetricCard(
                    title: "Active Influencers",
                    value: "\(metrics.activeInfluencers)",
                    subtitle: "of \(metrics.totalInfluencers) total",
                    icon: "person.2.fill"
                )
                
                MetricCard(
                    title: "Conversion Rate",
                    value: "\(String(format: "%.1f", metrics.conversionRate))%",
                    subtitle: "Average order: $\(String(format: "%.0f", metrics.averageOrderValue))",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
    
    private var revenueChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Revenue Trend")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(viewModel.selectedTimePeriod.displayName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if !viewModel.revenueChartData.isEmpty {
                Chart(viewModel.revenueChartData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", dataPoint.value)
                    )
                    .foregroundStyle(AppColors.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.secondary.opacity(0.3), AppColors.secondary.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("$\(Int(doubleValue))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let dateValue = value.as(Date.self) {
                                Text(DateFormatter.shortDate.string(from: dateValue))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("No data available")
                            .foregroundColor(AppColors.textSecondary)
                    )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private var performanceChartsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            SmallChartCard(
                title: "Engagement",
                data: viewModel.engagementChartData,
                color: AppColors.success,
                suffix: "%"
            )
            
            SmallChartCard(
                title: "Visitors",
                data: viewModel.visitorChartData,
                color: AppColors.warning,
                suffix: ""
            )
            
            SmallChartCard(
                title: "Conversions",
                data: viewModel.conversionChartData,
                color: AppColors.error,
                suffix: "%"
            )
            
            SmallChartCard(
                title: "Total Visits",
                value: viewModel.overviewMetrics?.totalVisits ?? 0,
                color: AppColors.secondary
            )
        }
    }
    
    private var quickInsightsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Insights")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                if let metrics = viewModel.overviewMetrics {
                    InsightRow(
                        icon: "arrow.up.circle.fill",
                        iconColor: AppColors.success,
                        title: "Revenue Growth",
                        description: "Revenue increased by \(String(format: "%.1f", metrics.revenueGrowth))% compared to previous period"
                    )
                    
                    InsightRow(
                        icon: "person.badge.plus.fill",
                        iconColor: AppColors.secondary,
                        title: "New Customers",
                        description: "\(metrics.newCustomers) new customers acquired this period"
                    )
                    
                    InsightRow(
                        icon: "chart.bar.fill",
                        iconColor: AppColors.warning,
                        title: "Retention Rate",
                        description: "\(String(format: "%.1f", metrics.customerRetentionRate))% customer retention rate"
                    )
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private var campaignsContent: some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(viewModel.filteredCampaignMetrics) { campaign in
                CampaignAnalyticsCard(campaign: campaign) {
                    viewModel.showCampaignDetail(campaign)
                }
            }
            
            if viewModel.filteredCampaignMetrics.isEmpty {
                StandardizedEmptyState(
                    icon: "megaphone",
                    title: "No Campaign Data",
                    message: "Campaign analytics will appear here once you have active campaigns."
                )
            }
        }
    }
    
    private var influencersContent: some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(viewModel.filteredInfluencerMetrics) { influencer in
                InfluencerAnalyticsCard(influencer: influencer) {
                    viewModel.showInfluencerDetail(influencer)
                }
            }
            
            if viewModel.filteredInfluencerMetrics.isEmpty {
                StandardizedEmptyState(
                    icon: "person.2",
                    title: "No Influencer Data",
                    message: "Influencer performance metrics will appear here once you start working with influencers."
                )
            }
        }
    }
    
    private var customersContent: some View {
        VStack(spacing: AppSpacing.lg) {
            if let customerMetrics = viewModel.customerMetrics {
                CustomerAnalyticsCard(metrics: customerMetrics)
            } else {
                StandardizedEmptyState(
                    icon: "person.3",
                    title: "No Customer Data",
                    message: "Customer analytics will appear here once you have customer interactions."
                )
            }
        }
    }
}

// MARK: - Supporting Views

enum AnalyticsTab: String, CaseIterable {
    case overview = "overview"
    case campaigns = "campaigns"
    case influencers = "influencers"
    case customers = "customers"
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .campaigns: return "Campaigns"
        case .influencers: return "Influencers"
        case .customers: return "Customers"
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String?
    let changeType: ChangeType?
    let subtitle: String?
    let icon: String
    
    init(title: String, value: String, change: String? = nil, changeType: ChangeType? = nil, subtitle: String? = nil, icon: String) {
        self.title = title
        self.value = value
        self.change = change
        self.changeType = changeType
        self.subtitle = subtitle
        self.icon = icon
    }
    
    enum ChangeType {
        case positive, negative, neutral
        
        var color: Color {
            switch self {
            case .positive: return AppColors.success
            case .negative: return AppColors.error
            case .neutral: return AppColors.textSecondary
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.secondary)
                    .font(.title3)
                
                Spacer()
                
                if let change = change, let changeType = changeType {
                    Text(change)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(changeType.color)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(changeType.color.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusMD)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct SmallChartCard: View {
    let title: String
    let data: [ChartDataPoint]?
    let value: Int?
    let color: Color
    let suffix: String
    
    init(title: String, data: [ChartDataPoint], color: Color, suffix: String = "") {
        self.title = title
        self.data = data
        self.value = nil
        self.color = color
        self.suffix = suffix
    }
    
    init(title: String, value: Int, color: Color) {
        self.title = title
        self.data = nil
        self.value = value
        self.color = color
        self.suffix = ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            if let data = data, !data.isEmpty {
                Chart(data) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 60)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                
                Text("\(String(format: "%.1f", data.last?.value ?? 0))\(suffix)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            } else if let value = value {
                Spacer()
                
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 60)
                    .overlay(
                        Text("No data")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    )
            }
        }
        .padding(AppSpacing.md)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusMD)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    BusinessAnalyticsView()
} 