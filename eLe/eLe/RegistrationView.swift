import SwiftUI

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct RegistrationView: View {
    @State private var name = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var gender = ""
    @State private var formErrors = [String: String]()

    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var shouldNavigateToLogin = false

    // Estado para rastrear si se ha presionado el botón de "Crear Usuario"
    @State private var createUserButtonPressed = false

    // Estado para rastrear si el correo electrónico está en uso
    @State private var isEmailInUse = false

    // Estado para almacenar el mensaje de error específico del correo electrónico
    @State private var emailErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $name)
                    if let error = formErrors["name"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    TextField("Apellidos", text: $lastName)
                    if let error = formErrors["lastName"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    DatePicker("Fecha de Nacimiento", selection: $birthDate, displayedComponents: .date)

                    Picker("Sexo", selection: $gender) {
                        Text("Masculino").tag("Masculino")
                        Text("Femenino").tag("Femenino")
                    }.pickerStyle(SegmentedPickerStyle())
                    if let error = formErrors["gender"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                Section(header: Text("Credenciales de Acceso")) {
                    TextField("Correo Electrónico", text: $email)
                    if let error = formErrors["email"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    SecureField("Contraseña", text: $password)
                    if let error = formErrors["password"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    SecureField("Confirmar Contraseña", text: $confirmPassword)
                    if let error = formErrors["confirmPassword"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                // Utilizar un botón personalizado para agregar interacción de cambio de color
                Button(action: {
                    // Establecer el estado para indicar que se ha presionado el botón
                    createUserButtonPressed = true
                    // Verificar la disponibilidad del correo electrónico antes de crear la cuenta
                    checkEmailAvailability()
                    // Solo crear la cuenta si el correo electrónico no está en uso
                    if !isEmailInUse {
                        validateAndCreateUser()
                    }
                }) {
                    Text("Crear Usuario")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(createUserButtonPressed ? Color.blue : Color.gray)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Registro")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Registro"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"), action: {
                        if shouldNavigateToLogin {
                            self.shouldNavigateToLogin = true
                        }
                    })
                )
            }
                .background(
                                NavigationLink(destination: LoginView(), isActive: $shouldNavigateToLogin) { }
                            )
        }
    }

    private func validateAndCreateUser() {
        formErrors.removeAll()

        validateField("name", value: name, errorMessage: "El nombre es obligatorio.")
        validateField("lastName", value: lastName, errorMessage: "Los apellidos son obligatorios.")
        validateField("gender", value: gender, errorMessage: "El sexo es obligatorio.")
        validateField("email", value: email, errorMessage: "El correo electrónico es obligatorio.", validation: isValidEmail)
        validateField("password", value: password, errorMessage: "La contraseña es obligatoria.", validation: isValidPassword)
        if password != confirmPassword {
            formErrors["confirmPassword"] = "Las contraseñas no coinciden."
        }

        if formErrors.isEmpty {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let user = authResult?.user, error == nil {
                    saveUserData(user)
                } else {
                    alertMessage = "Error al crear el usuario: \(error?.localizedDescription ?? "")"
                    showAlert = true
                }
            }
        }
    }

    private func saveUserData(_ user: User) {
        let db = Firestore.firestore()
        let userData = [
            "firstName": name,
            "lastName": lastName,
            "birthDate": "\(birthDate)", // Formato ISO 8601
            "gender": gender
        ]
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                alertMessage = "Error al guardar datos del usuario: \(error.localizedDescription)"
                showAlert = true
            } else {
                alertMessage = "Registro exitoso. Por favor inicia sesión con tus nuevas credenciales."
                showAlert = true
                shouldNavigateToLogin = true
            }
        }
    }

    private func validateField(_ field: String, value: String, errorMessage: String, validation: ((String) -> Bool)? = nil) {
        if value.isEmpty {
            formErrors[field] = errorMessage
            return
        }

        if let validation = validation, !validation(value) {
            formErrors[field] = errorMessage
        } else {
            formErrors[field] = nil
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        let passwordFormat = "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{5,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordFormat)
        return passwordPredicate.evaluate(with: password)
    }

    private func checkEmailAvailability() {
        Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                print("Error fetching sign-in methods: \(error.localizedDescription)")
                return
            }
            // Si methods contiene métodos de inicio de sesión, el correo electrónico está en uso
            if let methods = methods, !methods.isEmpty {
                isEmailInUse = true
                emailErrorMessage = "El correo electrónico ya está en uso."
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}


