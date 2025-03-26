import SwiftData
import SwiftUI

@Model
class Reel {
    var url: String
    var mediaIdentifierFromPhotosApp: String?
    var type: URLTypes
    var dateSaved: Date
    
    var thumbnailPath: String?

    init(_ url: String, type: URLTypes, mediaIdentifierFromPhotosApp: String? = nil) {
        self.url = url
        self.mediaIdentifierFromPhotosApp = mediaIdentifierFromPhotosApp
        self.type = type
        self.dateSaved = Date()
    }
    
    func cleanURL() -> String {
        urlToCleanURL(url) ?? ""
    }
    
    var thumbnail: UIImage? {
        get {
            guard let path = thumbnailPath else {
                return nil
            }
            guard let appGroupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Names.APPGROUP) else {
                return nil
            }
            let directory = appGroupDirectory.appendingPathComponent("Application Support")
            let fileName = directory.appendingPathComponent(path)
            return UIImage(contentsOfFile: fileName.path)
        }
        set {
            if let newValue = newValue {
                thumbnailPath = saveThumbnailToDisk(newValue)
            }
        }
    }
    
    private func saveThumbnailToDisk(_ image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        
        guard let appGroupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Names.APPGROUP) else {
            return nil
        }
        
        let directory = appGroupDirectory.appendingPathComponent("Application Support")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let fileName = UUID().uuidString + ".png"
        let filePath = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: filePath)
            return fileName
        } catch {
            return nil
        }
    }
}
