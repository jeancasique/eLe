import SwiftUI
import Firebase

struct PasswordResetView: View {
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEmailValid = true

    var body: some View {
        VStack {
            TextField("Correo Electrónico", text: $email)
                .padding()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .border(Color(UIColor.separator))
                .padding(.horizontal, 8)
                .padding(.vertical, 20)
                .onChange(of: email, perform: validateEmail)

            if !isEmailValid {
                Text("Correo electrónico no válido")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Restablecer Contraseña") {
                resetPassword()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            .padding()

        }
        .padding()
        .navigationTitle("Restablecer Contraseña")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Recuperar Contraseña"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func resetPassword() {
        if isEmailValid {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    alertMessage = "Error al enviar el correo electrónico de restablecimiento de contraseña: \(error.localizedDescription)"
                } else {
                    alertMessage = "Se ha enviado un correo electrónico de restablecimiento de contraseña a \(email). Por favor, verifica tu bandeja de entrada."
                    email = "" // Limpiar el campo de correo electrónico después de enviar
                }
                showAlert = true
            }
        }
    }

    private func validateEmail(_ email: String) {
        isEmailValid = isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
}

