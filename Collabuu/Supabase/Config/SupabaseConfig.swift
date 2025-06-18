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
        // Try Info.plist first, then fall back to hardcoded values for development
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        // Development fallback
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlY2l4cG9vcXFoaWZ2bXBjZG5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMzY0ODksImV4cCI6MjA2MjkxMjQ4OX0.Bgwyp5yMwZwQbP05cllIcfMT0f3x1UhRPMYEXEBjnlM"
    }
    
    var supabaseServiceKey: String? {
        // Try Info.plist first, then fall back to hardcoded values for development
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_KEY") as? String, !key.isEmpty {
            return key
        }
        // Development fallback
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlY2l4cG9vcXFoaWZ2bXBjZG5wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzMzNjQ4OSwiZXhwIjoyMDYyOTEyNDg5fQ.Jc70iM3MLimK_pa53_1PMaXEYdMimVnpWLJNMynBUeU"
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