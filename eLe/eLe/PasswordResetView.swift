import SwiftUI
import Firebase
import UIKit

// Definición de la vista para restablecer la contraseña
struct PasswordResetView: View {
    
    // Estado para almacenar el correo electrónico ingresado por el usuario
    @State private var email = ""
    
    // Estado para controlar la visibilidad de la alerta
    @State private var showAlert = false
    
    // Estado para almacenar el mensaje de la alerta
    @State private var alertMessage = ""
    
    // Estado para validar si el correo electrónico ingresado es válido
    @State private var isEmailValid = true

    var body: some View {
        VStack {
            Image("lock") // Usa el nombre del asset de la imagen
                .resizable() // Hace que la imagen sea redimensionable
                .scaledToFit() // Asegura que la imagen se escala proporcionalmente
                .frame(width: 120, height: 120) // Establece un tamaño específico para la imagen
                .padding(.top, 50) // Agrega un espacio en la parte superior

            TextField("Correo Electrónico", text: $email)
                .padding()
                .autocapitalization(.none) // Desactiva la autocapitalización del texto
                .keyboardType(.emailAddress) // Define el tipo de teclado como dirección de correo electrónico
                .disableAutocorrection(true) // Desactiva la autocorrección del texto
                .border(Color(UIColor.separator)) // Agrega un borde alrededor del campo de texto
                .padding(.horizontal, 8)
                .padding(.vertical, 20)
                .onChange(of: email, perform: validateEmail) // Realiza la validación del correo electrónico cuando cambia

            // Muestra un mensaje de error si el correo electrónico no es válido
            if !isEmailValid {
                Text("Correo electrónico no válido")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Botón para restablecer la contraseña
            Button("Restablecer Contraseña") {
                resetPassword() // Llama a la función para restablecer la contraseña
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            .padding()
        }
        .padding()
        .navigationTitle("Restablecer Contraseña") // Título de la vista en la barra de navegación
        .navigationBarTitleDisplayMode(.inline) // Define el modo de visualización del título
        .alert(isPresented: $showAlert) { // Muestra una alerta cuando showAlert es true
            Alert(
                title: Text("Recuperar Contraseña"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Función para restablecer la contraseña
    private func resetPassword() {
        if isEmailValid { // Verifica si el correo electrónico es válido
            Auth.auth().sendPasswordReset(withEmail: email) { error in // Envía una solicitud para restablecer la contraseña
                if let error = error { // Si hay un error al enviar la solicitud
                    alertMessage = "Error al enviar el correo electrónico de restablecimiento de contraseña: \(error.localizedDescription)"
                } else { // Si la solicitud se envía correctamente
                    alertMessage = "Se ha enviado un correo electrónico de restablecimiento de contraseña a \(email). Por favor, verifica tu bandeja de entrada."
                    email = "" // Limpia el campo de correo electrónico después de enviar
                }
                showAlert = true // Muestra la alerta
            }
        }
    }

    // Función para validar el formato del correo electrónico
    private func validateEmail(_ email: String) {
        isEmailValid = isValidEmail(email) // Llama a la función isValidEmail para validar el correo electrónico
    }

    // Función para validar el formato del correo electrónico utilizando una expresión regular
    private func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email) // Retorna true si el correo electrónico coincide con el formato especificado
    }
}

