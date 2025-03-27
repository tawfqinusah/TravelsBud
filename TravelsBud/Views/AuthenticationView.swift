import AuthenticationServices
import SwiftUI
import FirebaseAuth
import GoogleSignInSwift

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome to TravelsBud")
                .font(.largeTitle)
                .bold()
            
            Text("Connect with fellow travelers")
                .font(.title3)
                .foregroundColor(.gray)

            Spacer()

            VStack(spacing: 15) {
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                authViewModel.signInWithApple(credential: appleIDCredential)
                            }
                        case .failure(let error):
                            print("Apple Sign-In failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(8)

                GoogleSignInButton(action: {
                    authViewModel.signInWithGoogle()
                })
                .frame(height: 50)
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}
