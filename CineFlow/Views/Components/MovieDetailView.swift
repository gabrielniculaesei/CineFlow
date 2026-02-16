import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    @State private var similarMovies: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var showRatingPopup = false
    @ObservedObject private var watchedStore = WatchedMovieStore.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    
                    VStack(spacing: 16) {
                        infoSection
                        watchedButton
                        plotSection
                        
                        if !similarMovies.isEmpty {
                            similarSection
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.top, 8)
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(movie: movie)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIn = true
            }
            loadSimilarMovies()
        }
        .overlay {
            if showRatingPopup {
                ratingPopupOverlay
            }
        }
    }
    
    // MARK: - Hero (zoom fixed — uses .fit instead of .fill)
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if let url = movie.backdropURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        AppTheme.cardBackground
                            .frame(height: 220)
                    } else {
                        AppTheme.cardBackground
                            .frame(height: 220)
                            .overlay(ProgressView().tint(AppTheme.textTertiary))
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, AppTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                PosterImageView(url: movie.posterURL, cornerRadius: 0)
                    .frame(height: 220)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, AppTheme.background],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Poster + Title overlay
            HStack(alignment: .bottom, spacing: 16) {
                PosterImageView(url: movie.posterURL, cornerRadius: 10)
                    .frame(width: 90, height: 135)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
                    .scaleEffect(animateIn ? 1.0 : 0.85)
                    .opacity(animateIn ? 1 : 0)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(movie.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(String(movie.year))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
    }
    
    // MARK: - Watched Button
    private var watchedButton: some View {
        let isWatched = watchedStore.isWatched(movie)
        let currentRating = watchedStore.getRating(for: movie)
        
        return Button {
            showRatingPopup = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "eye.fill")
                    .font(.system(size: 16))
                
                if isWatched, let rating = currentRating {
                    Text("Watched · \(rating.label)")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Text("Mark as Watched")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundColor(isWatched ? .black : AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isWatched
                    ? AnyShapeStyle(AppTheme.goldGradient)
                    : AnyShapeStyle(AppTheme.cardBackground)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isWatched ? Color.clear : AppTheme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Rating Popup
    private var ratingPopupOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showRatingPopup = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("How did you feel about it?")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(movie.title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                VStack(spacing: 12) {
                    ForEach(MovieRating.allCases, id: \.self) { rating in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                watchedStore.addMovie(movie, rating: rating)
                                showRatingPopup = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: rating.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(rating.color)
                                    .frame(width: 30)
                                
                                Text(rating.label)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                if watchedStore.getRating(for: movie) == rating {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(rating.color.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showRatingPopup = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(.top, 4)
                }
            }
            .padding(24)
            .background(AppTheme.background)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Info
    private var infoSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppTheme.accent)
                    Text(movie.ratingFormatted)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                    Text("/ 10")
                        .font(.callout)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(AppTheme.accent.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(movie.genres) { genre in
                        HStack(spacing: 5) {
                            Image(systemName: genre.icon)
                                .font(.caption2)
                            Text(genre.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.genreColor(for: genre))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.genreColor(for: genre).opacity(0.12))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Plot
    private var plotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storyline")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(movie.plot)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Similar Movies
    private var similarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("You might also like")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(similarMovies) { similar in
                        Button {
                            selectedMovie = similar
                        } label: {
                            MovieCardView(movie: similar, compact: true)
                                .frame(width: 130)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadSimilarMovies() {
        guard let tmdbId = movie.tmdbId else { return }
        Task {
            do {
                let movies = try await TMDBService.shared.fetchSimilar(movieId: tmdbId)
                await MainActor.run {
                    similarMovies = Array(movies.prefix(10))
                }
            } catch {
                // Silent fail
            }
        }
    }
}
