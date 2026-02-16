import Foundation

enum APIConfig {
    // MARK: - TMDB API Configuration
    static let tmdbAPIKey = "YOUR_TMDB_API_KEY"
    
    static let tmdbBaseURL = "https://api.themoviedb.org/3"
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"
    
    static var isConfigured: Bool {
        !tmdbAPIKey.isEmpty && tmdbAPIKey != "YOUR_API_KEY_HERE"
    }
    
    // MARK: - Ollama Configuration (Local)
    static let ollamaBaseURL = "http://localhost:11434"
    static let ollamaModel = "llama3.2"
    
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
