import SwiftUI
import AlertKit

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

    func present(type: type, title: String? = nil) {
        guard let scene else { return }
        
        switch type {
        case .loading:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: title ?? "Downloading", icon: .spinnerSmall)
            currentNotification?.present(on: scene)
        case .success:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: title ?? "Added to photos", icon: .done)
            currentNotification?.haptic = .success
            currentNotification?.present(on: scene)
        case .error:
            currentNotification?.dismiss()
            currentNotification = AlertAppleMusic17View(title: title ?? "Error occured", icon: .error)
            currentNotification?.haptic = .error
            currentNotification?.present(on: scene)
        }
    }
    
    func dismiss() {
        currentNotification?.dismiss()
    }
}

struct Icon: View {
    let imageName: String
    let font: Font
    
    init(imageName: String, font: Font? = nil) {
        self.imageName = imageName
        self.font = font ?? .headline
    }
    
    var body: some View {
        Image(systemName: imageName)
            .font(font)
            .foregroundColor(.gray)
    }
}

struct Thumbnail: View {
    let reel: Reel
    
    var name: String {
        switch reel.type {
        case .video:
            return "video.fill"
        case .image:
            return "photo.fill"
        }
    }
    
    var body: some View {
        if let image = reel.thumbnail {
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50)
        }
         else {
             Icon(imageName: name)
             .frame(width: 50, height: 50)
        }
    }
}

/// Whte Text
struct WText: View {
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .foregroundStyle(.white)
    }
}
