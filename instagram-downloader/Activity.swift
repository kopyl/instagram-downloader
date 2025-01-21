import ActivityKit

struct DownloadProgressAttributes: ActivityAttributes {
    public typealias DownloadStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var isDownloading: Bool
        var isDownloaded: Bool
    }
}
