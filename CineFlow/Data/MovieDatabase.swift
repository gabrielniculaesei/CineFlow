import Foundation

// MovieDatabase is kept as a fallback and for sub-mood mapping.
// When TMDB API is configured, all movie data comes from the API.
class MovieDatabase {
    static let shared = MovieDatabase()
    
    // Sub-mood to TMDB genre ID mappings for the questionnaire
    struct SubMoodConfig {
        let label: String
        let icon: String
        let key: String
        let genreIds: [Int]
        let sortBy: String
    }
    
    static let subMoodOptions: [Genre: [SubMoodConfig]] = [
        .romance: [
            SubMoodConfig(label: "Light & Fun", icon: "sun.max.fill", key: "light_romantic", genreIds: [10749, 35], sortBy: "popularity.desc"),
            SubMoodConfig(label: "Deep & Emotional", icon: "drop.fill", key: "deep_romantic", genreIds: [10749, 18], sortBy: "vote_average.desc")
        ],
        .horror: [
            SubMoodConfig(label: "Psychological", icon: "brain.head.profile", key: "psychological_horror", genreIds: [27, 53], sortBy: "vote_average.desc"),
            SubMoodConfig(label: "Supernatural", icon: "eye.trianglebadge.exclamationmark", key: "supernatural_horror", genreIds: [27, 14], sortBy: "popularity.desc")
        ],
        .action: [
            SubMoodConfig(label: "Intense & Gritty", icon: "bolt.fill", key: "intense_action", genreIds: [28, 53], sortBy: "vote_average.desc"),
            SubMoodConfig(label: "Fun & Adventurous", icon: "star.fill", key: "fun_action", genreIds: [28, 12], sortBy: "popularity.desc")
        ],
        .comedy: [
            SubMoodConfig(label: "Laugh Out Loud", icon: "face.smiling.fill", key: "laugh_out_loud", genreIds: [35], sortBy: "popularity.desc"),
            SubMoodConfig(label: "Smart & Witty", icon: "lightbulb.fill", key: "smart_comedy", genreIds: [35, 18], sortBy: "vote_average.desc")
        ],
        .thriller: [
            SubMoodConfig(label: "Mind-Bending", icon: "circle.hexagongrid.fill", key: "mind_bending_thriller", genreIds: [53, 9648], sortBy: "vote_average.desc"),
            SubMoodConfig(label: "Edge of Your Seat", icon: "exclamationmark.triangle.fill", key: "edge_of_seat_thriller", genreIds: [53, 80], sortBy: "vote_average.desc")
        ],
        .sciFi: [
            SubMoodConfig(label: "Epic & Grand", icon: "globe.americas.fill", key: "epic_scifi", genreIds: [878, 12], sortBy: "popularity.desc"),
            SubMoodConfig(label: "Mind-Bending", icon: "waveform.path", key: "mind_bending_scifi", genreIds: [878, 53], sortBy: "vote_average.desc")
        ],
        .drama: [
            SubMoodConfig(label: "Inspiring & Uplifting", icon: "arrow.up.heart.fill", key: "inspiring_drama", genreIds: [18, 10751], sortBy: "vote_average.desc"),
            SubMoodConfig(label: "Intense & Raw", icon: "flame.fill", key: "intense_drama", genreIds: [18, 80], sortBy: "vote_average.desc")
        ],
        .animation: [
            SubMoodConfig(label: "Action-Packed", icon: "bolt.circle.fill", key: "action_animation", genreIds: [16, 28], sortBy: "popularity.desc"),
            SubMoodConfig(label: "Emotional & Deep", icon: "heart.circle.fill", key: "emotional_animation", genreIds: [16, 18], sortBy: "vote_average.desc")
        ]
    ]
}
