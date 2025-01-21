import SwiftData
import SwiftUI

@Model
class ReelUrl {
    @Attribute(.externalStorage) var url: String
    var isDownloaded: Bool

    init(url: String, isDownloaded: Bool = false) {
        self.url = url
        self.isDownloaded = isDownloaded
    }
}
