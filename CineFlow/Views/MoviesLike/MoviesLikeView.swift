import SwiftUI

struct MoviesLikeView: View {
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var selectedSourceMovie: Movie?
    @State private var similarMovies: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var showingSimilar = false
    @State private var isSearching = false
    @State private var isLoadingSimilar = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Movies Like...")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("beta")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.accent.opacity(0.15))
                                .cornerRadius(6)
                        }
                        
                        Text("Find similar movies to your favorites")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.textTertiary)
                            
                            TextField("Search a movie...", text: $searchText)
                                .foregroundColor(AppTheme.textPrimary)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    performSearch()
                                }
                            
                            if isSearching {
                                ProgressView()
                                    .tint(AppTheme.textTertiary)
                                    .scaleEffect(0.8)
                            }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    searchResults = []
                                    showingSimilar = false
                                    selectedSourceMovie = nil
                                    similarMovies = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                            }
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if showingSimilar, let source = selectedSourceMovie {
                                similarMoviesSection(source: source)
                            } else if !searchResults.isEmpty {
                                searchResultsSection
                            } else if isSearching {
                                ProgressView()
                                    .tint(AppTheme.accent)
                                    .padding(.top, 60)
                            } else {
                                suggestionsSection
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 3 {
                    performSearch()
                } else if newValue.isEmpty {
                    searchResults = []
                    showingSimilar = false
                }
            }
        }
    }
    
    // MARK: - Search
    private func performSearch() {
        guard searchText.count >= 2 else { return }
        isSearching = true
        showingSimilar = false
        Task {
            do {
                let results = try await TMDBService.shared.searchMovies(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    // MARK: - Search Results
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a movie to find similar ones")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            ForEach(searchResults) { movie in
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        selectedSourceMovie = movie
                        showingSimilar = true
                        loadSimilarMovies(for: movie)
                    }
                } label: {
                    searchResultRow(movie: movie)
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
    }
    
    private func searchResultRow(movie: Movie) -> some View {
        HStack(spacing: 14) {
            PosterImageView(url: movie.smallPosterURL, cornerRadius: 8)
                .frame(width: 50, height: 72)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if movie.year > 0 {
                        Text(String(movie.year))
                    }
                    if !movie.genreText.isEmpty {
                        Text("·")
                        Text(movie.genreText)
                    }
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            Text("Find Similar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(14)
        .glassCard()
    }
    
    // MARK: - Similar Movies
    private func loadSimilarMovies(for movie: Movie) {
        guard let tmdbId = movie.tmdbId else { return }
        isLoadingSimilar = true
        Task {
            do {
                let movies = try await TMDBService.shared.fetchSimilar(movieId: tmdbId)
                await MainActor.run {
                    similarMovies = movies
                    isLoadingSimilar = false
                }
            } catch {
                await MainActor.run {
                    similarMovies = []
                    isLoadingSimilar = false
                }
            }
        }
    }
    
    private func similarMoviesSection(source: Movie) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Source movie
            VStack(spacing: 8) {
                Text("Movies similar to")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack(spacing: 12) {
                    PosterImageView(url: source.smallPosterURL, cornerRadius: 8)
                        .frame(width: 50, height: 72)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.accent)
                            Text(source.ratingFormatted)
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showingSimilar = false
                            selectedSourceMovie = nil
                            searchText = ""
                            searchResults = []
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(8)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(Circle())
                    }
                }
                .padding(16)
                .background(
                    AppTheme.genreColor(for: source.genres.first ?? .drama).opacity(0.08)
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.genreColor(for: source.genres.first ?? .drama).opacity(0.2), lineWidth: 1)
                )
            }
            
            if isLoadingSimilar {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppTheme.accent)
                    Text("Finding similar movies...")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else if similarMovies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No similar movies found")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                Text("\(similarMovies.count) similar movies")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                ForEach(similarMovies) { movie in
                    Button {
                        selectedMovie = movie
                    } label: {
                        similarMovieRow(movie: movie)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func similarMovieRow(movie: Movie) -> some View {
        HStack(spacing: 14) {
            PosterImageView(url: movie.smallPosterURL, cornerRadius: 8)
                .frame(width: 55, height: 80)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                Text("\(String(movie.year)) · \(movie.genreText)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.accent)
                    Text(movie.ratingFormatted)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(14)
        .glassCard()
    }
    
    // MARK: - Suggestions
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try searching for...")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            let suggestions = [
                "Contratiempo",
                "Inception",
                "The Notebook",
                "Parasite",
                "Interstellar",
                "Get Out",
            ]
            
            ForEach(suggestions, id: \.self) { title in
                Button {
                    searchText = title
                    performSearch()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "film")
                            .font(.body)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(14)
                    .glassCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
}
