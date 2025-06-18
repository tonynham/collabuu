import SwiftUI

struct BusinessInviteInfluencerView: View {
    @StateObject private var viewModel = BusinessInviteInfluencerViewModel()
    @State private var selectedTab: InviteTab = .discover
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Search
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            switch selectedTab {
                            case .discover:
                                discoverContent
                            case .invitations:
                                invitationsContent
                            case .templates:
                                templatesContent
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Invite Influencers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if selectedTab == .discover {
                            Button(action: { viewModel.showingFilters = true }) {
                                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            
                            if !viewModel.selectedInfluencers.isEmpty {
                                Button(action: { viewModel.showingBulkInvite = true }) {
                                    Label("Bulk Invite (\(viewModel.selectedInfluencers.count))", systemImage: "paperplane.fill")
                                }
                            }
                        }
                        
                        Button(action: { viewModel.showingTemplateEditor = true }) {
                            Label("Create Template", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: { viewModel.loadInvitationHistory() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search influencers...")
        .onChange(of: viewModel.searchText) { _ in
            viewModel.searchInfluencers()
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            filtersSheet
        }
        .sheet(isPresented: $viewModel.showingBulkInvite) {
            bulkInviteSheet
        }
        .sheet(isPresented: $viewModel.showingInviteComposer) {
            if let influencer = viewModel.selectedInfluencer {
                inviteComposerSheet(influencer: influencer)
            }
        }
        .sheet(isPresented: $viewModel.showingInfluencerDetail) {
            if let influencer = viewModel.selectedInfluencer {
                InfluencerDetailView(influencer: influencer)
            }
        }
        .sheet(isPresented: $viewModel.showingTemplateEditor) {
            templateEditorSheet
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
                Text("Find & Invite Influencers")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.hasActiveFilters {
                    Button("Clear Filters") {
                        viewModel.clearFilters()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Selection Summary
            if !viewModel.selectedInfluencers.isEmpty {
                HStack {
                    Text("\(viewModel.selectedInfluencers.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Select All") {
                        viewModel.selectAllVisible()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    Button("Deselect All") {
                        viewModel.deselectAll()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(InviteTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            
                            Text(tab.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .medium)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content Views
    
    private var discoverContent: some View {
        VStack(spacing: 16) {
            // Search Results or Suggestions
            if viewModel.isSearching {
                searchingView
            } else {
                influencerGridView
            }
        }
    }
    
    private var invitationsContent: some View {
        VStack(spacing: 16) {
            // Invitation Statistics
            invitationStatsView
            
            // Sent Invitations List
            sentInvitationsView
        }
    }
    
    private var templatesContent: some View {
        VStack(spacing: 16) {
            // Templates Header
            HStack {
                Text("Invitation Templates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { viewModel.showingTemplateEditor = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Template")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Templates List
            templatesListView
        }
    }
    
    // MARK: - Influencer Grid View
    
    private var influencerGridView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(viewModel.searchText.isEmpty ? "Suggested Influencers" : "Search Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.currentInfluencers.isEmpty {
                    Text("\(viewModel.currentInfluencers.count) found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.currentInfluencers) { influencer in
                    InfluencerCard(
                        influencer: influencer,
                        isSelected: viewModel.selectedInfluencers.contains(influencer.id),
                        onSelect: { viewModel.toggleInfluencerSelection(influencer.id) },
                        onTap: { viewModel.showInfluencerDetail(influencer) },
                        onInvite: { viewModel.showInviteComposer(for: influencer) }
                    )
                }
            }
        }
    }
    
    // MARK: - Invitation Stats View
    
    private var invitationStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invitation Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InvitationStatCard(
                    title: "Sent",
                    value: "\(viewModel.sentInvitations.count)",
                    icon: "paperplane.fill",
                    color: .blue
                )
                
                InvitationStatCard(
                    title: "Accepted",
                    value: "\(viewModel.sentInvitations.filter { $0.status == .accepted }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                InvitationStatCard(
                    title: "Pending",
                    value: "\(viewModel.sentInvitations.filter { $0.status == .pending }.count)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Sent Invitations View
    
    private var sentInvitationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Invitations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    viewModel.showingInvitationHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.sentInvitations.prefix(5))) { invitation in
                    SentInvitationCard(
                        invitation: invitation,
                        onResend: { viewModel.resendInvitation(invitation) },
                        onCancel: { viewModel.cancelInvitation(invitation) }
                    )
                }
            }
        }
    }
    
    // MARK: - Templates List View
    
    private var templatesListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.inviteTemplates) { template in
                InviteTemplateCard(
                    template: template,
                    onUse: { viewModel.applyTemplate(template) }
                )
            }
        }
    }
    
    // MARK: - Searching View
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching influencers...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading influencers...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sheet Views
    
    private var filtersSheet: some View {
        NavigationView {
            InfluencerFiltersView(
                selectedCategories: $viewModel.selectedCategories,
                selectedTiers: $viewModel.selectedTiers,
                followerRangeMin: $viewModel.followerRangeMin,
                followerRangeMax: $viewModel.followerRangeMax,
                engagementRateMin: $viewModel.engagementRateMin,
                engagementRateMax: $viewModel.engagementRateMax,
                locationFilter: $viewModel.locationFilter,
                onApply: { viewModel.applyFilters() },
                onClear: { viewModel.clearFilters() }
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
                    Button("Apply") {
                        viewModel.applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var bulkInviteSheet: some View {
        NavigationView {
            BulkInviteView(
                selectedCount: viewModel.selectedInfluencers.count,
                invitationMessage: $viewModel.invitationMessage,
                offerAmount: $viewModel.offerAmount,
                offerType: $viewModel.offerType,
                deliverables: $viewModel.deliverables,
                deadline: $viewModel.deadline,
                templates: viewModel.inviteTemplates,
                isSending: viewModel.isSendingInvites,
                onSend: { viewModel.sendBulkInvitations() },
                onApplyTemplate: { template in viewModel.applyTemplate(template) }
            )
            .navigationTitle("Bulk Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingBulkInvite = false
                    }
                }
            }
        }
    }
    
    private func inviteComposerSheet(influencer: InfluencerSearchResult) -> some View {
        NavigationView {
            InviteComposerView(
                influencer: influencer,
                invitationMessage: $viewModel.invitationMessage,
                offerAmount: $viewModel.offerAmount,
                offerType: $viewModel.offerType,
                deliverables: $viewModel.deliverables,
                deadline: $viewModel.deadline,
                templates: viewModel.inviteTemplates,
                onSend: { viewModel.sendInvitation(to: influencer) },
                onApplyTemplate: { template in viewModel.applyTemplate(template) }
            )
            .navigationTitle("Invite \(influencer.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingInviteComposer = false
                    }
                }
            }
        }
    }
    
    private var templateEditorSheet: some View {
        NavigationView {
            TemplateEditorView(
                onSave: { template in
                    viewModel.inviteTemplates.append(template)
                    viewModel.showingTemplateEditor = false
                }
            )
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingTemplateEditor = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum InviteTab: String, CaseIterable {
    case discover = "discover"
    case invitations = "invitations"
    case templates = "templates"
    
    var displayName: String {
        switch self {
        case .discover: return "Discover"
        case .invitations: return "Invitations"
        case .templates: return "Templates"
        }
    }
    
    var icon: String {
        switch self {
        case .discover: return "magnifyingglass"
        case .invitations: return "paperplane"
        case .templates: return "doc.text"
        }
    }
}

// MARK: - Preview

struct BusinessInviteInfluencerView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessInviteInfluencerView()
    }
} 