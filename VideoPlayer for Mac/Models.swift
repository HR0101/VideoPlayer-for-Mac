//
//  Models.swift
//  VideoPlayer for Mac
//
//  Created by hara ryuto   on 2025/06/18.
//

import Foundation
import SwiftUI

// アプリケーションの全データ（動画とアルバム）をまとめて保存・読み込みするためのコンテナ.
struct AppData: Codable {
    var videos: [VideoItem]
    var albums: [Album]
}

// 動画ファイルの情報を管理する構造体.
struct VideoItem: Identifiable, Hashable, Codable {
    let id: UUID
    // bookmarkDataから復元されるため、直接は保存しない.
    var url: URL {
        do {
            var isStale = false
            let resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            // TODO: isStaleがtrueの場合、新しいブックマークで更新するのが望ましい.
            return resolvedUrl
        } catch {
            // ブックマークの解決に失敗した場合、ダミーのURLを返す.
            print("Failed to resolve bookmark for video \(id): \(error)")
            return URL(fileURLWithPath: "/")
        }
    }
    
    // URLへのアクセス許可を保持するデータ. こちらをファイルに保存する.
    private let bookmarkData: Data
    
    var isFavorite: Bool
    var isInTrash: Bool
    var albumIDs: Set<UUID>

    // Codableが利用するキーを定義します.
    enum CodingKeys: String, CodingKey {
        case id
        case bookmarkData // urlの代わりにbookmarkDataを保存.
        case isFavorite
        case isInTrash
        case albumIDs
    }

    // 新しく動画をインポートする際に使用するイニシャライザ.
    init(url: URL) throws {
        self.id = UUID()
        // URLからブックマークデータを作成し、保存する.
        self.bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        self.isFavorite = false
        self.isInTrash = false
        self.albumIDs = []
    }
    
    // Hashableのための適合.
    static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// Albumモデルは変更ありません.
struct Album: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}

// --- サイドバー関連のモデル（変更なし） ---
enum SidebarItem: Hashable, Identifiable {
    case category(Category)
    case album(Album)
    var id: String {
        switch self {
        case .category(let c): return c.rawValue
        case .album(let a): return a.id.uuidString
        }
    }
    var name: String {
        switch self {
        case .category(let c): return c.rawValue
        case .album(let a): return a.name
        }
    }
}
enum Category: String, CaseIterable, Identifiable {
    case allVideos = "すべての動画"
    case favorites = "お気に入り"
    case trash = "ゴミ箱"
    var id: String { self.rawValue }
    var systemImage: String {
        switch self {
        case .allVideos: return "play.rectangle.on.rectangle.fill"
        case .favorites: return "heart.fill"
        case .trash: return "trash.fill"
        }
    }
}
