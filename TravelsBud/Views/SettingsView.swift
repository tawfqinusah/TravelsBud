import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showEditProfile = false
    @State private var showManageInterests = false
    @State private var notificationsEnabled = true
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(Auth.auth().currentUser?.displayName ?? "Traveler")
                                .font(.headline)
                            Text(Auth.auth().currentUser?.email ?? "No email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileSetupView()) {
                        Text("Edit Profile")
                    }

                    Button("Manage Interests") {
                        showManageInterests = true
                    }

                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showManageInterests) {
                Text("Manage Interests View")
                    .font(.largeTitle)
            }
            .alert("Are you sure you want to log out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}
