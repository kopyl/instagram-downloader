import SwiftData
import SwiftUI

@Model
class ReelUrl {
    var url: String
    var type: URLTypes
    var dateSaved: Date

    init(_ url: String, type: URLTypes) {
        self.url = url
        self.type = type
        self.dateSaved = Date()
    }
}
