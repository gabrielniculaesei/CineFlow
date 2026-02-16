import SwiftUI

struct PosterImageView: View {
    let url: URL?
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    
            case .failure:
                posterPlaceholder
                    
            case .empty:
                ZStack {
                    AppTheme.cardBackground
                    ProgressView()
                        .tint(AppTheme.textTertiary)
                }
                
            @unknown default:
                posterPlaceholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var posterPlaceholder: some View {
        ZStack {
            AppTheme.cardBackgroundLight
            Image(systemName: "film")
                .font(.title2)
                .foregroundColor(AppTheme.textTertiary)
        }
    }
}
