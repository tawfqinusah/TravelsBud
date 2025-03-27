import Foundation
import FirebaseFirestore
import FirebaseAuth

class GroupChatViewModel: ObservableObject {
    @Published var groupChats: [GroupChat] = []
    @Published var currentGroupChat: GroupChat?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchGroupChats() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        db.collection("groupChats")
            .whereField("participants", arrayContains: userID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching group chats: \(error.localizedDescription)")
                    return
                }

                self.groupChats = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let creatorID = data["creatorID"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let participants = data["participants"] as? [String] else {
                        return nil
                    }
                    return GroupChat(id: doc.documentID,
                                     title: title,
                                     creatorID: creatorID,
                                     participants: participants,
                                     timestamp: timestamp)
                } ?? []
            }
    }

    func createGroupChat(title: String, participants: [String]) {
        guard let creatorID = Auth.auth().currentUser?.uid else { return }

        let groupChatData: [String: Any] = [
            "title": title,
            "creatorID": creatorID,
            "participants": participants,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("groupChats").addDocument(data: groupChatData) { error in
            if let error = error {
                print("Error creating group chat: \(error.localizedDescription)")
            }
        }
    }

    func sendMessage(to groupChat: GroupChat, message: Message) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let messageData: [String: Any] = [
            "senderID": userID,
            "text": message.text,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("groupChats")
            .document(groupChat.id)
            .collection("messages")
            .addDocument(data: messageData) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                }
            }
    }
}
