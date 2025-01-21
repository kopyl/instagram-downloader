import SwiftUI
import AlertKit
import Photos

func isValidInstagramReelURL(url: String) -> Bool {
    let pattern = "^https://www\\.instagram\\.com/reel/[A-Za-z0-9_-]+(?:/)?(?:\\?igsh=[A-Za-z0-9=]+)?$"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    let range = NSRange(location: 0, length: url.utf16.count)
    let match = regex.firstMatch(in: url, options: [], range: range)
    
    return match != nil
}

class Notification {
    var scene: UIWindow?
    var currentNotification: AlertAppleMusic17View?
    
    func setWindowScene() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene
        else {
            return
        }
        scene = windowScene.windows.first(where: { $0.isKeyWindow })
    }
    
    enum type {
        case loading
        case success
        case error
    }

    func present(type: type) {
        guard let scene else { return }
        
        switch type {
        case .loading:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: "Downloading", icon: .spinnerSmall)
            currentNotification?.present(on: scene)
        case .success:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: "Added to photos", icon: .done)
            currentNotification?.haptic = .success
            currentNotification?.present(on: scene)
        case .error:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: "Error occured", icon: .error)
            currentNotification?.present(on: scene)
        }
    }
}

func downloadFile(from url: URL) async throws -> URL? {
    let (tempFileURL, _) = try await URLSession.shared.download(from: url)
    
    let destinationURL = tempFileURL.appendingPathExtension("mp4")
    
    if FileManager.default.fileExists(atPath: destinationURL.relativePath) {
        try FileManager.default.removeItem(at: destinationURL)
    }
    
    do {
        try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)
    } catch let error {
        print(error)
    }

    return destinationURL
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isUrlValid = false
    @State private var url: String = ""
    @State private var isDownloading = false
    @State private var isDownloaded = false
    @State private var isError = false
    @State private var lastRequestResultedInError = false
    
    private var notification = Notification()
    
    func downloadVideoAndSaveToPhotos() {
        Task{
            do {
                lastRequestResultedInError = false

                guard let downloadUrl = try await getVideoDownloadURL(reelURL: url) else { return }
                guard let file = try await downloadFile(from: downloadUrl) else { return }
                
                try await PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
                })
                withAnimation(.linear(duration: 0.15)){
                    isDownloaded = true
                    isError = false
                    lastRequestResultedInError = false
                }
            } catch {
                isError = true
            }
        }
    }
    
    var body: some View {
        VStack {
            if isDownloaded {
                VStack(spacing: 10){
                    Image(systemName: "checkmark.rectangle.stack.fill")
                        .imageScale(.large)
                        .foregroundStyle(.white)
                    Text("Dowbloaded")
                }
            }
            else if lastRequestResultedInError {
                VStack(spacing: 10){
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.white)
                    Text("Network request")
                }
            } else {
                Text("Download URL is \(isUrlValid ? "valid" : "invalid")")
            }
        }
        .onChange(of: scenePhase) {
            notification.currentNotification?.dismiss()
            guard let _url = UIPasteboard.general.string else { return }
            withAnimation(.linear(duration: 0.15)){
                isDownloaded = false
                url = _url
                isUrlValid = isValidInstagramReelURL(url: _url)
            }
            guard scenePhase == .active else { return }
            guard isUrlValid else { return }
            notification.present(type: .loading)
            downloadVideoAndSaveToPhotos()
        }
        .onChange(of: isDownloaded) {
            if isDownloaded {
                notification.present(type: .success)
            }
        }
        .onChange(of: isError) {
            withAnimation(.linear(duration: 0.15)){
                isDownloading = false
                
                if isError {
                    notification.present(type: .error)
                    isError = false
                    isDownloaded = false
                    lastRequestResultedInError = true
                }
            }
        }
        .onAppear{
            notification.setWindowScene()
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(isDownloaded ? .green : isUrlValid && !lastRequestResultedInError ? .blue : .red)
    }
}

#Preview {
    ContentView()
}
