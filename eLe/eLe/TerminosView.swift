import SwiftUI

struct TerminosView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Términos y Condiciones")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Bienvenido a la Fundación ELE.")
                
                Text("Al utilizar nuestros servicios, aceptas estas condiciones. Te recomendamos que las leas detenidamente.")
                
                Text("1. Privacidad")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Entendemos la importancia de tu privacidad. Consulta nuestra política de privacidad para obtener más información sobre cómo manejamos tus datos personales.")
                
                Text("2. Uso de la información")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Nos comprometemos a utilizar la información que nos proporcionas de manera responsable y ética. No compartiremos tu información personal con terceros sin tu consentimiento previo.")
                
                Text("3. Seguridad")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Tomamos medidas para proteger tus datos personales y garantizar la seguridad de nuestra plataforma. Sin embargo, no podemos garantizar la seguridad absoluta de la información transmitida a través de Internet.")
                
                Text("4. Cambios en los términos y condiciones")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Nos reservamos el derecho de realizar cambios en estos términos y condiciones en cualquier momento. Te notificaremos cualquier cambio importante mediante un aviso en nuestra plataforma o por correo electrónico.")
                
                Text("Gracias por utilizar nuestros servicios.")
                
                Spacer()
            }
            .padding()
        }
    }
}

struct TerminosView_Previews: PreviewProvider {
    static var previews: some View {
        TerminosView()
    }
}
