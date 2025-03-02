import SwiftUI

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
