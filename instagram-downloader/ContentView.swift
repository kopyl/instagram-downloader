import SwiftUI
import AlertKit
import AVFoundation
import Photos

let INFO_DOWNLOAD_URL_SCHEME = "\(SERVER_URL)/info?url=%@"

func isValidInstagramReelURL(url: String) -> Bool {
    let pattern = "^https://www\\.instagram\\.com/reel/[A-Za-z0-9_-]+(?:/)?(?:\\?igsh=[A-Za-z0-9=]+)?$"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    let range = NSRange(location: 0, length: url.utf16.count)
    let match = regex.firstMatch(in: url, options: [], range: range)
    
    return match != nil
}

struct Notification {
    var scene: UIWindow?
    var currentNotification: AlertAppleMusic17View?
    
    mutating func setWindowScene() {
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

    mutating func present(type: type) {
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
        return
    }
}

func fetchVideoURL(reelUrl: String) async throws -> String? {
    guard let infoURL = URL(string: String(format: INFO_DOWNLOAD_URL_SCHEME, reelUrl)) else {
        return nil
    }
    let (infoData, _) = try await URLSession.shared.data(from: infoURL)
    let videoInfoResponse = try JSONDecoder().decode(String.self, from: infoData)
    return videoInfoResponse
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
    @State private var notification: Notification = Notification()
    
    func downloadVideoAndSaveToPhotos() {
        Task{
            do {
                guard let downloadUrl = try await fetchVideoURL(reelUrl: url) else { return }
                guard let downloadUrlURL = URL(string: downloadUrl) else { return }
                guard let file = try await downloadFile(from: downloadUrlURL) else { return }
                
                try await PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
                })
                withAnimation(.linear(duration: 0.15)){
                    isDownloading = false
                    isDownloaded = true
                }
            } catch {
                isDownloading = false
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Download URL is \(isUrlValid ? "valid" : "invalid")")
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .background else { return }
            withAnimation(.linear(duration: 0.15)){
                isDownloaded = false
            }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            guard let _url = UIPasteboard.general.string else { return }
            withAnimation(.linear(duration: 0.15)){
                isDownloaded = false
            }
            url = _url
            withAnimation(.linear(duration: 0.15)){
                isUrlValid = isValidInstagramReelURL(url: _url)
            }
            
            if isUrlValid {
                notification.present(type: .loading)
                downloadVideoAndSaveToPhotos()
            }
        }
        .onChange(of: isDownloaded) {
            if isDownloaded {
                notification.present(type: .success)
            }
        }
        .onAppear{
            notification.setWindowScene()
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(isDownloaded ? .green : isUrlValid ? .blue : .red)
    }
}

#Preview {
    ContentView()
}
