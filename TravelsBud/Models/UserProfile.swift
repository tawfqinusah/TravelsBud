import Foundation

struct UserProfile: Identifiable, Equatable {
    let id: String
    let name: String
    let bio: String
    let photoURL: String
}
