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
    
    @State private var reelURL: String?
    
    var body: some View {
        VStack{
            Text(lastError != nil ? "Network error: \(lastError!.localizedDescription)" : "")
                .task{
                    await extractItems()
                }
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(lastError == nil ? .clear : .red)
    }
    
    func extractItems() async {
        guard let itemProvider = itemProviders.first else { return }
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return }

        do {
            guard let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL else { return }
            reelURL = url.absoluteString
            
            guard let downloadUrl = try await getDownloadURL(reelURL: url.absoluteString) else { return }
            guard let file = try await downloadFile(from: downloadUrl) else { return }  
            
            try await PHPhotoLibrary.shared().performChanges({
                switch downloadUrl.type {
                case .video:
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
                case .image2:
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file)
                }
            })
            
            extensionContext?.completeRequest(returningItems: [])
            
        }
        catch let error {
            lastError = error
        }
    }
}
