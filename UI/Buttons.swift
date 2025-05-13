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
            HStack {
                if let text {
                    WText(text)
                }
                Spacer()
                Image(systemName: "document.on.document.fill")
                    .foregroundStyle(.white)
                    .opacity(0.9)
            }
        }
    }
}
