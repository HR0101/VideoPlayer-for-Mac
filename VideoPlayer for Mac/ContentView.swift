import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VideoLibraryViewModel()
    
    @State private var videoToPlay: VideoItem?
    @State private var isShowingPlayer = false
    
    @State private var selectedVideoID: UUID? = nil
    
    @State private var isShowingEmptyTrashAlert = false
    
    @State private var showTitles = true

    @State private var gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 150))
    ]
    @State private var columnCount: Double = 3.0
    
    var body: some View {
        if isShowingPlayer, let video = videoToPlay {
            VideoPlayerView(
                viewModel: VideoPlayerViewModel(videos: viewModel.videos, currentVideo: video),
                isShowing: $isShowingPlayer
            )
        } else {
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
                            selectedVideoID: $selectedVideoID,
                            showTitles: showTitles,
                            videoToPlay: $videoToPlay,
                            isShowingPlayer: $isShowingPlayer
                        )
                        
                        // カスタム操作パネル
                        HStack {
                            Button(action: { viewModel.importVideos() }) {
                                Label("Import", systemImage: "plus")
                            }
                            .help("Finderから動画をインポートします.")
                            
                            if viewModel.selectedItem != .category(.trash) {
                                Button(role: .destructive, action: {
                                    if let id = selectedVideoID {
                                        viewModel.moveVideosToTrash(videoIDs: [id])
                                        selectedVideoID = nil
                                    }
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .help("選択した項目をゴミ箱に入れます.")
                                .disabled(selectedVideoID == nil)
                            }
                            
                            Button(action: {
                                showTitles.toggle()
                            }) {
                                Label("Titles", systemImage: showTitles ? "tag.fill" : "tag")
                            }
                            .help(showTitles ? "タイトルを非表示" : "タイトルを表示")
                            
                            Spacer()
                            
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
            .alert("ゴミ箱を空にしますか？", isPresented: $isShowingEmptyTrashAlert) {
                Button("空にする", role: .destructive) { viewModel.emptyTrash() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません.")
            }
            .alert(item: $viewModel.importError) { error in
                Alert(
                    title: Text("インポートエラー"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

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
