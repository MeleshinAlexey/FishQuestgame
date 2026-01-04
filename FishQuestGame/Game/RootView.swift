//
//  RootView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import SwiftUI
import Combine
import UIKit

struct RootView: View {
    @StateObject private var gameState = GameState()

    @AppStorage("musicVolume") private var musicVolume: Double = 0.65
    @AppStorage("musicTrackIndex") private var musicTrackIndex: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = "en" // en / es / fr / it

    @State private var isLoading: Bool = true

    private let musicTracks: [(name: String, ext: String, title: String)] = [
        ("bg_music", "wav", "Track 1"),
        ("bg_music2", "wav", "Track 2"),
        ("bg_music3", "wav", "Track 3")
    ]

    var body: some View {
        Group {
            if isLoading {
                // ✅ Loading: разрешаем все ориентации
                LoadingView( // <-- ВАЖНО: замени на реальное имя твоего экрана загрузки
                    onFinished: {
                        goToMenu()
                    }
                )
                .environment(\.locale, Locale(identifier: appLanguage))
                .onAppear {
                    setOrientation(.all)
                    startMusicIfNeeded()
                }
            } else {
                // ✅ Menu+: только landscape
                MainMenuView()
                    .environmentObject(gameState)
                    .environment(\.locale, Locale(identifier: appLanguage))
                    .onAppear {
                        setOrientation([.landscapeLeft, .landscapeRight])
                    }
            }
        }
    }

    private func goToMenu() {
        // перед показом меню лочим landscape
        setOrientation([.landscapeLeft, .landscapeRight])
        withAnimation(.easeOut(duration: 0.2)) {
            isLoading = false
        }
    }

    private func startMusicIfNeeded() {
        let safeIndex = min(max(musicTrackIndex, 0), musicTracks.count - 1)
        musicTrackIndex = safeIndex
        let t = musicTracks[safeIndex]

        AudioManager.shared.startBackgroundMusic(
            fileName: t.name,
            fileExtension: t.ext,
            volume: Float(musicVolume),
            restartIfPlaying: false
        )
    }

    private func setOrientation(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask

        // Пнуть систему, чтобы пересчитала ориентации
        UIViewController.attemptRotationToDeviceOrientation()
        if #available(iOS 16.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
            }
        }
    }
}
