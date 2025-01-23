import SwiftUI
import AlertKit
import Photos
import ActivityKit

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

class ActivityManager {
    let attributes = DownloadProgressAttributes()
    var isDownloading = false
    var isDownloaded = false
    
    var preState = DownloadProgressAttributes.ContentState(isDownloading: false, isDownloaded: false)
    
    var activity: Activity<DownloadProgressAttributes>?

    func getState(isDownloaded: Bool = false) -> ActivityContent<DownloadProgressAttributes.ContentState>? {
        let preState = DownloadProgressAttributes.ContentState(isDownloading: true, isDownloaded: isDownloaded)
        return ActivityContent<DownloadProgressAttributes.ContentState>(state: preState,
                                                                            staleDate: nil)
    }

    func launch() {
        guard let state = getState() else { return }
        
        do {
            activity = try Activity<DownloadProgressAttributes>.request(attributes: attributes, content: state, pushType: nil)
        }
        catch let error {
            print(error)
        }
    }
    
    func end() {
        guard let stateFinishing = getState(isDownloaded: true) else { return }

        guard let a = activity else { return }
        Task {
            await a.update(stateFinishing)
            try await Task.sleep(for: .seconds(2))
            await a.end(stateFinishing, dismissalPolicy: .immediate)
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isUrlValid = false
    @State private var url: String = ""
    @State private var isDownloading = false
    @State private var isDownloaded = false
    @State private var isError = false
    @State private var lastError: Error?
    @State private var lastRequestResultedInError = false
    
    private var notification = Notification()
    private var activity = ActivityManager()
    
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
            } catch let error {
                isError = true
                lastError = error
                
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
                    Text(lastError != nil ? "Network error: \(lastError!.localizedDescription)" : "Network error")
                }
            } else {
                Text("Reel URL is \(isUrlValid ? "valid" : "invalid")")
            }
        }
        .onChange(of: activity.isDownloaded) {
            if activity.isDownloaded {
                
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
            print("Launching")
            activity.launch()

            downloadVideoAndSaveToPhotos()
        }
        .onChange(of: isDownloaded) {
            if isDownloaded {
                notification.present(type: .success)
                print("Ending")
                activity.end()
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
