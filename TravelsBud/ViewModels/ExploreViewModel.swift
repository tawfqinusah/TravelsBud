import Foundation
import FirebaseFirestore
import FirebaseAuth

class ExploreViewModel: ObservableObject {
    @Published var meetups: [Meetup] = []
    private let db = Firestore.firestore()

    func fetchMeetups() {
        db.collection("meetups")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading meetups: \(error.localizedDescription)")
                    return
                }

                self.meetups = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let desc = data["description"] as? String,
                          let location = data["location"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let creatorID = data["creatorID"] as? String,
                          let attendees = data["attendees"] as? [String] else {
                        return nil
                    }

                    return Meetup(
                        id: doc.documentID,
                        title: title,
                        description: desc,
                        location: location,
                        timestamp: timestamp,
                        creatorID: creatorID,
                        attendees: attendees
                    )
                } ?? []
            }
    }

    func joinMeetup(_ meetup: Meetup) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("meetups").document(meetup.id)
        ref.updateData([
            "attendees": FieldValue.arrayUnion([userID])
        ])
    }

    func leaveMeetup(_ meetup: Meetup) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("meetups").document(meetup.id)
        ref.updateData([
            "attendees": FieldValue.arrayRemove([userID])
        ])
    }

    func createMeetup(title: String, description: String, location: String, date: Date) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "title": title,
            "description": description,
            "location": location,
            "timestamp": Timestamp(date: date),
            "creatorID": userID,
            "attendees": [userID]
        ]

        db.collection("meetups").addDocument(data: data)
    }
}
