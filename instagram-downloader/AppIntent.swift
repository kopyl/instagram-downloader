import AppIntents
import Foundation

struct DownloadInstagramIntent: AppIntent {
    static var title: LocalizedStringResource = "Download Instagram Content"
    static var description = IntentDescription("Downloads media from an Instagram URL and saves it to Photos")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Instagram URL", description: "The URL of the Instagram post, reel, or story to download")
    var url: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !url.isEmpty else {
            throw IntentError.invalidURL
        }

        guard url.contains("instagram") else {
            throw IntentError.notInstagramURL
        }

        do {
            try await downloadAndSaveMedia(reelURL: url)
            return .result(value: "Successfully downloaded and saved to Photos")
        } catch Errors.noCookiesSavedFromWebView {
            throw IntentError.notLoggedIn
        } catch {
            throw IntentError.downloadFailed(error.localizedDescription)
        }
    }
}

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case invalidURL
    case notInstagramURL
    case notLoggedIn
    case downloadFailed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidURL:
            return "Please provide a valid URL"
        case .notInstagramURL:
            return "The URL must be from Instagram"
        case .notLoggedIn:
            return "Please open the app and log in to Instagram first"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        }
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DownloadInstagramIntent(),
            phrases: [
                "Download Instagram with \(.applicationName)",
                "Save Instagram reel with \(.applicationName)",
                "Download reel with \(.applicationName)"
            ],
            shortTitle: "Download Instagram",
            systemImageName: "arrow.down.circle"
        )
    }
}
