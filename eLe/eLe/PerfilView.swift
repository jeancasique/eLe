import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

class UserData: ObservableObject {
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: String = ""
    @Published var profileImage: UIImage? // Cambiado para almacenar directamente la imagen de perfil
}

struct PerfilView: View {
    @StateObject private var userData = UserData()
    @State private var editingField: String?
    @State private var showImagePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    Text(userData.firstName) // Cambiado para mostrar el nombre del usuario
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 10)

                    profileImageSection

                    HStack {
                        Text("Email")
                            .padding()
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(userData.email) // Mostrar el correo electrónico del usuario
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    .padding(.vertical) // Añadido espacio vertical

                    userInfoField(label: "Nombre", value: $userData.firstName, editing: $editingField, fieldKey: "firstName", editable: true)
                    userInfoField(label: "Apellidos", value: $userData.lastName, editing: $editingField, fieldKey: "lastName", editable: true)
                    datePickerField(label: "Fecha de Nacimiento", date: $userData.birthDate, editing: $editingField, fieldKey: "birthDate")
                    userInfoField(label: "Género", value: $userData.gender, editing: $editingField, fieldKey: "gender", editable: true)

                    Button("Guardar Cambios", action: saveData)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)

                    Spacer()
                }
                .padding()
            }
            .onAppear(perform: loadUserData)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $userData.profileImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Datos Guardados"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    var profileImageSection: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 140, height: 140)
                .shadow(radius: 10)

            if let image = userData.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 130, height: 130)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
        }
        .onTapGesture {
            // Mostrar el selector de imagen cuando se toca la imagen de perfil
            self.showImagePicker = true
        }
        .padding(.bottom, 20)
    }

    func userInfoField(label: String, value: Binding<String>, editing: Binding<String?>, fieldKey: String, editable: Bool) -> some View {
        HStack {
            if editing.wrappedValue == fieldKey {
                TextField(label, text: value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: { editing.wrappedValue = nil }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                Text(label)
                Spacer()
                Text(value.wrappedValue)
                if editable {
                    Spacer()
                    Button(action: { editing.wrappedValue = fieldKey }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
    }

    func datePickerField(label: String, date: Binding<Date>, editing: Binding<String?>, fieldKey: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            if editing.wrappedValue == fieldKey {
                DatePicker("", selection: date, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding(.horizontal)
                Button(action: { editing.wrappedValue = nil }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                Text("\(date.wrappedValue, formatter: DateFormatter.iso8601Full)")
                    .padding(.horizontal)
                Spacer()
                Button(action: { editing.wrappedValue = fieldKey }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }

    func saveData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userData = [
            "email": self.userData.email,
            "firstName": self.userData.firstName,
            "lastName": self.userData.lastName,
            "birthDate": DateFormatter.iso8601Full.string(from: self.userData.birthDate),
            "gender": self.userData.gender
        ]
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            } else {
                print("User data updated successfully")
                self.showAlert = true
                self.alertMessage = "Datos guardados correctamente"
            }
        }
        
        // Guardar imagen
        if let profileImage = self.userData.profileImage {
            saveProfileImage(userId: userId, image: profileImage)
        }
    }
    func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                
                if let googleData = GIDSignIn.sharedInstance.currentUser?.profile {
                    self.userData.email = googleData.email ?? ""
                    self.userData.firstName = googleData.givenName ?? ""
                    self.userData.lastName = googleData.familyName ?? ""
                    // Obtener foto de perfil de Google
                    if let url = googleData.imageURL(withDimension: 200) {
                        URLSession.shared.dataTask(with: url) { data, response, error in
                            guard let data = data, error == nil else { return }
                            DispatchQueue.main.async {
                                self.userData.profileImage = UIImage(data: data)
                            }
                        }.resume()
                    }
                } else {
                    self.userData.email = data?["email"] as? String ?? ""
                    self.userData.firstName = data?["firstName"] as? String ?? ""
                    self.userData.lastName = data?["lastName"] as? String ?? ""
                    self.userData.gender = data?["gender"] as? String ?? ""
                    self.userData.birthDate = (data?["birthDate"] as? Timestamp)?.dateValue() ?? Date()
                }

                if let base64String = data?["profileImage"] as? String,
                   let imageData = Data(base64Encoded: base64String),
                   let image = UIImage(data: imageData) {
                    self.userData.profileImage = image
                }
            } else {
                print("El documento no existe.")
            }
        }
    }
    
    func saveProfileImage(userId: String, image: UIImage) {
        DispatchQueue.global().async {
            // Redimensionar la imagen para reducir su tamaño antes de comprimirla
            let resizedImage = image.resized(to: CGSize(width: 300, height: 300))
            
            if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                let base64String = imageData.base64EncodedString()
                
                // Guardar la imagen en Firestore
                let db = Firestore.firestore()
                db.collection("users").document(userId).setData(["profileImage": base64String], merge: true) { error in
                    if let error = error {
                        print("Error updating profile image: \(error.localizedDescription)")
                    } else {
                        print("Profile image updated successfully")
                    }
                }
            }
        }
    }

}

struct PerfilView_Previews: PreviewProvider {
    static var previews: some View {
        PerfilView()
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// Función para redimensionar la imagen
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

