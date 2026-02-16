import Foundation

// MARK: - TMDB API Response Models

struct TMDBMovieResponse: Codable {
    let page: Int
    let results: [TMDBMovie]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIds = "genre_ids"
    }
    
    var year: Int {
        guard let dateStr = releaseDate, dateStr.count >= 4 else { return 0 }
        return Int(dateStr.prefix(4)) ?? 0
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return APIConfig.posterURL(path: path)
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return APIConfig.backdropURL(path: path)
    }
    
    func toMovie() -> Movie {
        Movie(
            tmdbId: id,
            title: title,
            year: year,
            genres: resolvedGenres,
            plot: overview,
            imdbRating: voteAverage,
            posterPath: posterPath,
            backdropPath: backdropPath,
            keywords: []
        )
    }
    
    private var resolvedGenres: [Genre] {
        let ids = genreIds ?? genres?.map { $0.id } ?? []
        return ids.compactMap { Genre.fromTMDBId($0) }
    }
}

struct TMDBGenre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct TMDBGenreResponse: Codable {
    let genres: [TMDBGenre]
}
