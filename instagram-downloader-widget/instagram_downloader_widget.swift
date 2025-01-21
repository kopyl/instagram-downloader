import ActivityKit
import WidgetKit
import SwiftUI

struct Instagram_downloader_widget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadProgressAttributes.self) { context in
            Instagram_downloader_widgetView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                }
            } compactLeading: {
            } compactTrailing: {
                if context.state.isDownloaded {
                    Circle()
                        .fill(.green)
                }
                else if context.state.isDownloading {
                    Circle()
                        .fill(.blue)
                    
                } else {
                    EmptyView()
                }
            } minimal: {
                Text("Minimal")
            }

        }
    }
}

struct Instagram_downloader_widgetView: View {
    let context: ActivityViewContext<DownloadProgressAttributes>
    
    var body: some View {
        Text("Hi")
    }
}
