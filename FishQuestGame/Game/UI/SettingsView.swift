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

    // Временно: локальные настройки. Потом можно сохранить в AppStorage.
    @AppStorage("musicVolume") private var musicVolume: Double = 0.65
    private var musicVolumeFloat: Float { Float(musicVolume) }

    // Список фоновых треков (добавляй файлы в проект с такими именами)
    private let musicTracks: [(name: String, ext: String, title: String)] = [
        ("bg_music", "wav", "Track 1"),
        ("bg_music2", "wav", "Track 2"),
        ("bg_music3", "wav", "Track 3")
    ]

    @AppStorage("musicTrackIndex") private var musicTrackIndex: Int = 0

    @State private var soundsVolume: Double = 0.65

    // Язык пока просто UI (позже подключим локализацию)
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
                        Button { onClose() } label: {
                            Image("home_button")
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        ZStack {
                            Image("user_balance")

                            Text("\(gameState.coins)")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .offset(x: 18)
                        }
                    }

                    // Title
                    Text("Settings")
                        .font(.system(size: min(72, h * 0.11), weight: .heavy))
                        .foregroundStyle(.green)
                        .shadow(radius: 6)
                        .whiteTextOutline()

                    Text("Language")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                        .greenTextOutline()

                    // 3 columns: Music | Language | Sounds
                    HStack() {

                        // MUSIC
                        VStack() {
                            Text("Music")
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
                                    // применяем сохранённые настройки при открытии
                                    AudioManager.shared.setVolume(musicVolumeFloat)

                                    // применяем сохранённый трек при открытии
                                    if !musicTracks.isEmpty {
                                        let safeIndex = min(max(musicTrackIndex, 0), musicTracks.count - 1)
                                        musicTrackIndex = safeIndex
                                        let t = musicTracks[musicTrackIndex]
                                        AudioManager.shared.changeBackgroundMusic(fileName: t.name, fileExtension: t.ext)
                                    }
                                }
                                .onChange(of: musicVolume) { newValue in
                                    AudioManager.shared.setVolume(Float(newValue))
                                }
                        }
                        .offset(y: -13)

                        // LANGUAGE
                        HStack() {
                            Button {
                                languageIndex = (languageIndex - 1 + languagesCount) % languagesCount
                            } label: {
                                Image("leftFlip_button")
                            }
                            .buttonStyle(.plain)

                            Image("lenguage_icon_\(languageIndex + 1)")
                                .shadow(radius: 6)

                            Button {
                                languageIndex = (languageIndex + 1) % languagesCount
                            } label: {
                                Image("rightFlip_button")
                            }
                            .buttonStyle(.plain)
                        }

                        // SOUNDS
                        VStack() {
                            Text("Sounds")
                                .font(.system(size: min(56, h * 0.09), weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 6)
                                .greenTextOutline()

                            CapsuleSlider(value: $soundsVolume)
                                .frame(width: w * 0.26)
                        }
                        .offset(y: -13)
                    }

                    Spacer()
                }
            }
        }
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
