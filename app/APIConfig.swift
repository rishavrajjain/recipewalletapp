import Foundation

/// Select which backend you want to hit.
enum APIEnvironment {
    case local
    case production
}

/// Global API configuration
struct APIConfig {
    /// Change this when you need to switch
    static var environment: APIEnvironment = .local
    
    /// Base URL resolved from the current environment
    static var baseURL: URL {
        switch environment {
        case .local:
            return URL(string: "http://localhost:8000")!
        case .production:
            return URL(string: "https://recipewallet.onrender.com")!
        }
    }
    
    /// Helper for building absolute endpoint URLs
    static func endpoint(_ path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }
} 
