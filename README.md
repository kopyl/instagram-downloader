# Instagram video and photo downloader
*With user cookies and headers for downloading*

**IMPORTANT:** <br>
A user is required to enter username and password from Instagram, so use it on your own risk. <br>
Using a fresh instagram account you're not afraid to loose is highly advised.

### Features:
- Video downloads
- Pictures downloads
- Ads downloads
- History of downloads
- Downloads with Share Extension (Share to -> Instagram dl)


### Here is a video demo on how it works:
<video src="https://github.com/user-attachments/assets/fda935e4-886e-4666-9bee-7e94debdf1ae" width="300" controls></video>

How to:

# Distribute

### Change app version:

1. Go to Project settings (not targes)
2. Go to Build Settings
3. Scroll to the very bottom
4. Change `APP_BUILD` to `APP_BUILD` +1 and `APP_VERSION` to any higher number

# Develop:

### Use XCode Previews with SwiftData:

```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ReelUrl.self, configurations: config)
    
    let context = container.mainContext
    
    context.insert(
        ReelUrl("https://www.instagram.com/reel/DF2k_eFMhgb/?igsh=ZThrZGtta3czcWt5", type: .video)
    )

    return ContentView()
        .modelContainer(container)
}
```

### Delete all data from SwiftData store:

```swift
let context = try ModelContext(.init(for: ReelUrl.self))
try context.delete(model: ReelUrl.self)
```

### Insert some dummy data to the SwiftData store:

```swift
let context = try ModelContext(.init(for: ReelUrl.self))
context.insert(ReelUrl("shortCode", type: .image))  // add more data if needed
try context.save()  // this is necessary step, otherwise the data is not saved
```

### Download video with a final item URL:

```swift
func downloadAndSaveMedia(reelURL: String) async throws {
    var downloadUrl = _URL(type: .video, url: URL(string: "https://github.com/user-attachments/assets/ef9b2c52-b98a-4346-a84e-d546c73a9deb")!)
    guard let file = try await downloadFile(from: downloadUrl) else {
        throw Errors.emptyLocalFileURL
    }
    downloadUrl.localFilePath = file
    
    downloadUrl = try await saveMediaToPhotos(downloadUrl: downloadUrl)

    if let thumbnailImage = try generateThumbnailFromItem(downloadUrl: downloadUrl) {
        downloadUrl.thumbnail = thumbnailImage
    }
    
    try await saveMediaToHistory(downloadUrl: downloadUrl)
    
    try deleteAllTmpFiles()
}
```