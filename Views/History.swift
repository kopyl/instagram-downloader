import Foundation
import SwiftUI
import SwiftData

struct EmptyHistoryView: View {
    @Binding var isTutorialSheetOpen: Bool
    @StateObject private var step = Step()
    
    var body: some View {
        Spacer()
        WText("History of downloaded media will appear here")
            .font(.system(size: 14))
        Spacer()
        Button() {
            withAnimation() {
                isTutorialSheetOpen = true
            }
        } label: {
            VStack {
                WText("How to download media?")
                    .foregroundStyle(.white)
                    .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .background(.button)
            .cornerRadius(borderRadius)
            .font(.system(size: 14))
        }
        .padding(.horizontal, 18)
        .sheet(isPresented: $isTutorialSheetOpen.animation()) {
            ZStack {
                Color.appBg
                    .ignoresSafeArea()
                VStack {
                    StepperView(stepper: step)
                        .padding(.horizontal, 18)
                    .gesture(dragGesture(step: step))
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct HistoryView: View {
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var store
    @Environment(\.openURL) var openURL
    @State private var showingWebView  = false
    @State private var isTutorialSheetOpen = false
    @Query(sort: \Reel.dateSaved, order: .reverse) private var savedReels: [Reel]

    public var notification = Notification()
    
    var body: some View {
        ZStack {
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
                    if savedReels.isEmpty {
                        EmptyHistoryView(isTutorialSheetOpen: $isTutorialSheetOpen)
                    }
                    else {
                        List(savedReels, id: \.self) { (reel: Reel) in
                            LazyVStack {
                                HStack(spacing: 15) {
                                    let preview = Thumbnail(reel: reel)
                                    preview
                                    HStack {
                                        HStack(spacing: 12) {
                                            Icon(imageName: preview.name, font: .system(size: 12))
                                            WText(formattedDate(reel.dateSaved))
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
                                    openURL(URL(string: reel.url)!)
                                }
                                .contextMenu {
                                    Button {
                                        openURL(URL(string: reel.url)!)
                                    } label: {
                                        WText("Go to video")
                                        Image(systemName: "arrow.right")
                                    }
                                    Button {
                                        reel.thumbnail?.pngData()
                                        guard let thumbnail = reel.thumbnail else { return }
                                        UIImageWriteToSavedPhotosAlbum(thumbnail, nil, nil, nil)
                                        notification.present(type: .success)
                                    } label: {
                                        WText("Save preview")
                                        Image(systemName: "photo.fill")
                                    }
                                    CopyButton(text: "Copy link", reel: reel, notification: notification)
                                } preview: {
                                    if let image = reel.thumbnail {
                                        Image(uiImage: image).resizable()
                                    }
                                }
                            }
                            .listRowInsets(.init(top: 0, leading: 20, bottom: 5, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.appBg)
                            .swipeActions(edge: .trailing) {
                                CopyButton(text: nil, reel: reel, notification: notification)
                            }
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
            Color.white.opacity(0.05)
            .ignoresSafeArea()
            .opacity(isTutorialSheetOpen ? 0.7 : 0)
        }
    }
}
