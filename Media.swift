import Photos
import SwiftData

func downloadMedia(reelURL: String) async throws -> _URL? {
    guard var downloadUrl = try await getDownloadURL(reelURL: reelURL) else { return nil }
    guard let file = try await downloadFile(from: downloadUrl) else { return nil }
    
    downloadUrl.localFilePath = file
    return downloadUrl
}

func saveMediaToPhotos(downloadUrl: _URL) async throws {
    guard let localFilePath = downloadUrl.localFilePath else {
        throw Errors.emptyLocalFileURL
    }
    
    try await PHPhotoLibrary.shared().performChanges({
        switch downloadUrl.type {
        case .video:
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localFilePath)
        case .image2:
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: localFilePath)
        }
    })
}

func saveMediaToHistory(downloadUrl: _URL) async throws {
    let context = try ModelContext(.init(for: ReelUrl.self))
    context.insert(ReelUrl(downloadUrl.initReelURL, type: downloadUrl.type))
    try context.save()
}

func downloadAndSaveMedia(reelURL: String) async throws {
    guard let downloadUrl = try await downloadMedia(reelURL: reelURL) else {
        throw Errors.noDownloadURL
    }
    try await saveMediaToPhotos(downloadUrl: downloadUrl)
    try await saveMediaToHistory(downloadUrl: downloadUrl)

//    context.insert(ReelUrl("shortCode", type: .image2))
//    try context.save()
//    try context.delete(model: ReelUrl.self)
}
