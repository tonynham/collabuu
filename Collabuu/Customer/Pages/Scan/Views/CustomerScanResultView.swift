import SwiftUI

struct CustomerScanResultView: View {
    let scanResult: CustomerScanResult
    @ObservedObject var viewModel: CustomerScanViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Scan Result Content
                    resultContentSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
            .background(AppColors.backgroundSecondary)
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.dismissScanResult()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Status Icon
            Circle()
                .fill(scanResult.isValid ? AppColors.success : AppColors.error)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: scanResult.isValid ? "checkmark" : "xmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Status Message
            VStack(spacing: AppSpacing.sm) {
                Text(scanResult.isValid ? "QR Code Verified" : "Invalid QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(scanResult.message)
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var resultContentSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Business Information
            businessInfoCard
            
            // Deal or Visit Information
            if scanResult.scanType == .deal, let deal = scanResult.deal {
                dealInfoCard(deal)
            } else if scanResult.scanType == .visit {
                visitInfoCard
            }
        }
    }
    
    private var businessInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "building.2")
                    .font(.title3)
                    .foregroundColor(AppColors.secondary)
                
                Text("Business Information")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Business:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(scanResult.businessName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Scan Type:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(scanResult.scanType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Scanned At:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(scanResult.timestamp, style: .time)
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
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    private func dealInfoCard(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "gift")
                    .font(.title3)
                    .foregroundColor(AppColors.secondary)
                
                Text("Deal Information")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                CampaignBadge(
                    text: "\(deal.creditsReward) points",
                    backgroundColor: AppColors.secondary.opacity(0.1),
                    textColor: AppColors.secondary
                )
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(deal.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(deal.description)
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                
                if let category = deal.category {
                    HStack {
                        Text("Category:")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        CampaignBadge(
                            text: category,
                            backgroundColor: AppColors.backgroundSecondary,
                            textColor: AppColors.textSecondary
                        )
                    }
                }
                
                HStack {
                    Text("Expires:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(deal.expiryDate, style: .date)
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
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    private var visitInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "location")
                    .font(.title3)
                    .foregroundColor(AppColors.secondary)
                
                Text("Visit Information")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                CampaignBadge(
                    text: "10 points",
                    backgroundColor: AppColors.secondary.opacity(0.1),
                    textColor: AppColors.secondary
                )
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Check-in Visit")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Record your visit to earn points and track your activity")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack {
                    Text("Visit Type:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(scanResult.visitType.displayName)
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
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: AppSpacing.md) {
            if scanResult.isValid {
                // Primary Action Button
                if scanResult.scanType == .deal {
                    AppButton(
                        title: "Claim Deal",
                        action: {
                            viewModel.claimDeal()
                            dismiss()
                        },
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isLoading
                    )
                } else if scanResult.scanType == .visit {
                    AppButton(
                        title: "Record Visit",
                        action: {
                            viewModel.recordVisit()
                            dismiss()
                        },
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isLoading
                    )
                }
                
                // Secondary Actions
                HStack(spacing: AppSpacing.md) {
                    AppButton(
                        title: "Add to Favorites",
                        action: {
                            viewModel.addToFavorites()
                        },
                        style: .secondary,
                        size: .medium
                    )
                    
                    AppButton(
                        title: "Share",
                        action: {
                            // TODO: Implement sharing
                        },
                        style: .secondary,
                        size: .medium
                    )
                }
            } else {
                // Invalid scan - try again
                AppButton(
                    title: "Scan Again",
                    action: {
                        viewModel.dismissScanResult()
                        dismiss()
                    },
                    style: .primary,
                    size: .large
                )
            }
        }
    }
}

// MARK: - Extensions

extension CustomerScanResult.ScanType {
    var displayName: String {
        switch self {
        case .deal:
            return "Deal"
        case .visit:
            return "Visit"
        case .favorite:
            return "Favorite"
        case .invalid:
            return "Invalid"
        }
    }
}

extension CustomerScanResult.VisitType {
    var displayName: String {
        switch self {
        case .checkin:
            return "Check-in"
        case .purchase:
            return "Purchase"
        case .event:
            return "Event"
        }
    }
}

#Preview {
    CustomerScanResultView(
        scanResult: CustomerScanResult(
            qrCode: "DEMO123",
            businessId: "business1",
            businessName: "Sunny Cafe",
            scanType: .deal,
            deal: Deal(
                id: "deal1",
                title: "20% Off Summer Menu",
                description: "Get 20% off our delicious summer menu items",
                businessId: "business1",
                businessName: "Sunny Cafe",
                creditsReward: 25,
                category: "Food",
                imageUrl: nil,
                expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                location: "Downtown",
                isActive: true
            ),
            visitType: .checkin,
            timestamp: Date(),
            isValid: true,
            message: "Valid deal found! Tap to claim your reward."
        ),
        viewModel: CustomerScanViewModel()
    )
} 