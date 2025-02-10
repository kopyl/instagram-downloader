# Instagram video and photo downloader

### Here is a video demo on how it works:
![Video demo](https://github.com/user-attachments/assets/fda935e4-886e-4666-9bee-7e94debdf1ae)

How to:

### Use XCode Previews Previews with SwiftData:

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
var downloadUrlManual = _URL(type: .video, url: URL(string: "https://scontent-iev1-1.cdninstagram.com/o1/v/t16/f2/m86/AQPhRo6eZDIJepfEbC1wtD20dsXp6PrjW_9UzafG8ncTsbbPszHTIFQ0HNYEUSx0Ffz6qqLLq8rirHkf7Fuskuv5SLNL38ddGnSVZw8.mp4?efg=eyJ4cHZfYXNzZXRfaWQiOjEzMTY2MzQ0NDYwMDcxODMsInZlbmNvZGVfdGFnIjoieHB2X3Byb2dyZXNzaXZlLklOU1RBR1JBTS5DTElQUy5DMy43MjAuZGFzaF9iYXNlbGluZV8xX3YxIn0&_nc_ht=scontent-iev1-1.cdninstagram.com&_nc_cat=104&_nc_oc=AdiRRzBZZjYz4U-Rsr-8kVNssIaTpKrefj7sqHDJf5P6Ed101PF2ZZnbVmZRO7J6Qb4&vs=cca14c0ad7163879&_nc_vs=HBksFQIYUmlnX3hwdl9yZWVsc19wZXJtYW5lbnRfc3JfcHJvZC9GNzREMDgzNTlFNzk4QjFGRjdCNUVBQ0JEQzM3QTc4MF92aWRlb19kYXNoaW5pdC5tcDQVAALIAQAVAhg6cGFzc3Rocm91Z2hfZXZlcnN0b3JlL0dNNGRQeHlNVlFFaVc3QUVBSWUyNFY0YWRCbEFicV9FQUFBRhUCAsgBACgAGAAbAogHdXNlX29pbAExEnByb2dyZXNzaXZlX3JlY2lwZQExFQAAJp6uoIeb3tYEFQIoAkMzLBdAK5mZmZmZmhgSZGFzaF9iYXNlbGluZV8xX3YxEQB1_gcA&ccb=9-4&oh=00_AYDxbBdwXCTOswtgAGbuXhkuEGpAOWE8UeoHURRsAK31vw&oe=67AB1C51&_nc_sid=1d576d")!)

downloadUrlManual.initReelURL = "https://www.instagram.com/reel/DE_nthRIafF/?igsh=NTBxaDU4eDk5bTh2"

guard let file = try await downloadFile(from: downloadUrlManual) else { return }
downloadUrlManual.localFilePath = file

try await saveMediaToPhotos(downloadUrl: downloadUrlManual)
```