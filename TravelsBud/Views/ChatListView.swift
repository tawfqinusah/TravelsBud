import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatOverview: Identifiable {
    let id: String
    let title: String
}

struct ChatListView: View {
    @State private var chats: [ChatOverview] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading chats...")
                } else if chats.isEmpty {
                    Text("No chats available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(chats) { chat in
                        NavigationLink(destination: ChatView(chatID: chat.id, chatTitle: chat.title)) {
                            Text(chat.title)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
        }
        .onAppear(perform: loadChats)
    }

    private func loadChats() {
        guard let userID = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("chats")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                }

                if let error = error {
                    print("Failed to load chats: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.chats = documents.map {
                    ChatOverview(id: $0.documentID, title: $0.data()["title"] as? String ?? "Unknown Chat")
                }
            }
    }
}
