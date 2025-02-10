import Photos
import SwiftData
import AVFoundation
import SwiftUI

func generateThumbnailFromVideo(localFilePath: URL) throws -> UIImage? {
    
    let asset = AVURLAsset(url: localFilePath, options: nil)
    let imgGenerator = AVAssetImageGenerator(asset: asset)
    imgGenerator.appliesPreferredTrackTransform = true
    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
    let thumbnail = UIImage(cgImage: cgImage)
    return thumbnail
}

func generateThumbnailFromItem(downloadUrl: _URL) throws -> UIImage? {
    guard let localFilePath = downloadUrl.localFilePath else {
        throw Errors.emptyLocalFileURL
    }
    
    if downloadUrl.type == .image {
        return UIImage(contentsOfFile: localFilePath.relativePath)
    }
    
    return try generateThumbnailFromVideo(localFilePath: localFilePath)
}

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
        case .image:
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: localFilePath)
        }
    })
}

func saveMediaToHistory(downloadUrl: _URL) async throws {
    let context = try ModelContext(.init(for: ReelUrl.self))
    let reelUrl = ReelUrl(downloadUrl.initReelURL, type: downloadUrl.type)
    reelUrl.thumbnail = downloadUrl.thumbnail
    context.insert(reelUrl)
    try context.save()
}

func downloadAndSaveMedia(reelURL: String) async throws {
    guard var downloadUrl = try await downloadMedia(reelURL: reelURL) else {
        throw Errors.noDownloadURL
    }
    try await saveMediaToPhotos(downloadUrl: downloadUrl)
    
    if let thumbnailImage = try generateThumbnailFromItem(downloadUrl: downloadUrl) {
        downloadUrl.thumbnail = thumbnailImage
    }
    
    try await saveMediaToHistory(downloadUrl: downloadUrl)

//    let context = try ModelContext(.init(for: ReelUrl.self))
//    context.insert(ReelUrl("shortCode", type: .image))
//    try context.save()
//    try context.delete(model: ReelUrl.self)
}
