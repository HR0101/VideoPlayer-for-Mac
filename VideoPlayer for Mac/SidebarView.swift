//
//  SidebarView.swift
//  VideoPlayer for Mac
//
//  Created by hara ryuto   on 2025/06/18.
//

import SwiftUI

struct SidebarView: View {
    // ERROR FIX: viewModelをObservedObjectとして受け取ります.
    @ObservedObject var viewModel: VideoLibraryViewModel
    @Binding var selection: SidebarItem?
    
    @State private var isShowingCreateAlbumAlert = false
    @State private var newAlbumName = ""

    var body: some View {
        List(selection: $selection) {
            Section("ライブラリ") {
                ForEach(Category.allCases) { category in
                    Label(category.rawValue, systemImage: category.systemImage)
                        .tag(SidebarItem.category(category))
                }
            }
            
            Section("アルバム") {
                ForEach(viewModel.albums) { album in
                    Label(album.name, systemImage: "rectangle.stack.fill")
                        .tag(SidebarItem.album(album))
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    newAlbumName = ""
                    isShowingCreateAlbumAlert = true
                }) {
                    Image(systemName: "plus")
                }
                .help("新規アルバムを作成")
            }
        }
        .alert("新規アルバム", isPresented: $isShowingCreateAlbumAlert) {
            TextField("アルバム名", text: $newAlbumName)
            Button("作成") {
                if !newAlbumName.isEmpty {
                    viewModel.createAlbum(name: newAlbumName)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("アルバムの名前を入力してください.")
        }
    }
}

#Preview {
    // プレビューが正常に動作するように、ダミーのViewModelとデータを用意します.
    let previewViewModel = VideoLibraryViewModel()
    previewViewModel.createAlbum(name: "Test Album 1")
    previewViewModel.createAlbum(name: "旅行動画")
    
    // 実際のアプリのようにNavigationSplitViewの中に入れて表示を確認します.
    return NavigationSplitView {
        SidebarView(
            viewModel: previewViewModel,
            selection: .constant(.category(.allVideos))
        )
    } detail: {
        Text("選択してください")
    }
}
