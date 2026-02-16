import Foundation

enum Genre: String, CaseIterable, Codable, Identifiable {
    case action = "Action"
    case comedy = "Comedy"
    case drama = "Drama"
    case horror = "Horror"
    case romance = "Romance"
    case sciFi = "Sci-Fi"
    case thriller = "Thriller"
    case animation = "Animation"
    case mystery = "Mystery"
    case adventure = "Adventure"
    case crime = "Crime"
    case fantasy = "Fantasy"
    
    var id: String { rawValue }
    
    // TMDB genre IDs for API requests
    var tmdbId: Int? {
        switch self {
        case .action: return 28
        case .comedy: return 35
        case .drama: return 18
        case .horror: return 27
        case .romance: return 10749
        case .sciFi: return 878
        case .thriller: return 53
        case .animation: return 16
        case .mystery: return 9648
        case .adventure: return 12
        case .crime: return 80
        case .fantasy: return 14
        }
    }
    
    var icon: String {
        switch self {
        case .action: return "flame.fill"
        case .comedy: return "face.smiling.fill"
        case .drama: return "theatermasks.fill"
        case .horror: return "eye.fill"
        case .romance: return "heart.fill"
        case .sciFi: return "sparkles"
        case .thriller: return "bolt.fill"
        case .animation: return "paintbrush.fill"
        case .mystery: return "magnifyingglass"
        case .adventure: return "mountain.2.fill"
        case .crime: return "shield.fill"
        case .fantasy: return "wand.and.stars"
        }
    }
    
    static func fromTMDBId(_ id: Int) -> Genre? {
        allCases.first { $0.tmdbId == id }
    }
}
