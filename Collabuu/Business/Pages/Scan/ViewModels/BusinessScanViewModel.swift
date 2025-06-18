import SwiftUI
import AVFoundation
import Combine

@MainActor
class BusinessScanViewModel: ObservableObject {
    @Published var isCameraAvailable = false
    @Published var isTorchOn = false
    @Published var statusMessage = ""
    @Published var currentScanResult: ScanResult?
    @Published var isScanning = false
    @Published var lastScanResult: ScanResult?
    @Published var recentScans: [ScanResult] = []
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    init() {
        checkCameraPermission()
        loadRecentScans()
    }
    
    // MARK: - Camera Setup
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAvailable = true
            statusMessage = "Camera ready"
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAvailable = granted
                    self?.statusMessage = granted ? "Camera ready" : "Camera access denied"
                }
            }
        case .denied, .restricted:
            isCameraAvailable = false
            statusMessage = "Camera access denied"
        @unknown default:
            isCameraAvailable = false
            statusMessage = "Camera status unknown"
        }
    }
    
    // MARK: - Scanning Controls
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
    
    // MARK: - Code Processing
    func processManualCode(_ code: String) {
        // Simulate processing the manual code
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = self.createScanResult(from: code)
            self.lastScanResult = result
            self.addToRecentScans(result)
        }
    }
    
    func processScannedCode(_ code: String) {
        let result = createScanResult(from: code)
        lastScanResult = result
        addToRecentScans(result)
    }
    
    private func createScanResult(from code: String) -> ScanResult {
        // In a real app, this would validate the QR code and fetch campaign details
        return ScanResult(
            id: UUID(),
            influencerName: "Test Influencer",
            campaignTitle: "Test Campaign",
            verificationCode: code,
            timestamp: Date(),
            isValid: true
        )
    }
    
    private func addToRecentScans(_ result: ScanResult) {
        recentScans.insert(result, at: 0)
        if recentScans.count > 10 {
            recentScans.removeLast()
        }
        saveRecentScans()
    }
    
    private func loadRecentScans() {
        // In a real app, this would load from persistent storage
        recentScans = []
    }
    
    private func saveRecentScans() {
        // In a real app, this would save to persistent storage
    }
    
    // MARK: - Scan Result Actions
    func handleScanResultAction(_ action: ScanResultAction) {
        switch action {
        case .approve:
            approveVisit()
        case .reject:
            rejectScan()
        case .viewDetails:
            viewScanDetails()
        }
    }
    
    private func approveVisit() {
        guard let scanResult = lastScanResult else { return }
        
        Task {
            do {
                // Call backend API to verify and approve visit
                try await recordVisit(scanResult)
                await MainActor.run {
                    self.statusMessage = "Visit approved for \(scanResult.influencerName)!"
                    self.lastScanResult = nil
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Failed to approve visit: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func rejectScan() {
        lastScanResult = nil
        statusMessage = "Scan rejected"
    }
    
    private func viewScanDetails() {
        // TODO: Implement scan details view
        statusMessage = "Viewing scan details..."
    }
}

// MARK: - Supporting Models
struct ScanResult: Identifiable {
    let id: UUID
    let influencerName: String
    let campaignTitle: String
    let verificationCode: String
    let timestamp: Date
    let isValid: Bool
}

enum ScanResultAction {
    case approve
    case reject
    case viewDetails
}

// MARK: - Backend Integration
extension BusinessScanViewModel {
    private let apiService = APIService.shared
    
    func recordVisit(_ scanResult: ScanResult) async throws {
        // Extract campaign and influencer info from QR code
        let visitData = [
            "qrCode": scanResult.verificationCode,
            "timestamp": ISO8601DateFormatter().string(from: scanResult.timestamp)
        ]
        
        // Call backend to verify and approve visit
        let _: EmptyResponse = try await apiService.post(
            endpoint: "business/visits/verify",
            body: visitData
        )
    }
} 