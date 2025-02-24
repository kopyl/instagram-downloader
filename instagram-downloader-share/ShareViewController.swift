import SwiftUI
import Photos

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
    
    @State private var lastError: Error?
    @State var isInstagramLoginSheetVisible = false
    @State var isLoggingIn = false
    @State var hasUserLoggedInAtLeastOnce = false
    
    var body: some View {
        VStack{
            if let lastError {
                Text("Network error: \(lastError.localizedDescription)")
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
        guard let itemProvider = itemProviders.first else { return }
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return }

        do {
            guard let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL else { return }
            try await downloadAndSaveMedia(reelURL: url.absoluteString)
            extensionContext?.completeRequest(returningItems: [])
            
        }
        catch let error {
            lastError = error
            isInstagramLoginSheetVisible = true
            hasUserLoggedInAtLeastOnce = false
        }
    }
}
