
//
//  AudioManager.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    @Published private(set) var isPlaying = false

    private init() {}

    func startBackgroundMusic(
        fileName: String = "bg_music",
        volume: Float = 0.35
    ) {
        guard !isPlaying else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            // ищем любой формат
            let exts = ["wav", "mp3", "m4a"]
            guard
                let url = exts.compactMap({
                    Bundle.main.url(forResource: fileName, withExtension: $0)
                }).first
            else {
                print("❌ Music file not found:", fileName)
                return
            }

            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = volume
            p.prepareToPlay()
            p.play()

            player = p
            isPlaying = true
        } catch {
            print("❌ Audio error:", error)
        }
    }

    func stopBackgroundMusic() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    func setVolume(_ v: Float) {
        player?.volume = v
    }
    
    func changeBackgroundMusic(fileName: String, fileExtension: String) {
        // Reuse existing API (should already handle replacing the currently playing background track).
        startBackgroundMusic(fileName: "bg_music")
    }
    

}
