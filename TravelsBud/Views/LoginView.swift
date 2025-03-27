import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @State private var showingSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to TravelsBud")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Text("Connect with fellow travelers")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button(action: {
                    isLoading = true
                    authViewModel.signIn(email: email, password: password) { result in
                        isLoading = false
                        switch result {
                        case .success:
                            print("Successfully signed in")
                        case .failure(let error):
                            print("Sign in error: \(error.localizedDescription)")
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button("Forgot Password?") {
                    showingForgotPassword = true
                }
                .foregroundColor(.blue)
                
                Divider()
                    .padding(.vertical)
                
                VStack(spacing: 15) {
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            guard let credential = authResults.credential as? ASAuthorizationAppleIDCredential else { return }
                            authViewModel.signInWithApple(credential: credential)
                        case .failure(let error):
                            print("Apple sign in failed: \(error.localizedDescription)")
                            authViewModel.errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .padding(.horizontal)
                    
                    GoogleSignInButton(action: {
                        authViewModel.signInWithGoogle()
                    })
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .padding(.horizontal)
                }
                
                Button("Don't have an account? Sign Up") {
                    showingSignUp = true
                }
                .foregroundColor(.blue)
                .padding(.top)
            }
            .padding()
            .alert(item: Binding(
                get: { authViewModel.errorMessage.map { ErrorMessage(message: $0) } },
                set: { _ in authViewModel.errorMessage = nil }
            )) { errorMessage in
                Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthenticationViewModel())
    }
} 