import Foundation
import SwiftUI
import SwiftData
import Photos
import AVKit

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

func getVideoURL(from mediaIdentifierFromPhotosApp: String, completion: @escaping (URL?) -> Void) {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [mediaIdentifierFromPhotosApp], options: nil)
    guard let asset = assets.firstObject else {
        completion(nil)
        return
    }

    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true

    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
        if let urlAsset = avAsset as? AVURLAsset {
            completion(urlAsset.url)
        } else {
            completion(nil)
        }
    }
}

struct VideoPlayerView: View {
    let mediaIdentifierFromPhotosApp: String
    let thumbnail: UIImage?
    @State private var player: AVPlayer?
    @State private var isVideoNotPresentInPhotos = false

    var body: some View {
        VStack {
            if let player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.isMuted = true
                        player.play()
                    }
            } else {
                if isVideoNotPresentInPhotos {
                    if let thumbnail {
                        Image(uiImage: thumbnail).resizable()
                    } else {
                        Text("There is no preview for this reel")
                    }
                }
                else {
                    Text("Loading video...")
                }
            }
        }
        .onAppear {
            fetchVideo()
        }
        .onDisappear {
            player = nil
        }
    }

    private func fetchVideo() {
        getVideoURL(from: mediaIdentifierFromPhotosApp) { url in
            if let url {
                player = AVPlayer(url: url)
            }
            else {
                isVideoNotPresentInPhotos = true
            }
        }
    }
}

struct HistoryView: View {
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    @Binding var path: [Route]
    @Environment(\.modelContext) private var store
    @State private var showingWebView  = false
    @State private var isLoggingIn  = false
    @State private var isTutorialSheetOpen = false
    @Query(sort: \Reel.dateSaved, order: .reverse) private var savedReels: [Reel]

    public var notification: AlertNotification
    
    private func openReel(_ reel: Reel) {
        guard let url = URL(string: reel.url) else {
            notification.present(type: .error, title: "Invalid URL")
            return
        }
        UIApplication.shared.open(url)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    WText("History").font(.title)
                    Spacer()
                }
                .padding(.trailing, 2)
                .padding(.leading, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack {
                    if savedReels.isEmpty {
                        EmptyHistoryView(isTutorialSheetOpen: $isTutorialSheetOpen)
                    }
                    else {
                        List {
                            Color.clear
                                .frame(height: UIScreen.main.bounds.height/2.5)
                                .listRowBackground(Color.clear)
                            
                            ForEach(savedReels, id: \.self) { (reel: Reel) in
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
                                            Image(systemName: "chevron.forward")
                                                .font(.caption)
                                                .opacity(0.6)
                                        }
                                    }
                                    .frame(height: 70)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        path.append(.savedItem(reel))
                                    }
                                    .contextMenu {
                                        Button { openReel(reel) } label: {
                                            WText("Open in Instagram")
                                            Image(systemName: "arrow.up.forward")
                                        }
                                        Button {
                                            reel.thumbnail?.pngData()
                                            guard let thumbnail = reel.thumbnail else { return }
                                            UIImageWriteToSavedPhotosAlbum(thumbnail, nil, nil, nil)
                                            notification.present(type: .success)
                                        } label: {
                                            if reel.type == .video {
                                                WText("Save first frame")
                                            }
                                            else {
                                                WText("Save picture")
                                            }
                                            Image(systemName: "photo.fill")
                                        }
                                        CopyButton(text: "Copy link", reel: reel, notification: notification)
                                    } preview: {
                                        if reel.type == .image {
                                            if let image = reel.thumbnail {
                                                Image(uiImage: image).resizable()
                                            }
                                        }
                                        else {
                                            if let mediaIdentifierFromPhotosApp = reel.mediaIdentifierFromPhotosApp {
                                                VideoPlayerView(
                                                    mediaIdentifierFromPhotosApp: mediaIdentifierFromPhotosApp,
                                                    thumbnail: reel.thumbnail
                                                )
                                            }
                                            else if let image = reel.thumbnail {
                                                Image(uiImage: image).resizable()
                                            }
                                            
                                        }
                                    }
                                }
                                .listRowInsets(.init(top: 0, leading: 20, bottom: 5, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.appBg)
                                
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.delete(reel)
                                        notification.present(type: .success, title: "Deleted successfully")
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                    
                                    Button {
                                        UIPasteboard.general.string = reel.cleanURL()
                                        notification.present(type: .success, title: "Copied to clipboard")
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 0)
            }
            .background(.appBg)
            .navigationBarBackButtonHidden()
            Color.white.opacity(0.05)
            .ignoresSafeArea()
            .opacity(isTutorialSheetOpen ? 0.7 : 0)
        }
        .modifier(
            InstagramLoginSheet(
                isPresented: $showingWebView,
                isLoggingIn: $isLoggingIn,
                hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                path: $path,
                notification: notification
            )
        )
    }
}
