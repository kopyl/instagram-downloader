import SwiftUI
import Photos

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let itemProviders = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments {
            
            guard let itemProvider = itemProviders.first else { return }
            guard itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return }
            
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier as String) { [unowned self] (item, error) in
                let contentView = ShareView(extensionContext: extensionContext, url: item as? URL)

                DispatchQueue.main.async {
                    let hostingView = UIHostingController(rootView: contentView)
                    hostingView.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300)
                    hostingView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    hostingView.view.frame.origin.y = self.view.frame.height - hostingView.view.frame.height
                    self.view.addSubview(hostingView.view)
                }
            }
        }
    }
}

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    var url: URL?
    
    @State private var lastError: Error?
    @State var isInstagramLoginSheetVisible = false
    @State var isLoggingIn = false
    
    @AppStorage(
        Names.hasUserLoggedInAtLeastOnce,
        store: UserDefaults(suiteName: Names.APPGROUP)
    ) private var hasUserLoggedInAtLeastOnce: Bool = false
    
    var body: some View {
        VStack{
            if let lastError {
                Text("Network error: \(lastError.localizedDescription)")
                Button("Re-login") {
                    isInstagramLoginSheetVisible = true
                }
            }
            else {
                Text("Downloading media")
                ProgressView()
            }
        }
        .task{
            await extractItems()
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(lastError == nil ? .clear : .red)
        .modifier(
            InstagramLoginSheet(
                isPresented: $isInstagramLoginSheetVisible,
                isLoggingIn: $isLoggingIn,
                hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                onSuccess: {
                    Task {
                        lastError = nil
                        await extractItems()
                    }
                }
            )
        )
    }
    
    func extractItems() async {
        do {
            guard let url else { return }
            try await downloadAndSaveMedia(reelURL: url.absoluteString)
            extensionContext?.completeRequest(returningItems: [])
        }
        catch let error {
            lastError = error
        }
    }
}
