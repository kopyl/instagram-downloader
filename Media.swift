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

func downloadMedia(reelURL: String) async throws -> [_URL] {
    let downloadUrls = try await getDownloadURLs(reelURL: reelURL)

    var downloadedUrls: [_URL] = []

    for downloadUrl in downloadUrls {
        var url = downloadUrl
        guard let file = try await downloadFile(from: url) else { continue }
        url.localFilePath = file
        downloadedUrls.append(url)
    }

    return downloadedUrls
}

func saveMediaToPhotos(downloadUrl: _URL) async throws -> _URL {
    var _downloadUrl = downloadUrl
    
    guard let localFilePath = downloadUrl.localFilePath else {
        throw Errors.emptyLocalFileURL
    }
    
    
    try await PHPhotoLibrary.shared().performChanges({
        switch downloadUrl.type {
        case .video:
            guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localFilePath) else { return }
            let placeholder = request.placeholderForCreatedAsset
            _downloadUrl.mediaIdentifierFromPhotosApp = placeholder?.localIdentifier
        case .image:
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: localFilePath)
        }
    })
    
    return _downloadUrl
}

func saveMediaToHistory(downloadUrl: _URL) async throws {
    let context = try ModelContext(.init(for: Reel.self))
    let reel = Reel(
        downloadUrl.initReelURL,
        type: downloadUrl.type,
        mediaIdentifierFromPhotosApp: downloadUrl.mediaIdentifierFromPhotosApp
    )
    reel.thumbnail = downloadUrl.thumbnail
    context.insert(reel)
    try context.save()
}

func downloadAndSaveMedia(reelURL: String) async throws {
    let downloadUrls = try await downloadMedia(reelURL: reelURL)

    guard !downloadUrls.isEmpty else {
        throw Errors.noDownloadURL
    }
    
    for downloadUrl in downloadUrls {
        var url = downloadUrl
        url = try await saveMediaToPhotos(downloadUrl: url)

        if let thumbnailImage = try generateThumbnailFromItem(downloadUrl: url) {
            url.thumbnail = thumbnailImage
        }

        try await saveMediaToHistory(downloadUrl: url)
    }

    try deleteAllTmpFiles()
}
