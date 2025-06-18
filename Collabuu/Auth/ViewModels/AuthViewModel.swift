import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSignUp = false
    @Published var showForgotPassword = false
    @Published var forgotPasswordEmail = ""
    @Published var forgotPasswordSent = false
    
    // Form State
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var selectedUserType: UserType = .customer
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var username = ""
    
    // Validation
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe auth state from APIService
        apiService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        // Observe current user from APIService
        apiService.$currentUser
            .receive(on: DispatchQueue.main)
            .map { user in
                guard let user = user else { return nil }
                return UserProfile(
                    id: UUID(uuidString: user.id) ?? UUID(),
                    email: user.email,
                    userType: user.userType,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    username: user.username,
                    profileImageUrl: user.profileImageUrl,
                    bio: user.bio,
                    createdAt: user.createdAt
                )
            }
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
        
        // Setup form validation
        setupValidation()
        
        // Clear errors when user starts typing
        setupErrorClearing()
    }
    
    // MARK: - Authentication Actions
    func signIn() async {
        guard validateSignInForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("🔐 Starting sign in for: \(email)")
        
        do {
            // Determine user type from email for now (you can improve this later)
            let userType = determineUserTypeFromEmail(email)
            try await apiService.signIn(email: email, password: password, userType: userType)
            print("✅ API sign in successful")
        } catch {
            print("❌ API sign in failed: \(error)")
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard validateSignUpForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let additionalData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "username": username.isEmpty ? nil : username
            ].compactMapValues { $0 }
            
            try await apiService.signUp(
                email: email,
                password: password,
                userType: selectedUserType,
                additionalData: additionalData
            )
            print("✅ API sign up successful")
        } catch {
            print("❌ API sign up failed: \(error)")
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await apiService.signOut()
            currentUser = nil
            clearForm()
        } catch {
            errorMessage = "Failed to sign out"
        }
    }
    
    private func determineUserTypeFromEmail(_ email: String) -> UserType {
        if email.contains("business") {
            return .business
        } else if email.contains("influencer") {
            return .influencer
        } else {
            return .customer
        }
    }
    
    func sendPasswordReset() async {
        guard !forgotPasswordEmail.isEmpty, isValidEmail(forgotPasswordEmail) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.sendPasswordReset(email: forgotPasswordEmail)
            forgotPasswordSent = true
        } catch {
            errorMessage = "Failed to send password reset email. Please try again."
        }
        
        isLoading = false
    }
    
    func resendEmailVerification() async {
        guard currentUser != nil else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.resendEmailVerification()
            errorMessage = "Verification email sent successfully"
        } catch {
            errorMessage = "Failed to send verification email"
        }
        
        isLoading = false
    }
    
    // MARK: - User Profile
    private func loadUserProfile() async {
        guard let user = supabaseService.currentUser else { 
            print("❌ No current user found in loadUserProfile")
            return 
        }
        
        print("🔄 Loading user profile for user ID: \(user.id)")
        
        do {
            let profiles: [UserProfile] = try await supabaseService.fetch(
                UserProfile.self,
                from: "user_profiles"
            )
            
            print("📊 Found \(profiles.count) profiles in database")
            for profile in profiles {
                print("📋 Profile: ID=\(profile.id), Email=\(profile.email), Type=\(profile.userType)")
            }
            
            currentUser = profiles.first { $0.id == user.id }
            
            if let currentUser = currentUser {
                print("✅ Successfully loaded user profile: \(currentUser.email) as \(currentUser.userType)")
            } else {
                print("❌ No profile found for user ID: \(user.id)")
            }
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
    }
    
    // MARK: - Form Validation
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { email in
                if email.isEmpty {
                    return nil
                } else if !self.isValidEmail(email) {
                    return "Please enter a valid email address"
                } else {
                    return nil
                }
            }
            .assign(to: \.emailError, on: self)
            .store(in: &cancellables)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { password in
                if password.isEmpty {
                    return nil
                } else if password.count < 6 {
                    return "Password must be at least 6 characters"
                } else {
                    return nil
                }
            }
            .assign(to: \.passwordError, on: self)
            .store(in: &cancellables)
        
        // Confirm password validation
        Publishers.CombineLatest($password, $confirmPassword)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { password, confirmPassword in
                if confirmPassword.isEmpty {
                    return nil
                } else if password != confirmPassword {
                    return "Passwords do not match"
                } else {
                    return nil
                }
            }
            .assign(to: \.confirmPasswordError, on: self)
            .store(in: &cancellables)
    }
    
    private func setupErrorClearing() {
        // Clear general error message when user types
        Publishers.CombineLatest($email, $password)
            .sink { _ in
                if self.errorMessage != nil {
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateSignInForm() -> Bool {
        emailError = nil
        passwordError = nil
        
        var isValid = true
        
        if email.isEmpty {
            emailError = "Email is required"
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        }
        
        return isValid
    }
    
    private func validateSignUpForm() -> Bool {
        let isSignInValid = validateSignInForm()
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            return false
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            return false
        }
        
        return isSignInValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        username = ""
        forgotPasswordEmail = ""
        forgotPasswordSent = false
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil
    }
    
    // MARK: - Helper Methods
    func clearErrors() {
        errorMessage = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid login credentials") || errorMessage.contains("invalid email or password") {
            return "Invalid email or password"
        } else if errorMessage.contains("email already registered") || errorMessage.contains("user already registered") {
            return "An account with this email already exists"
        } else if errorMessage.contains("weak password") {
            return "Password is too weak. Please choose a stronger password"
        } else if errorMessage.contains("invalid email") {
            return "Please enter a valid email address"
        } else if errorMessage.contains("network") || errorMessage.contains("connection") {
            return "Connection error. Please check your internet and try again"
        } else if errorMessage.contains("rate limit") {
            return "Too many attempts. Please wait a moment and try again"
        } else {
            return "Something went wrong. Please try again"
        }
    }
    
    // MARK: - Navigation Helpers
    func getUserTypeColor() -> Color {
        switch selectedUserType {
        case .influencer: return AppColors.influencerColor
        case .business: return AppColors.businessColor
        case .customer: return AppColors.customerColor
        }
    }
} 