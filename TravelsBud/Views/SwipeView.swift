import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel = SwipeViewModel()

    var body: some View {
        VStack {
            if viewModel.profiles.isEmpty {
                Spacer()
                Text("No more travelers nearby.")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ZStack {
                    ForEach(viewModel.profiles.reversed()) { user in
                        SwipeCardView(user: user)
                            .padding()
                            .transition(.slide)
                    }
                }

                HStack(spacing: 40) {
                    Button(action: viewModel.skipUser) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.red)
                    }

                    Button(action: viewModel.likeUser) {
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            viewModel.loadProfiles()
        }
        .sheet(item: $viewModel.matchedUser) { user in
            VStack(spacing: 20) {
                Text("🎉 It's a Match!")
                    .font(.largeTitle)
                    .bold()

                Text("You and \(user.name) liked each other.")
                    .font(.title3)

                Button("Close") {
                    viewModel.clearMatch()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}
