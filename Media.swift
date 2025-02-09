import Photos
import SwiftData

func saveMedia(downloadUrl: _URL, file: URL) async throws {
    let context = try ModelContext(.init(for: ReelUrl.self))
    
    try await PHPhotoLibrary.shared().performChanges({
        switch downloadUrl.type {
        case .video:
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
        case .image2:
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file)
        }
    })
    
    context.insert(ReelUrl(downloadUrl.url.absoluteString))
}

func downloadMedia(reelURL: String) async throws {
    guard let downloadUrl = try await getDownloadURL(reelURL: reelURL) else { return }
    guard let file = try await downloadFile(from: downloadUrl) else { return }
    
    try await saveMedia(downloadUrl: downloadUrl, file: file)
}
