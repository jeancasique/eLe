import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var isUserLoggedIn = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    emailField
                    passwordField
                    actionButtons
                    Spacer()
                }
                .padding()
                .navigationTitle("Iniciar Sesión")
                .navigationBarTitleDisplayMode(.inline)
                .background(
                    NavigationLink(destination: PerfilView(), isActive: $isUserLoggedIn) {
                        EmptyView()
                    }
                )
            }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading) {
            TextField("Correo Electrónico", text: $email)
                .padding()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
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

    private var passwordField: some View {
        VStack(alignment: .leading) {
            SecureField("Contraseña", text: $password)
                .padding()
                .border(Color(UIColor.separator))
                .padding(.horizontal, 8)
                .padding(.vertical, 20)
                .onChange(of: password, perform: validatePassword)
                .submitLabel(.done)
                .onSubmit(validateFields)

            if !passwordError.isEmpty {
                Text(passwordError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding([.horizontal, .top], 4)
            }
        }
    }

    private var actionButtons: some View {
        VStack {
            HStack(spacing: 60) {
                Button("Iniciar Sesión") {
                    validateFields()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)

                NavigationLink("Registro", destination: RegistrationView())
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding()

            NavigationLink(destination: PasswordResetView()) {
                Text("¿Olvidaste tu contraseña?")
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                let config = GIDConfiguration(clientID: clientID)

                GIDSignIn.sharedInstance.configuration = config
                
                let viewController: UIViewController = (UIApplication.shared.windows.first?.rootViewController!)!
                
                GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signResult, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let user = signResult?.user,
                          let idToken = user.idToken else { return }
                    
                    let accessToken = user.accessToken
                    
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)

                    // Use the credential to authenticate with Firebase
                    Auth.auth().signIn(with: credential) { authResult, error in
                        isUserLoggedIn = true
                    }
                }
            }) {
                HStack {
                    Image("logo_google")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    
                    Text("Iniciar sesión con Google")
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            }
            
        }
        .padding()
    }

    private func validateFields() {
        if emailError.isEmpty && passwordError.isEmpty {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    passwordError = "Error de autenticación: \(error.localizedDescription)"
                } else {
                    isUserLoggedIn = true
                }
            }
        } else {
            passwordError = "Por favor corrige los errores antes de continuar."
        }
    }

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = "El correo electrónico es obligatorio."
        } else if !isValidEmail(email) {
            emailError = "Introduce un correo electrónico válido."
        } else {
            emailError = ""
        }
    }

    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordError = "La contraseña es obligatoria."
        } else if !isValidPassword(password) {
            passwordError = "La contraseña debe tener al menos 5 caracteres, una mayúscula y un número."
        } else {
            passwordError = ""
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

