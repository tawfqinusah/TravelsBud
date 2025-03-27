import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            SwipeView()
                .tabItem {
                    Label("Discover", systemImage: "airplane.circle.fill")
                }
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "message.fill")
                }
            SettingsView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
