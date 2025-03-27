import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileSetupViewModel: ObservableObject {
    static let shared = ProfileSetupViewModel() // Singleton shared instance
    
    @Published var username: String = ""
    @Published var age: String = ""
    @Published var interests: [String] = []
    @Published var profileImage: UIImage?
    @Published var gender: String = ""
    @Published var bio: String = ""  // Add bio property here
    
    private var db = Firestore.firestore()

    private init() {} // Make the initializer private to prevent multiple instances

    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "username": username,
            "age": age,
            "interests": interests,
            "gender": gender,
            "bio": bio // Save bio to Firestore
        ]

        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
                return
            }
            self.uploadProfileImage(uid: uid)
        }
    }

    private func uploadProfileImage(uid: String) {
        guard let image = profileImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        let ref = Storage.storage().reference().child("profile_images/\(uid).jpg")
        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            print("Profile image uploaded successfully")
        }
    }
}
