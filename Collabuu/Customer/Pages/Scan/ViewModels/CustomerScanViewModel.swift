import Foundation
import SwiftUI
import AVFoundation

@MainActor
class CustomerScanViewModel: ObservableObject {
    // Camera and Scanning
    @Published var isCameraAvailable: Bool = false
    @Published var isScanning: Bool = false
    @Published var isTorchOn: Bool = false
    @Published var statusMessage: String = ""
    @Published var showingManualEntry: Bool = false
    
    // Scan Results
    @Published var lastScanResult: CustomerScanResult?
    @Published var showingScanResult: Bool = false
    @Published var recentScans: [CustomerScanResult] = []
    
    // Deal and Visit Management
    @Published var availableDeals: [Deal] = []
    @Published var claimedDeals: [ClaimedDeal] = []
    @Published var visitHistory: [VisitRecord] = []
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    // Points and Rewards
    @Published var currentPoints: Int = 0
    @Published var earnedPointsToday: Int = 0
    
    private let apiService = APIService.shared
    private var captureSession: AVCaptureSession?
    
    init() {
        checkCameraPermission()
        loadCustomerData()
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAvailable = true
            statusMessage = "Camera ready - Point at QR code to scan"
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAvailable = granted
                    self?.statusMessage = granted ? "Camera ready - Point at QR code to scan" : "Camera access required for scanning"
                }
            }
        case .denied, .restricted:
            isCameraAvailable = false
            statusMessage = "Camera access required. Please enable in Settings."
        @unknown default:
            isCameraAvailable = false
            statusMessage = "Camera status unknown"
        }
    }
    
    func startScanning() {
        guard isCameraAvailable else { return }
        isScanning = true
        statusMessage = "Point camera at QR code to scan..."
    }
    
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
    }
    
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - QR Code Processing
    
    func processScannedCode(_ code: String) {
        isLoading = true
        statusMessage = "Verifying QR code..."
        
        Task {
            do {
                let scanResult = try await apiService.verifyCustomerQRCode(code)
                await MainActor.run {
                    self.lastScanResult = scanResult
                    self.showingScanResult = true
                    self.addToRecentScans(scanResult)
                    self.isLoading = false
                    self.stopScanning()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to verify QR code: \(error.localizedDescription)"
                    self.isLoading = false
                    self.statusMessage = "Scan failed - Try again"
                }
            }
        }
    }
    
    func processManualCode(_ code: String) {
        processScannedCode(code)
    }
    
    private func addToRecentScans(_ result: CustomerScanResult) {
        recentScans.insert(result, at: 0)
        if recentScans.count > 20 {
            recentScans.removeLast()
        }
    }
    
    // MARK: - Deal and Visit Actions
    
    func claimDeal() {
        guard let scanResult = lastScanResult,
              let deal = scanResult.deal else { return }
        
        isLoading = true
        
        Task {
            do {
                let claimRequest = ClaimDealRequest(
                    dealId: deal.id,
                    businessId: deal.businessId,
                    qrCode: scanResult.qrCode
                )
                
                let claimedDeal = try await apiService.claimCustomerDeal(claimRequest)
                
                await MainActor.run {
                    self.claimedDeals.append(claimedDeal)
                    self.currentPoints += deal.creditsReward
                    self.earnedPointsToday += deal.creditsReward
                    self.isLoading = false
                    self.showSuccessMessage("Deal claimed! Earned \(deal.creditsReward) points")
                    self.lastScanResult = nil
                    self.showingScanResult = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to claim deal: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func recordVisit() {
        guard let scanResult = lastScanResult else { return }
        
        isLoading = true
        
        Task {
            do {
                let visitRequest = RecordVisitRequest(
                    businessId: scanResult.businessId,
                    qrCode: scanResult.qrCode,
                    visitType: scanResult.visitType
                )
                
                let visitRecord = try await apiService.recordCustomerVisit(visitRequest)
                
                await MainActor.run {
                    self.visitHistory.insert(visitRecord, at: 0)
                    self.currentPoints += visitRecord.pointsEarned
                    self.earnedPointsToday += visitRecord.pointsEarned
                    self.isLoading = false
                    self.showSuccessMessage("Visit recorded! Earned \(visitRecord.pointsEarned) points")
                    self.lastScanResult = nil
                    self.showingScanResult = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to record visit: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func addToFavorites() {
        guard let scanResult = lastScanResult else { return }
        
        Task {
            do {
                let favoriteRequest = AddFavoriteRequest(
                    businessId: scanResult.businessId,
                    businessName: scanResult.businessName,
                    dealId: scanResult.deal?.id
                )
                
                try await apiService.addCustomerFavorite(favoriteRequest)
                
                await MainActor.run {
                    self.showSuccessMessage("Added \(scanResult.businessName) to favorites")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add to favorites: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadCustomerData() {
        Task {
            do {
                async let pointsTask = apiService.getCustomerPoints()
                async let dealsTask = apiService.getAvailableDeals()
                async let claimedDealsTask = apiService.getClaimedDeals()
                async let visitsTask = apiService.getVisitHistory()
                
                let (points, deals, claimed, visits) = try await (pointsTask, dealsTask, claimedDealsTask, visitsTask)
                
                await MainActor.run {
                    self.currentPoints = points.total
                    self.earnedPointsToday = points.earnedToday
                    self.availableDeals = deals
                    self.claimedDeals = claimed
                    self.visitHistory = visits
                }
            } catch {
                await MainActor.run {
                    print("Error loading customer data: \(error)")
                    // Load sample data as fallback
                    self.loadSampleDataAsFallback()
                }
            }
        }
    }
    
    private func loadSampleDataAsFallback() {
        currentPoints = 1250
        earnedPointsToday = 50
        
        availableDeals = [
            Deal(
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
            )
        ]
        
        claimedDeals = []
        visitHistory = []
        recentScans = []
    }
    
    func refreshData() {
        loadCustomerData()
    }
    
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
    
    func dismissScanResult() {
        lastScanResult = nil
        showingScanResult = false
        startScanning() // Resume scanning
    }
}

// MARK: - Supporting Models

struct CustomerScanResult: Identifiable {
    let id = UUID()
    let qrCode: String
    let businessId: String
    let businessName: String
    let scanType: ScanType
    let deal: Deal?
    let visitType: VisitType
    let timestamp: Date
    let isValid: Bool
    let message: String
    
    enum ScanType {
        case deal
        case visit
        case favorite
        case invalid
    }
    
    enum VisitType {
        case checkin
        case purchase
        case event
    }
}

struct ClaimDealRequest: Codable {
    let dealId: String
    let businessId: String
    let qrCode: String
}

struct RecordVisitRequest: Codable {
    let businessId: String
    let qrCode: String
    let visitType: CustomerScanResult.VisitType
}

struct ClaimedDeal: Identifiable, Codable {
    let id: String
    let dealId: String
    let dealTitle: String
    let businessName: String
    let pointsEarned: Int
    let claimedAt: Date
    let expiryDate: Date
    let isUsed: Bool
}

struct VisitRecord: Identifiable, Codable {
    let id: String
    let businessId: String
    let businessName: String
    let visitType: CustomerScanResult.VisitType
    let pointsEarned: Int
    let visitedAt: Date
}

struct CustomerPoints: Codable {
    let total: Int
    let earnedToday: Int
    let earnedThisWeek: Int
    let earnedThisMonth: Int
} 