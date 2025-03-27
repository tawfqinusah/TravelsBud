import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var otherUserReadID: String?
    let chatID: String
    let chatTitle: String
    
    init(chatID: String, chatTitle: String) {
        self.chatID = chatID
        self.chatTitle = chatTitle
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatID: chatID))
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            VStack(alignment: message.senderID == currentUserID ? .trailing : .leading) {
                                HStack {
                                    if message.senderID == currentUserID {
                                        Spacer()
                                        Text(message.text)
                                            .padding()
                                            .background(Color.blue.opacity(0.8))
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
                                
                                if message.senderID == currentUserID,
                                   message.id == otherUserReadID {
                                    Text("✅ Read")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 6)
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                        fetchOtherUserReadID()
                    }
                }
            }
            
            if viewModel.isTyping {
                Text("The other user is typing...")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            
            HStack {
                TextField("Type a message...", text: $viewModel.messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.messageText) {
                        viewModel.updateTyping(isTyping: !viewModel.messageText.isEmpty)
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle(chatTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var currentUserID: String {
        FirebaseAuth.Auth.auth().currentUser?.uid ?? ""
    }
    
    private func fetchOtherUserReadID() {
        viewModel.fetchLastReadID(for: chatTitle) { id in
            DispatchQueue.main.async {
                otherUserReadID = id
            }
        }
    }
}
