
//
//  AudioManager.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import Foundation
import AVFoundation
import Combine
import UIKit

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    @Published private(set) var isPlaying = false

    private var wasPlayingBeforeBackground: Bool = false

    private init() {
        let nc = NotificationCenter.default

        // Pause when app is no longer active
        nc.addObserver(self, selector: #selector(handleWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Resume when app becomes active again
        nc.addObserver(self, selector: #selector(handleDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private var currentFileName: String = "bg_music"
    private var currentFileExtension: String?
    private var currentVolume: Float = 0.35

    func startBackgroundMusic(
        fileName: String = "bg_music",
        fileExtension: String? = nil,
        volume: Float? = nil,
        restartIfPlaying: Bool = false
    ) {
        // If we're already playing and not asked to restart, just update volume (if provided) and return.
        if isPlaying, !restartIfPlaying {
            if let volume {
                setVolume(volume)
            }
            return
        }

        // Save requested state (so changeBackgroundMusic can reuse current volume).
        currentFileName = fileName
        currentFileExtension = fileExtension
        if let volume { currentVolume = max(0, min(1, volume)) }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            // Stop previous player if any
            player?.stop()
            player = nil
            isPlaying = false

            // Find resource URL (explicit extension first, otherwise try common ones)
            let url: URL?
            if let fileExtension {
                url = Bundle.main.url(forResource: fileName, withExtension: fileExtension)
            } else {
                let exts = ["wav", "mp3", "m4a"]
                url = exts.compactMap {
                    Bundle.main.url(forResource: fileName, withExtension: $0)
                }.first
            }

            guard let url else {
                print("❌ Music file not found:", fileName)
                return
            }

            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.prepareToPlay()

            // Apply volume reliably (iOS 16)
            p.volume = currentVolume
            p.setVolume(currentVolume, fadeDuration: 0)

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
        let clamped = max(0, min(1, v))
        currentVolume = clamped
        // Apply immediately to the currently playing player (if any)
        player?.volume = clamped
        player?.setVolume(clamped, fadeDuration: 0)
    }
    
    func changeBackgroundMusic(fileName: String, fileExtension: String? = nil) {
        // Restart playback with a new track, preserving current volume.
        startBackgroundMusic(
            fileName: fileName,
            fileExtension: fileExtension,
            volume: currentVolume,
            restartIfPlaying: true
        )
    }
    

    // MARK: - App lifecycle pause/resume

    func pauseBackgroundMusic() {
        guard let p = player else { return }

        // Multiple notifications can fire (willResignActive + didEnterBackground).
        // Don't overwrite the "was playing" flag with false on the second call.
        if p.isPlaying {
            wasPlayingBeforeBackground = true
            p.pause()
            isPlaying = false
        }
    }

    func resumeBackgroundMusicIfNeeded() {
        guard let p = player else { return }
        guard wasPlayingBeforeBackground else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // ignore
        }

        if !p.isPlaying {
            // Re-apply volume on resume (some devices may reset it after interruptions)
            p.volume = currentVolume
            p.setVolume(currentVolume, fadeDuration: 0)

            p.play()
            isPlaying = true
        }

        // Consume the flag so we don't resume multiple times.
        wasPlayingBeforeBackground = false
    }

    @objc private func handleWillResignActive() {
        pauseBackgroundMusic()
    }

    @objc private func handleDidEnterBackground() {
        pauseBackgroundMusic()
    }

    @objc private func handleDidBecomeActive() {
        resumeBackgroundMusicIfNeeded()
    }
}
