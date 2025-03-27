import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import AuthenticationServices
import UIKit
import FirebaseFirestore
import FirebaseStorage

class AuthenticationViewModel: NSObject, ObservableObject {
    @Published var authState: AuthState = .unknown
    @Published var isProfileSetupComplete = false
    @Published var errorMessage: String?
    @Published var userData: [String: Any]? = nil
    private var stateHandler: AuthStateDidChangeListenerHandle?
    
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
    }
    
    override init() {
        super.init()
        setupAuthStateListener()
    }
    
    deinit {
        if let handler = stateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    private func setupAuthStateListener() {
        stateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // Check if profile exists
                    self?.checkProfileExists(for: user.uid)
                } else {
                    self?.authState = .unauthenticated
                    self?.isProfileSetupComplete = false
                }
            }
        }
    }
    
    // Email/Password Sign Up
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("Attempting to sign up with email: \(email)")
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Sign up error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if let user = result?.user {
                    print("Successfully signed up user with ID: \(user.uid)")
                    self?.errorMessage = nil
                    self?.authState = .authenticated
                    self?.isProfileSetupComplete = false
                    completion(.success(user))
                }
            }
        }
    }
    
    // Email/Password Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if let user = result?.user {
                    self?.errorMessage = nil
                    completion(.success(user))
                }
            }
        }
    }
    
    // Reset Password
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func checkProfileExists(for uid: String) {
        print("Checking profile existence for user: \(uid)")
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking profile: \(error.localizedDescription)")
                    self?.isProfileSetupComplete = false
                    return
                }
                
                if let data = snapshot?.data(), !data.isEmpty {
                    print("Profile data found: \(data)")
                    self?.userData = data
                    self?.isProfileSetupComplete = data["isProfileComplete"] as? Bool ?? false
                } else {
                    print("No profile data found")
                    self?.userData = nil
                    self?.isProfileSetupComplete = false
                }
                self?.authState = .authenticated
            }
        }
    }

    func refreshUserProfile() {
        print("Refreshing user profile")
        if let userId = Auth.auth().currentUser?.uid {
            checkProfileExists(for: userId)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            authState = .unauthenticated
            isProfileSetupComplete = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func signInWithGoogle() {
        print("Starting Google Sign In process...")
        guard let clientID = FirebaseApp.app()?.options.clientID else { 
            print("Error: Firebase client ID not found. Please check GoogleService-Info.plist")
            self.errorMessage = "Google Sign In configuration error"
            return 
        }
        
        print("Using Client ID: \(clientID)")
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Error: No root view controller found")
            self.errorMessage = "Internal configuration error"
            return
        }

        print("Attempting Google Sign In...")
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            if let error = error {
                print("Google sign-in failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                }
                return
            }

            guard let signInResult = signInResult else {
                print("Error: No sign in result")
                DispatchQueue.main.async {
                    self?.errorMessage = "Google Sign In failed: No result"
                }
                return
            }

            guard let idToken = signInResult.user.idToken?.tokenString else {
                print("Error: No ID token")
                DispatchQueue.main.async {
                    self?.errorMessage = "Google Sign In failed: No ID token"
                }
                return
            }

            let accessToken = signInResult.user.accessToken.tokenString
            print("Successfully got Google tokens, authenticating with Firebase...")

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Firebase Auth failed with error: \(error.localizedDescription)")
                        self?.errorMessage = "Firebase authentication failed: \(error.localizedDescription)"
                        return
                    }
                    
                    if let user = result?.user {
                        print("Successfully signed in with Firebase, user ID: \(user.uid)")
                        self?.errorMessage = nil
                        self?.authState = .authenticated
                        self?.checkProfileExists(for: user.uid)
                    } else {
                        print("Error: No user data from Firebase")
                        self?.errorMessage = "Failed to get user data"
                    }
                }
            }
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let token = credential.identityToken,
              let tokenString = String(data: token, encoding: .utf8) else {
            print("Missing Apple identity token")
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: credential.fullName
        )

        Auth.auth().signIn(with: firebaseCredential) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Apple Sign-In failed: \(error.localizedDescription)")
                    return
                }
                
                if let user = result?.user {
                    self?.checkProfileExists(for: user.uid)
                }
            }
        }
    }

    func uploadProfileImage(_ imageData: Data, for userId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("Starting profile image upload in AuthViewModel for user: \(userId)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images").child("\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("Attempting upload to path: profile_images/\(userId).jpg")
        
        profileImageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Upload failed in AuthViewModel: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("Upload successful in AuthViewModel, getting download URL")
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL in AuthViewModel: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                if let downloadURL = url {
                    print("Got download URL in AuthViewModel: \(downloadURL.absoluteString)")
                    completion(.success(downloadURL))
                } else {
                    let error = NSError(domain: "ProfileUpload", code: -1, 
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                }
            }
        }
    }
}
