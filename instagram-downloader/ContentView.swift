import SwiftUI
import AlertKit
import AVFoundation
import Photos

class PhotoLibrary {

    class func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            return status
        }
    }

    enum PhotoLibraryError: Error {
        case insufficientPermissions
        case savingFailed
    }

    class func saveVideoToCameraRoll(url: URL) async throws {

        let authStatus = await requestAuthorizationIfNeeded()

        guard authStatus == .authorized else {
            throw PhotoLibraryError.insufficientPermissions
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
        } catch {
            throw PhotoLibraryError.savingFailed
        }
    }
}

func isValidInstagramReelURL(url: String) -> Bool {
    let pattern = "^https://www\\.instagram\\.com/reel/[A-Za-z0-9_-]+(?:/)?(?:\\?igsh=[A-Za-z0-9=]+)?$"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    let range = NSRange(location: 0, length: url.utf16.count)
    let match = regex.firstMatch(in: url, options: [], range: range)
    
    return match != nil
}

struct Notification {
    var scene: UIWindow?
    var loadingNotification: AlertAppleMusic17View? = AlertAppleMusic17View(title: "Downloading", icon: .spinnerSmall)
    
    mutating func setWindowScene() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene
        else {
            return
        }
        scene = windowScene.windows.first(where: { $0.isKeyWindow })
    }

    func present() {
        guard let scene, let loadingNotification else { return }
        loadingNotification.present(on: scene)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isUrlValid = false
    @State private var url: String = ""
    @State private var isDownloading = false
    @State private var downloadStatus = ""
    @State private var notification: Notification = Notification()
    
    let videoURL = "https://www.instagram.com/reel/DDhhST0NGVy/?igsh=MTE4ZXAxOGw5eDNsZQ=="
    
    var body: some View {
        VStack {
            Text(url)
            Text("Is valid: \(String(isUrlValid))")
            Button("Test") {
//                notification.present()
                downloadVideo(from: videoURL)
            }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            guard let _url = UIPasteboard.general.string else { return }
            url = _url
            
            isUrlValid = isValidInstagramReelURL(url: _url)
        }
        .onAppear{
            notification.setWindowScene()
        }
    }
    
    func downloadVideo(from url: String) {
            isDownloading = true
            downloadStatus = "Starting download..."
            
            guard let serverURL = URL(string: "http://192.168.0.79:6000/download") else {
                downloadStatus = "Invalid server URL"
                isDownloading = false
                return
            }
            
            var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "url", value: url)]
            
            let task = URLSession.shared.downloadTask(with: components.url!) { (localURL, response, error) in
                DispatchQueue.main.async {
                    self.isDownloading = false
                    
                    if let error = error {
                        self.downloadStatus = "Download failed: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let localURL = localURL else {
                        self.downloadStatus = "Failed to get video"
                        return
                    }
                    
                    print("Downloaded")
                    
                    Task{
                        do {
                            try await PhotoLibrary.saveVideoToCameraRoll(url: localURL)
                        } catch {
                            // Handle error
                        }
                    }
                }
            }
            
            task.resume()
        }
    
    func saveToPhotos(_ localURL: URL) {
        // Ensure the app has permission to save to the Photos library
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission denied to access Photos library.")
                return
            }
            
            // Perform the save operation
            PHPhotoLibrary.shared().performChanges({
                // Create a request to save the video to the Photos library
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Video successfully saved to Photos.")
                    } else if let error = error {
                        print("Error saving video: \(error.localizedDescription)")
                    } else {
                        print("Unknown error occurred while saving video.")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
