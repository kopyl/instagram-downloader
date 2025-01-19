import SwiftUI
import AlertKit
import AVFoundation
import Photos

let SERVER_URL = "http://192.168.0.79:6000"
let DOWNLOAD_URL_SCHEME = "\(SERVER_URL)/download?url=%@"

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
            currentNotification?.present(on: scene)
        case .error:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: "Error occured", icon: .error)
            currentNotification?.present(on: scene)
        }
        return
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isUrlValid = false
    @State private var url: String = ""
    @State private var isDownloading = false
    @State private var isDownloaded = false
    @State private var notification: Notification = Notification()
    
    var backgroundColor: Color {
        if isUrlValid {
            return .red
        }
        if isDownloaded {
            return .green
        }
        if isDownloading {
            return .gray
        }
        return .red
    }
    
    func downloadVideoAndSaveToPhotos() {
        DispatchQueue.global(qos: .background).async {
            isDownloading = true
            if let _url = URL(string: String(format: DOWNLOAD_URL_SCHEME, url)),
                let urlData = NSData(contentsOf: _url) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/tempFile.mp4"
                DispatchQueue.main.async {
                    urlData.write(toFile: filePath, atomically: true)
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                    }) { completed, error in
                        if completed {
                            withAnimation(.linear(duration: 0.15)){
                                isDownloading = false
                                isDownloaded = true
                            }
                        }
                    }
                }
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
