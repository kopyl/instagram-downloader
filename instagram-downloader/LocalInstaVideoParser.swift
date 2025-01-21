import Foundation

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

    let (cookies, headers) = getCookiesAndHeaders(videoCode: videoCode)

    headers.forEach { key, value in
        request.setValue(value, forHTTPHeaderField: key)
    }

    let cookieHeader = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

func getBiggestVideo(from responseData: Data) -> String? {
    var videoUrls: Array<String> = []
    let jsonObject: Any
    
    do {
        jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
    } catch {
        print("Failed to parse JSON: \(error.localizedDescription)")
        return nil
    }
        
    guard let jsonDictionary = jsonObject as? [String: Any] else {
        return nil
    }
    
    guard let items = jsonDictionary["items"] as? [[String: Any]] else {
        print("`items` key not found or not an array")
        return nil
    }
    
    guard items.count == 1 else {
        print("`items` count is not 1. It's \(items.count)")
        return nil
    }
    
    guard let firstItem = items.first else {
        print("There is no first item in `items`")
        return nil
    }

    guard let videoVersions = firstItem["video_versions"] as? [[String: Any]] else {
        print("`video_versions` key not found")
        return nil
    }

    let sortedVideoVersions = videoVersions.sorted {
            if let width1 = $0["width"] as? Int, let width2 = $1["width"] as? Int {
                return width1 > width2
            }
            return false
        }

    for videoVersion in sortedVideoVersions {
        if let videoURL = videoVersion["url"] as? String {
            videoUrls.append(videoURL)
        }
    }

    return videoUrls.first
}

func getVideoDownloadURL(reelURL: String) async throws -> URL? {
    guard let videoCode = urlToVideoCode(reelURL) else { return nil }
    guard let videoID = videoCodeToVideoID(videoCode) else { return nil }
    let videoApiURL = videoIDToAPIURl(videoID)

    let response = try await makeRequest(strUrl: videoApiURL, videoCode: videoCode)
    guard let videoURL = getBiggestVideo(from: response) else { return nil }
    
    return URL(string: videoURL)
}
