import SwiftUI
import FirebaseCore
import Firebase
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

class UserInterfaceMode: ObservableObject {
    @Published var isDarkModeEnabled = UIScreen.main.traitCollection.userInterfaceStyle == .dark
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userInterfaceMode = UserInterfaceMode()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userInterfaceMode) // Pasar el objeto observado al contenido de la aplicación
                .preferredColorScheme(userInterfaceMode.isDarkModeEnabled ? .dark : .light)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { _ in
                        let isDarkModeEnabled = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                        if isDarkModeEnabled != userInterfaceMode.isDarkModeEnabled {
                            userInterfaceMode.isDarkModeEnabled = isDarkModeEnabled
                        }
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var userInterfaceMode: UserInterfaceMode

    var body: some View {
        ZStack {
            if userInterfaceMode.isDarkModeEnabled {
                Color.black.edgesIgnoringSafeArea(.all)
            } else {
                Color.white.edgesIgnoringSafeArea(.all)
            }
            LoginView()
        }
    }
}

