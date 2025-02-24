import SwiftData
import SwiftUI

@Model
class Reel {
    var url: String
    var mediaIdentifierFromPhotosApp: String?
    var type: URLTypes
    var dateSaved: Date
    
    @Attribute(.externalStorage) var thumbnailData: Data?

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
            guard let data = thumbnailData else { return nil }
            return UIImage(data: data)
        }
        set {
            thumbnailData = newValue?.pngData()
        }
    }
}
