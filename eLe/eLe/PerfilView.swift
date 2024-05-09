import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import LocalAuthentication
import AuthenticationServices

// Clase para gestionar los datos del usuario utilizando el patrón ObservableObject
class UserData: ObservableObject {
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: String = ""
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String = ""
}

// Vista principal de perfil del usuario
struct PerfilView: View {
    @StateObject private var userData = UserData() // Datos del usuario como objeto de estado
    @State private var editingField: String?       // Campo actualmente en edición
    @State private var showActionSheet = false     // Controla la visibilidad del selector de imagen
    @State private var showImagePicker = false
    @State private var showAlert = false           // Controla la visibilidad de la alerta
    @State private var alertMessage = ""           // Mensaje para la alerta
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var showDocumentPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack (alignment: .top) {
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: UIScreen.main.bounds.height * 0.2) // Ajusta este valor para controlar la altura del color
                        .edgesIgnoringSafeArea(.top) // Solo extiende el color melón hasta el área segura superior
                    
                    VStack(alignment: .center, spacing: 20) {
                        
                        Text(userData.firstName)
                            .font(.title) // Establece el tamaño de la fuente como título
                            .fontWeight(.bold) // Hace que la fuente sea negrita
                            .padding(.top, 10) // Añade un espacio superior de 10 puntos
                        
                        // Llama a la sección que muestra y maneja la imagen de perfil
                        profileImageSection
                            .padding(.top, 20)
                        
                        
                        // Contenedor horizontal para el correo electrónico
                        VStack(alignment: .leading) {
                            Text("Email")
                                .padding(.vertical, 8) // Añade padding vertical para el alineamiento con otros elementos
                                .font(.body)
                                .fontWeight(.bold)// Establece el tamaño de la fuente como cuerpo de texto
                                .foregroundColor(.primary) // Establece el color del texto al color primario
                            
                            Spacer(minLength: 8) // Inserta un espacio mínimo de 8 dp entre el label y el contenido
                            
                            Text(userData.email)
                                .frame(maxWidth: .infinity, alignment: .leading) // Asegura que el texto se alinee a la izquierda y ocupe el espacio disponible
                                .font(.body) // Establece el tamaño de la fuente como cuerpo de texto
                                .foregroundColor(.primary) // Establece el color del texto al color primario
                                .padding(.trailing, 8) // Añade padding al final del texto para mantener el diseño dentro de los límites
                        }
                        .padding(.vertical, 8) // Añade relleno vertical al contenedor HStack
                        VStack(alignment: .leading) {
                            userInfoField(label: "Nombre", value: $userData.firstName, editing: $editingField, fieldKey: "firstName", editable: true)
                            userInfoField(label: "Apellidos", value: $userData.lastName, editing: $editingField, fieldKey: "lastName", editable: true)
                            datePickerField(label: "Fecha de Nacimiento:", date: $userData.birthDate, editing: $editingField, fieldKey: "birthDate")
                            userInfoField(label: "Género", value: $userData.gender, editing: $editingField, fieldKey: "gender", editable: true)
                            
                        }
                        // Botón para guardar los cambios realizados en el perfil del usuario
                        Button("Guardar Cambios", action: saveData) // Define el botón y su acción
                            .padding() // Añade relleno alrededor del botón
                            .foregroundColor(.white) // Establece el color del texto a blanco
                            .background(Color.blue) // Establece el color de fondo a azul
                            .cornerRadius(10) // Redondea las esquinas del botón
                        
                        Spacer() // Inserta un espacio flexible que empuja el contenido hacia arriba
                    }
                    .padding() // Añade relleno alrededor del VStack
                }
                .onAppear(perform: loadUserData) // Carga los datos del usuario al aparecer la vista
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $userData.profileImage)
                }
                
                .alert(isPresented: $showAlert) { // Muestra una alerta cuando se guarda la información
                    Alert(
                        title: Text("Datos Guardados"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    // Sección que muestra y gestiona la imagen de perfil
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
            self.showActionSheet = true
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Selecciona una opción"), buttons: [
                .default(Text("Abrir Galería")) {
                    self.showImagePicker = true
                    self.sourceType = .photoLibrary
                },
                .default(Text("Tomar Foto")) {
                    self.showImagePicker = true
                    self.sourceType = .camera
                },
                .default(Text("Seleccionar Archivo")) {
                    self.showDocumentPicker = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $userData.profileImage, sourceType: sourceType!)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(image: $userData.profileImage)
        }
        
    }

    // Función para generar campos de usuario editables
    func userInfoField(label: String, value: Binding<String>, editing: Binding<String?>, fieldKey: String, editable: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .fontWeight(.bold)

            HStack {
                if editing.wrappedValue == fieldKey {
                    TextField("", text: value) // Usando el texto vacío para el placeholder
                        
                        .background(.blue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .cornerRadius(5)
                    
                    Button(action: { editing.wrappedValue = nil }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    Text(value.wrappedValue)
                        .frame(maxWidth: .infinity, alignment: .leading) // Asegura que el texto se alinee a la izquierda

                    if editable {
                        Button(action: { editing.wrappedValue = fieldKey }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

           // Función para generar un selector de fechas con consistencia en el diseño
    func datePickerField(label: String, date: Binding<Date>, editing: Binding<String?>, fieldKey: String) -> some View {
        
            HStack {
                Text(label)
                    .fontWeight(.bold)
                
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
            .padding(.vertical,8)
        }

    
    // Función para guardar los cambios realizados a los datos del usuario
    func saveData() {
        // Verifica si hay un usuario actualmente autenticado, si no lo hay, sale de la función
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Si hay una imagen de perfil seleccionada, la guarda en Firestore
        if let profileImage = userData.profileImage {
            saveProfileImage(userId: userId, image: profileImage)
        }
        
        // Obtiene una instancia de Firestore
        let db = Firestore.firestore()
        
        // Crea un diccionario con los datos del usuario a guardar en Firestore
        let userData = [
            "email": self.userData.email,
            "firstName": self.userData.firstName,
            "lastName": self.userData.lastName,
            "birthDate": DateFormatter.iso8601Full.string(from: self.userData.birthDate),
            "gender": self.userData.gender,
            "profileImageURL": self.userData.profileImageURL
            
        ]
        
        // Guarda los datos del usuario en Firestore
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                // Si hay un error al guardar los datos, muestra un mensaje de error
                print("Error updating user data: \(error.localizedDescription)")
            } else {
                // Si los datos se guardan correctamente, muestra un mensaje de éxito
                print("User data updated successfully")
                self.showAlert = true
                self.alertMessage = "Datos guardados correctamente"
            }
        }
    }
    
    func loadImageFromGoogle() {
        
        // Verifica si ya hay una imagen de perfil almacenada en Firestore
        if userData.profileImage == nil {
            // Obtiene el usuario actualmente autenticado
            guard let user = Auth.auth().currentUser else {
                print("No hay usuario autenticado")
                return
            }
            
            // Obtiene la URL de la imagen de perfil de Google
            if let imageUrl = user.photoURL {
                // Descarga la imagen de perfil desde la URL de Google
                URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                    guard let data = data, error == nil else {
                        // Si hay un error al descargar la imagen, muestra un mensaje de error
                        print("Failed to download image data:", error?.localizedDescription ?? "Unknown error")
                        return
                    }
                    DispatchQueue.main.async {
                        // Si se descarga la imagen correctamente, la asigna a la imagen de perfil y la guarda en Firestore
                        if let image = UIImage(data: data) {
                            self.userData.profileImage = image
                            self.saveProfileImage(userId: user.uid, image: image)
                        }
                    }
                }.resume()
            } else {
                print("No se encontró la URL de la imagen de perfil de Google")
            }
        }
    }
    
    // Función para cargar los datos del usuario desde Firestore
    func loadUserData() {
        // Verifica si hay un usuario actualmente autenticado, si no lo hay, sale de la función
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Obtiene una instancia de Firestore
        let db = Firestore.firestore()
        
        // Obtiene el documento del usuario actual de la colección "users" en Firestore
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                // Si el documento existe, extrae los datos
                let data = document.data()
                
                // Actualiza los datos del usuario en la interfaz de usuario en la cola principal
                DispatchQueue.main.async {
                    self.userData.email = data?["email"] as? String ?? ""
                    self.userData.firstName = data?["firstName"] as? String ?? ""
                    self.userData.lastName = data?["lastName"] as? String ?? ""
                    self.userData.gender = data?["gender"] as? String ?? ""
                    
                    // Verifica si hay una fecha de nacimiento en el documento
                    if let birthDate = data?["birthDate"] as? String {
                        // Si hay una fecha de nacimiento, intenta convertirla a un objeto Date
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: birthDate) {
                            self.userData.birthDate = date
                        } else {
                            print("Error: No se pudo convertir la fecha de nacimiento a Date")
                        }
                    } else {
                        print("Advertencia: No se encontró la fecha de nacimiento en el documento")
                    }
                    
                    // Si hay una URL de imagen de perfil en Firestore, la asigna al usuario
                    if let profileImageURL = data?["profileImageURL"] as? String {
                        self.userData.profileImageURL = profileImageURL
                        
                        // Carga la imagen desde la URL
                        self.loadProfileImageFromURL()
                    } else {
                        // Si no hay una URL de imagen de perfil en Firestore, carga la imagen desde Google
                        self.loadImageFromGoogle()
                    }
                }
            } else {
                // Si el documento no existe, carga los datos del usuario desde Apple
                self.loadUserDataFromApple()
            }
        }
    }

    func loadUserDataFromApple() {
        // Verifica si ya hay una imagen de perfil almacenada en Firestore
        if userData.profileImage == nil {
            // Obtiene el usuario actualmente autenticado
            guard let user = Auth.auth().currentUser else {
                print("No hay usuario autenticado")
                return
            }
            
            // Carga los datos del usuario de Apple
            userData.email = user.email ?? ""
            userData.firstName = user.displayName?.components(separatedBy: " ").first ?? ""
            userData.lastName = user.displayName?.components(separatedBy: " ").last ?? ""
            
            // Actualiza la vista con los datos del usuario
            DispatchQueue.main.async {
                // Actualiza los datos del usuario en la interfaz de usuario
            }
        }
    }

    // Función para actualizar los datos del usuario en el objeto UserData y en la vista
    func updateUserData(with data: [String: Any]?) {
        guard let data = data else { return }
        // Actualiza los datos del usuario en el objeto UserData
        self.userData.email = data["email"] as? String ?? ""
        self.userData.firstName = data["firstName"] as? String ?? ""
        self.userData.lastName = data["lastName"] as? String ?? ""
        self.userData.gender = data["gender"] as? String ?? ""
        
        // Convierte la fecha de nacimiento del formato Timestamp a Date
        if let birthDateTimestamp = data["birthDate"] as? Timestamp {
            self.userData.birthDate = birthDateTimestamp.dateValue()
        }
        
        // Si hay una URL de imagen de perfil en Firestore, la asigna al usuario
        if let profileImageURL = data["profileImageURL"] as? String {
            self.userData.profileImageURL = profileImageURL
            
            // Carga la imagen desde la URL
            self.loadProfileImageFromURL()
        } else {
            // Si no hay una URL de imagen de perfil en Firestore, carga la imagen desde Apple
            self.loadUserDataFromApple()
        }
    }
    // Función para cargar la imagen de perfil desde una URL
    func loadProfileImageFromURL() {
        guard let profileImageURL = URL(string: userData.profileImageURL) else {
            print("Invalid profile image URL")
            return
        }
        
        URLSession.shared.dataTask(with: profileImageURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to load profile image:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            DispatchQueue.main.async {
                self.userData.profileImage = UIImage(data: data)
            }
        }.resume()
    }
    
    // Función para guardar la imagen de perfil en Firebase Storage y obtener la URL de descarga
   
    func saveProfileImage(userId: String, image: UIImage) {
        // Redimensiona la imagen para reducir el tamaño de almacenamiento (opcional)
        let resizedImage = image.resized(to: CGSize(width: 300, height: 300))
        
        // Convierte la imagen en datos JPEG
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        // Crea una referencia al directorio del usuario en Firebase Storage
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        
        // Sube la imagen al directorio del usuario en Firebase Storage
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard let _ = metadata, error == nil else {
                // Si hay un error al subir la imagen, muestra un mensaje de error
                print("Error uploading profile image:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            // Obtiene la URL de descarga de la imagen
            storageRef.downloadURL { url, error in
                guard let downloadURL = url, error == nil else {
                    // Si hay un error al obtener la URL de descarga, muestra un mensaje de error
                    print("Error fetching download URL:", error?.localizedDescription ?? "Unknown error")
                    return
                }
                
                // Actualiza la URL de la imagen de perfil en el objeto de datos del usuario
                DispatchQueue.main.async {
                    self.userData.profileImageURL = downloadURL.absoluteString
                    self.updateProfileImageURLInFirestore(userId: userId, imageUrl: downloadURL.absoluteString)
                }
            }
        }
    }
    
    func updateProfileImageURLInFirestore(userId: String, imageUrl: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["profileImageURL": imageUrl]) { error in
            if let error = error {
                print("Error updating image URL in Firestore:", error.localizedDescription)
            } else {
                print("Image URL successfully updated in Firestore")
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

// Extensión de UIImage para redimensionar imágenes
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
