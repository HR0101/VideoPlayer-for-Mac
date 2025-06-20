import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var isShowing: Bool

    // フォーカス管理用のプロパティ
    @FocusState private var isViewFocused: Bool

    var body: some View {
        ZStack {
            Color.black
            
            VideoPlayer(player: viewModel.player)
        }
        .ignoresSafeArea()
        .focusable() // このビューがフォーカスを受け取れるようにする
        .focused($isViewFocused) // isViewFocusedとフォーカス状態を同期
        .onAppear {
            // ビューが表示された瞬間に、即座にフォーカスを当てる
            isViewFocused = true
        }
        .onKeyPress(phases: .down, action: handleKeyPress)
    }
    
    private func handleKeyPress(press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .space:
            // スペースキーで再生ビューを閉じる
            isShowing = false
            return .handled
        case "j":
            viewModel.seek(by: -10)
            return .handled
        case "k":
            viewModel.playPause()
            return .handled
        case "l":
            viewModel.seek(by: 10)
            return .handled
        case .leftArrow:
            viewModel.playPreviousVideo()
            return .handled
        case .rightArrow:
            viewModel.playNextVideo()
            return .handled
        default:
            return .ignored
        }
    }
}
