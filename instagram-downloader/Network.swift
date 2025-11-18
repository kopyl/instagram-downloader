import Foundation
import SwiftUI

func convertStringToDictionary(_ text: String) throws -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        return json
    }
    return nil
}

func deleteAllTmpFiles() throws {
    let tempDirectory = FileManager.default.temporaryDirectory
    
    let fileURLs = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
    
    for fileURL in fileURLs {
        try FileManager.default.removeItem(at: fileURL)
    }
}

func downloadFile(from url: _URL) async throws -> URL? {
    guard let (tempFileURL, _) = try? await URLSession.shared.download(from: url.url) else {
        throw Errors.makeRequestForDownloadingFinalMediaFileFailed
    }
    
    var destinationURL: URL
    switch url.type {
    case .video:
        destinationURL = tempFileURL.appendingPathExtension("mp4")
    case .image:
        destinationURL = tempFileURL.appendingPathExtension("png")
    }
    
    try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)

    return destinationURL
}

func urlToVideoCode(_ url: String) -> String? {
    guard let urlComponents = URL(string: url) else { return nil }
    let path = urlComponents.path
    let parts = path.split(separator: "/").map { String($0) }
    return parts.last
}

func urlToCleanURL(_ url: String) -> String? {
    guard let url = URL(string: url),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        components.query = nil
        components.scheme = nil
        components.host = components.host?.replacingOccurrences(of: "www.", with: "")
        
        return components.url?.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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


var HEADERS: [String: String] = [
    "X-IG-App-ID": "936619743392459",
    "X-ASBD-ID": "198387",
    "X-IG-WWW-Claim": "0",
    "Origin": "https://www.instagram.com",
    "Accept": "*/*",
    "X-Requested-With": "XMLHttpRequest",
]

func makeRequest(strUrl: String) async throws -> Data {
    guard let url = URL(string: strUrl) else {
        throw Errors.InvalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    guard let sharedDefaults = UserDefaults(suiteName: Names.APPGROUP),
          let savedCookies = sharedDefaults.array(forKey: Names.cookies) as? [[String: String]] else {
        throw Errors.noCookiesSavedFromWebView
    }

    if let csrfToken = savedCookies.first(where: { $0["name"] == "csrftoken" })?["value"] {
        HEADERS["X-CSRFToken"] = csrfToken
    }
    
    HEADERS["Referer"] = strUrl
    HEADERS.forEach { key, value in
        request.setValue(value, forHTTPHeaderField: key)
    }

    let cookieHeader = savedCookies.map { "\($0["name"] ?? "")=\($0["value"] ?? "")" }.joined(separator: "; ")
    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

    guard let (data, _) = try? await URLSession.shared.data(for: request) else {
        throw Errors.makeRequestFailed
    }
    
    return data
}

enum Errors: String, LocalizedError {
    case InvalidURL
    case keyNotFoundError
    case itemVersionIsEmpty
    case invalidItemURL
    case emptyLocalFileURL
    case invalidImageVersion
    case noWidth
    case URLOBjectInvalid
    case noSavedCookies
    case noSavedHeaders
    case noDownloadURL
    case noCookiesSavedFromWebView
    case makeRequestFailed
    case makeRequestForDownloadingFinalMediaFileFailed
    case loginStatusIsFailed
    case jsonWithMediaURLsCantBeRead
    case urlIsNotFromInstagram
    
    var errorDescription: String? {
        rawValue
    }
}

func getFirstItemFrom(from responseData: Data) throws -> [String : Any] {
    var jsonObject: Any
    
    do {
        jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
    } catch {
        throw Errors.jsonWithMediaURLsCantBeRead
    }

    guard let jsonDictionary = jsonObject as? [String: Any] else {
        throw Errors.keyNotFoundError
    }

    guard let items = jsonDictionary["items"] as? [[String: Any]], items.count == 1 else {
        throw Errors.keyNotFoundError
    }
    
    guard let firstItem = items.first else {
        throw Errors.keyNotFoundError
    }
    
    return firstItem
}

func getBiggestItem(itemVersion: [[String : Any]]) throws -> String {
    guard !itemVersion.isEmpty else { throw Errors.itemVersionIsEmpty }
    
    let sortedItemVersions = try itemVersion.sorted {
        guard let width1 = $0["width"] as? Int else { throw Errors.noWidth }
        guard let width2 = $1["width"] as? Int else { throw Errors.noWidth }
        return width1 > width2
    }

    guard let firsItem = sortedItemVersions.first, let firsItemURL = firsItem["url"] as? String else {
        throw Errors.invalidItemURL
    }

    return firsItemURL
}

func getCarousel(item initialJson: [String : Any]) throws -> [[String : Any]]? {
    if let carouselMedia = initialJson["carousel_media"] as? [[String : Any]] {
        return carouselMedia
    }
    return nil
}

func getBiggestVideoOrImageURL(from initialJson: [String: Any]) throws -> _URL {
    if let videoVersions = initialJson["video_versions"] as? [[String: Any]] {
        let biggestItem = try getBiggestItem(itemVersion: videoVersions)
        guard let _url = URL(string: biggestItem) else { throw Errors.URLOBjectInvalid }
        return _URL(type: .video, url: _url)
    }
    guard
        let imageCandidates = initialJson["image_versions2"] as? [String: [[String: Any]]],
        let imageVersion = imageCandidates["candidates"]
    else {
        throw Errors.invalidImageVersion
    }
    let biggestItem = try getBiggestItem(itemVersion: imageVersion)
    guard let _url = URL(string: biggestItem) else { throw Errors.URLOBjectInvalid }
    return _URL(type: .image, url: _url)
}


enum URLTypes: String, Codable {
    case video
    case image
}

struct _URL {
    let type: URLTypes
    let url: URL
    var mediaIdentifierFromPhotosApp: String? = nil
    var localFilePath = URL(string: "")
    var initReelURL = ""
    var thumbnail: UIImage?
}

func downloadRegularMediaURLs(reelURL: String) async throws -> [_URL] {
    guard let videoCode = urlToVideoCode(reelURL) else { return [] }
    guard let videoID = videoCodeToVideoID(videoCode) else { return [] }
    let videoApiURL = videoIDToAPIURl(videoID)

    let response = try await makeRequest(strUrl: videoApiURL)
    let firstItem = try getFirstItemFrom(from: response)
    
    let carouselMedia = try getCarousel(item: firstItem)
    if let cm = carouselMedia {
        var itemURLs: [_URL] = []
        for carouselItem in cm {
            var itemURL = try getBiggestVideoOrImageURL(from: carouselItem)
            itemURL.initReelURL = reelURL
            itemURLs.append(itemURL)
        }
        return itemURLs
    }
    
    var itemURL = try getBiggestVideoOrImageURL(from: firstItem)
    itemURL.initReelURL = reelURL

    return [itemURL]
}

func getDownloadURLs(reelURL: String) async throws -> [_URL] {
    if !reelURL.contains("instagram") {
        throw Errors.urlIsNotFromInstagram
    }
    if reelURL.contains("/stories/") {
        return try await getStoryDownloadURLs(reelURL: reelURL)
    }
    return try await downloadRegularMediaURLs(reelURL: reelURL)
}

func getStoryDownloadURLs(reelURL: String) async throws -> [_URL] {
    guard let url = URL(string: reelURL) else {
        throw Errors.InvalidURL
    }
    let pathComponents = Array(url.pathComponents.dropFirst())
    guard
        pathComponents.count >= 2,
        pathComponents[0] == "stories"
    else {
        throw Errors.InvalidURL
    }
    
    let username = pathComponents[1]
    let storyID = pathComponents[2]
    
    let userProfileAPIURL = "https://www.instagram.com/api/v1/users/web_profile_info/?username=\(username)"
    let userProfileResponse = try await makeRequest(strUrl: userProfileAPIURL)
    
    guard let userProfileJSON = try JSONSerialization.jsonObject(with: userProfileResponse) as? [String: Any],
          let data = userProfileJSON["data"] as? [String: Any],
          let user = data["user"] as? [String: Any],
          let userID = user["id"] as? String else {
        throw Errors.keyNotFoundError
    }
    
    let storyAPIURL = "https://i.instagram.com/api/v1/feed/user/\(userID)/story/"
    let storyResponse = try await makeRequest(strUrl: storyAPIURL)
    
    guard let storyJSON = try JSONSerialization.jsonObject(with: storyResponse) as? [String: Any],
          let reel = storyJSON["reel"] as? [String: Any],
          let items = reel["items"] as? [[String: Any]] else {
        throw Errors.keyNotFoundError
    }
    
    guard let storyItem = items.first(where: { item in
        if let pk = item["pk"] as? String {
            return pk == storyID
        } else if let pk = item["pk"] as? Int {
            return String(pk) == storyID
        }
        return false
    }) else {
        throw Errors.keyNotFoundError
    }
    
    var itemURL = try getBiggestVideoOrImageURL(from: storyItem)
    itemURL.initReelURL = reelURL
    
    return [itemURL]
}
