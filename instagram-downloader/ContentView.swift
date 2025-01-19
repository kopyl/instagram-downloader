import SwiftUI

struct NotificationBanner: View {
    var message: String
    var body: some View {
        Text(message)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var showNotification = true
    @State private var url: String = ""
    
    
    var body: some View {
        VStack {
            Text(url)
            NotificationBanner(message: "Test")
                                .transition(.move(edge: .top))
                                .animation(.easeInOut, value: showNotification)
                                .padding()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            guard let _url = UIPasteboard.general.string else { return }
            url = _url
        }
    }
}

#Preview {
    ContentView()
}
