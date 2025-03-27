import SwiftUI

struct NewMeetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ExploreViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Button("Create Meetup") {
                    viewModel.createMeetup(
                        title: title,
                        description: description,
                        location: location,
                        date: date
                    )
                    dismiss()
                }
                .disabled(title.isEmpty || description.isEmpty || location.isEmpty)
            }
            .navigationTitle("New Meetup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
