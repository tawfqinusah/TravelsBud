import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isTyping = false
    @Published var lastReadMessageID: String?

    private let db = Firestore.firestore()
    private var chatID: String
    private var listener: ListenerRegistration?
    private var typingRef: DocumentReference?
    private var typingListener: ListenerRegistration?
    private var readReceiptRef: DocumentReference?

    init(chatID: String) {
        self.chatID = chatID
        listenForMessages()
        listenForTyping()
        markMessagesAsRead()
    }

    deinit {
        listener?.remove()
        typingListener?.remove()
    }

    func sendMessage() {
        guard let senderID = Auth.auth().currentUser?.uid else { return }

        let message: [String: Any] = [
            "senderID": senderID,
            "text": messageText,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats").document(chatID).collection("messages")
            .addDocument(data: message)

        db.collection("chats").document(chatID).updateData([
            "lastMessage": messageText,
            "timestamp": FieldValue.serverTimestamp()
        ])

        messageText = ""
        updateTyping(isTyping: false)
        
        // Send push notification when a new message is sent
        sendPushNotification(message: messageText)
    }

    func updateTyping(isTyping: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        typingRef = db.collection("chats").document(chatID).collection("typing").document(userID)
        typingRef?.setData(["typing": isTyping])
    }

    private func listenForMessages() {
        listener = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                self.messages = snapshot?.documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard let senderID = data["senderID"] as? String,
                          let text = data["text"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    return Message(
                        id: doc.documentID,
                        senderID: senderID,
                        text: text,
                        timestamp: timestamp.dateValue()
                    )
                } ?? []

                self.markMessagesAsRead()
            }
    }

    private func listenForTyping() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        typingListener = db.collection("chats")
            .document(chatID)
            .collection("typing")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                for doc in docs {
                    if doc.documentID != userID,
                       let isTyping = doc.data()["typing"] as? Bool, isTyping {
                        DispatchQueue.main.async {
                            self.isTyping = true
                        }
                        return
                    }
                }
                DispatchQueue.main.async {
                    self.isTyping = false
                }
            }
    }

    private func markMessagesAsRead() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard let lastMessage = messages.last else { return }

        lastReadMessageID = lastMessage.id

        let ref = db.collection("chats")
            .document(chatID)
            .collection("readReceipts")
            .document(userID)

        ref.setData([
            "lastReadID": lastMessage.id ?? "",  // Ensure lastReadID is not nil
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error saving read receipt: \(error.localizedDescription)")
            }
        }
    }

    func fetchLastReadID(for otherUserID: String, completion: @escaping (String?) -> Void) {
        let ref = db.collection("chats")
            .document(chatID)
            .collection("readReceipts")
            .document(otherUserID)

        ref.getDocument { snapshot, _ in
            let data = snapshot?.data()
            completion(data?["lastReadID"] as? String)
        }
    }

    // Function to send push notification using Firebase Cloud Messaging
    func sendPushNotification(message: String) {
        guard let token = Messaging.messaging().fcmToken else { return }

        let data: [String: Any] = [
            "to": token, // FCM token for the target user
            "notification": [
                "title": "New Message!",
                "body": message
            ]
        ]

        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_SERVER_KEY", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: [])
        } catch {
            print("Error creating JSON body: \(error.localizedDescription)")
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending push notification: \(error.localizedDescription)")
            } else {
                print("Notification sent successfully")
            }
        }

        task.resume()
    }
}
