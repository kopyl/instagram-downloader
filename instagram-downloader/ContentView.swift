import SwiftUI

struct ContentView: View {
    @AppStorage(
        Names.hasUserLoggedInAtLeastOnce,
        store: UserDefaults(suiteName: Names.APPGROUP)
    ) private var hasUserLoggedInAtLeastOnce: Bool = false
    
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingView(
                hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                path: $path
            )
            .onAppear {
                if hasUserLoggedInAtLeastOnce {
                    path.append("Home")
                }
            }
            .onChange(of: hasUserLoggedInAtLeastOnce) {
                if hasUserLoggedInAtLeastOnce {
                    path.append("Home")
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "Home" {
                    HistoryView(
                        hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                        path: $path
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
