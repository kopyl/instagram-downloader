import SwiftUI
import AlertKit
import Photos
import ActivityKit
import SwiftData

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

struct LoginBrowserButton: View {
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "safari")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .opacity(0.7)
        }
    }
}

struct Icon: View {
    let reelUrl: ReelUrl
    
    var name: String {
        switch reelUrl.type {
        case .video:
            return "video.fill"
        case .image:
            return "photo.fill"
        }
    }
    
    var body: some View {
        if let image = reelUrl.thumbnail {
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50)
        }
         else {
            Image(systemName: name)
                .font(.headline)
                .foregroundColor(.gray)
                .frame(width: 50, height: 50)
        }
    }
}

struct CopyButton: View {
    let text: String?
    let reelUrl: ReelUrl
    let notification: Notification
    
    var body: some View {
        Button {
            UIPasteboard.general.string = reelUrl.cleanURL()
            notification.present(type: .success, title: "URL copied")
        } label: {
            if let text {
                Text(text)
            }
            Image(systemName: "document.on.document.fill")
        }
    }
}

func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

struct HistoryView: View {
    let notification: Notification
    @Query(sort: \ReelUrl.dateSaved, order: .reverse) private var savedReelUrls: [ReelUrl]
    @Environment(\.openURL) var openURL
    
    var body: some View {
        List {
            ForEach(savedReelUrls, id: \.self) { (reelUrl: ReelUrl) in
                HStack(spacing: 20) {
                    Icon(reelUrl: reelUrl)
                    HStack() {
                        VStack(alignment: .leading) {
                            Text(reelUrl.type.rawValue)
                                .font(.caption)
                                .opacity(0.6)
                            Text(formattedDate(reelUrl.dateSaved))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .opacity(0.6)
                    }
                }
                .frame(height: 70)
                .contentShape(Rectangle())
                .onTapGesture {
                    openURL(URL(string: reelUrl.url)!)
                }
                .contextMenu {
                    Button {
                        openURL(URL(string: reelUrl.url)!)
                    } label: {
                        Text("Go to video")
                        Image(systemName: "arrow.right")
                    }
                    CopyButton(text: "Copy link", reelUrl: reelUrl, notification: notification)
                } preview: {
                    if let image = reelUrl.thumbnail {
                        Image(uiImage: image).resizable()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 20, bottom: 5, trailing: 20))
                .swipeActions(edge: .trailing) {
                    CopyButton(text: nil, reelUrl: reelUrl, notification: notification)
                }
            }
            .listRowBackground(Color.bg)
        }
    }
}

struct ContentView: View {
    @State private var showingWebView  = false
    
    @Environment(\.modelContext) private var store
    
    private var notification = Notification()
    private var activity = ActivityManager()
    
    var body: some View {
        VStack {
            HStack {
                Text("History").font(.title)
                Spacer()
                LoginBrowserButton {
                    showingWebView.toggle()
                }
                .sheet(isPresented: $showingWebView) {
                    WebView(url: URL(string: "https://instagram.com")!)
                }
            }
            .padding()
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
            HistoryView(notification: notification)
                .listStyle(.plain)
                .padding(.horizontal, 0)
        }
        .background(.bg)
        .onAppear {
            notification.setWindowScene()
        }
    }
}

#Preview {
    ContentView()
}
