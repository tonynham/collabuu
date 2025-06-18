import Foundation
import SwiftUI

@MainActor
class PurchaseCreditsViewModel: ObservableObject {
    @Published var currentCredits: Int = 0
    @Published var creditPackages: [CreditPackage] = []
    @Published var selectedPackage: CreditPackage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPayment = false
    @Published var showingPurchaseSuccess = false
    @Published var purchaseSuccessMessage = ""
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    
    private let apiService = APIService.shared
    
    init() {
        loadCreditPackages()
        loadCurrentBalance()
    }
    
    func loadCreditPackages() {
        // Credit packages matching the screenshot
        creditPackages = [
            CreditPackage(
                id: "100",
                credits: 100,
                points: 100,
                pointsPerCredit: 1,
                discount: nil,
                isBestValue: false
            ),
            CreditPackage(
                id: "500",
                credits: 500,
                points: 450,
                pointsPerCredit: 0,
                discount: 10,
                isBestValue: false
            ),
            CreditPackage(
                id: "1000",
                credits: 1000,
                points: 800,
                pointsPerCredit: 0,
                discount: 20,
                isBestValue: false
            ),
            CreditPackage(
                id: "2000",
                credits: 2000,
                points: 1400,
                pointsPerCredit: 0,
                discount: 30,
                isBestValue: true
            )
        ]
        
        // Auto-select the 500 credits package (as shown in screenshot)
        selectedPackage = creditPackages.first { $0.credits == 500 }
    }
    
    func loadCurrentBalance() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let balance = try await apiService.getBusinessCreditBalance()
                await MainActor.run {
                    self.currentCredits = balance
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading balance: \(error)")
                    
                    // Fallback to sample data
                    self.currentCredits = 250 // Sample balance
                }
            }
        }
    }
    
    func selectPackage(_ package: CreditPackage) {
        selectedPackage = package
    }
    
    func purchaseCredits() {
        guard let package = selectedPackage else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let purchaseRequest = CreditPurchaseRequest(
                    packageId: package.id,
                    credits: package.credits,
                    amount: Double(package.points),
                    paymentMethod: selectedPaymentMethod
                )
                
                let transaction = try await apiService.purchaseBusinessCredits(purchaseRequest)
                
                await MainActor.run {
                    self.currentCredits += package.credits
                    self.isLoading = false
                    self.showingPayment = false
                    self.purchaseSuccessMessage = "Successfully purchased \(package.credits) credits!"
                    self.showingPurchaseSuccess = true
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.showingPurchaseSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func startPaymentFlow() {
        guard selectedPackage != nil else { return }
        showingPayment = true
    }
    
    func cancelPayment() {
        showingPayment = false
    }
    
    func refreshBalance() {
        loadCurrentBalance()
    }
    
    func dismissPurchaseSuccess() {
        showingPurchaseSuccess = false
    }
    
    var selectedPackageTotal: Int {
        return selectedPackage?.points ?? 0
    }
}

enum PaymentMethod: String, CaseIterable {
    case creditCard = "credit_card"
    case paypal = "paypal"
    case applePay = "apple_pay"
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .paypal: return "PayPal"
        case .applePay: return "Apple Pay"
        }
    }
    
    var icon: String {
        switch self {
        case .creditCard: return "creditcard"
        case .paypal: return "p.circle"
        case .applePay: return "applelogo"
        }
    }
}

struct CreditPurchaseRequest: Codable {
    let packageId: String
    let credits: Int
    let amount: Double
    let paymentMethod: PaymentMethod
}

struct CreditTransaction: Codable {
    let id: String
    let credits: Int
    let amount: Double
    let paymentMethod: PaymentMethod
    let status: String
    let createdAt: Date
} 