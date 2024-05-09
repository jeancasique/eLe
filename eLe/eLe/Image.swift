import SwiftUI
import UIKit
import UniformTypeIdentifiers  // Necesario para usar los identificadores de tipo universal de Apple.

// Un envoltorio de SwiftUI para el UIImagePickerController de UIKit, permitiendo seleccionar imágenes desde la biblioteca de fotos o la cámara.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?  // La imagen seleccionada, vinculada a la vista de SwiftUI.
    var sourceType: UIImagePickerController.SourceType = .photoLibrary  // Fuente predeterminada es la biblioteca de fotos.
    @Environment(\.presentationMode) var presentationMode  // Controla el modo de presentación de la vista.

    // Crea el UIImagePickerController de UIKit cuando la vista de SwiftUI lo requiere.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()  // Instancia un nuevo controlador de selector de imágenes.
        picker.delegate = context.coordinator  // Establece el coordinador como delegado para manejar respuestas del selector de imágenes.
        picker.sourceType = sourceType  // Establece el tipo de fuente (cámara o biblioteca de fotos).
        picker.allowsEditing = true
        return picker
    }

    // Requerido por UIViewControllerRepresentable, pero no usado en este caso.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // Crea el coordinador personalizado que maneja la respuesta del selector de imágenes.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Clase Coordinador para manejar la delegación del selector de imágenes.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker  // Referencia al ImagePicker padre.

        init(_ parent: ImagePicker) {
            self.parent = parent  // Inicializa con una referencia al padre.
        }

        // Maneja la selección de imágenes.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Extrae la imagen de la respuesta del selector.
            if let uiImage = info[.editedImage] as? UIImage {
                parent.image = uiImage  // Asigna la imagen seleccionada a la vinculación de imagen del padre.
            }
            parent.presentationMode.wrappedValue.dismiss()  // Cierra el selector de imágenes.
        }

        // Maneja la cancelación del selector de imágenes.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()  // Cierra el selector de imágenes.
        }
    }
}

// Un envoltorio de SwiftUI para UIDocumentPickerViewController de UIKit, habilitando la selección de archivos.
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?  // La imagen seleccionada, vinculada a la vista de SwiftUI.
    @Environment(\.presentationMode) var presentationMode  // Controla el modo de presentación de la vista.

    // Crea el UIDocumentPickerViewController para abrir archivos de imágenes.
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image], asCopy: true)
        controller.delegate = context.coordinator  // Establece el coordinador como delegado.
        return controller
    }
    
    // Requerido por UIViewControllerRepresentable, pero no usado en este caso.
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    // Crea el coordinador que maneja la respuesta del selector de documentos.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Clase Coordinador para manejar la delegación del selector de documentos.
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker  // Referencia al DocumentPicker padre.
        
        init(_ parent: DocumentPicker) {
            self.parent = parent  // Inicializa con una referencia al padre.
        }
        
        // Maneja la selección de documentos.
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }  // Asegura que haya una URL presente.
            // Intenta crear una imagen a partir de los datos del documento.
            guard let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) else { return }
            parent.image = image  // Establece la imagen seleccionada a la vinculación de imagen del padre.
            parent.presentationMode.wrappedValue.dismiss()  // Cierra el selector de documentos.
        }
        
        // Maneja la cancelación del selector de documentos.
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()  // Cierra el selector de documentos.
        }
    }
}

