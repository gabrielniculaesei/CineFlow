import SwiftUI

struct WhatToWatchView: View {
    // Steps: 0=Genre, 1=Subgenre/Mood, 2=Company, 3=Era, 4=Rating, 5=Vibe, 6=Results
    @State private var currentStep = 0
    @State private var selectedGenre: Genre?
    @State private var selectedSubgenre: SubgenreOption?
    @State private var selectedCompany: CompanyOption?
    @State private var selectedEra: EraOption?
    @State private var selectedRating: RatingOption?
    @State private var selectedVibe: VibeOption?
    @State private var recommendations: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var isLoadingRecs = false
    
    private let totalSteps = 7
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    switch currentStep {
                    case 0: genreStep
                    case 1: subgenreStep
                    case 2: companyStep
                    case 3: eraStep
                    case 4: ratingStep
                    case 5: vibeStep
                    default: recommendationsStep
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What to Watch")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(stepDescription)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                
                if currentStep > 0 {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            goBack()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(10)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? AppTheme.accent : AppTheme.cardBackground)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            
            // Step counter
            Text("Step \(min(currentStep + 1, totalSteps - 1)) of \(totalSteps - 1)")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textTertiary)
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 0: return "What genre are you feeling?"
        case 1:
            if let genre = selectedGenre {
                return "What style of \(genre.rawValue)?"
            }
            return "What's the mood tonight?"
        case 2: return "Who are you watching with?"
        case 3: return "Classic or modern?"
        case 4: return "How picky are you about ratings?"
        case 5: return "One last thing..."
        case 6: return "Here's what we picked for you"
        default: return ""
        }
    }
    
    private func goBack() {
        if currentStep > 0 {
            currentStep -= 1
            switch currentStep {
            case 0: selectedGenre = nil; selectedSubgenre = nil; selectedCompany = nil; selectedEra = nil; selectedRating = nil; selectedVibe = nil
            case 1: selectedSubgenre = nil; selectedCompany = nil; selectedEra = nil; selectedRating = nil; selectedVibe = nil
            case 2: selectedCompany = nil; selectedEra = nil; selectedRating = nil; selectedVibe = nil
            case 3: selectedEra = nil; selectedRating = nil; selectedVibe = nil
            case 4: selectedRating = nil; selectedVibe = nil
            case 5: selectedVibe = nil
            default: break
            }
        }
    }
    
    private func advance() {
        withAnimation(.spring(response: 0.4)) {
            currentStep += 1
        }
    }
    
    // MARK: - Step 1: Genre
    private var genreStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 14) {
                    ForEach(Genre.allCases) { genre in
                        Button {
                            selectedGenre = genre
                            advance()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: genre.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.genreColor(for: genre))
                                
                                Text(genre.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.genreColor(for: genre).opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.genreColor(for: genre).opacity(0.2), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                }
                
                notSureButton {
                    selectedGenre = nil
                    advance()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Step 2: Dynamic Subgenre / Fallback Mood
    private var subgenreStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if let genre = selectedGenre {
                    // Show genre-specific subgenre options
                    let options = SubgenreOption.options(for: genre)
                    ForEach(options) { sub in
                        Button {
                            selectedSubgenre = sub
                            advance()
                        } label: {
                            optionRow(icon: sub.icon, title: sub.title, subtitle: sub.subtitle)
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                } else {
                    // No genre selected — show fallback moods
                    ForEach(SubgenreOption.fallbackMoods) { mood in
                        Button {
                            selectedSubgenre = mood
                            advance()
                        } label: {
                            optionRow(icon: mood.icon, title: mood.title, subtitle: mood.subtitle)
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                }
                
                notSureButton {
                    selectedSubgenre = nil
                    advance()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Step 3: Company
    private var companyStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(CompanyOption.allCases) { company in
                    Button {
                        selectedCompany = company
                        advance()
                    } label: {
                        optionRow(icon: company.icon, title: company.title, subtitle: company.subtitle)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
                
                notSureButton {
                    selectedCompany = nil
                    advance()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Step 4: Era
    private var eraStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(EraOption.allCases) { era in
                    Button {
                        selectedEra = era
                        advance()
                    } label: {
                        optionRow(icon: era.icon, title: era.title, subtitle: era.subtitle)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
                
                notSureButton {
                    selectedEra = nil
                    advance()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Step 5: Rating
    private var ratingStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(RatingOption.allCases) { rating in
                    Button {
                        selectedRating = rating
                        advance()
                    } label: {
                        optionRow(icon: rating.icon, title: rating.title, subtitle: rating.subtitle)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
                
                notSureButton {
                    selectedRating = nil
                    advance()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Step 6: Vibe
    private var vibeStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(VibeOption.allCases) { vibe in
                    Button {
                        selectedVibe = vibe
                        loadRecommendations()
                        withAnimation(.spring(response: 0.4)) {
                            currentStep = 6
                        }
                    } label: {
                        optionRow(icon: vibe.icon, title: vibe.title, subtitle: vibe.subtitle)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
                
                notSureButton {
                    selectedVibe = nil
                    loadRecommendations()
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 6
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Shared Components
    
    private func optionRow(icon: String, title: String, subtitle: String) -> some View {
        let accentColor = selectedGenre.map { AppTheme.genreColor(for: $0) } ?? AppTheme.accent
        return HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(accentColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func notSureButton(action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.textSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("I'm not sure")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Skip this — surprise me")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(20)
            .background(AppTheme.cardBackground.opacity(0.5))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    // MARK: - Step 7: Results
    private var recommendationsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Selection summary chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let genre = selectedGenre {
                            selectionTag(icon: genre.icon, text: genre.rawValue, color: AppTheme.genreColor(for: genre))
                        }
                        if let sub = selectedSubgenre {
                            selectionTag(icon: sub.icon, text: sub.title, color: AppTheme.accent)
                        }
                        if let company = selectedCompany {
                            selectionTag(icon: company.icon, text: company.title, color: AppTheme.accent)
                        }
                        if let era = selectedEra {
                            selectionTag(icon: era.icon, text: era.title, color: AppTheme.accent)
                        }
                        if let rating = selectedRating {
                            selectionTag(icon: rating.icon, text: rating.title, color: AppTheme.accent)
                        }
                        if let vibe = selectedVibe {
                            selectionTag(icon: vibe.icon, text: vibe.title, color: AppTheme.accent)
                        }
                    }
                }
                .padding(.bottom, 4)
                
                if isLoadingRecs {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(AppTheme.accent)
                        Text("Finding the perfect movies...")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, movie in
                        Button {
                            selectedMovie = movie
                        } label: {
                            RecommendationRow(movie: movie, index: index + 1)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if recommendations.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textTertiary)
                            Text("No movies found for this combination")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Try being less specific or go back to change some answers")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }
                }
                
                // Start Over
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 0
                        selectedGenre = nil
                        selectedSubgenre = nil
                        selectedCompany = nil
                        selectedEra = nil
                        selectedRating = nil
                        selectedVibe = nil
                        recommendations = []
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Start Over")
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.accent)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accent.opacity(0.1))
                    .cornerRadius(14)
                }
                .padding(.top, 12)
            }
            .padding(20)
        }
    }
    
    private func selectionTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .cornerRadius(16)
    }
    
    // MARK: - Build Query & Load
    private func loadRecommendations() {
        isLoadingRecs = true
        
        // Build genre IDs
        var genreIds: [Int] = []
        if let genre = selectedGenre, let id = genre.tmdbId {
            genreIds.append(id)
        }
        
        // Add subgenre extra genre IDs
        if let sub = selectedSubgenre {
            genreIds.append(contentsOf: sub.extraGenreIds)
        }
        
        // Company affects genre overlay
        if let company = selectedCompany {
            genreIds.append(contentsOf: company.extraGenreIds)
        }
        
        // Determine sort order
        let sortBy = selectedVibe?.sortBy ?? "popularity.desc"
        
        // Build extra params
        var extraParams: [String: String] = [:]
        
        // Keywords from subgenre
        if let sub = selectedSubgenre, !sub.keywords.isEmpty {
            extraParams["with_keywords"] = sub.keywords
        }
        
        // Era date range
        if let era = selectedEra {
            if let minDate = era.minDate {
                extraParams["primary_release_date.gte"] = minDate
            }
            if let maxDate = era.maxDate {
                extraParams["primary_release_date.lte"] = maxDate
            }
        }
        
        // Rating filter
        if let rating = selectedRating {
            extraParams["vote_average.gte"] = rating.minRating
            extraParams["vote_count.gte"] = rating.minVotes
        } else {
            extraParams["vote_count.gte"] = "50"
        }
        
        // Remove duplicates from genreIds
        let uniqueGenreIds = Array(Set(genreIds))
        
        Task {
            do {
                let movies: [Movie]
                if uniqueGenreIds.isEmpty {
                    movies = try await TMDBService.shared.fetchTrending()
                } else {
                    let genreStr = uniqueGenreIds.map { "\($0)" }.joined(separator: ",")
                    var params: [String: String] = [
                        "with_genres": genreStr,
                        "sort_by": sortBy,
                        "page": "1"
                    ]
                    params.merge(extraParams) { _, new in new }
                    
                    let url = buildDiscoverURL(params: params)
                    movies = try await TMDBService.shared.fetchFromURL(url: url)
                }
                
                await MainActor.run {
                    recommendations = Array(movies.prefix(10))
                    isLoadingRecs = false
                }
            } catch {
                await MainActor.run {
                    recommendations = []
                    isLoadingRecs = false
                }
            }
        }
    }
    
    private func buildDiscoverURL(params: [String: String]) -> URL {
        var components = URLComponents(string: "\(APIConfig.tmdbBaseURL)/discover/movie")!
        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: "api_key", value: APIConfig.tmdbAPIKey))
        queryItems.append(URLQueryItem(name: "language", value: "en-US"))
        components.queryItems = queryItems
        return components.url!
    }
}

// MARK: - Subgenre Options (dynamic per genre)
struct SubgenreOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let extraGenreIds: [Int]
    let keywords: String  // TMDB keyword IDs comma-separated
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SubgenreOption, rhs: SubgenreOption) -> Bool { lhs.id == rhs.id }
    
    // MARK: - Genre-specific subgenres
    static func options(for genre: Genre) -> [SubgenreOption] {
        switch genre {
        case .romance:
            return [
                SubgenreOption(id: "rom_light", title: "Light & Sweet", subtitle: "Warm, feel-good love stories", icon: "sun.max.fill", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "rom_comedy", title: "Romantic Comedy", subtitle: "Funny, charming, and heartwarming", icon: "face.smiling.fill", extraGenreIds: [35], keywords: ""),
                SubgenreOption(id: "rom_drama", title: "Dramatic Romance", subtitle: "Deep, intense love stories", icon: "theatermasks.fill", extraGenreIds: [18], keywords: ""),
                SubgenreOption(id: "rom_period", title: "Period Romance", subtitle: "Historical love stories, costume dramas", icon: "clock.arrow.circlepath", extraGenreIds: [36], keywords: ""),
            ]
        case .horror:
            return [
                SubgenreOption(id: "hor_slasher", title: "Slasher", subtitle: "Masked killers, survival horror", icon: "scissors", extraGenreIds: [], keywords: "186427"),
                SubgenreOption(id: "hor_psych", title: "Psychological Horror", subtitle: "Mind games, creeping dread", icon: "brain.head.profile", extraGenreIds: [53], keywords: ""),
                SubgenreOption(id: "hor_found", title: "Found Footage", subtitle: "Handheld cameras, raw terror", icon: "video.fill", extraGenreIds: [], keywords: "224636"),
                SubgenreOption(id: "hor_body", title: "Body Horror", subtitle: "Grotesque transformations", icon: "figure.arms.open", extraGenreIds: [], keywords: "190065"),
                SubgenreOption(id: "hor_super", title: "Supernatural", subtitle: "Ghosts, demons, the unknown", icon: "moon.stars.fill", extraGenreIds: [], keywords: "162846"),
            ]
        case .crime:
            return [
                SubgenreOption(id: "cri_police", title: "Police Procedural", subtitle: "Detectives cracking cases", icon: "shield.checkered", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "cri_heist", title: "Heist", subtitle: "Elaborate plans, big scores", icon: "lock.open.fill", extraGenreIds: [], keywords: "10068"),
                SubgenreOption(id: "cri_gang", title: "Gangster / Mafia", subtitle: "Organized crime, power plays", icon: "person.3.fill", extraGenreIds: [], keywords: "1696"),
                SubgenreOption(id: "cri_true", title: "True Crime", subtitle: "Based on real events", icon: "doc.text.magnifyingglass", extraGenreIds: [], keywords: "9672"),
            ]
        case .action:
            return [
                SubgenreOption(id: "act_martial", title: "Martial Arts", subtitle: "Hand-to-hand combat, choreographed fights", icon: "figure.martial.arts", extraGenreIds: [], keywords: "779"),
                SubgenreOption(id: "act_military", title: "Military / War", subtitle: "Battlefields, soldiers, strategy", icon: "shield.fill", extraGenreIds: [10752], keywords: ""),
                SubgenreOption(id: "act_spy", title: "Spy / Espionage", subtitle: "Secret agents, covert ops", icon: "eye.trianglebadge.exclamationmark.fill", extraGenreIds: [], keywords: "470"),
                SubgenreOption(id: "act_super", title: "Superhero", subtitle: "Powers, capes, saving the world", icon: "bolt.shield.fill", extraGenreIds: [], keywords: "9715"),
            ]
        case .comedy:
            return [
                SubgenreOption(id: "com_slap", title: "Slapstick", subtitle: "Physical humor, over-the-top laughs", icon: "hands.clap.fill", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "com_dark", title: "Dark Comedy", subtitle: "Twisted, edgy, morbid humor", icon: "moon.fill", extraGenreIds: [], keywords: "11800"),
                SubgenreOption(id: "com_rom", title: "Romantic Comedy", subtitle: "Love with laughs", icon: "heart.fill", extraGenreIds: [10749], keywords: ""),
                SubgenreOption(id: "com_parody", title: "Parody / Satire", subtitle: "Mocking genres, pop culture", icon: "theatermask.and.paintbrush.fill", extraGenreIds: [], keywords: "189098"),
            ]
        case .drama:
            return [
                SubgenreOption(id: "dra_court", title: "Courtroom Drama", subtitle: "Trials, lawyers, justice", icon: "building.columns.fill", extraGenreIds: [], keywords: "10087"),
                SubgenreOption(id: "dra_bio", title: "Biographical", subtitle: "Real people, true stories", icon: "person.text.rectangle.fill", extraGenreIds: [], keywords: "818"),
                SubgenreOption(id: "dra_family", title: "Family Drama", subtitle: "Relationships, dysfunction, bonds", icon: "figure.2.and.child.holdinghands", extraGenreIds: [], keywords: "155906"),
                SubgenreOption(id: "dra_war", title: "War Drama", subtitle: "Human cost of conflict", icon: "flag.fill", extraGenreIds: [10752], keywords: ""),
            ]
        case .sciFi:
            return [
                SubgenreOption(id: "sci_space", title: "Space Opera", subtitle: "Epic adventures among the stars", icon: "sparkles", extraGenreIds: [], keywords: "3801"),
                SubgenreOption(id: "sci_dys", title: "Dystopian", subtitle: "Dark futures, broken societies", icon: "building.2.fill", extraGenreIds: [], keywords: "4458"),
                SubgenreOption(id: "sci_time", title: "Time Travel", subtitle: "Past and future collide", icon: "clock.arrow.circlepath", extraGenreIds: [], keywords: "4379"),
                SubgenreOption(id: "sci_cyber", title: "Cyberpunk", subtitle: "Neon cities, tech noir, hackers", icon: "cpu.fill", extraGenreIds: [], keywords: "12190"),
            ]
        case .thriller:
            return [
                SubgenreOption(id: "thr_psych", title: "Psychological Thriller", subtitle: "Mind games, unreliable narrators", icon: "brain.head.profile", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "thr_polit", title: "Political Thriller", subtitle: "Conspiracies, power struggles", icon: "building.columns.fill", extraGenreIds: [], keywords: "11162"),
                SubgenreOption(id: "thr_crime", title: "Crime Thriller", subtitle: "Cat-and-mouse, investigations", icon: "magnifyingglass", extraGenreIds: [80], keywords: ""),
                SubgenreOption(id: "thr_surv", title: "Survival Thriller", subtitle: "Against all odds, staying alive", icon: "flame.fill", extraGenreIds: [], keywords: "10349"),
            ]
        case .animation:
            return [
                SubgenreOption(id: "ani_family", title: "Family Animated", subtitle: "Fun for kids and adults alike", icon: "figure.2.and.child.holdinghands", extraGenreIds: [10751], keywords: ""),
                SubgenreOption(id: "ani_anime", title: "Anime-Style", subtitle: "Japanese animation & storytelling", icon: "sparkles", extraGenreIds: [], keywords: "210024"),
                SubgenreOption(id: "ani_adult", title: "Adult Animation", subtitle: "Mature themes, not for kids", icon: "person.fill", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "ani_musical", title: "Animated Musical", subtitle: "Songs, spectacle, heartfelt stories", icon: "music.note", extraGenreIds: [10402], keywords: ""),
            ]
        case .mystery:
            return [
                SubgenreOption(id: "mys_who", title: "Whodunit", subtitle: "Who did it? Classic detective puzzle", icon: "magnifyingglass", extraGenreIds: [], keywords: "187056"),
                SubgenreOption(id: "mys_noir", title: "Noir", subtitle: "Dark, moody, cynical atmosphere", icon: "moon.fill", extraGenreIds: [], keywords: "1937"),
                SubgenreOption(id: "mys_consp", title: "Conspiracy", subtitle: "Nothing is what it seems", icon: "eye.slash.fill", extraGenreIds: [53], keywords: ""),
                SubgenreOption(id: "mys_detect", title: "Detective Story", subtitle: "Following clues, solving crimes", icon: "person.badge.shield.checkmark.fill", extraGenreIds: [80], keywords: ""),
            ]
        case .adventure:
            return [
                SubgenreOption(id: "adv_treasure", title: "Treasure Hunt", subtitle: "Ancient maps, lost artifacts", icon: "map.fill", extraGenreIds: [], keywords: "2428"),
                SubgenreOption(id: "adv_explore", title: "Exploration", subtitle: "Uncharted lands, discovery", icon: "globe.americas.fill", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "adv_surv", title: "Survival Adventure", subtitle: "Stranded, fighting nature", icon: "leaf.fill", extraGenreIds: [], keywords: "10349"),
                SubgenreOption(id: "adv_epic", title: "Epic Quest", subtitle: "Grand journeys, destiny awaits", icon: "mountain.2.fill", extraGenreIds: [14], keywords: ""),
            ]
        case .fantasy:
            return [
                SubgenreOption(id: "fan_high", title: "High Fantasy", subtitle: "Vast worlds, magical systems, lore", icon: "wand.and.stars", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "fan_dark", title: "Dark Fantasy", subtitle: "Grim, gothic, morally gray", icon: "moon.stars.fill", extraGenreIds: [], keywords: "235019"),
                SubgenreOption(id: "fan_urban", title: "Urban Fantasy", subtitle: "Magic in the modern world", icon: "building.2.fill", extraGenreIds: [], keywords: ""),
                SubgenreOption(id: "fan_fairy", title: "Fairy Tale / Myth", subtitle: "Retellings, legends, folklore", icon: "book.fill", extraGenreIds: [], keywords: "2038"),
            ]
        }
    }
    
    // MARK: - Fallback moods (when no genre selected)
    static let fallbackMoods: [SubgenreOption] = [
        SubgenreOption(id: "mood_happy", title: "Feel-Good", subtitle: "Uplifting, fun, leaves you smiling", icon: "sun.max.fill", extraGenreIds: [35], keywords: ""),
        SubgenreOption(id: "mood_dark", title: "Dark & Intense", subtitle: "Gritty, raw, emotionally heavy", icon: "moon.fill", extraGenreIds: [80], keywords: ""),
        SubgenreOption(id: "mood_thrill", title: "Heart-Pounding", subtitle: "Tense, suspenseful, on the edge", icon: "bolt.fill", extraGenreIds: [28, 53], keywords: ""),
        SubgenreOption(id: "mood_think", title: "Thought-Provoking", subtitle: "Makes you think, layered story", icon: "brain.head.profile", extraGenreIds: [18], keywords: ""),
        SubgenreOption(id: "mood_chill", title: "Chill & Easy", subtitle: "Low-key, casual, easy watch", icon: "cup.and.saucer.fill", extraGenreIds: [35, 10751], keywords: ""),
        SubgenreOption(id: "mood_emo", title: "Emotional & Moving", subtitle: "Touching, might make you cry", icon: "heart.fill", extraGenreIds: [18, 10749], keywords: ""),
    ]
}

// MARK: - Company Options
enum CompanyOption: String, CaseIterable, Identifiable {
    case solo, date, friends, family
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .solo: return "Just Me"
        case .date: return "Date Night"
        case .friends: return "With Friends"
        case .family: return "Family Movie Night"
        }
    }
    
    var subtitle: String {
        switch self {
        case .solo: return "Something personal and immersive"
        case .date: return "Romantic, engaging, not too heavy"
        case .friends: return "Fun, quotable, crowd-pleaser"
        case .family: return "Appropriate and enjoyable for all ages"
        }
    }
    
    var icon: String {
        switch self {
        case .solo: return "person.fill"
        case .date: return "heart.circle.fill"
        case .friends: return "person.3.fill"
        case .family: return "house.fill"
        }
    }
    
    var extraGenreIds: [Int] {
        switch self {
        case .solo: return []
        case .date: return [10749]
        case .friends: return [35]
        case .family: return [10751, 16]
        }
    }
}

// MARK: - Era Options
enum EraOption: String, CaseIterable, Identifiable {
    case classics, nineties, modern, recent
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .classics: return "Classics"
        case .nineties: return "90s & 2000s"
        case .modern: return "2010s"
        case .recent: return "Recent"
        }
    }
    
    var subtitle: String {
        switch self {
        case .classics: return "Timeless films before 1990"
        case .nineties: return "Nostalgic hits from 1990-2009"
        case .modern: return "Modern cinema 2010-2019"
        case .recent: return "Latest releases 2020+"
        }
    }
    
    var icon: String {
        switch self {
        case .classics: return "clock.arrow.circlepath"
        case .nineties: return "play.rectangle.fill"
        case .modern: return "film.stack.fill"
        case .recent: return "sparkles"
        }
    }
    
    var minDate: String? {
        switch self {
        case .classics: return nil
        case .nineties: return "1990-01-01"
        case .modern: return "2010-01-01"
        case .recent: return "2020-01-01"
        }
    }
    
    var maxDate: String? {
        switch self {
        case .classics: return "1989-12-31"
        case .nineties: return "2009-12-31"
        case .modern: return "2019-12-31"
        case .recent: return nil
        }
    }
}

// MARK: - Rating Options
enum RatingOption: String, CaseIterable, Identifiable {
    case masterpiece, good, anything, underrated
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .masterpiece: return "Only the Best"
        case .good: return "Well-Rated"
        case .anything: return "I'll Try Anything"
        case .underrated: return "Underrated Picks"
        }
    }
    
    var subtitle: String {
        switch self {
        case .masterpiece: return "8.0+ rating, critically acclaimed"
        case .good: return "6.5+ rating, solid movies"
        case .anything: return "Any rating, just entertain me"
        case .underrated: return "Low vote count, hidden potential"
        }
    }
    
    var icon: String {
        switch self {
        case .masterpiece: return "crown.fill"
        case .good: return "hand.thumbsup.fill"
        case .anything: return "dice.fill"
        case .underrated: return "eye.slash.fill"
        }
    }
    
    var minRating: String {
        switch self {
        case .masterpiece: return "8.0"
        case .good: return "6.5"
        case .anything: return "0"
        case .underrated: return "6.0"
        }
    }
    
    var minVotes: String {
        switch self {
        case .masterpiece: return "500"
        case .good: return "200"
        case .anything: return "20"
        case .underrated: return "10"
        }
    }
}

// MARK: - Vibe Options
enum VibeOption: String, CaseIterable, Identifiable {
    case popular, rated, hidden, blockbuster
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .popular: return "Crowd Favorites"
        case .rated: return "Critically Acclaimed"
        case .hidden: return "Hidden Gems"
        case .blockbuster: return "Box Office Hits"
        }
    }
    
    var subtitle: String {
        switch self {
        case .popular: return "Most popular with audiences"
        case .rated: return "Highest ratings from critics"
        case .hidden: return "Under-the-radar picks"
        case .blockbuster: return "Big budget spectacles"
        }
    }
    
    var icon: String {
        switch self {
        case .popular: return "person.3.fill"
        case .rated: return "star.fill"
        case .hidden: return "eye.slash.fill"
        case .blockbuster: return "ticket.fill"
        }
    }
    
    var sortBy: String {
        switch self {
        case .popular: return "popularity.desc"
        case .rated: return "vote_average.desc"
        case .hidden: return "vote_average.desc"
        case .blockbuster: return "revenue.desc"
        }
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let movie: Movie
    let index: Int
    
    var body: some View {
        HStack(spacing: 14) {
            Text("#\(index)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.accent.opacity(0.5))
                .frame(width: 36)
            
            PosterImageView(url: movie.smallPosterURL, cornerRadius: 10)
                .frame(width: 55, height: 80)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                Text(movie.genreText)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.accent)
                    Text(movie.ratingFormatted)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                    Text("· \(String(movie.year))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
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
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}
