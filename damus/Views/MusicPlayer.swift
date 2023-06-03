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
            let currentProgress = (self.currentTime / self.totalTime) * 100.0
            self.progress = Float(currentProgress)
        }
    }

    func playPause(url: URL) {
        let manifestService = ManifestService()
        Task {
            do {
                guard let previewURL = try await manifestService.getPreviewURL(urlString: url.absoluteString) else { return }
                print("Preview URL: \(previewURL)")
                if isPlaying, let currentItemURL = playerItem?.asset as? AVURLAsset, currentItemURL.url == url {
                    // If the song is currently playing, pause it. If it's paused, resume it.
                    stop()
                } else {
                    // If a different song is chosen, start it from the beginning.
                    play(url: previewURL)
                }
            } catch {
                print("Error retrieving preview URL:", error)
            }
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
    
    func extractMP3URL(from string: String) -> String? {
        let pattern = #"https?://[\w./_-]+\.mp3"#
        
        if let range = string.range(of: pattern, options: .regularExpression) {
            return String(string[range])
        }
        
        return nil
    }
}
