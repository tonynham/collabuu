import Foundation
import SwiftUI

@MainActor
class DealDetailViewModel: ObservableObject {
    @Published var deal: Deal
    @Published var isFavorited: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingQRCode: Bool = false
    @Published var showingShareSheet: Bool = false
    @Published var showingAddToFavoritesSuccess: Bool = false
    @Published var qrCodeImage: UIImage?
    
    private let apiService = APIService.shared
    
    init(deal: Deal) {
        self.deal = deal
        checkIfFavorited()
        generateQRCode()
    }
    
    func checkIfFavorited() {
        Task {
            do {
                let favorites = try await apiService.getCustomerFavorites()
                await MainActor.run {
                    self.isFavorited = favorites.contains { $0.businessId == self.deal.businessId }
                }
            } catch {
                await MainActor.run {
                    print("Error checking favorites: \(error)")
                    // Fallback to false
                    self.isFavorited = false
                }
            }
        }
    }
    
    func toggleFavorite() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isFavorited {
                    try await apiService.removeCustomerFavorite(businessId: deal.businessId)
                } else {
                    let favoriteRequest = AddFavoriteRequest(
                        businessId: deal.businessId,
                        businessName: deal.businessName,
                        dealId: deal.id
                    )
                    try await apiService.addCustomerFavorite(favoriteRequest)
                }
                
                await MainActor.run {
                    self.isFavorited.toggle()
                    self.isLoading = false
                    
                    if self.isFavorited {
                        self.showingAddToFavoritesSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.showingAddToFavoritesSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update favorites: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func generateQRCode() {
        Task {
            do {
                let qrData = QRCodeData(
                    type: .deal,
                    dealId: deal.id,
                    businessId: deal.businessId,
                    customerId: nil // Will be set by API
                )
                
                let qrImage = try await apiService.generateCustomerQRCode(qrData)
                await MainActor.run {
                    self.qrCodeImage = qrImage
                }
            } catch {
                await MainActor.run {
                    print("Error generating QR code: \(error)")
                    // Generate fallback QR code
                    self.generateFallbackQRCode()
                }
            }
        }
    }
    
    private func generateFallbackQRCode() {
        let qrString = "collabuu://deal/\(deal.id)"
        qrCodeImage = generateQRCodeImage(from: qrString)
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    func showQRCode() {
        showingQRCode = true
    }
    
    func shareQRCode() {
        showingShareSheet = true
    }
    
    func claimDeal() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let claimRequest = ClaimDealRequest(
                    dealId: deal.id,
                    businessId: deal.businessId
                )
                
                try await apiService.claimCustomerDeal(claimRequest)
                
                await MainActor.run {
                    self.isLoading = false
                    // Show success or navigate to claimed deals
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to claim deal: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshDeal() {
        Task {
            do {
                let updatedDeal = try await apiService.getDealDetails(dealId: deal.id)
                await MainActor.run {
                    self.deal = updatedDeal
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to refresh deal: \(error.localizedDescription)"
                }
            }
        }
    }
    
    var shareText: String {
        "Check out this amazing deal from \(deal.businessName): \(deal.title). Get \(deal.creditsReward) credits! Download Collabuu to claim it."
    }
    
    var isExpired: Bool {
        Date() > deal.expiryDate
    }
    
    var timeUntilExpiry: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: deal.expiryDate, relativeTo: Date())
    }
}

struct AddFavoriteRequest: Codable {
    let businessId: String
    let businessName: String
    let dealId: String
}

struct ClaimDealRequest: Codable {
    let dealId: String
    let businessId: String
}

struct QRCodeData: Codable {
    let type: QRCodeType
    let dealId: String?
    let businessId: String
    let customerId: String?
}

enum QRCodeType: String, Codable {
    case deal = "deal"
    case visit = "visit"
    case favorite = "favorite"
} 