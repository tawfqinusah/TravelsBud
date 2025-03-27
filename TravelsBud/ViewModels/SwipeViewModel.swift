import Foundation
import FirebaseFirestore
import FirebaseAuth

class SwipeViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var matchedUser: UserProfile? = nil

    func loadProfiles() {
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading users: \(error.localizedDescription)")
                return
            }

            self.profiles = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let bio = data["bio"] as? String,
                      let photoURL = data["photoURL"] as? String else {
                    return nil
                }

                return UserProfile(id: doc.documentID, name: name, bio: bio, photoURL: photoURL)
            } ?? []
        }
    }

    func skipUser() {
        if !profiles.isEmpty {
            profiles.removeLast()
        }
    }

    func likeUser() {
        guard let likedUser = profiles.last else { return }

        MatchService.shared.likeUser(targetUserId: likedUser.id) { isMatch in
            DispatchQueue.main.async {
                if isMatch {
                    self.matchedUser = likedUser
                }
                self.skipUser()
            }
        }
    }

    func clearMatch() {
        matchedUser = nil
    }
}
