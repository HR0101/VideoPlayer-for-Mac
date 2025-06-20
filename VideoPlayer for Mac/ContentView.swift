import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VideoLibraryViewModel()
    
    @State private var videoToPlay: VideoItem?
    @State private var isShowingPlayer = false
    
    // ゴミ箱を空にする確認アラート用のState
    @State private var isShowingEmptyTrashAlert = false

    @State private var gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 150))
    ]
    @State private var columnCount: Double = 3.0
    
    var body: some View {
        ZStack {
            NavigationSplitView {
                SidebarView(viewModel: viewModel, selection: $viewModel.selectedItem)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            } detail: {
                NavigationStack {
                    VStack(spacing: 0) {
                        VideoGridView(
                            viewModel: viewModel,
                            videos: viewModel.videos,
                            gridColumns: $gridColumns,
                            columnCount: Int(columnCount),
                            videoToPlay: $videoToPlay,
                            isShowingPlayer: $isShowingPlayer
                        )
                        
                        // カスタム操作パネル
                        HStack {
                            Button(action: {
                                viewModel.importVideos()
                            }) {
                                Label("Import Videos", systemImage: "plus")
                            }
                            .help("Finderから動画をインポートします.")
                            
                            Spacer()
                            
                            // 「ゴミ箱」選択時のみ表示するボタン
                            if viewModel.selectedItem == .category(.trash) && !viewModel.videos.isEmpty {
                                Button("ゴミ箱を空にする", role: .destructive) {
                                    isShowingEmptyTrashAlert = true
                                }
                            }
                            
                            GridSizeSlider(gridColumns: $gridColumns, sliderValue: $columnCount)
                        }
                        .padding()
                        .background(.regularMaterial)
                    }
                    .navigationTitle(viewModel.selectedItem?.name ?? "VideoPlayer for Mac")
                }
            }
            
            if isShowingPlayer, let video = videoToPlay {
                VideoPlayerView(
                    viewModel: VideoPlayerViewModel(videos: viewModel.videos, currentVideo: video),
                    isShowing: $isShowingPlayer
                )
                .zIndex(1)
            }
        }
        .alert("ゴミ箱を空にしますか？", isPresented: $isShowingEmptyTrashAlert) {
            Button("空にする", role: .destructive) {
                viewModel.emptyTrash()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}

// GridSizeSliderは変更ありませんが、ファイルの完全性のために記載します。
struct GridSizeSlider: View {
    @Binding var gridColumns: [GridItem]
    @Binding var sliderValue: Double

    var body: some View {
        HStack {
            Image(systemName: "square.grid.2x2")
            Slider(value: $sliderValue, in: 1...8, step: 1)
                .frame(width: 100)
                .onChange(of: sliderValue) { _, newValue in
                    let minSize = 300 / newValue
                    gridColumns = [GridItem(.adaptive(minimum: minSize))]
                }
            Image(systemName: "square.grid.4x3.fill")
        }
    }
}
