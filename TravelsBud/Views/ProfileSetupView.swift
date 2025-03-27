import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var name = ""
    @State private var bio = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var profileImageURL: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        }
                        
                        Button(action: { isImagePickerPresented = true }) {
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(isLoading ? "Saving..." : "Complete Profile Setup")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                    .foregroundColor(name.isEmpty ? .gray : .blue)
                }
            }
            .navigationTitle("Set Up Profile")
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    // Image was selected, no need to force update
                    // SwiftUI will automatically update the view
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No user found"
            showError = true
            return
        }
        
        print("Starting profile save for user: \(userId)")
        isLoading = true
        
        // First save the user data
        saveUserData(userId: userId) { result in
            switch result {
            case .success:
                // If we have an image, upload it after user data is saved
                if let imageData = selectedImage?.jpegData(compressionQuality: 0.8) {
                    uploadProfileImage(userId: userId, imageData: imageData)
                } else {
                    print("No image to upload, profile save complete")
                    DispatchQueue.main.async {
                        isLoading = false
                        authViewModel.isProfileSetupComplete = true
                    }
                }
            case .failure(let error):
                print("Failed to save user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func uploadProfileImage(userId: String, imageData: Data) {
        print("Starting image upload for user: \(userId)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create the full path including user ID
        let profileImageRef = storageRef.child("profile_images").child(userId).child("profile.jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("Attempting upload to path: profile_images/\(userId)/profile.jpg")
        
        profileImageRef.putData(imageData, metadata: metadata) { metadata, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Image upload failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                print("Image upload successful, getting download URL")
                profileImageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Failed to get download URL: \(error.localizedDescription)")
                            self.errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                            self.showError = true
                            return
                        }
                        
                        if let downloadURL = url {
                            print("Got download URL: \(downloadURL.absoluteString)")
                            self.updateUserWithPhotoURL(userId: userId, photoURL: downloadURL.absoluteString)
                        }
                    }
                }
            }
        }
    }
    
    private func saveUserData(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userData: [String: Any] = [
            "name": name,
            "bio": bio,
            "createdAt": FieldValue.serverTimestamp(),
            "lastUpdated": FieldValue.serverTimestamp(),
            "isProfileComplete": true
        ]
        
        print("Saving initial user data")
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                print("Failed to save user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    self.showError = true
                }
                completion(.failure(error))
            } else {
                print("Successfully saved user data")
                DispatchQueue.main.async {
                    self.authViewModel.isProfileSetupComplete = true
                }
                completion(.success(()))
            }
        }
    }
    
    private func updateUserWithPhotoURL(userId: String, photoURL: String) {
        print("Updating user with photo URL")
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "photoURL": photoURL,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Failed to update user with photo URL: \(error.localizedDescription)")
                    self.errorMessage = "Failed to update profile with photo: \(error.localizedDescription)"
                    self.showError = true
                } else {
                    print("Successfully updated user with photo URL")
                    self.profileImageURL = photoURL // Update the local state
                    self.authViewModel.isProfileSetupComplete = true
                    // Refresh the profile data
                    self.authViewModel.refreshUserProfile()
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
            .environmentObject(AuthenticationViewModel())
    }
}
