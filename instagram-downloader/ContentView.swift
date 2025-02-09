import SwiftUI
import AlertKit
import Photos
import ActivityKit
import SwiftData

class Alert {
    func show(notification: Notification) {
        let alertController = UIAlertController(title: "Enter your data", message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Headers"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Cookies"
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textFields = alertController.textFields else { return }
            let inputs = textFields.compactMap { $0.text }
            guard inputs[0] != "", inputs[1] != "" else {
                notification.present(type: .error, title: "All fields need to have data")
                return
            }
            let headers = inputs[0]
            let cookies = inputs[1]
            
            do {
                try _ = convertStringToDictionary(headers)
            } catch let error {
                print(error)
                notification.present(type: .error, title: "Headers are not valid")
            }
            
            do {
                _ = try convertStringToDictionary(cookies)
            } catch let error {
                print(error)
                notification.present(type: .error, title: "Cookies are not valid")
            }
            
            UserDefaults(suiteName: "group.CY-041AF8F6-4884-11E7-AB8C-406C8F57CB9A.com.cydia.Extender")?.set(inputs[0], forKey: "headers")
            UserDefaults(suiteName: "group.CY-041AF8F6-4884-11E7-AB8C-406C8F57CB9A.com.cydia.Extender")?.set(inputs[1], forKey: "cookies")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        notification.scene?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
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

struct CredentialsButton: View {
    let alert: Alert
    let notification: Notification
    
    var body: some View {
        Button(action: {alert.show(notification: notification)}) {
            Text("Set cookies and headers")
                .padding(10)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .font(.system(size: 14))
        }
        .background(.black)
        .cornerRadius(5)
        .padding()
    }
}

struct Icon: View {
    let reelUrl: ReelUrl
    
    var name: String {
        switch reelUrl.type {
        case .video:
            return "video.fill"
        case .image2:
            return "photo.fill"
        }
    }
    
    var body: some View {
        Image(systemName: name)
            .font(.headline)
            .foregroundColor(.gray)
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
                        Text(formattedDate(reelUrl.dateSaved))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .opacity(0.6)
                    }
                }
                .frame(height: 50)
                .contentShape(Rectangle())
                .onTapGesture {
                    openURL(URL(string: reelUrl.url)!)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
                .swipeActions(edge: .trailing) {
                    Button("", systemImage: "document.on.document.fill") {
                        UIPasteboard.general.string = reelUrl.cleanURL()
                        notification.present(type: .success, title: "URL copied")
                    }
                }
            }
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
    @State private var showingHistory = true
    
    @Environment(\.modelContext) private var store
    
    private var notification = Notification()
    private var alert = Alert()
    private var activity = ActivityManager()
    
    func downloadVideoAndSaveToPhotos() {
        Task{
            do {
                lastRequestResultedInError = false

                try await downloadAndSaveMedia(reelURL: url)
                
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
            Button(action: {
                showingHistory.toggle()
            }) {
                
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(notification: notification)
                .listStyle(.plain)
                .padding(.horizontal, 0)
                .padding(.top, 50)
                    .presentationDetents([.medium, .large])
            }
            .padding()
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
            
            Spacer()
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
            Spacer()
            CredentialsButton(alert: alert, notification: notification)
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
            activity.launch()

            downloadVideoAndSaveToPhotos()
        }
        .onChange(of: isDownloaded) {
            if isDownloaded {
                notification.present(type: .success)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ReelUrl.self, configurations: config)
    
    let context = container.mainContext
    
    context.insert(
        ReelUrl("https://www.instagram.com/reel/DF2k_eFMhgb/?igsh=ZThrZGtta3czcWt5", type: .video)
    )

    return ContentView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
