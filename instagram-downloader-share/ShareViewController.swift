import SwiftUI
import UniformTypeIdentifiers
import Photos

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let itemProviders = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments {
            let hostingView = UIHostingController(rootView: ShareView(extensionContext: extensionContext, itemProviders: itemProviders))
            view.addSubview(hostingView.view)
        }
        
    }
}

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    var itemProviders: [NSItemProvider]
    
    @State private var reelURL: String?
    
    var body: some View {
        Text(reelURL ?? "")
            .task{
                await extractItems()
            }
    }
    
    func extractItems() async {
        guard let itemProvider = itemProviders.first else { return }
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return }

        do {
            guard let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL else { return }
            reelURL = url.absoluteString
            
            guard let downloadUrl = try await getVideoDownloadURL(reelURL: url.absoluteString) else { return }
            guard let file = try await downloadFile(from: downloadUrl) else { return }
            try await PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
            })
            
            extensionContext?.completeRequest(returningItems: [])
            
        }
        catch let error {
            log(error)
        }
    }
}
