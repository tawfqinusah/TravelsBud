import SwiftUI
import SDWebImageSwiftUI

struct SwipeCardView: View {
    let user: UserProfile

    var body: some View {
        VStack {
            if let url = URL(string: user.photoURL) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
            }

            Text(user.name)
                .font(.title)
                .bold()

            Text(user.bio)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}
