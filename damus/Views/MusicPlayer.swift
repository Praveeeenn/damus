//
//  MusicPlayer.swift
//  damus
//
//  Created by Praveen Rajput on 25/05/23.
//

import AVFoundation
import Combine

class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    @Published var isPlaying = false
    @Published var progress: Float = 0.0
    @Published var currentTime: Double = 0.0
    @Published var totalTime: Double = 0.0

    private init() { setup() }

    private func setup() {
        player = AVPlayer()
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            guard let item = self.player?.currentItem else { return }
            self.currentTime = item.currentTime().seconds
            self.totalTime = item.duration.seconds
            let currentProgress = self.currentTime / self.totalTime
            self.progress = Float(currentProgress)
        }
    }

    func playPause(url: URL) {
        if let currentItemURL = playerItem?.asset as? AVURLAsset, currentItemURL.url == url {
            // If the song is currently playing, pause it. If it's paused, resume it.
            isPlaying ? pause() : resume()
        } else {
            // If a different song is chosen, start it from the beginning.
            play(url: url)
        }
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem = nil
        isPlaying = false
        currentTime = 0.0
        totalTime = 0.0
        progress = 0.0
    }

    private func play(url: URL) {
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        isPlaying = true
    }

    private func resume() {
        player?.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }
}
