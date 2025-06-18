import SwiftUI

struct InfluencerCampaignDetailView: View {
    let campaign: AcceptedCampaign
    @StateObject private var viewModel = InfluencerCampaignDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Calculate progress for earned credits
    private var creditsProgress: Double {
        let totalCredits = Double(campaign.totalCredits)
        let earnedCredits = Double(campaign.earnedCredits)
        return totalCredits > 0 ? earnedCredits / totalCredits : 0.0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header Image Container
                headerImageContainer
                
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Campaign Title Section
                    campaignTitleSection
                    
                    // Combined Information Container
                    combinedInformationSection
                    
                    // Performance Section (if active/completed)
                    if campaign.status == .active || campaign.status == .completed {
                        performanceSection
                    }
                    
                    // Content Section
                    contentSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.backgroundSecondary)
        .standardNavigationTitle("Campaign Details", displayMode: .inline)
        .standardBackButton {
            dismiss()
        }
        .onAppear {
            viewModel.loadCampaignDetails(campaign)
        }
        .sheet(isPresented: $viewModel.showingContentCreation) {
            Text("Content Creation View")
        }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .standardizedAlert(
            isPresented: $viewModel.showingSubmissionSuccess,
            config: StandardizedAlertConfig(
                title: "Content Submitted",
                message: "Your social media link has been submitted successfully!",
                primaryButton: StandardizedAlertConfig.AlertButton(
                    title: "OK",
                    action: { viewModel.dismissSubmissionSuccess() }
                )
            )
        )
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(activityItems: [viewModel.shareText])
        }
        .overlay(
            Group {
                if viewModel.copiedToClipboard {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Copied to clipboard")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(AppSpacing.radiusMD)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.copiedToClipboard)
                }
            }
        )
    }
    
    // MARK: - View Components
    
    private var headerImageContainer: some View {
        VStack(spacing: 0) {
            AsyncImage(url: URL(string: campaign.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.white)
                    .overlay(
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.textTertiary)
                            Text("Campaign Image")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    )
            }
            .frame(height: 200)
            .clipped()
        }
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
        .padding(.horizontal, AppSpacing.md)
    }
    
    private var campaignTitleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(campaign.title)
                .headlineLarge()
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Text("Status:")
                    .titleMedium()
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text(campaign.status.displayName)
                    .labelLarge()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(for: campaign.status))
                    .cornerRadius(12)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var combinedInformationSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Section Header
            HStack {
                Text("Campaign Information")
                    .titleLarge()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: AppSpacing.lg) {
                // Campaign Details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Campaign Details")
                        .titleMedium()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    VStack(spacing: AppSpacing.sm) {
                        CampaignDetailRow(title: "Description", value: campaign.description)
                        CampaignDetailRow(title: "Business", value: campaign.businessName)
                        CampaignDetailRow(title: "Start Date", value: formatDate(campaign.startDate))
                        CampaignDetailRow(title: "End Date", value: formatDate(campaign.endDate))
                    }
                }
                
                // Payment Information
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Payment Information")
                        .titleMedium()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    VStack(spacing: AppSpacing.sm) {
                        PaymentDetailRow(title: "Campaign Type", value: campaign.paymentType.displayName)
                        PaymentDetailRow(title: "Credits per Visit", value: "\(campaign.creditsPerVisitor)")
                        
                        // Credits Progress with Progress Bar
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text("Credits Earned")
                                    .bodyLarge()
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text("\(campaign.earnedCredits) / \(campaign.totalCredits)")
                                    .bodyLarge()
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(AppColors.backgroundSecondary)
                                        .frame(height: 6)
                                        .cornerRadius(3)
                                    
                                    Rectangle()
                                        .fill(AppColors.primary)
                                        .frame(width: geometry.size.width * creditsProgress, height: 6)
                                        .cornerRadius(3)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                
                // Requirements (if available)
                if let requirements = campaign.requirements, !requirements.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Requirements")
                            .titleMedium()
                            .foregroundColor(AppColors.textPrimary)
                        
                        Divider()
                            .background(AppColors.border)
                        
                        VStack(spacing: AppSpacing.sm) {
                            InfoDetailRow(title: "Requirements", value: requirements)
                        }
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
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var performanceSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Section Header
            HStack {
                Text("Your Performance")
                    .titleLarge()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            // KPI Grid
            KPIGrid(kpis: [
                .postsCreated(viewModel.postsCreated),
                .totalViews(viewModel.totalViews),
                .engagementRate(viewModel.engagementRate),
                .earnings(Double(viewModel.totalEarnings))
            ], columns: 2)
            
            // Visitors Area Chart
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Visitors Over Time")
                    .titleMedium()
                    .foregroundColor(AppColors.textPrimary)
                
                StandardizedAreaChart(
                    data: .visitorsChart(
                        values: viewModel.visitorData.map { CGFloat($0) },
                        labels: viewModel.visitorLabels
                    )
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var contentSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Section Header
            HStack {
                Text("Your Content")
                    .titleLarge()
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            if viewModel.contentPosts.isEmpty {
                VStack(spacing: AppSpacing.lg) {
                    // Social Media Link Submission
                    socialMediaSubmissionSection
                    
                    // Unique Code Sharing
                    uniqueCodeSharingSection
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.md) {
                    ForEach(viewModel.contentPosts) { post in
                        ContentPostCard(post: post)
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
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var socialMediaSubmissionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "link.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                
                Text("Submit Social Media Link")
                    .titleMedium()
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.semibold)
            }
            
            Text("Share the link to your social media post about this campaign")
                .bodyMedium()
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.md) {
                StandardizedFormField(
                    title: "Social Media Post URL",
                    text: $viewModel.socialMediaLink,
                    placeholder: "https://instagram.com/p/your-post...",
                    keyboardType: .URL,
                    leadingIcon: "link"
                )
                
                StandardizedButton(
                    title: "Submit Link",
                    action: {
                        viewModel.submitSocialMediaLink()
                    },
                    style: .secondary,
                    size: .medium,
                    isLoading: viewModel.isSubmittingLink,
                    isDisabled: viewModel.socialMediaLink.isEmpty
                )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMD)
    }
    
    private var uniqueCodeSharingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "qrcode")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                
                Text("Your Unique Campaign Code")
                    .titleMedium()
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.semibold)
            }
            
            Text("Share this code or link to get credit for customer visits")
                .bodyMedium()
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.md) {
                // Unique Code Display
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Campaign Code")
                            .bodyMedium()
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Button("Copy") {
                            viewModel.copyCodeToClipboard()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                    }
                    
                    HStack {
                        Text(campaign.campaignCode)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(AppColors.secondary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.white)
                    .cornerRadius(AppSpacing.radiusMD)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                // Deep Link Display
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Share Link")
                            .bodyMedium()
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Button("Copy Link") {
                            viewModel.copyLinkToClipboard()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                    }
                    
                    HStack {
                        Text(viewModel.campaignDeepLink)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Image(systemName: "link")
                            .foregroundColor(AppColors.secondary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.white)
                    .cornerRadius(AppSpacing.radiusMD)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                // Share Button
                StandardizedButton(
                    title: "Share Campaign",
                    action: {
                        viewModel.shareCampaign()
                    },
                    style: .primary,
                    size: .medium,
                    leadingIcon: "square.and.arrow.up"
                )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondary.opacity(0.05))
        .cornerRadius(AppSpacing.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                .stroke(AppColors.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    
    private func statusColor(for status: CampaignStatus) -> Color {
        return status.color
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views (Note: CampaignDetailRow, PaymentDetailRow, InfoDetailRow are defined in BusinessCampaignDetailView)

struct ContentPostCard: View {
    let post: ContentPost
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Rectangle()
                .fill(AppColors.backgroundTertiary)
                .frame(height: 80)
                .cornerRadius(AppSpacing.radiusSM)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(AppColors.textTertiary)
                )
            
            VStack(spacing: 2) {
                Text(post.platform)
                    .labelSmall(AppColors.textPrimary)
                
                Text("\(post.views) views")
                    .labelSmall(AppColors.textSecondary)
            }
        }
        .standardCard(
            padding: AppSpacing.sm,
            cornerRadius: AppSpacing.radiusSM
        )
    }
}

#Preview {
    let calendar = Calendar.current
    let currentDate = Date()
    
    let sampleCampaign = AcceptedCampaign(
        id: "1",
        opportunityId: "opp1",
        title: "Fitness Center Grand Opening",
        description: "Help promote our new fitness center location",
        businessId: "business1",
        businessName: "FitLife Gym",
        paymentType: .payPerCustomer,
        creditsPerVisitor: 10,
        totalCredits: 500,
        startDate: calendar.date(byAdding: .day, value: -10, to: currentDate) ?? currentDate,
        endDate: calendar.date(byAdding: .day, value: 20, to: currentDate) ?? currentDate,
        status: .active,
        acceptedAt: calendar.date(byAdding: .day, value: -15, to: currentDate) ?? currentDate,
        currentVisits: 12,
        targetVisits: 50,
        earnedCredits: 120,
        imageUrl: nil,
        requirements: "Must visit during business hours and post within 24 hours",
        location: "Downtown Location",
        campaignCode: "FITNESS2024",
        isActive: true
    )
    
    InfluencerCampaignDetailView(campaign: sampleCampaign)
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 