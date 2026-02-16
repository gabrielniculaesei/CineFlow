import Foundation
import SwiftUI

/// Stores watched movies with user ratings, persisted in UserDefaults
class WatchedMovieStore: ObservableObject {
    static let shared = WatchedMovieStore()
    
    @Published private(set) var watchedMovies: [WatchedMovie] = []
    
    private let storageKey = "cineflow_watched_movies"
    
    init() {
        load()
    }
    
    func addMovie(_ movie: Movie, rating: MovieRating) {
        // Avoid duplicates (by tmdbId or title+year)
        if let index = watchedMovies.firstIndex(where: { $0.matches(movie) }) {
            watchedMovies[index].rating = rating
            watchedMovies[index].dateWatched = Date()
        } else {
            let watched = WatchedMovie(
                tmdbId: movie.tmdbId,
                title: movie.title,
                year: movie.year,
                posterPath: movie.posterPath,
                genreText: movie.genreText,
                imdbRating: movie.imdbRating,
                rating: rating,
                dateWatched: Date()
            )
            watchedMovies.insert(watched, at: 0)
        }
        save()
    }
    
    func removeMovie(_ watched: WatchedMovie) {
        watchedMovies.removeAll { $0.id == watched.id }
        save()
    }
    
    func isWatched(_ movie: Movie) -> Bool {
        watchedMovies.contains { $0.matches(movie) }
    }
    
    func getRating(for movie: Movie) -> MovieRating? {
        watchedMovies.first { $0.matches(movie) }?.rating
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(watchedMovies) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let movies = try? JSONDecoder().decode([WatchedMovie].self, from: data) {
            watchedMovies = movies
        }
    }
}

struct WatchedMovie: Identifiable, Codable, Hashable {
    let id: UUID
    let tmdbId: Int?
    let title: String
    let year: Int
    let posterPath: String?
    let genreText: String
    let imdbRating: Double
    var rating: MovieRating
    var dateWatched: Date
    
    init(tmdbId: Int?, title: String, year: Int, posterPath: String?, genreText: String, imdbRating: Double, rating: MovieRating, dateWatched: Date) {
        self.id = UUID()
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.posterPath = posterPath
        self.genreText = genreText
        self.imdbRating = imdbRating
        self.rating = rating
        self.dateWatched = dateWatched
    }
    
    func matches(_ movie: Movie) -> Bool {
        if let tmdbId = tmdbId, let movieTmdbId = movie.tmdbId {
            return tmdbId == movieTmdbId
        }
        return title == movie.title && year == movie.year
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return APIConfig.posterURL(path: path, size: .medium)
    }
    
    var ratingFormatted: String {
        String(format: "%.1f", imdbRating)
    }
}

enum MovieRating: String, Codable, CaseIterable {
    case disliked
    case liked
    case loved
    
    var label: String {
        switch self {
        case .disliked: return "Didn't Like It"
        case .liked: return "Liked It"
        case .loved: return "Loved It"
        }
    }
    
    var icon: String {
        switch self {
        case .disliked: return "hand.thumbsdown.fill"
        case .liked: return "hand.thumbsup.fill"
        case .loved: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .disliked: return .red
        case .liked: return .blue
        case .loved: return Color(red: 1.0, green: 0.75, blue: 0.0)
        }
    }
}
