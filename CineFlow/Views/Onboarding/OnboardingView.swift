import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    @State private var currentStep = 0
    @State private var nameInput = ""
    @State private var ageInput = ""
    @State private var selectedGenres: Set<Genre> = []
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { step in
                        Capsule()
                            .fill(step <= currentStep ? AppTheme.accent : AppTheme.cardBackground)
                            .frame(height: 4)
                            .animation(.spring(response: 0.4), value: currentStep)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                
                // Content
                TabView(selection: $currentStep) {
                    nameStep.tag(0)
                    ageStep.tag(1)
                    genreStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                
                Spacer()
                
                // Continue button
                Button(action: nextStep) {
                    HStack(spacing: 12) {
                        Text(currentStep == 2 ? "Get Started" : "Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Image(systemName: currentStep == 2 ? "arrow.right" : "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        isStepValid
                        ? AppTheme.goldGradient
                        : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: isStepValid ? AppTheme.accent.opacity(0.4) : .clear, radius: 16, y: 4)
                }
                .disabled(!isStepValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Steps
    
    private var nameStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(AppTheme.accent)
                .scaleEffect(animateIn ? 1.0 : 0.3)
                .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: animateIn)
            
            Text("Welcome to CineFlow")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text("What should we call you?")
                .font(.title3)
                .foregroundColor(AppTheme.textSecondary)
            
            TextField("Your name", text: $nameInput)
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.accent.opacity(nameInput.isEmpty ? 0.2 : 0.6), lineWidth: 1.5)
                )
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private var ageStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(AppTheme.accent)
            
            Text("How old are you, \(nameInput)?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("This helps us recommend age-appropriate films")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
            
            TextField("Age", text: $ageInput)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(AppTheme.accent)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.accent.opacity(ageInput.isEmpty ? 0.2 : 0.6), lineWidth: 1.5)
                )
                .frame(width: 160)
        }
        .padding()
    }
    
    private var genreStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "theatermasks.fill")
                .font(.system(size: 50, weight: .thin))
                .foregroundColor(AppTheme.accent)
            
            Text("What do you love?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Pick at least 2 genres")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Genre.allCases) { genre in
                    GenreChip(genre: genre, isSelected: selectedGenres.contains(genre)) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0: return !nameInput.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return Int(ageInput) != nil && Int(ageInput)! > 0
        case 2: return selectedGenres.count >= 2
        default: return false
        }
    }
    
    private func nextStep() {
        if currentStep < 2 {
            withAnimation { currentStep += 1 }
        } else {
            userProfile.completeOnboarding(
                name: nameInput.trimmingCharacters(in: .whitespaces),
                age: Int(ageInput) ?? 0,
                genres: Array(selectedGenres)
            )
        }
    }
}

// MARK: - Genre Chip
struct GenreChip: View {
    let genre: Genre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: genre.icon)
                    .font(.title3)
                Text(genre.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                        ? AppTheme.genreColor(for: genre).opacity(0.25)
                        : AppTheme.cardBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? AppTheme.genreColor(for: genre)
                            : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .foregroundColor(isSelected ? AppTheme.genreColor(for: genre) : AppTheme.textSecondary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
