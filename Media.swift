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
