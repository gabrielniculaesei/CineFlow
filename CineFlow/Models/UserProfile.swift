import Foundation
import SwiftUI

class UserProfile: ObservableObject {
    @AppStorage("userName") var name: String = ""
    @AppStorage("userAge") var age: Int = 0
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("favoriteGenresRaw") private var favoriteGenresRaw: String = ""
    
    var favoriteGenres: [Genre] {
        get {
            guard !favoriteGenresRaw.isEmpty else { return [] }
            return favoriteGenresRaw
                .split(separator: ",")
                .compactMap { Genre(rawValue: String($0)) }
        }
        set {
            favoriteGenresRaw = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    func completeOnboarding(name: String, age: Int, genres: [Genre]) {
        self.name = name
        self.age = age
        self.favoriteGenres = genres
        self.hasCompletedOnboarding = true
    }
    
    func resetProfile() {
        name = ""
        age = 0
        favoriteGenres = []
        hasCompletedOnboarding = false
    }
}
