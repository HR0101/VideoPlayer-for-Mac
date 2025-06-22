//
//  VideoLibraryViewModel.swift
//  VideoPlayer for Mac
//
//  Created by hara ryuto   on 2025/06/18.
//

import SwiftUI
import AVKit

@MainActor
class VideoLibraryViewModel: ObservableObject {
    @Published var allVideos: [VideoItem] = [] {
        didSet { saveData() }
    }
    @Published var albums: [Album] = [] {
        didSet { saveData() }
    }
    @Published var selectedItem: SidebarItem? = .category(.allVideos)
    
    @Published var importError: IdentifiableError?
    
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
        guard let data = try? Data(contentsOf: dataURL) else {
            return
        }
        
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
        
        openPanel.allowedFileTypes = ["mov", "mp4", "m4v", "avi"]

        if openPanel.runModal() == .OK {
            var targetAlbumID: UUID?
            if case .album(let selectedAlbum) = self.selectedItem {
                targetAlbumID = selectedAlbum.id
            }
            
            for url in openPanel.urls {
                if !allVideos.contains(where: { $0.url == url }) {
                    do {
                        var newItem = try VideoItem(url: url)
                        if let albumID = targetAlbumID {
                            newItem.albumIDs.insert(albumID)
                        }
                        allVideos.append(newItem)
                    } catch {
                        let message = "ファイルのアクセス許可の作成に失敗しました.\n\nXcodeプロジェクトの「Signing & Capabilities」でApp Sandboxが正しく設定されているか確認してください。\n\n\(error.localizedDescription)"
                        self.importError = IdentifiableError(message: message)
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
            updateVideo(withID: videoID) { video in
                video.albumIDs.insert(album.id)
            }
        }
    }
    
    func moveVideosToTrash(videoIDs: Set<UUID>) {
        var videosToPermanentlyDelete: [UUID] = []
        for videoID in videoIDs {
            updateVideo(withID: videoID) { video in
                if video.isInTrash {
                    videosToPermanentlyDelete.append(videoID)
                } else {
                    video.isInTrash = true
                    video.isFavorite = false
                }
            }
        }
        
        if !videosToPermanentlyDelete.isEmpty {
            allVideos.removeAll { videosToPermanentlyDelete.contains($0.id) }
        }
    }

    func recoverVideosFromTrash(videoIDs: Set<UUID>) {
        for videoID in videoIDs {
            updateVideo(withID: videoID) { video in
                video.isInTrash = false
            }
        }
    }
    
    func emptyTrash() {
        allVideos.removeAll { $0.isInTrash }
    }
    
    // MARK: - Private Helpers
    
    private func updateVideo(withID id: UUID, action: (inout VideoItem) -> Void) {
        if let index = allVideos.firstIndex(where: { $0.id == id }) {
            var videoToUpdate = allVideos[index]
            action(&videoToUpdate)
            allVideos[index] = videoToUpdate
        }
    }
}

// アラートで表示するためのエラー構造体
struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

