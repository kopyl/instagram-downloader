import Foundation

func downloadFile(from url: URL) async throws -> URL? {
    let (tempFileURL, _) = try await URLSession.shared.download(from: url)
    
    let destinationURL = tempFileURL.appendingPathExtension("mp4")
    
    if FileManager.default.fileExists(atPath: destinationURL.relativePath) {
        try FileManager.default.removeItem(at: destinationURL)
    }
    
    do {
        try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)
    } catch let error {
        print(error)
    }

    return destinationURL
}

func isValidInstagramReelURL(url: String) -> Bool {
    let pattern = "^https://(www.)?instagram\\.com/(reel|p)/[A-Za-z0-9_-]+(?:/)?(?:\\?igsh=[A-Za-z0-9%=]+)?$"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    let range = NSRange(location: 0, length: url.utf16.count)
    let match = regex.firstMatch(in: url, options: [], range: range)
    
    return match != nil
}

func urlToVideoCode(_ url: String) -> String? {
    guard let urlComponents = URL(string: url) else { return nil }
    let path = urlComponents.path
    let parts = path.split(separator: "/").map { String($0) }
    return parts.last
}

func videoCodeToVideoID(_ shortcode: String) -> Int? {
    let encodingChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    var table: [Character: Int] = [:]
    
    for (index, char) in encodingChars.enumerated() {
        table[char] = index
    }
    
    var result = 0
    let base = table.count
    
    for char in shortcode.prefix(11) {
        guard let value = table[char] else { return nil }
        result = result * base + value
    }
    
    return result
}

func videoIDToAPIURl(_ id: Int) -> String {
    let API_BASE_URL = "https://i.instagram.com/api/v1"
    return "\(API_BASE_URL)/media/\(id)/info/"
}

func makeRequest(strUrl: String, videoCode: String) async throws -> Data {
    guard let url = URL(string: strUrl) else {
        throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (cookies, headers) = getCookiesAndHeaders(reelURL: strUrl)

    headers.forEach { key, value in
        request.setValue(value, forHTTPHeaderField: key)
    }

    let cookieHeader = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

enum VideoParserError: String, LocalizedError {
    case jsonParsingError
    case keyNotFoundError
    case invalidVideoVersions
    case invalidVideoURL
    case noWidth
    
    var errorDescription: String? {
        rawValue
    }
}

func getBiggestVideo(from responseData: Data) throws -> String {
    let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])

    guard let jsonDictionary = jsonObject as? [String: Any] else {
        throw VideoParserError.keyNotFoundError
    }

    guard let items = jsonDictionary["items"] as? [[String: Any]], items.count == 1 else {
        throw VideoParserError.keyNotFoundError
    }
    
    guard let firstItem = items.first else {
        throw VideoParserError.keyNotFoundError
    }

    guard let videoVersions = firstItem["video_versions"] as? [[String: Any]], !videoVersions.isEmpty else {
        throw VideoParserError.invalidVideoVersions
    }

    let sortedVideoVersions = try videoVersions.sorted {
        guard let width1 = $0["width"] as? Int else { throw VideoParserError.noWidth }
        guard let width2 = $1["width"] as? Int else { throw VideoParserError.noWidth }
        return width1 > width2
    }

    guard let firstVideo = sortedVideoVersions.first, let firstVideoURL = firstVideo["url"] as? String else {
        throw VideoParserError.invalidVideoURL
    }

    return firstVideoURL
}

func getVideoDownloadURL(reelURL: String) async throws -> URL? {
    guard let videoCode = urlToVideoCode(reelURL) else { return nil }
    guard let videoID = videoCodeToVideoID(videoCode) else { return nil }
    let videoApiURL = videoIDToAPIURl(videoID)

    let response = try await makeRequest(strUrl: videoApiURL, videoCode: videoCode)
    let videoURL = try getBiggestVideo(from: response)
    
    return URL(string: videoURL)
}
