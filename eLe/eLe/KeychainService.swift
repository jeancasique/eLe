import Foundation
import Security

struct KeychainService {
    // Define las constantes para identificar el servicio, el email y la contraseña en el llavero.
    private static let service = "YourAppService"
    private static let accountEmail = "UserEmail"
    private static let accountPassword = "UserPassword"
    
    // Función para guardar el email en el llavero.
    static func saveEmail(_ email: String) {
        save(account: accountEmail, data: email)
    }
    
    // Función para cargar el email desde el llavero.
    static func loadEmail() -> String? {
        return load(account: accountEmail)
    }
    
    // Función para guardar la contraseña en el llavero.
    static func savePassword(_ password: String) {
        save(account: accountPassword, data: password)
    }
    
    // Función para cargar la contraseña desde el llavero.
    static func loadPassword() -> String? {
        return load(account: accountPassword)
    }
    
    // Función privada para guardar datos en el llavero.
    private static func save(account: String, data: String) {
        // Convierte la cadena de datos a un objeto Data.
        guard let data = data.data(using: .utf8) else { return }
        
        // Configura la consulta para guardar en el llavero.
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        
        // Borra cualquier dato existente con la misma cuenta.
        SecItemDelete(query as CFDictionary)
        
        // Agrega los nuevos datos al llavero.
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // Función privada para cargar datos desde el llavero.
    private static func load(account: String) -> String? {
        // Configura la consulta para cargar desde el llavero.
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        // Realiza la consulta al llavero.
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Verifica si se pudo cargar el dato correctamente.
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        
        // Convierte el dato a una cadena y lo devuelve.
        return String(data: data, encoding: .utf8)
    }
}

