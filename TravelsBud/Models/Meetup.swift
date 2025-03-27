import Foundation
import FirebaseFirestore

struct Meetup: Identifiable, Equatable {
    var id: String
    let title: String
    let description: String
    let location: String
    let timestamp: Date
    let creatorID: String
    var attendees: [String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
