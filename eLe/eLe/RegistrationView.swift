import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct RegistrationView: View {
    // Estado para los campos del formulario de registro
    @State private var name = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate: Date?  // Hacer la fecha opcional para validar su selección
    @State private var gender = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var formErrors = [String: String]()  // Almacenar mensajes de error para cada campo

    // Estado para alertas y navegación
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var shouldNavigateToLogin = false

    var body: some View {
        NavigationStack {
            Form {
                // Sección de información personal
                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $name)
                    if let error = formErrors["name"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    TextField("Apellidos", text: $lastName)
                    if let error = formErrors["lastName"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    DatePicker(
                        "Fecha de Nacimiento",
                        selection: Binding(
                            get: { self.birthDate ?? Date() },
                            set: { self.birthDate = $0 }
                        ),
                        displayedComponents: .date
                    ).onChange(of: birthDate) { newDate in
                        if let newDate = newDate {
                            checkAge(date: newDate)
                        }
                    }
                    if let error = formErrors["birthDate"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    Picker("Sexo", selection: $gender) {
                        Text("Masculino").tag("Masculino")
                        Text("Femenino").tag("Femenino")
                    }.pickerStyle(SegmentedPickerStyle())
                    if let error = formErrors["gender"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                // Sección para las credenciales de acceso
                Section(header: Text("Credenciales de Acceso")) {
                                  TextField("Correo Electrónico", text: $email)
                                  if let error = formErrors["email"] {
                                      Text(error).foregroundColor(.red).font(.caption)
                                  }

                                  HStack {
                                      if showPassword {
                                          TextField("Contraseña", text: $password)
                                              .autocapitalization(.none)
                                      } else {
                                          SecureField("Contraseña", text: $password)
                                      }
                                      Button(action: {
                                          self.showPassword.toggle()
                                      }) {
                                          Image(systemName: showPassword ? "eye.slash" : "eye")
                                      }
                                  }
                                  if let error = formErrors["password"] {
                                      Text(error).foregroundColor(.red).font(.caption)
                                  }

                                  HStack {
                                      if showConfirmPassword {
                                          TextField("Confirmar Contraseña", text: $confirmPassword)
                                              .autocapitalization(.none)
                                      } else {
                                          SecureField("Confirmar Contraseña", text: $confirmPassword)
                                      }
                                      Button(action: {
                                          self.showConfirmPassword.toggle()
                                      }) {
                                          Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                      }
                                  }
                                  if let error = formErrors["confirmPassword"] {
                                      Text(error).foregroundColor(.red).font(.caption)
                                  }
                              }
                            
                Button("Crear Usuario") {
                    validateAndCreateUser()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(allFieldsFilled ? Color.blue : Color.gray)
                .cornerRadius(8)
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
        }
    }

    // Comprueba si todos los campos están llenos y correctos
    private var allFieldsFilled: Bool {
        !name.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        !gender.isEmpty &&
        birthDate != nil
    }

    // Valida y crea el usuario
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

        if let date = birthDate {
            checkAge(date: date)  // Asegúrate de pasar la fecha actual a la función
        } else {
            formErrors["birthDate"] = "La fecha de nacimiento es obligatoria."
        }

        if formErrors.isEmpty && allFieldsFilled {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let user = authResult?.user, error == nil {
                    saveUserData(user)
                } else {
                    alertMessage = "Error al crear el usuario: \(error?.localizedDescription ?? "")"
                    showAlert = true
                }
            }
        } else {
            alertMessage = "Por favor, corrige los errores para continuar."
            showAlert = true
        }
    }
    
    private func validateField(_ field: String, value: String, errorMessage: String, validation: ((String) -> Bool)? = nil) {
        if value.isEmpty {
            formErrors[field] = errorMessage
        } else {
            // Si se proporciona una función de validación, usarla para validar el campo
            if let validation = validation, !validation(value) {
                // Personaliza el mensaje de error para la contraseña
                if field == "password" && !isValidPassword(value) {
                    formErrors[field] = "La contraseña debe tener mínimo 5 caracteres, una mayúscula y un número."
                } else {
                    formErrors[field] = errorMessage
                }
            } else {
                formErrors[field] = nil
            }
        }
    }
    // Guarda los datos del usuario en la base de datos
    private func saveUserData(_ user: User) {
        let db = Firestore.firestore()
        let userData = [
            "email": email,
            "firstName": name,
            "lastName": lastName,
            "birthDate": "\(birthDate!)", // Formato ISO 8601
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

    // Verifica la edad del usuario para ser mayor de edad
    private func checkAge(date: Date) {
        let ageComponents = Calendar.current.dateComponents([.year], from: date, to: Date())
        if let age = ageComponents.year, age < 18 {
            formErrors["birthDate"] = "No puedes registrarte siendo menor de edad."
        } else {
            formErrors["birthDate"] = nil
        }
    }

    // Valida el formato del email
    func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }

    // Valida el formato de la contraseña
    func isValidPassword(_ password: String) -> Bool {
        let passwordFormat = "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{5,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordFormat)
        return passwordPredicate.evaluate(with: password)
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}

