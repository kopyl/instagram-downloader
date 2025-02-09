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
        throw JSONParserError.emptyLocalFileURL
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

func saveMediaToHistory(downloadUrl: String) async throws {
    let context = try ModelContext(.init(for: ReelUrl.self))
    context.insert(ReelUrl(downloadUrl))
    try context.save()
    
    //    let context = try ModelContext(.init(for: ReelUrl.self))
    //    context.insert(ReelUrl("Test-3"))
    //    try context.save()
        
    //    try context.delete(model: ReelUrl.self)
}

func downloadAndSaveMedia(reelURL: String) async throws {
//    guard let downloadUrl = try await downloadMedia(reelURL: reelURL) else {
//        throw JSONParserError.noDownloadURL
//    }
//    try await saveMediaToPhotos(downloadUrl: downloadUrl)
//    try await saveMediaToHistory(downloadUrl: reelURL)
}
