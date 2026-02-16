import SwiftUI

struct ProfileView: View {
    @ObservedObject var userProfile: UserProfile
    @ObservedObject var watchedStore = WatchedMovieStore.shared
    @State private var showResetAlert = false
    @State private var selectedFilter: MovieRating? = nil
    
    var filteredMovies: [WatchedMovie] {
        if let filter = selectedFilter {
            return watchedStore.watchedMovies.filter { $0.rating == filter }
        }
        return watchedStore.watchedMovies
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileHeader
                        statsSection
                        filterSection
                        moviesListSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .alert("Reset Profile?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    userProfile.resetProfile()
                }
            } message: {
                Text("This will clear your name, age, and genre preferences. Your watched movies will be kept.")
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Profile")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                
                Button {
                    showResetAlert = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(10)
                        .background(AppTheme.cardBackground)
                        .clipShape(Circle())
                }
            }
            
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.goldGradient)
                        .frame(width: 64, height: 64)
                    Text(String(userProfile.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfile.name.isEmpty ? "Movie Fan" : userProfile.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if !userProfile.favoriteGenres.isEmpty {
                        Text(userProfile.favoriteGenres.prefix(3).map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(20)
            .glassCard()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Stats
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(watchedStore.watchedMovies.count)",
                label: "Watched",
                icon: "eye.fill"
            )
            
            statCard(
                value: "\(watchedStore.watchedMovies.filter { $0.rating == .loved }.count)",
                label: "Loved",
                icon: "heart.fill"
            )
            
            statCard(
                value: avgRating,
                label: "Avg Rating",
                icon: "star.fill"
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var avgRating: String {
        let movies = watchedStore.watchedMovies
        guard !movies.isEmpty else { return "—" }
        let avg = movies.map { $0.imdbRating }.reduce(0, +) / Double(movies.count)
        return String(format: "%.1f", avg)
    }
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accent)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }
    
    // MARK: - Filter
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Movies")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", icon: "film.fill", filter: nil)
                    
                    ForEach(MovieRating.allCases, id: \.self) { rating in
                        filterChip(label: rating.label, icon: rating.icon, filter: rating)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func filterChip(label: String, icon: String, filter: MovieRating?) -> some View {
        let isActive = selectedFilter == filter
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isActive ? .black : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? AnyShapeStyle(AppTheme.goldGradient) : AnyShapeStyle(AppTheme.cardBackground))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Movies List
    private var moviesListSection: some View {
        VStack(spacing: 10) {
            if filteredMovies.isEmpty {
                emptyState
            } else {
                ForEach(filteredMovies) { watched in
                    watchedMovieRow(watched)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "popcorn.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textTertiary)
            
            Text(selectedFilter == nil ? "No movies watched yet" : "No movies with this rating")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Mark movies as watched from the movie detail screen")
                .font(.subheadline)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    private func watchedMovieRow(_ watched: WatchedMovie) -> some View {
        HStack(spacing: 14) {
            PosterImageView(url: watched.posterURL, cornerRadius: 8)
                .frame(width: 50, height: 75)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(watched.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Text("\(String(watched.year)) · \(watched.genreText)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // TMDB rating
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.accent)
                        Text(watched.ratingFormatted)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    // User rating
                    HStack(spacing: 3) {
                        Image(systemName: watched.rating.icon)
                            .font(.system(size: 9))
                        Text(watched.rating.label)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(watched.rating.color)
                }
            }
            
            Spacer()
            
            // Delete
            Button {
                withAnimation {
                    watchedStore.removeMovie(watched)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .glassCard()
    }
}
