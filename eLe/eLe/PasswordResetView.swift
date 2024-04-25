
import SwiftUI
import Firebase

struct PasswordResetView: View {
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

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
