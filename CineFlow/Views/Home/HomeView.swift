import SwiftUI

struct HomeView: View {
    @ObservedObject var userProfile: UserProfile
    @State private var selectedMovie: Movie?
    @State private var trendingMovies: [Movie] = []
    @State private var nowPlayingMovies: [Movie] = []
    @State private var topRatedMovies: [Movie] = []
    @State private var popularMovies: [Movie] = []
    @State private var upcomingMovies: [Movie] = []
    @State private var criticallyAcclaimed: [Movie] = []
    @State private var genreMovies: [Genre: [Movie]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                if !APIConfig.isConfigured {
                    apiSetupView
                } else if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppTheme.accent)
                            .scaleEffect(1.2)
                        Text("Loading movies...")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else if let error = errorMessage, trendingMovies.isEmpty && topRatedMovies.isEmpty {
                    errorView(message: error)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                            headerSection
                            
                            if !trendingMovies.isEmpty {
                                movieSection(title: "Trending This Week", movies: trendingMovies)
                            }
                            
                            if !nowPlayingMovies.isEmpty {
                                movieSection(title: " Now Playing", movies: nowPlayingMovies)
                            }
                            
                            if !topRatedMovies.isEmpty {
                                movieSection(title: "Top Rated", movies: topRatedMovies)
                            }
                            
                            if !popularMovies.isEmpty {
                                movieSection(title: "Popular This Month", movies: popularMovies)
                            }
                            
                            if !upcomingMovies.isEmpty {
                                movieSection(title: "Coming Soon", movies: upcomingMovies)
                            }
                            
                            if !criticallyAcclaimed.isEmpty {
                                movieSection(title: "Critically Acclaimed", movies: criticallyAcclaimed)
                            }
                            
                            // Per-genre sections for user's preferences
                            ForEach(userProfile.favoriteGenres, id: \.self) { genre in
                                if let movies = genreMovies[genre], !movies.isEmpty {
                                    movieSection(title: "\(genre.rawValue) for You", movies: movies)
                                }
                            }
                            
                            Spacer(minLength: 30)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie)
            }
            .task {
                await loadMovies()
            }
        }
    }
    
    // MARK: - API Setup View
    private var apiSetupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accent)
            
            Text("TMDB API Key Required")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("To show real movies, you need a free API key:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                setupStep(number: "1", text: "Go to themoviedb.org")
                setupStep(number: "2", text: "Create a free account")
                setupStep(number: "3", text: "Settings → API → Create")
                setupStep(number: "4", text: "Copy your Read Access Token")
                setupStep(number: "5", text: "Paste it in APIConfig.swift")
            }
            .padding(20)
            .glassCard()
        }
        .padding(30)
    }
    
    private func setupStep(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 26, height: 26)
                .background(AppTheme.accent)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accent)
            
            Text("Couldn't load movies")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                isLoading = true
                errorMessage = nil
                Task { await loadMovies() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppTheme.goldGradient)
                .cornerRadius(14)
            }
        }
        .padding(30)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hey, \(userProfile.name)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("What are we watching today?")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text(String(userProfile.name.prefix(1)).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private func movieSection(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(movies) { movie in
                        Button {
                            selectedMovie = movie
                        } label: {
                            MovieCardView(movie: movie)
                                .frame(width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMovies() async {
        guard APIConfig.isConfigured else {
            await MainActor.run { isLoading = false }
            return
        }
        
        do {
            // Load primary sections in parallel
            async let trending = TMDBService.shared.fetchTrending()
            async let nowPlaying = TMDBService.shared.fetchNowPlaying()
            async let topRated = TMDBService.shared.fetchTopRated()
            async let popular = TMDBService.shared.fetchPopular()
            async let upcoming = TMDBService.shared.fetchUpcoming()
            async let acclaimed = TMDBService.shared.fetchTopRated(page: 2)
            
            let (t, np, tr, pop, up, acc) = try await (trending, nowPlaying, topRated, popular, upcoming, acclaimed)
            
            await MainActor.run {
                trendingMovies = t
                nowPlayingMovies = np
                topRatedMovies = tr
                popularMovies = pop
                upcomingMovies = up
                criticallyAcclaimed = acc
            }
            
            // Load genre-specific movies
            for genre in userProfile.favoriteGenres {
                do {
                    let movies = try await TMDBService.shared.discoverByGenre(genre)
                    await MainActor.run {
                        genreMovies[genre] = Array(movies.prefix(15))
                    }
                } catch {
                    // Skip this genre silently
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
