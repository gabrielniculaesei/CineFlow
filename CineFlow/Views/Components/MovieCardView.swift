import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    var compact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster image
            PosterImageView(url: compact ? movie.smallPosterURL : movie.posterURL, cornerRadius: 0)
                .frame(height: compact ? 170 : 210)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    // Rating badge
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text(movie.ratingFormatted)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent)
                    .cornerRadius(8)
                    .padding(8)
                }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: compact ? 13 : 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                if let firstGenre = movie.genres.first {
                    Text("\(String(movie.year)) · \(firstGenre.rawValue)")
                        .font(.system(size: compact ? 10 : 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(compact ? 12 : 14)
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 12 : 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
