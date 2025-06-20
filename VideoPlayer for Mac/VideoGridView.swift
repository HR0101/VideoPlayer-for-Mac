import SwiftUI
import AVKit

struct VideoGridView: View {
    @ObservedObject var viewModel: VideoLibraryViewModel
    let videos: [VideoItem]
    @Binding var gridColumns: [GridItem]
    let columnCount: Int
    
    @Binding var videoToPlay: VideoItem?
    @Binding var isShowingPlayer: Bool
    
    @State private var selection: Set<VideoItem.ID> = []
    @FocusState private var focusedVideoID: VideoItem.ID?

    var body: some View {
        let isTrashView = viewModel.selectedItem == .category(.trash)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(videos) { video in
                        VideoGridCell(video: video, isSelected: selection.contains(video.id))
                            .id(video.id)
                            .focusable()
                            .focused($focusedVideoID, equals: video.id)
                            .onTapGesture {
                                self.videoToPlay = video
                                self.isShowingPlayer = true
                            }
                            .contextMenu {
                                if isTrashView {
                                    Button("元に戻す") {
                                        viewModel.recoverVideosFromTrash(videoIDs: [video.id])
                                    }
                                    Button("完全に削除", role: .destructive) {
                                        viewModel.moveVideosToTrash(videoIDs: [video.id])
                                    }
                                } else {
                                    if !viewModel.albums.isEmpty {
                                        Menu("アルバムに追加") {
                                            ForEach(viewModel.albums) { album in
                                                Button(album.name) {
                                                    viewModel.addVideos(videoIDs: [video.id], to: album)
                                                }
                                            }
                                        }
                                    }
                                    Button("ゴミ箱に入れる", role: .destructive) {
                                        viewModel.moveVideosToTrash(videoIDs: [video.id])
                                    }
                                }
                            }
                    }
                }
                .padding()
            }
            .onKeyPress(phases: .down) { press in handleKeyPress(press: press, proxy: proxy) }
            .onAppear { Task { if focusedVideoID == nil, let first = videos.first { focusedVideoID = first.id } } }
        }
    }
    
    private func handleKeyPress(press: KeyPress, proxy: ScrollViewProxy) -> KeyPress.Result {
        guard let currentFocusedId = focusedVideoID,
              let currentIndex = videos.firstIndex(where: { $0.id == currentFocusedId })
        else { return .ignored }
        var nextIndex: Int?
        switch press.key {
        case .rightArrow: if currentIndex < videos.count - 1 { nextIndex = currentIndex + 1 }
        case .leftArrow: if currentIndex > 0 { nextIndex = currentIndex - 1 }
        case .downArrow: if currentIndex + columnCount < videos.count { nextIndex = currentIndex + columnCount }
        case .upArrow: if currentIndex - columnCount >= 0 { nextIndex = currentIndex - columnCount }
        case .space:
            self.videoToPlay = videos[currentIndex]
            self.isShowingPlayer = true
            return .handled
        case .delete:
            viewModel.moveVideosToTrash(videoIDs: [currentFocusedId])
            return .handled
        default: return .ignored
        }
        if let next = nextIndex, videos.indices.contains(next) {
            let nextId = videos[next].id
            focusedVideoID = nextId
            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(nextId, anchor: .center) }
            return .handled
        }
        return .ignored
    }
}

struct VideoGridCell: View {
    let video: VideoItem
    let isSelected: Bool
    @State private var thumbnail: Image?

    var body: some View {
        VStack {
            (thumbnail ?? Image(systemName: "film"))
                .resizable().aspectRatio(contentMode: .fit).frame(minHeight: 80)
                .background(Color.secondary.opacity(0.1)).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3))
                .shadow(radius: 2)
            Text(video.url.deletingPathExtension().lastPathComponent)
                .lineLimit(1).truncationMode(.middle).font(.caption).padding(.top, 4)
        }
        .onAppear(perform: generateThumbnail)
    }

    private func generateThumbnail() {
        let url = video.url
        // ファイルアクセスのスコープを開始.
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security scope for thumbnail.")
            return
        }
        // 必ずスコープを終了させる.
        defer { url.stopAccessingSecurityScopedResource() }
        
        Task {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            do {
                let cgImage = try await generator.image(at: time).image
                await MainActor.run { self.thumbnail = Image(cgImage, scale: 1.0, label: Text("Thumbnail")) }
            } catch {
                print("サムネイルの生成に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}
