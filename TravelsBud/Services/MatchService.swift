import Foundation
import FirebaseFirestore
import FirebaseAuth

class MatchService {
    static let shared = MatchService()
    private let db = Firestore.firestore()

    func likeUser(targetUserId: String, completion: @escaping (Bool) -> Void) {
        guard let myUID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let myLikesRef = db.collection("users").document(myUID).collection("likes")
        let theirLikesRef = db.collection("users").document(targetUserId).collection("likes")

        myLikesRef.document(targetUserId).setData(["liked": true]) { error in
            if let error = error {
                print("Error liking user: \(error.localizedDescription)")
                completion(false)
                return
            }

            theirLikesRef.document(myUID).getDocument { snapshot, error in
                if let likedMe = snapshot?.data()?["liked"] as? Bool, likedMe {
                    self.registerMatch(userA: myUID, userB: targetUserId)
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    private func registerMatch(userA: String, userB: String) {
        let chatRef = db.collection("chats").document()
        let chatID = chatRef.documentID

        let timestamp = Timestamp(date: Date())
        let chatData: [String: Any] = [
            "participantIDs": [userA, userB],
            "lastMessage": "",
            "timestamp": timestamp
        ]

        chatRef.setData(chatData)

        // Add chat ref to both users' subcollections
        let userARef = db.collection("users").document(userA).collection("chats").document(chatID)
        let userBRef = db.collection("users").document(userB).collection("chats").document(chatID)

        userARef.setData(["title": "Chat with \(userB)", "timestamp": timestamp])
        userBRef.setData(["title": "Chat with \(userA)", "timestamp": timestamp])
    }
}
