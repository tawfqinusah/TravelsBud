import Foundation

// Message Model — ONLY define it here
struct Message: Identifiable {
    var id: String?
    let senderID: String
    let text: String
    let timestamp: Date
}
