import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Define un tipo de datos que se conforme a Identifiable y encapsule UIImagePickerController.SourceType
struct ImagePickerSourceType: Identifiable {
    let id: UIImagePickerController.SourceType
    
    // Inicializador para asignar el id
    init(id: UIImagePickerController.SourceType) {
        self.id = id
    }
}

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
    @State private var showAlert = false           // Controla la visibilidad de la alerta
    @State private var alertMessage = ""           // Mensaje para la alerta
    @State private var sourceType: ImagePickerSourceType?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Muestra el primer nombre del usuario, con estilo de título y negrita
                    Text(userData.firstName)
                        .font(.title) // Establece el tamaño de la fuente como título
                        .fontWeight(.bold) // Hace que la fuente sea negrita
                        .padding(.top, 10) // Añade un espacio superior de 10 puntos

                    // Llama a la sección que muestra y maneja la imagen de perfil
                    profileImageSection

                    // Contenedor horizontal para el correo electrónico
                    HStack {
                        Text("Email") // Texto estático "Email"
                            .padding() // Añade relleno alrededor del texto
                            .font(.body) // Establece el tamaño de la fuente como cuerpo de texto
                            .foregroundColor(.primary) // Establece el color del texto al color primario
                        Spacer() // Inserta un espacio flexible que empuja el contenido adyacente
                        Text(userData.email) // Muestra el correo electrónico del usuario
                            .font(.body) // Establece el tamaño de la fuente como cuerpo de texto
                            .foregroundColor(.primary) // Establece el color del texto al color primario
                            .padding() // Añade relleno alrededor del texto
                    }
                    .padding(.vertical) // Añade relleno vertical al contenedor HStack

                    // Otras secciones para mostrar y editar la información del usuario
                    // ...

                    // Botón para seleccionar la imagen
                    Button("Seleccionar Imagen") {
                        sourceType = ImagePickerSourceType(id: .camera) // O .photoLibrary según corresponda
                    }

                    Spacer() // Inserta un espacio flexible que empuja el contenido hacia arriba
                }
                .padding() // Añade relleno alrededor del VStack
            }
            .sheet(item: $sourceType) { selectedSourceType in
                ImagePicker(image: $userData.profileImage, sourceType: selectedSourceType.id)
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

    // Sección que muestra y gestiona la imagen de perfil
    var profileImageSection: some View {
        // ...
    }
}

// Vista de representación de un selector de imágenes utilizando UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType // Fuente de la imagen
    @Environment(\.presentationMode) var presentationMode // Referencia de presentación de la vista

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss() // Cerrar la vista después de seleccionar la imagen
        }
    }
}

// Extensión de UIImage para redimensionar imágenes
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

struct PerfilView_Previews: PreviewProvider {
    static var previews: some View {
        PerfilView()
    }
}

