import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore
import LocalAuthentication
import AuthenticationServices

struct LoginView: View {
    // Estados para almacenar el correo electrónico y contraseña ingresados por el usuario
    @State private var email = ""
    @State private var password = ""
    // Estados para manejar errores de validación de correo electrónico y contraseña
    @State private var emailError = ""
    @State private var passwordError = ""
    // Estado para controlar si el usuario está logueado
    @State private var isUserLoggedIn = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        // Navegación y presentación de la vista principal
        NavigationStack {
            ScrollView {
                VStack {
                    emailField // Vista para el campo de correo electrónico
                    passwordField // Vista para el campo de contraseña
                    actionButtons // Vista para los botones de acción
                    Spacer() // Espaciador para empujar todo hacia arriba
                }
                .foregroundColor(.primary)
                .padding() // Padding general para el VStack
                .navigationTitle("Iniciar Sesión") // Título de la barra de navegación
                .navigationBarTitleDisplayMode(.inline) // Estilo del título
                
                    .navigationDestination(isPresented: $isUserLoggedIn) { // Destino de navegación cuando el usuario está logueado
                        PerfilView() // Vista de perfil del usuario
                    }
                  
            }
        }
    }
    func isDarkMode() -> Bool {
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            return true
        } else {
            return false
        }
    }
    // Definición de la vista para el campo de correo electrónico
    private var emailField: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                TextField("Correo Electrónico", text: $email)
                    .padding(.vertical, 20)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
            }
            .border(Color(UIColor.separator))
            .padding(.horizontal, 8)
            .padding(.vertical, 20)
            .onChange(of: email, perform: validateEmail)
            .submitLabel(.next)
            
            if !emailError.isEmpty {
                Text(emailError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding([.horizontal, .top], 4)
            }
        }
    }

    // Definición de la vista para el campo de contraseña
    private var passwordField: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                SecureField("Contraseña", text: $password)
                    .padding(.vertical, 20)
            }
            .border(Color(UIColor.separator))
            .padding(.horizontal, 8)
            .padding(.vertical, 20)
            .onChange(of: password, perform: validatePassword)
            .submitLabel(.done)
            
            if !passwordError.isEmpty {
                Text(passwordError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding([.horizontal, .top], 4)
            }
        }
    }

    // Definición de la vista para los botones de acción
    private var actionButtons: some View {
        VStack {
            HStack(spacing: 60) {
                SwiftUI.Button("Iniciar Sesión") {
                    validateFields() // Validar campos al intentar iniciar sesión
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                
                NavigationLink("Registro", destination: RegistrationView()) // Enlace a la vista de registro
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding()
            
            NavigationLink(destination: PasswordResetView()) { // Enlace a la vista de restablecimiento de contraseña
                Text("¿Olvidaste tu contraseña?")
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                authenticateWithBiometrics() // Iniciar sesión con Face ID
            }) {
                HStack {
                    Image(systemName: "faceid") // Agrega el icono del Face ID
                       
                    Text("Inicia Sesión con Face ID") // Agrega el texto del botón
                }
                .padding(8)
            }
            
            HStack(spacing: 20) {
                // Botón de inicio de sesión con Google
                Button(action: {
                               // Verifica si existe un 'clientID' para la configuración de Firebase. Si no existe, se imprime un mensaje de error y se detiene la ejecución.
                               guard let clientID = FirebaseApp.app()?.options.clientID else {
                                   print("Fallo al iniciar sesión con Google")
                                   return
                               }

                               // Configura el inicio de sesión de Google con el 'clientID' obtenido de Firebase.
                               let config = GIDConfiguration(clientID: clientID)
                               GIDSignIn.sharedInstance.configuration = config
                               
                               // Obtiene el controlador de vista raíz para presentar la pantalla de inicio de sesión de Google.
                               let viewController: UIViewController = (UIApplication.shared.windows.first?.rootViewController!)!
                               
                               // Inicia el proceso de autenticación de Google.
                               GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signResult, error in
                                   // Verifica si ocurrió un error durante el intento de inicio de sesión.
                                   if let error = error {
                                       print(error)
                                       return
                                   }
                                   
                                   // Comprueba que se haya obtenido un usuario de Google y su token de identificación.
                                   guard let googleUser = signResult?.user,
                                         let idToken = googleUser.idToken else { return }
                                   
                                   // Obtiene el token de acceso de Google.
                                   let accessToken = googleUser.accessToken
                                   
                                   // Crea las credenciales para Firebase utilizando el token de Google.
                                   let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)

                                   // Utiliza las credenciales para autenticar al usuario en Firebase.
                                   Auth.auth().signIn(with: credential) { authResult, error in
                                       // Maneja posibles errores durante el inicio de sesión en Firebase.
                                       if let error = error {
                                           print("Error durante el inicio de sesión con Google: \(error.localizedDescription)")
                                           return
                                       }
                                       
                                       // Verifica que el usuario de Firebase se haya obtenido correctamente.
                                       guard let user = Auth.auth().currentUser else {
                                           print("Error: No se pudo obtener el usuario actual.")
                                           return
                                       }
                                       
                                       // Accede a Firestore para verificar o guardar datos del usuario.
                                       let db = Firestore.firestore()
                                       let docRef = db.collection("users").document(user.uid)
                                       Task {
                                           do {
                                               // Intenta obtener el documento del usuario en Firestore.
                                               let document = try await docRef.getDocument()
                                               if !document.exists {
                                                   // Si el usuario es nuevo, prepara la descarga y almacenamiento de la imagen de perfil.
                                                   let imageUrl = googleUser.profile!.imageURL(withDimension: 200)?.absoluteString ?? ""
                                                   
                                                   if let imageUrl = URL(string: imageUrl), googleUser.profile!.hasImage {
                                                       // Descarga la imagen de perfil desde la URL de Google.
                                                       URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                                                           guard let data = data, error == nil else {
                                                               print("Fallo al descargar los datos de la imagen")
                                                               return
                                                           }
                                                           let image = UIImage(data: data)
                                                           // Prepara los datos del usuario para guardar en Firestore, incluyendo la imagen en formato Base64.
                                                           let userData: [String: Any] = [
                                                               "email": user.email ?? "",
                                                               "firstName": user.displayName?.components(separatedBy: " ").first ?? "",
                                                               "lastName": user.displayName?.components(separatedBy: " ").last ?? "",
                                                               "gender": "", // Espacio reservado para el género
                                                               "birthDate": "", // Espacio reservado para la fecha de nacimiento
                                                               "profileImage": image?.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""
                                                           ]
                                                           
                                                           // Guarda los datos del usuario en Firestore.
                                                           db.collection("users").document(user.uid).setData(userData) { error in
                                                               if let error = error {
                                                                   print("Error al guardar los datos del usuario: \(error.localizedDescription)")
                                                               } else {
                                                                   print("Datos del usuario guardados correctamente.")
                                                                   DispatchQueue.main.async {
                                                                       self.isUserLoggedIn = true
                                                                   }
                                                               }
                                                           }
                                                       }.resume()
                                                   }
                                               } else {
                                                   DispatchQueue.main.async {
                                                       self.isUserLoggedIn = true
                                                   }
                                               }
                                           } catch {
                                               print(error)
                                           }
                                       }
                                   }
                               }
                           }) {
                    Image("logo_google")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40) // Modificado el tamaño del logo
                        .foregroundColor(.red) // Cambiado el color del logo
                        .padding(8) // Añadido relleno alrededor del logo
                        .background(colorScheme == .dark ? Color.clear : Color.white) // Cambiado a transparente en modo oscuro
                        .cornerRadius(8) // Bordes redondeados del botón.
                }
                
                // Botón de inicio de sesión con Apple
                Button(action: {
                    performAppleSignIn() // Iniciar proceso de registro con Apple
                }) {
                    Image(systemName: "applelogo") // Agregar el sistema de símbolos de Apple
                                   .resizable()
                                   .aspectRatio(contentMode: .fit)
                                   .frame(width: 40, height: 40) // Modificado el tamaño del logo
                                   .padding(8) // Añadido relleno alrededor del logo
                                   .background(colorScheme == .dark ? Color.black : Color.white) // Ajusta el color de fondo según el modo de interfaz
                                   .cornerRadius(8) // Bordes redondeados del botón.
                }
            }
            .padding(2)

        }
    }

    private func performAppleSignIn() {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = ASAuthorizationControllerDelegateImpl(completion: { fullName, email in
                guard let fullName = fullName, let email = email else { return }
                let (firstName, lastName) = splitFullName(fullName)
                saveCredentialsToFirestore(firstName: firstName, lastName: lastName, email: email)
            })
            controller.presentationContextProvider = controller.delegate as? ASAuthorizationControllerPresentationContextProviding
            controller.performRequests()
        }

        // Función para dividir el nombre completo en nombre y apellidos
        private func splitFullName(_ fullName: String) -> (String, String) {
            let components = fullName.components(separatedBy: " ")
            let firstName = components.first ?? ""
            let lastName = components.dropFirst().joined(separator: " ")
            return (firstName, lastName)
        }

        // Función para guardar las credenciales en Firestore
        private func saveCredentialsToFirestore(firstName: String, lastName: String, email: String) {
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "first_name": firstName,
                "last_name": lastName,
                "email": email
            ]
            
            // Guardar los datos del usuario en Firestore
            db.collection("users").document(email).setData(userData) { error in
                if let error = error {
                    print("Error al guardar los datos del usuario en Firestore: \(error.localizedDescription)")
                } else {
                    print("Datos del usuario guardados correctamente en Firestore.")
                    isUserLoggedIn = true
                }
            }
        }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autenticarse con Face ID"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Autenticación exitosa
                        // Obtenemos el correo electrónico del usuario del llavero seguro
                        if let savedEmail = KeychainService.loadEmail() {
                            self.email = savedEmail
                        }
                        
                        // Obtenemos la contraseña del usuario del llavero seguro
                        if let savedPassword = KeychainService.loadPassword() {
                            self.password = savedPassword
                        }
                        
                        // Llamamos a validateFields() para iniciar automáticamente el proceso de inicio de sesión
                        self.validateFields()
                    } else {
                        // La autenticación falló o fue cancelada
                        // Maneja el error en consecuencia
                        print("La autenticación con Face ID falló o fue cancelada.")
                    }
                }
            }
        } else {
            // El dispositivo no es compatible con Face ID
            // Muestra una alerta al usuario
            let alertController = UIAlertController(title: "No compatible", message: "Tu dispositivo no es compatible con Face ID", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Presenta la alerta desde el controlador de vista actual
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                viewController.present(alertController, animated: true, completion: nil)
            }
        }
    }

    private func validateFields() {
        // Valida que no haya errores en el correo electrónico y la contraseña para permitir el inicio de sesión
        if emailError.isEmpty && passwordError.isEmpty {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.passwordError = "Error de autenticación: \(error.localizedDescription)"
                } else {
                    self.isUserLoggedIn = true
                }
            }
        } else {
            self.passwordError = "Por favor corrige los errores antes de continuar."
        }
    }

    private func validateEmail(_ email: String) {
        // Valida que el correo electrónico no esté vacío y cumpla con un formato adecuado
        if email.isEmpty {
            self.emailError = "El correo electrónico es obligatorio."
        } else if !isValidEmail(email) {
            self.emailError = "Introduce un correo electrónico válido."
        } else {
            self.emailError = ""
        }
    }

    private func validatePassword(_ password: String) {
        // Valida que la contraseña no esté vacía y cumpla con requisitos mínimos de seguridad
        if password.isEmpty {
            self.passwordError = "La contraseña es obligatoria."
        } else if !isValidPassword(password) {
            self.passwordError = "La contraseña debe tener al menos 5 caracteres, una mayúscula y un número."
        } else {
            self.passwordError = ""
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        // Utiliza una expresión regular para validar el formato del correo electrónico
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        // Utiliza una expresión regular para validar el formato de la contraseña
        let passwordFormat = "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{5,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordFormat)
        return passwordPredicate.evaluate(with: password)
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
           
    }
}

class ASAuthorizationControllerDelegateImpl: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var completion: ((String?, String?) -> Void)?
    
    init(completion: @escaping (String?, String?) -> Void) {
        self.completion = completion
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let fullName = (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? "")
            let email = appleIDCredential.email ?? ""
            completion?(fullName, email)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Error de autenticación con Apple: \(error.localizedDescription)")
    }
}

