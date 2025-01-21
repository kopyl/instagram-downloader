//
//  instagram_downloader_widget.swift
//  instagram-downloader-widget
//
//  Created by Oleh Kopyl on 21.01.2025.
//

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
                if context.state.isDownloading {
                    Image(systemName: "arrow.down.circle.fill").foregroundColor(.blue)
                }
                EmptyView()
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
