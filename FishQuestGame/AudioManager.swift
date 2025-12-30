
//
//  AudioManager.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?

    private init() {}

    func startMusic(volume: Float) {
        if player != nil { return } // уже играет

        guard let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") else {
            print("❌ background_music.mp3 not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // бесконечно
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ Audio error:", error)
        }
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
