import FirebaseAuth
import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var showingNewMeetup = false
    @State private var currentUserID: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.meetups) { meetup in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(meetup.title)
                            .font(.headline)
                        Text(meetup.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        HStack {
                            Text("📍 \(meetup.location)")
                            Spacer()
                            Text(meetup.formattedDate)
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)

                        if meetup.attendees.contains(currentUserID) {
                            Button("Leave") {
                                viewModel.leaveMeetup(meetup)
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("Join") {
                                viewModel.joinMeetup(meetup)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Meetups")
            .toolbar {
                Button(action: {
                    showingNewMeetup = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingNewMeetup) {
                NewMeetupView(viewModel: viewModel)
            }
        }
        .onAppear {
            currentUserID = Auth.auth().currentUser?.uid ?? ""
            viewModel.fetchMeetups()
        }
    }
}
