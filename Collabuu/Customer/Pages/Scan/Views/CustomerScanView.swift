import SwiftUI
import AVFoundation

struct CustomerScanView: View {
    @StateObject private var viewModel = CustomerScanViewModel()
    @State private var showingManualEntry = false
    
    var body: some View {
        ZStack {
            // Full Screen Black Background for Scanning
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                Spacer()
                
                // Scanner Area
                scannerArea
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingManualEntry) {
            ManualCodeEntryView { code in
                viewModel.processManualCode(code)
            }
        }
        .sheet(isPresented: $viewModel.showingScanResult) {
            if let result = viewModel.lastScanResult {
                CustomerScanResultView(scanResult: result, viewModel: viewModel)
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
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Points Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Points")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(viewModel.currentPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Earned Today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("+\(viewModel.earnedPointsToday)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            // Title and Instructions
            VStack(spacing: AppSpacing.md) {
                Text("Scan QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Scan QR codes at businesses to claim deals, earn points, and record visits")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.top, AppSpacing.xl)
    }
    
    private var scannerArea: some View {
        ZStack {
            // Scanner Frame with Corner Indicators
            VStack {
                HStack {
                    ScannerCorner()
                    Spacer()
                    ScannerCorner(flipped: true)
                }
                Spacer()
                HStack {
                    ScannerCorner(rotated: true)
                    Spacer()
                    ScannerCorner(flipped: true, rotated: true)
                }
            }
            .frame(width: 250, height: 250)
            
            // Center Content
            VStack(spacing: AppSpacing.md) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.secondary)
                }
                
                Text(viewModel.statusMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
            }
            .onTapGesture {
                if !viewModel.isLoading {
                    simulateScan()
                }
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: AppSpacing.lg) {
            // Control Buttons
            HStack(spacing: AppSpacing.xl) {
                // Torch Button
                Button(action: viewModel.toggleTorch) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.isTorchOn ? AppColors.secondary : .white)
                        
                        Text("Flash")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .disabled(!viewModel.isCameraAvailable)
                
                Spacer()
                
                // Manual Entry Button
                Button(action: { viewModel.showingManualEntry = true }) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("Manual")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Recent Scans Button
                Button(action: { /* TODO: Show recent scans */ }) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("Recent")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            
            // Recent Scans Preview
            if !viewModel.recentScans.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("Recent Scans")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("View All") {
                            // TODO: Show all recent scans
                        }
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondary)
                    }
                    
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.recentScans.prefix(2)) { scan in
                            RecentScanCard(scan: scan)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.bottom, AppSpacing.xl)
    }
    
    private func simulateScan() {
        // Simulate a successful scan for testing
        let mockResult = CustomerScanResult(
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
        )
        
        viewModel.lastScanResult = mockResult
        viewModel.showingScanResult = true
    }
}

// MARK: - Supporting Views

struct ScannerCorner: View {
    let flipped: Bool
    let rotated: Bool
    
    init(flipped: Bool = false, rotated: Bool = false) {
        self.flipped = flipped
        self.rotated = rotated
    }
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(AppColors.secondary, lineWidth: 4)
        .frame(width: 30, height: 30)
        .scaleEffect(x: flipped ? -1 : 1, y: rotated ? -1 : 1)
    }
}

struct RecentScanCard: View {
    let scan: CustomerScanResult
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Status Indicator
            Circle()
                .fill(scan.isValid ? AppColors.success : AppColors.error)
                .frame(width: 12, height: 12)
            
            // Scan Info
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.businessName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(scan.scanType == .deal ? "Deal Scan" : "Visit Scan")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Timestamp
            Text(scan.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.white.opacity(0.1))
        .cornerRadius(AppSpacing.radiusMD)
    }
}

struct ManualCodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""
    let onCodeEntered: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.secondary)
                    
                    Text("Enter Code Manually")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Enter the QR code manually if scanning isn't working")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                StandardizedFormField(
                    title: "QR Code",
                    text: $code,
                    placeholder: "Enter QR code here",
                    isRequired: true
                )
                
                AppButton(
                    title: "Submit Code",
                    action: {
                        onCodeEntered(code)
                        dismiss()
                    },
                    style: .primary,
                    size: .large
                )
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xl)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CustomerScanView()
} 