import Foundation

struct SupabaseConfig {
    static let shared = SupabaseConfig()
    
    private init() {}
    
    // MARK: - Supabase Configuration
    var supabaseURL: String {
        // Try Info.plist first, then fall back to hardcoded values for development
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        // Development fallback
        return "https://eecixpooqqhifvmpcdnp.supabase.co"
    }
    
    var supabaseAnonKey: String {
        // Try Info.plist first - REQUIRED for production
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        // No fallback - must be configured in Info.plist
        fatalError("SUPABASE_ANON_KEY must be configured in Info.plist")
    }
    
    var supabaseServiceKey: String? {
        // Try Info.plist first - REQUIRED for admin operations
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_KEY") as? String, !key.isEmpty {
            return key
        }
        // No fallback - must be configured in Info.plist for admin operations
        return nil
    }
}

// MARK: - Environment Helper
extension SupabaseConfig {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
    }
} 