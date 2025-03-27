import SwiftUI

struct SplashScreen: View {
    var body: some View {
        VStack {
            Image(systemName: "airplane.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TravelsBud")
                .font(.largeTitle)
                .bold()
                .padding(.top)
        }
        .opacity(0.8)
    }
} 