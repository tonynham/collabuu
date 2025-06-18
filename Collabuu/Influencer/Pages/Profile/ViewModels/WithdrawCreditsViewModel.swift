import Foundation
import SwiftUI

@MainActor
class WithdrawCreditsViewModel: ObservableObject {
    @Published var availableCredits: Int = 0
    @Published var withdrawalAmountText: String = ""
    @Published var selectedMethod: WithdrawalMethod = .paypal
    @Published var paypalEmail: String = ""
    @Published var transactions: [WithdrawalTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingWithdrawalSuccess = false
    @Published var lastWithdrawalAmount: Int = 0
    
    private let apiService = APIService.shared
    private let creditValue: Double = 0.01 // $0.01 per credit
    private let minimumWithdrawal: Int = 100
    
    init() {
        loadBalance()
        loadTransactionHistory()
    }
    
    var availableValue: Double {
        return Double(availableCredits) * creditValue
    }
    
    var withdrawalAmount: Int {
        return Int(withdrawalAmountText) ?? 0
    }
    
    var withdrawalValue: Double {
        return Double(withdrawalAmount) * creditValue
    }
    
    var canWithdraw: Bool {
        guard withdrawalAmount >= minimumWithdrawal else { return false }
        guard withdrawalAmount <= availableCredits else { return false }
        
        switch selectedMethod {
        case .paypal:
            return !paypalEmail.isEmpty && isValidEmail(paypalEmail)
        case .bankTransfer:
            return true // Additional bank details would be required in real implementation
        }
    }
    
    func loadBalance() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let credits = try await apiService.getInfluencerCredits()
                await MainActor.run {
                    self.availableCredits = credits
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading credits: \(error)")
                    
                    // Fallback to sample data for development
                    self.availableCredits = 250 // Sample data
                }
            }
        }
    }
    
    func loadTransactionHistory() {
        Task {
            do {
                let history = try await apiService.getWithdrawalHistory()
                await MainActor.run {
                    self.transactions = history
                }
            } catch {
                await MainActor.run {
                    print("Error loading transaction history: \(error)")
                    // Fallback to empty array for development
                    self.transactions = []
                }
            }
        }
    }
    
    func setMaxAmount() {
        withdrawalAmountText = "\(availableCredits)"
    }
    
    func setPercentageAmount(_ percentage: Int) {
        let amount = (Double(availableCredits) * Double(percentage) / 100.0).rounded()
        withdrawalAmountText = "\(Int(amount))"
    }
    
    func requestWithdrawal() {
        guard canWithdraw else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let withdrawalRequest = WithdrawalRequest(
                    amount: withdrawalAmount,
                    method: selectedMethod,
                    paypalEmail: selectedMethod == .paypal ? paypalEmail : nil
                )
                
                try await apiService.requestWithdrawal(withdrawalRequest)
                
                await MainActor.run {
                    self.lastWithdrawalAmount = self.withdrawalAmount
                    self.availableCredits -= self.withdrawalAmount
                    self.showingWithdrawalSuccess = true
                    self.withdrawalAmountText = ""
                    self.paypalEmail = ""
                    self.isLoading = false
                    
                    // Refresh transaction history
                    self.loadTransactionHistory()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func dismissWithdrawalSuccess() {
        showingWithdrawalSuccess = false
        lastWithdrawalAmount = 0
    }
    
    func refreshData() {
        loadBalance()
        loadTransactionHistory()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct WithdrawalRequest: Codable {
    let amount: Int
    let method: WithdrawalMethod
    let paypalEmail: String?
}

enum WithdrawalMethod: String, Codable, CaseIterable {
    case paypal
    case bankTransfer
    
    var displayName: String {
        switch self {
        case .paypal:
            return "PayPal"
        case .bankTransfer:
            return "Bank Transfer"
        }
    }
}

struct WithdrawalTransaction: Identifiable, Codable {
    let id: String
    let amount: Int
    let value: Double
    let method: WithdrawalMethod
    let status: WithdrawalStatus
    let requestedAt: Date
    let processedAt: Date?
    
    var formattedAmount: String {
        return "\(amount) Credits"
    }
    
    var formattedValue: String {
        return "US$\(String(format: "%.2f", value))"
    }
}

enum WithdrawalStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
} 