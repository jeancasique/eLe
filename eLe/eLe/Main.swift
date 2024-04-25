import SwiftUI
import GoogleSignIn
import Firebase
import UIKit



@main
struct MyApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup() {
            LoginView()
        }
    }
}
