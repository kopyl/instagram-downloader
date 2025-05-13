//
//  SavedItem.swift
//  instagram-downloader
//
//  Created by Oleh Kopyl on 13.05.2025.
//

import Foundation
import SwiftUI

struct SavedItemView: View {
    let reel: Reel
    public var notification: AlertNotification
    
    private func openReel(_ reel: Reel) {
        guard let url = URL(string: reel.url) else {
            notification.present(type: .error, title: "Invalid URL")
            return
        }
        UIApplication.shared.open(url)
    }
    
    var body: some View {
        VStack {
            HStack {
                WText(reel.type == .image ? "Image" : "Video").font(.title)
                Spacer()
                HStack {
                    Button(
                        action: {
                            print("Hi")
                            openReel(reel)
                        }, label: {
                            Text("Open in Instagram")
                                .foregroundStyle(.white)
                                .opacity(0.6)
                        }
                    )
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .opacity(0.6)
                }
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 18)
            VStack {
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
            VStack {
                List {
                    Button {
                        reel.thumbnail?.pngData()
                        guard let thumbnail = reel.thumbnail else { return }
                        UIImageWriteToSavedPhotosAlbum(thumbnail, nil, nil, nil)
                        notification.present(type: .success)
                    } label: {
                        HStack {
                            if reel.type == .video {
                                WText("Save first frame")
                            }
                            else {
                                WText("Save picture")
                            }
                            Spacer()
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.white)
                                .opacity(0.9)
                        }
                    }
                    CopyButton(text: "Copy link", reel: reel, notification: notification)
                }
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
            }
        }
        .background(.appBg)
        .navigationBarBackButtonHidden()
        .onAppear {
            AppState.shared.swipeEnabled = true
        }
    }
}

//extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if AppState.shared.swipeEnabled {
//            return viewControllers.count > 1
//        }
//        return false
//    }
//    
//}


#Preview {
    SavedItemView(reel: .mock, notification: AlertNotification())
}
