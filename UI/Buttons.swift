import SwiftUI

struct LoginBrowserButton: View {
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "safari")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .opacity(0.7)
        }
    }
}

struct CopyButton: View {
    let text: String?
    let reel: Reel
    let notification: AlertNotification
    
    var body: some View {
        Button {
            UIPasteboard.general.string = reel.cleanURL()
            notification.present(type: .success, title: "URL copied")
        } label: {
            if let text {
                WText(text)
            }
            Image(systemName: "document.on.document.fill")
        }
    }
}
