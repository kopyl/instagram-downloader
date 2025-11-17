import SwiftUI
import Photos

class AppState {
    static let shared = AppState()
    var swipeEnabled = false
}

struct ContentView: View {
    @AppStorage(
        Names.hasUserLoggedInAtLeastOnce,
        store: UserDefaults(suiteName: Names.APPGROUP)
    ) private var hasUserLoggedInAtLeastOnce: Bool = false
    
    @State private var path: [Route] = []
    
    public var notification = AlertNotification()

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingView(
                hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                path: $path,
                notification: notification
            )
            .onAppear {
                if hasUserLoggedInAtLeastOnce {
                    path.append(.home)
                }
            }
            .onChange(of: hasUserLoggedInAtLeastOnce) {
                if hasUserLoggedInAtLeastOnce {
                    path.append(.home)
                }
            }
            .navigationDestination(for: Route.self) { value in
                switch value {
                    case .home:
                        HistoryView(
                            hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                            path: $path,
                            notification: notification
                        )
                    case .savedItem(let reel):
                        SavedItemView(
                            reel: reel,
                            notification:
                                notification
                        )
                    }
            }
        }
        .onAppear {
            notification.setWindowScene(application: UIApplication.shared)
            requestPhotosPermissionIfNeeded()
        }
    }

    private func requestPhotosPermissionIfNeeded() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                print("Photos permission status:", newStatus.rawValue)
            }
        }
    }
}
