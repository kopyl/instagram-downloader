import SwiftUI
import UniformTypeIdentifiers
import ActivityKit
import SwiftData

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let itemProviders = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments {
            let hostingView = UIHostingController(rootView: ShareView(extensionContext: extensionContext, itemProviders: itemProviders))
            hostingView.view.frame = view.frame
            view.addSubview(hostingView.view)
        }
        
    }
}

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    var itemProviders: [NSItemProvider]
    
    @State private var reelURL: String?
    
    @State private var activity: Activity<DownloadProgressAttributes>?
    
    var body: some View {
        Text(reelURL ?? "")
            .task{
                await extractItems()
            }
            .onChange(of: reelURL) {
                guard let reelURL else { return }
                
                do {
                    let context = try ModelContext(.init(for: ReelUrl.self))
                    context.insert(ReelUrl(url: reelURL))
                }
                catch {
                    
                }
            }
    }
    
    func extractItems() async {
        guard let itemProvider = itemProviders.first else { return }
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return }

        do {
            guard let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL else { return }
            reelURL = url.absoluteString
        }
        catch let error {
            log(error)
        }
    }
}

struct DownloadProgressAttributes: ActivityAttributes {
    public typealias DownloadStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var isDownloading: Bool
        var isDownloaded: Bool
    }
}
