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
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
