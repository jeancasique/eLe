import Foundation
import Security

struct KeychainService {
    private static let service = "YourAppService"
    private static let accountEmail = "UserEmail"
    private static let accountPassword = "UserPassword"
    
    static func saveEmail(_ email: String) {
        save(account: accountEmail, data: email)
    }
    
    static func loadEmail() -> String? {
        return load(account: accountEmail)
    }
    
    static func savePassword(_ password: String) {
        save(account: accountPassword, data: password)
    }
    
    static func loadPassword() -> String? {
        return load(account: accountPassword)
    }
    
    private static func save(account: String, data: String) {
        guard let data = data.data(using: .utf8) else { return }
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        
        SecItemDelete(query as CFDictionary)
        
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func load(account: String) -> String? {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}
