import SwiftUI

struct InstagramLoginSheet: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var isLoggingIn: Bool
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    var path: Binding<NavigationPath>? = nil
    var notification: AlertNotification? = nil
    var onSuccess: () -> Void = {}

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: {
            Task() {
                do {
                    let response = try await makeRequest(strUrl: "https://www.instagram.com/api/v1/friendships/pending/")
                    let jsonObject = try JSONSerialization.jsonObject(with: response, options: [])
                    
                    guard let jsonDictionary = jsonObject as? [String: Any] else {
                        throw Errors.keyNotFoundError
                    }
                    guard let status = jsonDictionary["status"] as? String else {
                        throw Errors.keyNotFoundError
                    }
                    if status == "fail" {
                        throw Errors.loginStatusIsFailed
                    }

                    if let notification {
                        notification.dismiss()
                    }
                    isLoggingIn = false
                    hasUserLoggedInAtLeastOnce = true
                    path?.wrappedValue.append("Home")
                    onSuccess()
                }
                catch {
                    if let notification {
                        notification.present(type: .error, title: "Login failed. Please login.")
                    }
                    isLoggingIn = false
                    path?.wrappedValue = .init()
                }
            }
        },
        content: {
            WebView(url: URL(string: "https://instagram.com")!)
                .onAppear {
                    isLoggingIn = true
                }
        }
    )
    }
}
