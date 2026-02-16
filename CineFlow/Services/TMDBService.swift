import Foundation

class TMDBService {
    static let shared = TMDBService()
    private let session = URLSession.shared
    
    // MARK: - Trending Movies
    
    func fetchTrending() async throws -> [Movie] {
        let url = buildURL(path: "/trending/movie/week")
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Popular Movies
    
    func fetchPopular(page: Int = 1) async throws -> [Movie] {
        let url = buildURL(path: "/movie/popular", params: ["page": "\(page)"])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Top Rated
    
    func fetchTopRated(page: Int = 1) async throws -> [Movie] {
        let url = buildURL(path: "/movie/top_rated", params: ["page": "\(page)"])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Now Playing
    
    func fetchNowPlaying(page: Int = 1) async throws -> [Movie] {
        let url = buildURL(path: "/movie/now_playing", params: ["page": "\(page)"])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Upcoming
    
    func fetchUpcoming(page: Int = 1) async throws -> [Movie] {
        let url = buildURL(path: "/movie/upcoming", params: ["page": "\(page)"])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Discover by Genre
    
    func discoverByGenre(_ genre: Genre, page: Int = 1) async throws -> [Movie] {
        guard let tmdbId = genre.tmdbId else { return [] }
        let url = buildURL(path: "/discover/movie", params: [
            "with_genres": "\(tmdbId)",
            "sort_by": "vote_average.desc",
            "vote_count.gte": "200",
            "page": "\(page)"
        ])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Discover by Multiple Genres (for sub-moods)
    
    func discoverByGenres(_ genreIds: [Int], sortBy: String = "vote_average.desc", page: Int = 1) async throws -> [Movie] {
        let genreStr = genreIds.map { "\($0)" }.joined(separator: ",")
        let url = buildURL(path: "/discover/movie", params: [
            "with_genres": genreStr,
            "sort_by": sortBy,
            "vote_count.gte": "100",
            "page": "\(page)"
        ])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Search Movies
    
    func searchMovies(query: String, page: Int = 1) async throws -> [Movie] {
        let url = buildURL(path: "/search/movie", params: [
            "query": query,
            "page": "\(page)"
        ])
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Similar Movies
    
    func fetchSimilar(movieId: Int) async throws -> [Movie] {
        let url = buildURL(path: "/movie/\(movieId)/similar")
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Movie Details
    
    func fetchMovieDetails(movieId: Int) async throws -> Movie {
        let url = buildURL(path: "/movie/\(movieId)")
        let tmdb: TMDBMovie = try await request(url: url)
        return tmdb.toMovie()
    }
    
    // MARK: - Recommendations
    
    func fetchRecommendations(movieId: Int) async throws -> [Movie] {
        let url = buildURL(path: "/movie/\(movieId)/recommendations")
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Generic Fetch (for custom URLs)
    
    func fetchFromURL(url: URL) async throws -> [Movie] {
        let response: TMDBMovieResponse = try await request(url: url)
        return response.results.map { $0.toMovie() }
    }
    
    // MARK: - Private Helpers
    
    private func buildURL(path: String, params: [String: String] = [:]) -> URL {
        var components = URLComponents(string: APIConfig.tmdbBaseURL + path)!
        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: "api_key", value: APIConfig.tmdbAPIKey))
        queryItems.append(URLQueryItem(name: "language", value: "en-US"))
        components.queryItems = queryItems
        return components.url!
    }
    
    private func request<T: Codable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum TMDBError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error: \(code)"
        case .notConfigured: return "TMDB API key not configured"
        }
    }
}
