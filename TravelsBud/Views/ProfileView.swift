import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image
                    if let photoURL = authViewModel.userData?["photoURL"] as? String,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            case .failure(_):
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                            case .empty:
                                ProgressView()
                                    .frame(width: 120, height: 120)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    // Name
                    Text(authViewModel.userData?["name"] as? String ?? "Traveler")
                        .font(.title)
                        .bold()
                    
                    // Bio
                    if let bio = authViewModel.userData?["bio"] as? String {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Edit Profile Button
                    NavigationLink(destination: ProfileSetupView()) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Log Out Button
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            authViewModel.signOut()
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Log Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                authViewModel.refreshUserProfile()
            }
        }
    }
}
