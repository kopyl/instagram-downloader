import Foundation
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var store
    @Environment(\.openURL) var openURL
    @State private var showingWebView  = false
    @Query(sort: \ReelUrl.dateSaved, order: .reverse) private var savedReelUrls: [ReelUrl]

    public var notification = Notification()
    
    var body: some View {
        VStack {
            HStack {
                WText("History").font(.title)
                Spacer()
                LoginBrowserButton {
                    showingWebView.toggle()
                }
                .sheet(isPresented: $showingWebView) {
                    WebView(url: URL(string: "https://instagram.com")!)
                }
            }
            .padding(.trailing, 2)
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack {
                if savedReelUrls.isEmpty {
                    Spacer()
                    WText("History of downloaded media will appear here")
                        .font(.system(size: 14))
                    Spacer()
                }
                else {
                    List {
                        ForEach(savedReelUrls, id: \.self) { (reelUrl: ReelUrl) in
                            HStack(spacing: 15) {
                                let preview = Thumbnail(reelUrl: reelUrl)
                                preview
                                HStack {
                                    HStack(spacing: 12) {
                                        Icon(imageName: preview.name, font: .system(size: 12))
                                        WText(formattedDate(reelUrl.dateSaved))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .opacity(0.6)
                                }
                            }
                            .frame(height: 70)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openURL(URL(string: reelUrl.url)!)
                            }
                            .contextMenu {
                                Button {
                                    openURL(URL(string: reelUrl.url)!)
                                } label: {
                                    WText("Go to video")
                                    Image(systemName: "arrow.right")
                                }
                                Button {
                                    reelUrl.thumbnail?.pngData()
                                    guard let thumbnail = reelUrl.thumbnail else { return }
                                    UIImageWriteToSavedPhotosAlbum(thumbnail, nil, nil, nil)
                                    notification.present(type: .success)
                                } label: {
                                    WText("Save preview")
                                    Image(systemName: "photo.fill")
                                }
                                CopyButton(text: "Copy link", reelUrl: reelUrl, notification: notification)
                            } preview: {
                                if let image = reelUrl.thumbnail {
                                    Image(uiImage: image).resizable()
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 20, bottom: 5, trailing: 20))
                            .swipeActions(edge: .trailing) {
                                CopyButton(text: nil, reelUrl: reelUrl, notification: notification)
                            }
                        }
                        .listRowBackground(Color.appBg)
                    }
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, 0)
        }
        .background(.appBg)
        .onAppear {
            notification.setWindowScene()
        }
        .navigationBarBackButtonHidden()
    }
}
