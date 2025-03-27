import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

@main
struct TravelsBudApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .authenticated:
                    if authViewModel.isProfileSetupComplete {
                        ContentView()
                            .environmentObject(authViewModel)
                    } else {
                        ProfileSetupView()
                            .environmentObject(authViewModel)
                    }
                case .unauthenticated, .unknown:
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
