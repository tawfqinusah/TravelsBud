import SwiftUI
import FirebaseAuth

struct GroupChatView: View {
    @StateObject private var viewModel = GroupChatViewModel()
    @State private var messageText = ""  // Bind to a local message text
    let groupChat: GroupChat

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(groupChat.messages) { message in
                        HStack {
                            if message.senderID == Auth.auth().currentUser?.uid {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                }
            }

            HStack {
                TextField("Type a message...", text: $messageText)  // Bind directly to messageText
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    // Ensure senderID and timestamp are provided when creating the message
                    guard let senderID = Auth.auth().currentUser?.uid else { return }
                    let newMessage = Message(
                        id: nil,
                        senderID: senderID,
                        text: messageText,
                        timestamp: Date() // Current date as the timestamp
                    )

                    viewModel.sendMessage(to: groupChat, message: newMessage)
                    messageText = ""  // Reset text after sending
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle(groupChat.title)
        .onAppear { viewModel.fetchGroupChats() }
    }
}
