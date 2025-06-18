import SwiftUI

struct DealDetailView: View {
    let deal: Deal
    @StateObject private var viewModel: DealDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorited = false
    
    init(deal: Deal) {
        self.deal = deal
        self._viewModel = StateObject(wrappedValue: DealDetailViewModel(deal: deal))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header Image Container
                headerImageContainer
                
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Deal Title Section
                    dealTitleSection
                    
                    // Deal Information Section
                    dealInformationSection
                    
                    // Terms & Conditions Section
                    termsSection
                    
                    // Action Button Section
                    actionButtonSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.backgroundSecondary)
        .standardNavigationTitle("Deal Details", displayMode: .inline)
        .standardBackButton {
            dismiss()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                StandardToolbarActionButton(
                    icon: viewModel.isFavorited ? "heart.fill" : "heart",
                    action: { 
                        viewModel.toggleFavorite()
                    },
                    isCircular: true,
                    backgroundColor: AppColors.secondary.opacity(0.1),
                    foregroundColor: viewModel.isFavorited ? AppColors.secondary : AppColors.textSecondary
                )
                
                Menu {
                    Button("Show QR Code") {
                        viewModel.showQRCode()
                    }
                    
                    Button("Share Deal") {
                        viewModel.shareQRCode()
                    }
                    
                    Button("Refresh") {
                        viewModel.refreshDeal()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .sheet(isPresented: $viewModel.showingQRCode) {
            QRCodeView(
                qrImage: viewModel.qrCodeImage,
                title: "Deal QR Code",
                subtitle: "Show this code at \(viewModel.deal.businessName) to claim your deal"
            )
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(
                activityItems: [viewModel.shareText, viewModel.qrCodeImage].compactMap { $0 }
            )
        }
        .overlay(
            Group {
                if viewModel.showingAddToFavoritesSuccess {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                            Text("Added to favorites")
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
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingAddToFavoritesSuccess)
                }
            }
        )
    }
    
    // MARK: - View Components
    
    private var headerImageContainer: some View {
        VStack(spacing: 0) {
            AsyncImage(url: URL(string: deal.imageUrl ?? "")) { image in
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
                            Text("Deal Image")
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
    
    private var dealTitleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(deal.title)
                .headlineLarge()
                .foregroundColor(AppColors.textPrimary)
            
            Text("by \(deal.businessName)")
                .titleLarge()
                .foregroundColor(AppColors.textSecondary)
            
            HStack {
                if let category = deal.category {
                    CampaignBadge(
                        text: category,
                        backgroundColor: AppColors.backgroundSecondary,
                        textColor: AppColors.textSecondary
                    )
                }
                
                Spacer()
                
                CampaignBadge(
                    text: "\(deal.creditsReward) credits",
                    backgroundColor: AppColors.secondary.opacity(0.1),
                    textColor: AppColors.secondary
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
    
    private var dealInformationSection: some View {
        let cardContent = VStack(spacing: AppSpacing.lg) {
            // Section Header
            HStack {
                Text("Deal Information")
                    .titleLarge()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Description
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Description")
                        .titleMedium()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    Text(deal.description)
                        .bodyLarge()
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Deal Details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Deal Details")
                        .titleMedium()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    VStack(spacing: AppSpacing.sm) {
                        DealDetailRow(title: "Expires", value: formatDate(deal.expiryDate))
                        if let location = deal.location {
                            DealDetailRow(title: "Location", value: location)
                        }
                        DealDetailRow(title: "Credits Reward", value: "\(deal.creditsReward) credits")
                        DealDetailRow(title: "Status", value: deal.isActive ? "Active" : "Inactive")
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        
        return cardContent
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
    
    private var termsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Section Header
            HStack {
                Text("Terms & Conditions")
                    .titleLarge()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                TermsRow(icon: "checkmark.circle", text: "Valid for new and existing customers")
                TermsRow(icon: "clock", text: "Limited time offer")
                TermsRow(icon: "person.2", text: "Cannot be combined with other offers")
                TermsRow(icon: "location", text: "Valid at specified location only")
                if let location = deal.location {
                    TermsRow(icon: "mappin.circle", text: "Available at \(location)")
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
    
    private var actionButtonSection: some View {
        VStack(spacing: AppSpacing.lg) {
            StandardizedButton(
                title: "Save to Favorites",
                action: {
                    // TODO: Implement save to favorites functionality
                },
                style: .primary,
                size: .large
            )
            
            Text("You'll receive \(deal.creditsReward) credits when you redeem this deal")
                .bodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
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
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct DealDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .bodyMedium()
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .bodyMedium()
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

struct TermsRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppColors.secondary)
                .frame(width: 20)
            
            Text(text)
                .bodyMedium()
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    DealDetailView(deal: Deal.sampleDeals[0])
} 