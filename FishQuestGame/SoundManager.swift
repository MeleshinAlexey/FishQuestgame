//
//  SoundManager.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 1/3/26.
//

import AVFoundation
import SwiftUI

final class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]

    @AppStorage("soundsVolume") private var soundsVolume: Double = 0.65

    private init() {}

    func play(_ name: String, ext: String) {
        let key = "\(name).\(ext)"

        if let player = players[key] {
            player.currentTime = 0
            player.volume = Float(soundsVolume)
            player.play()
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("❌ Sound not found:", key)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = Float(soundsVolume)
            players[key] = player
            player.play()
        } catch {
            print("❌ Failed to play sound:", key, error)
        }
    }

    func updateVolume(_ value: Double) {
        for player in players.values {
            player.volume = Float(value)
        }
    }
}

// MARK: - Helpers (avoid magic strings in Views)
extension SoundManager {
    func playButton() {
        play("button_click", ext: "wav")
    }
}
