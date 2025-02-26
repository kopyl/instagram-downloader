import Foundation
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        init(parent: WebView) {
            self.parent = parent
        }
        
        func saveCookiesToUserDefaults(webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var cookieData: [[String: String]] = []

                for cookie in cookies {
                    let cookieProperties: [String: String] = [
                        "name": cookie.name,
                        "value": cookie.value
                    ]
                    cookieData.append(cookieProperties)
                }
                
                
                guard let sharedDefaults = UserDefaults(suiteName: Names.APPGROUP) else {
                    return
                }
                
                sharedDefaults.set(cookieData, forKey: Names.cookies)
                sharedDefaults.synchronize()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            saveCookiesToUserDefaults(webView: webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        // Create a new configuration for the WebView
        let configuration = WKWebViewConfiguration()
        
        // Create a non-persistent data store (this will not save data between app launches)
        let nonPersistentDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = nonPersistentDataStore
        
        // Create the WebView with the configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Create and load the request
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    // Helper method to clear cookies
    private func clearCookies(in webView: WKWebView) {
        // Get all cookie types
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        // Clear all website data
        webView.configuration.websiteDataStore.removeData(
            ofTypes: dataTypes,
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: {}
        )
    }
}
