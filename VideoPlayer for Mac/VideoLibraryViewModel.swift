//
//  VideoLibraryViewModel.swift
//  VideoPlayer for Mac
//
//  Created by hara ryuto   on 2025/06/18.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers

@MainActor
class VideoLibraryViewModel: ObservableObject {
    @Published var allVideos: [VideoItem] = [] {
        didSet { saveData() }
    }
    @Published var albums: [Album] = [] {
        didSet { saveData() }
    }
    @Published var selectedItem: SidebarItem? = .category(.allVideos)
    
    private let dataURL: URL

    // MARK: - Initialization & Persistence
    init() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory could not be found.")
        }
        let appDirectoryURL = appSupportURL.appendingPathComponent("VideoPlayer for Mac")
        if !fileManager.fileExists(atPath: appDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Could not create app support directory: \(error)")
            }
        }
        self.dataURL = appDirectoryURL.appendingPathComponent("library.json")
        loadData()
    }
    
    func saveData() {
        let appData = AppData(videos: allVideos, albums: albums)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(appData)
            try data.write(to: dataURL, options: [.atomicWrite])
        } catch {
            print("Failed to save data: \(error.localizedDescription)")
        }
    }
    
    func loadData() {
        guard let data = try? Data(contentsOf: dataURL) else { return }
        let decoder = JSONDecoder()
        do {
            let appData = try decoder.decode(AppData.self, from: data)
            self.allVideos = appData.videos
            self.albums = appData.albums
        } catch {
            print("Failed to load or decode data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    var videos: [VideoItem] {
        guard let selectedItem = selectedItem else { return [] }
        switch selectedItem {
        case .category(let category):
            switch category {
            case .allVideos: return allVideos.filter { !$0.isInTrash }
            case .favorites: return allVideos.filter { $0.isFavorite && !$0.isInTrash }
            case .trash: return allVideos.filter { $0.isInTrash }
            }
        case .album(let album):
            return allVideos.filter { $0.albumIDs.contains(album.id) && !$0.isInTrash }
        }
    }
    
    // MARK: - Intentions
    func importVideos() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [UTType.movie, UTType.video, UTType.quickTimeMovie]

        if openPanel.runModal() == .OK {
            for url in openPanel.urls {
                if !allVideos.contains(where: { $0.url == url }) {
                    do {
                        // 新しいイニシャライザを使い、ブックマークデータを作成する.
                        let newItem = try VideoItem(url: url)
                        allVideos.append(newItem)
                    } catch {
                        print("Failed to create bookmark for \(url.path): \(error)")
                        // ここでユーザーにエラーを通知するUIを表示するのが望ましい.
                    }
                }
            }
        }
    }

    func createAlbum(name: String) {
        let newAlbum = Album(id: UUID(), name: name)
        albums.append(newAlbum)
    }
    
    func addVideos(videoIDs: Set<UUID>, to album: Album) {
        for videoID in videoIDs {
            if let index = allVideos.firstIndex(where: { $0.id == videoID }) {
                allVideos[index].albumIDs.insert(album.id)
            }
        }
    }
    
    // --- 動画削除関連のメソッド ---
    func moveVideosToTrash(videoIDs: Set<UUID>) {
        var videosToPermanentlyDelete: [UUID] = []
        for videoID in videoIDs {
            if let index = allVideos.firstIndex(where: { $0.id == videoID }) {
                if allVideos[index].isInTrash {
                    videosToPermanentlyDelete.append(videoID)
                } else {
                    allVideos[index].isInTrash = true
                    allVideos[index].isFavorite = false
                }
            }
        }
        if !videosToPermanentlyDelete.isEmpty {
            allVideos.removeAll { videosToPermanentlyDelete.contains($0.id) }
        }
    }

    func recoverVideosFromTrash(videoIDs: Set<UUID>) {
        for videoID in videoIDs {
            if let index = allVideos.firstIndex(where: { $0.id == videoID }) {
                allVideos[index].isInTrash = false
            }
        }
    }
    
    func emptyTrash() {
        allVideos.removeAll { $0.isInTrash }
    }
}
