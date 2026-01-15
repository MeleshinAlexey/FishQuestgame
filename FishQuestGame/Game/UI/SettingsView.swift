//
//  SettingsView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject private var gameState: GameState
    let onClose: () -> Void

    // Persisted music volume (storage) + live slider value (for immediate updates on iOS 16)
    @AppStorage("musicVolume") private var storedMusicVolume: Double = 0.65
    @State private var musicVolume: Double = 0.65

    // Список фоновых треков (добавляй файлы в проект с такими именами)
    private let musicTracks: [(name: String, ext: String, title: String)] = [
        ("bg_music", "wav", "Track 1"),
        ("bg_music2", "wav", "Track 2"),
        ("bg_music3", "wav", "Track 3")
    ]

    @AppStorage("musicTrackIndex") private var musicTrackIndex: Int = 0

    @AppStorage("soundsVolume") private var soundsVolume: Double = 0.65

    // Language (EN / ES / FR / IT) persisted and applied via RootView's `.environment(\.locale, ...)`
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    // Must match lenguage_icon_1...4 order: EN, IT, ES, FR
    private let languageCodes: [String] = ["en", "it", "es", "fr"]

    @State private var languageIndex: Int = 0
    private let languagesCount = 4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Image("menu_background")
                    .resizable()
                    .ignoresSafeArea()

                VStack() {
                    // Top bar (home + balance) внутри safeArea
                    HStack {
                        Button {
                            SoundManager.shared.playButton()
                            onClose()
                        } label: {
                            Image("home_button")
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        ZStack {
                            Image("user_balance")

                            Text("\(gameState.coins)")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .offset(x: 18)
                        }
                    }
                    .padding(.horizontal, max(16, w * 0.04))
                    .padding(.top, max(6, h * 0.015))

                    // Title
                    Text("settings.title")
                        .font(.system(size: min(72, h * 0.11), weight: .heavy))
                        .foregroundStyle(.green)
                        .shadow(radius: 6)
                        .whiteTextOutline()

                    Text("settings.language")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                        .greenTextOutline()

                    // 3 columns: Music | Language | Sounds
                    HStack() {

                        // MUSIC
                        VStack() {
                            Text("settings.music")
                                .font(.system(size: min(56, h * 0.09), weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 6)
                                .greenTextOutline()

//                            // Выбор трека
//                            HStack() {
//                                Button {
//                                    if musicTracks.isEmpty { return }
//                                    musicTrackIndex = (musicTrackIndex - 1 + musicTracks.count) % musicTracks.count
//                                    let t = musicTracks[musicTrackIndex]
//                                    AudioManager.shared.changeBackgroundMusic(fileName: t.name, fileExtension: t.ext)
//                                } label: {
//                                    Image("leftFlip_button")
//                                }
//                                .buttonStyle(.plain)
//
//                                Text(musicTracks.isEmpty ? "No tracks" : musicTracks[musicTrackIndex].title)
//                                    .font(.system(size: 26, weight: .heavy))
//                                    .foregroundStyle(.white)
//                                    .shadow(radius: 4)
//                                    .greenTextOutline()
//
//                                Button {
//                                    if musicTracks.isEmpty { return }
//                                    musicTrackIndex = (musicTrackIndex + 1) % musicTracks.count
//                                    let t = musicTracks[musicTrackIndex]
//                                    AudioManager.shared.changeBackgroundMusic(fileName: t.name, fileExtension: t.ext)
//                                } label: {
//                                    Image("rightFlip_button")
//                                }
//                                .buttonStyle(.plain)
//                            }
//                            .padding(.bottom, 10)

                            // Громкость
                            CapsuleSlider(value: $musicVolume)
                                .frame(width: w * 0.26)
                                .onAppear {
                                    // Sync live slider from persisted value and apply immediately (without restarting music)
                                    musicVolume = storedMusicVolume
                                    AudioManager.shared.setVolume(Float(musicVolume))
                                }
                                .onChange(of: musicVolume) { newValue in
                                    // Live volume updates while dragging
                                    AudioManager.shared.setVolume(Float(newValue))
                                    // Persist for future launches/screens
                                    storedMusicVolume = newValue
                                }
                                .onChange(of: storedMusicVolume) { newValue in
                                    // If something else changes storage (e.g. on another screen), keep slider in sync
                                    if abs(musicVolume - newValue) > 0.0001 {
                                        musicVolume = newValue
                                    }
                                }
                        }
                        .offset(y: -13)

                        // LANGUAGE
                        HStack() {
                            Button {
                                SoundManager.shared.playButton()
                                languageIndex = (languageIndex - 1 + languagesCount) % languagesCount
                                if languageCodes.indices.contains(languageIndex) {
                                    appLanguage = languageCodes[languageIndex]
                                }
                            } label: {
                                Image("leftFlip_button")
                            }
                            .buttonStyle(.plain)

                            Image("lenguage_icon_\(languageIndex + 1)")
                                .shadow(radius: 6)
                                .onChange(of: appLanguage) { newValue in
                                    if let idx = languageCodes.firstIndex(of: newValue) {
                                        languageIndex = min(max(idx, 0), languagesCount - 1)
                                    }
                                }

                            Button {
                                SoundManager.shared.playButton()
                                languageIndex = (languageIndex + 1) % languagesCount
                                if languageCodes.indices.contains(languageIndex) {
                                    appLanguage = languageCodes[languageIndex]
                                }
                            } label: {
                                Image("rightFlip_button")
                            }
                            .buttonStyle(.plain)
                        }

                        // SOUNDS
                        VStack() {
                            Text("settings.sounds")
                                .font(.system(size: min(56, h * 0.09), weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 6)
                                .greenTextOutline()

                            CapsuleSlider(value: $soundsVolume)
                                .frame(width: w * 0.26)
                                .onAppear {
                                    // Ensure any cached SFX players use current saved volume
                                    SoundManager.shared.updateVolume(soundsVolume)
                                }
                                .onChange(of: soundsVolume) { newValue in
                                    // Live SFX volume update while dragging
                                    SoundManager.shared.updateVolume(newValue)
                                }
                        }
                        .offset(y: -13)
                    }

                    Spacer()
                }
                .onAppear {
                    // Sync language selector from persisted app language
                    if let idx = languageCodes.firstIndex(of: appLanguage) {
                        languageIndex = min(max(idx, 0), languagesCount - 1)
                    } else {
                        languageIndex = 0
                        appLanguage = languageCodes[0]
                    }
                }
            }
        }
        // Ensure this screen responds immediately to in-app language changes (iOS 16 safe)
        .environment(\.locale, Locale(identifier: appLanguage))
        // Force SwiftUI to rebuild localized Text views when language changes
        .id(appLanguage)
    }
}

private struct CapsuleSlider: View {
    @Binding var value: Double

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 55/255, green: 126/255, blue: 151/255))
                .frame(height: 18)

            Capsule()
                .stroke(Color(red: 244/255, green: 235/255, blue: 92/255), lineWidth: 3)
                .frame(height: 22)

            Slider(value: $value, in: 0...1)
                .padding(.horizontal, 10)
        }
        .offset(y: -20)
    }
}

extension View {
    func greenTextOutline() -> some View {
        self
            .overlay(
                self
                    .foregroundColor(.clear)
                    .shadow(color: Color(red: 64/255, green: 145/255, blue: 63/255), radius: 0, x: 2, y: 0)
                    .shadow(color: Color(red: 64/255, green: 145/255, blue: 63/255), radius: 0, x: -2, y: 0)
                    .shadow(color: Color(red: 64/255, green: 145/255, blue: 63/255), radius: 0, x: 0, y: 2)
                    .shadow(color: Color(red: 64/255, green: 145/255, blue: 63/255), radius: 0, x: 0, y: -2)
            )
    }
}

extension View {
    func whiteTextOutline() -> some View {
        self
            .overlay(
                self
                    .foregroundColor(.clear)
                    .shadow(color: Color(red: 1, green: 1, blue: 1), radius: 0, x: 2, y: 0)
                    .shadow(color: Color(red: 1, green: 1, blue: 1), radius: 0, x: -2, y: 0)
                    .shadow(color: Color(red: 1, green: 1, blue: 1), radius: 0, x: 0, y: 2)
                    .shadow(color: Color(red: 1, green: 1, blue: 1), radius: 0, x: 0, y: -2)
            )
    }
}

#Preview {
    SettingsView(onClose: {})
        .environmentObject(GameState())
        .previewInterfaceOrientation(.landscapeLeft)
}
