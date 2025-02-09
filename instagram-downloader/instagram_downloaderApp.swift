import SwiftUI
import SwiftData

@main
struct instagram_downloaderApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ReelUrl.self])
        }
    }
}
