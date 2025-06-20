//
//  VideoPlayerViewModel.swift
//  VideoPlayer for Mac
//
//  Created by hara ryuto   on 2025/06/18.
//

import Foundation
import AVKit

// 再生中の動画の状態とプレイヤーを管理するクラス.
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    
    let allVideos: [VideoItem]
    @Published var currentVideo: VideoItem
    
    init(videos: [VideoItem], currentVideo: VideoItem) {
        self.allVideos = videos
        self.currentVideo = currentVideo
        self.player = AVPlayer(url: currentVideo.url)
        self.player.play() // 自動再生を開始.
    }
    
    // 指定した秒数だけ再生位置を移動します (シーク).
    func seek(by seconds: Double) {
        guard let currentTime = player.currentItem?.currentTime() else { return }
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let seekTime = CMTime(seconds: newTime, preferredTimescale: .max)
        player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // 再生と一時停止を切り替えます.
    func playPause() {
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }
    
    // 次の動画を再生します.
    func playNextVideo() {
        guard let currentIndex = allVideos.firstIndex(of: currentVideo) else { return }
        let nextIndex = currentIndex + 1
        if allVideos.indices.contains(nextIndex) {
            changeVideo(to: allVideos[nextIndex])
        }
    }
    
    // 前の動画を再生します.
    func playPreviousVideo() {
        guard let currentIndex = allVideos.firstIndex(of: currentVideo) else { return }
        let previousIndex = currentIndex - 1
        if allVideos.indices.contains(previousIndex) {
            changeVideo(to: allVideos[previousIndex])
        }
    }
    
    // 再生する動画を切り替えます.
    private func changeVideo(to newVideo: VideoItem) {
        self.currentVideo = newVideo
        let newItem = AVPlayerItem(url: newVideo.url)
        self.player.replaceCurrentItem(with: newItem)
        self.player.play()
    }
}
