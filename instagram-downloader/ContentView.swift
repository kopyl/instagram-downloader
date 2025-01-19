import SwiftUI
import AlertKit

struct Notification {
    var windowScene: UIWindow?
    var loadingNotification: AlertAppleMusic17View?
    
    func getWindowScene() -> UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene
        else {
            return nil
        }
        return windowScene.windows.first(where: { $0.isKeyWindow })
    }
    
    init() {
        windowScene = getWindowScene()
        loadingNotification = AlertAppleMusic17View(title: "Downloading", icon: .spinnerSmall)
    }

    func present() {
        guard let scene = windowScene, let loadingNotification else { return }
        loadingNotification.present(on: scene)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var url: String = ""
    
    let notification = Notification()
    
    var body: some View {
        VStack {
            Text(url)
            Button("Test") {
                notification.present()
            }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            guard let _url = UIPasteboard.general.string else { return }
            url = _url
        }
    }
}

#Preview {
    ContentView()
}
