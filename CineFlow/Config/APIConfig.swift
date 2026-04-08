import Foundation

enum APIConfig {
    // MARK: - TMDB API Configuration
    static let tmdbAPIKey = Secrets.tmdbAPIKey
    
    static let tmdbBaseURL = "https://api.themoviedb.org/3"
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"
    
    static var isConfigured: Bool {
        !tmdbAPIKey.isEmpty && tmdbAPIKey != "YOUR_API_KEY_HERE"
    }
    
    // MARK: - ML API Configuration (Backend)
    // For local development: http://localhost:8000
    // For production: https://your-app.onrender.com
    static let mlAPIBaseURL = "http://localhost:8000"
    
    // Image sizes
    enum PosterSize: String {
        case small = "/w185"
        case medium = "/w342"
        case large = "/w500"
        case original = "/original"
    }
    
    static func posterURL(path: String, size: PosterSize = .large) -> URL? {
        URL(string: "\(tmdbImageBaseURL)\(size.rawValue)\(path)")
    }
    
    static func backdropURL(path: String) -> URL? {
        URL(string: "\(tmdbImageBaseURL)/w780\(path)")
    }
}
