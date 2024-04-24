import SwiftUI
import FirebaseAuth
import Firebase
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

    // Estado para rastrear si el correo electrónico está en uso
    @State private var isEmailInUse = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $name)
                    LabelError(message: formErrors["name"])
                    TextField("Apellidos", text: $lastName)
                    LabelError(message: formErrors["lastName"])
                    DatePicker("Fecha de Nacimiento", selection: $birthDate, displayedComponents: .date)
                    Picker("Sexo", selection: $gender) {
                        Text("Masculino").tag("Masculino")
                        Text("Femenino").tag("Femenino")
                    }.pickerStyle(SegmentedPickerStyle())
                    LabelError(message: formErrors["gender"])
                }

                Section(header: Text("Credenciales de Acceso")) {
                    TextField("Correo Electrónico", text: $email)
                    LabelError(message: formErrors["email"])
                    SecureField("Contraseña", text: $password)
                    LabelError(message: formErrors["password"])
                    SecureField("Confirmar Contraseña", text: $confirmPassword)
                    LabelError(message: formErrors["confirmPassword"])
                }

                // Modernized button
                Section {
                    Button(action: {
                        validateFields()
                    }) {
                        Text("Crear Usuario")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .navigationTitle("Registro")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Registro"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(
                NavigationLink(destination: LoginView(), isActive: $shouldNavigateToLogin) { EmptyView() }
            )
        }
    }

    private func checkEmailAvailability() {
        Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                alertMessage = "Error fetching sign-in methods: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Si methods contiene métodos de inicio de sesión, el correo electrónico está en uso
            if let methods = methods, !methods.isEmpty {
                isEmailInUse = true
                formErrors["email"] = "El correo electrónico ya está en uso."
            } else {
                isEmailInUse = false
            }
        }
    }

    private func validateFields() {
        formErrors = [:]

        if name.isEmpty {
            formErrors["name"] = "Nombre requerido"
        }
        if lastName.isEmpty {
            formErrors["lastName"] = "Apellido requerido"
        }
        if email.isEmpty {
            formErrors["email"] = "Correo electrónico requerido"
        }
        if password.isEmpty {
            formErrors["password"] = "Contraseña requerida"
        }
        if confirmPassword.isEmpty {
            formErrors["confirmPassword"] = "Confirmación de contraseña requerida"
        }

        if formErrors.isEmpty {
            createUser()
        } else {
            showAlert = true
            alertMessage = "Rellena los campos vacíos."
        }
    }

    private func createUser() {
        shouldNavigateToLogin = true // Simplemente para pruebas, reemplace con su lógica real
    }
}

struct LabelError: View {
    var message: String?

    var body: some View {
        if let message = message {
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.red)
        } else {
            EmptyView()
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}

