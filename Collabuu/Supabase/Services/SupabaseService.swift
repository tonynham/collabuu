import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private init() {
        let config = SupabaseConfig.shared
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: config.supabaseURL)!,
            supabaseKey: config.supabaseAnonKey
        )
        
        // Check initial auth state
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication
    func checkAuthState() async {
        // Clear any existing session to force manual login
        do {
            try await client.auth.signOut()
        } catch {
            // Ignore errors when signing out (user might not be logged in)
        }
        
        // Always set to not authenticated to require manual login
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)
        self.currentUser = response.user
        self.isAuthenticated = true
    }
    
    func signUp(email: String, password: String, userType: UserType) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        
        // Create user profile with type
        let user = response.user
        try await createUserProfile(userId: user.id, email: email, userType: userType)
        
        self.currentUser = response.user
        self.isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    func resetPassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }
    
    // MARK: - Email Verification
    func resendEmailVerification() async throws {
        try await client.auth.resend(email: currentUser?.email ?? "", type: .signup)
    }
    

    
    // MARK: - Database Operations
    private func createUserProfile(userId: UUID, email: String, userType: UserType) async throws {
        let profile = UserProfile(
            id: userId,
            email: email,
            userType: userType.rawValue,
            createdAt: Date()
        )
        
        try await client
            .from("user_profiles")
            .insert(profile)
            .execute()
    }
    
    // MARK: - Generic Database Methods
    func fetch<T: Codable>(_ type: T.Type, from table: String) async throws -> [T] {
        let response: [T] = try await client
            .from(table)
            .select()
            .execute()
            .value
        
        return response
    }
    
    func insert<T: Codable>(_ data: T, into table: String) async throws {
        try await client
            .from(table)
            .insert(data)
            .execute()
    }
    
    func update<T: Codable>(_ data: T, in table: String, matching column: String, value: String) async throws {
        try await client
            .from(table)
            .update(data)
            .eq(column, value: value)
            .execute()
    }
} 