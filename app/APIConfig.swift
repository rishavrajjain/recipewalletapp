import Foundation

/// Select which backend you want to hit.
enum APIEnvironment {
    case local
    case production
}

/// Global API configuration
struct APIConfig {
    /// Change this when you need to switch
    static var environment: APIEnvironment = .production
    
    /// Base URL resolved from the current environment
    static var baseURL: URL {
        switch environment {
        case .local:
            return URL(string: "http://192.168.1.7:8000")!
        case .production:
            return URL(string: "https://okra.onrender.com")!
        }
    }
    
    /// Helper for building absolute endpoint URLs
    static func endpoint(_ path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }
} 
