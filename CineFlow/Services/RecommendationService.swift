import Foundation

// MARK: - Recommendation Service

class RecommendationService {
    static let shared = RecommendationService()
    private let session = URLSession.shared
    
    // MARK: - Fetch ML Recommendations
    
    func fetchRecommendations(movieId: Int, limit: Int = 10) async throws -> [Movie] {
        let url = URL(string: "\(APIConfig.mlAPIBaseURL)/recommend")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10  // Don't wait too long if API is down
        
        let body = MLRecommendRequest(movieId: movieId, limit: limit)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecommendationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RecommendationError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let mlResponse = try decoder.decode(MLRecommendResponse.self, from: data)
        
        return mlResponse.recommendations.map { $0.toMovie() }
    }
    
    // MARK: - Health Check
    
    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(APIConfig.mlAPIBaseURL)/health") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - API Request/Response Models

private struct MLRecommendRequest: Encodable {
    let movieId: Int
    let limit: Int
    
    enum CodingKeys: String, CodingKey {
        case movieId = "movie_id"
        case limit
    }
}

struct MLRecommendResponse: Decodable {
    let sourceMovieId: Int
    let recommendations: [MLRecommendedMovie]
    let modelVersion: String
}

struct MLRecommendedMovie: Decodable {
    let tmdbId: Int
    let title: String
    let year: Int
    let genreIds: [Int]
    let overview: String
    let voteAverage: Double
    let posterPath: String?
    let backdropPath: String?
    let similarityScore: Double
    
    func toMovie() -> Movie {
        Movie(
            tmdbId: tmdbId,
            title: title,
            year: year,
            genres: genreIds.compactMap { Genre.fromTMDBId($0) },
            plot: overview,
            imdbRating: voteAverage,
            posterPath: posterPath,
            backdropPath: backdropPath,
            keywords: []
        )
    }
}

// MARK: - Errors

enum RecommendationError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case modelUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from recommendation server"
        case .httpError(let code): return "Recommendation API error: \(code)"
        case .modelUnavailable: return "Recommendation model is not available"
        }
    }
}
