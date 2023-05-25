//
//  TidalMiniPlayerView.swift
//  damus
//
//  Created by Praveen Rajput on 27/03/23.
//

import SwiftUI
import AVFoundation

struct AsyncImageView: View {
    @StateObject private var loader: ImageLoader

    init(url: URL) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }

    var body: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let url: URL
    private var cancellable: AnyObject?

    init(url: URL) {
        self.url = url
        loadImage()
    }

    private func loadImage() {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.image = image
            }
    }
}

//struct AsyncImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        AsyncImageView(url: URL(string: "https://via.placeholder.com/150")!)
//    }
//}

struct ProgressBar: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: geometry.size.width * CGFloat(value))
            }
        }
    }
}


struct MiniPlayerView: View {
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var progress: Double = 0.0

    let audioURL: URL
    let artworkURL: URL

    var body: some View {
        VStack {
            HStack() {
                AsyncImageView(url: artworkURL)
                    .imageScale(.medium)
                    //.frame(width: 100, height: 100)
                VStack(alignment: .leading) {
                    Text("On the floor")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Jennifer Lopez ft. Pit Bull")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    HStack(alignment: .center)  {
                        Button(action: {
                            isPlaying.toggle()
                            if isPlaying {
                                player = AVPlayer(url: audioURL)
                                player?.play()
                                startProgressObserver()
                            } else {
                                player?.pause()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 4)
                        .background(.black)
//                        VStack(alignment: .center) {
//
//                        }
//                        ProgressBar(value: $progress)
//                            .frame(height: 4)
//                            .padding(.horizontal)
//                            .foregroundColor(.purple)
//                            .accentColor(.purple)
//                            .background(.pink)
                        ProgressView(value: progress, total: 100)
                            .accentColor(.purple)
                            .foregroundColor(.white)
                            .padding(.trailing, 16)
                    }
                    //.background(in: Rectangle())
                    //.cornerRadius(6)
                    //.frame(alignment: .center)
                    //.background(Color.black)
                }
                .padding(8)
                VStack {
                    Button(action: {
                        //open tidal app
                    }) {
                        //Add TIDAL Logo
                        Image("tidal")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        //open tidal app
                    }) {
                        //Add share logo
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .accentColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 6)
                .padding(.trailing, 6)
            }
        }
        .frame(maxHeight: 100)
        .background(Color.black)
        .cornerRadius(10)
    }
    
    func startProgressObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { time in
            guard let duration = player.currentItem?.duration else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            let totalTime = CMTimeGetSeconds(duration)
            self.progress = (currentTime / totalTime) * 100.0
        }
    }
}

struct MiniPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MiniPlayerView(audioURL: URL(string: "https://archive.org/download/OpenGoldbergVariations/01_Aria.mp3")!, artworkURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/9/91/On_the_Floor.png")!)
    }
}

