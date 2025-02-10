import Foundation
import SwiftUI

extension String: Error {}

func getCookiesAndHeaders(reelURL: String) throws -> ([String: String], [String: String]) {
    guard let cookiesFromStore = UserDefaults(suiteName: "group.CY-041AF8F6-4884-11E7-AB8C-406C8F57CB9A.com.cydia.Extender")?.string(forKey: "cookies") else {
        throw Errors.noSavedCookies
    }
    let cookies = try (convertStringToDictionary(cookiesFromStore)) as! [String: String]
    
    guard let headersFromStore = UserDefaults(suiteName: "group.CY-041AF8F6-4884-11E7-AB8C-406C8F57CB9A.com.cydia.Extender")?.string(forKey: "headers")  else {
        throw Errors.noSavedHeaders
    }
    var headers = try (convertStringToDictionary(headersFromStore)) as! [String: String]
    
    headers["referer"] = reelURL
    
    return (cookies, headers)
}

func convertStringToDictionary(_ text: String) throws -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        return json
    }
    return nil
}

func downloadFile(from url: _URL) async throws -> URL? {
    let (tempFileURL, _) = try await URLSession.shared.download(from: url.url)
    
    var destinationURL: URL
    switch url.type {
    case .video:
        destinationURL = tempFileURL.appendingPathExtension("mp4")
    case .image:
        destinationURL = tempFileURL.appendingPathExtension("png")
    }
    
    if FileManager.default.fileExists(atPath: destinationURL.relativePath) {
        try FileManager.default.removeItem(at: destinationURL)
    }
    
    try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)

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

func makeRequest(strUrl: String, videoCode: String) async throws -> Data {
    guard let url = URL(string: strUrl) else {
        throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (cookies, headers) = try getCookiesAndHeaders(reelURL: strUrl)

    headers.forEach { key, value in
        request.setValue(value, forHTTPHeaderField: key)
    }

    let cookieHeader = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

enum Errors: String, LocalizedError {
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
    
    var errorDescription: String? {
        rawValue
    }
}

func getFirstItemFrom(from responseData: Data) throws -> [String : Any] {
    let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])

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

func getBiggestVideoOrImageURL(from responseData: Data) throws -> _URL {
    
    let firstItem = try getFirstItemFrom(from: responseData)

    if let videoVersions = firstItem["video_versions"] as? [[String: Any]] {
        let biggestItem = try getBiggestItem(itemVersion: videoVersions)
        guard let _url = URL(string: biggestItem) else { throw Errors.URLOBjectInvalid }
        return _URL(type: .video, url: _url)
    }
    guard
        let imageCandidates = firstItem["image_versions2"] as? [String: [[String: Any]]],
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
    var localFilePath = URL(string: "")
    var initReelURL = ""
    var thumbnail: UIImage?
}

func getDownloadURL(reelURL: String) async throws -> _URL? {
    guard let videoCode = urlToVideoCode(reelURL) else { return nil }
    guard let videoID = videoCodeToVideoID(videoCode) else { return nil }
    let videoApiURL = videoIDToAPIURl(videoID)

    let response = try await makeRequest(strUrl: videoApiURL, videoCode: videoCode)
    var itemURL = try getBiggestVideoOrImageURL(from: response)
    
    itemURL.initReelURL = reelURL
    
    return itemURL
}
