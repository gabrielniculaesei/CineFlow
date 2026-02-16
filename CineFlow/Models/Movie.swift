import Foundation

struct Movie: Identifiable, Hashable {
    let id: UUID
    let tmdbId: Int?
    let title: String
    let year: Int
    let genres: [Genre]
    let plot: String
    let imdbRating: Double
    let posterPath: String?
    let backdropPath: String?
    let keywords: [String]
    let subMood: [String]
    
    init(
        tmdbId: Int? = nil,
        title: String,
        year: Int,
        genres: [Genre],
        plot: String,
        imdbRating: Double,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        keywords: [String] = [],
        subMood: [String] = []
    ) {
        self.id = UUID()
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.genres = genres
        self.plot = plot
        self.imdbRating = imdbRating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.keywords = keywords
        self.subMood = subMood
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return APIConfig.posterURL(path: path)
    }
    
    var smallPosterURL: URL? {
        guard let path = posterPath else { return nil }
        return APIConfig.posterURL(path: path, size: .medium)
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return APIConfig.backdropURL(path: path)
    }
    
    var ratingFormatted: String {
        String(format: "%.1f", imdbRating)
    }
    
    var genreText: String {
        genres.map { $0.rawValue }.joined(separator: " · ")
    }
    
    func similarityScore(to other: Movie) -> Int {
        let sharedGenres = Set(genres).intersection(Set(other.genres)).count
        let sharedKeywords = Set(keywords.map { $0.lowercased() })
            .intersection(Set(other.keywords.map { $0.lowercased() })).count
        return sharedGenres * 3 + sharedKeywords * 2
    }
}
