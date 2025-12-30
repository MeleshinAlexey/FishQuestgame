//
//  GameHostView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/28/25.
//

import SwiftUI
import SpriteKit

/// Allows SpriteKit to render reliably in Xcode Canvas by hosting an `SKView`.
struct SpriteKitCanvasView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }
}

struct GameHostView: View {
    // Выход в главное меню (закрывает цепочку экранов и возвращает в MainMenuView)
    let onExitToMenu: () -> Void

    // Пока GameHostView сам держит VM (позже можно вынести наверх как EnvironmentObject)
    @EnvironmentObject private var gameState: GameState
    @StateObject private var vm = GameViewModel()

    // Данные игроков (приходят с экрана выбора режима)
    let player1Name: String
    let player2Name: String
    let player1IconAsset: String
    let player2IconAsset: String
    let isFriendMode: Bool

    init(
        player1Name: String = "Player 1",
        player2Name: String = "Player 2",
        player1IconAsset: String = "user_icon_base",
        player2IconAsset: String = "user_icon_base",
        isFriendMode: Bool = true,
        onExitToMenu: @escaping () -> Void = {}
    ) {
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.player1IconAsset = player1IconAsset
        self.player2IconAsset = player2IconAsset
        self.isFriendMode = isFriendMode
        self.onExitToMenu = onExitToMenu
    }

    // Важно: держим одну сцену, чтобы она не пересоздавалась.
    @State private var scene: GameScene? = nil

    private var winnerName: String {
        // При равенстве пусть победителем считается Player 1 (потом можно сделать DRAW)
        vm.leftScore >= vm.rightScore ? player1Name : player2Name
    }
    
    private func goToMainMenu() {
        onExitToMenu()
    }

    var body: some View {
        ZStack {
            if let scene {
                SpriteKitCanvasView(scene: scene)
                    .ignoresSafeArea() // background/game can extend under safe area
            } else {
                Color.black.ignoresSafeArea()
            }

            centerOverlay

            if vm.isGameOver {
                WinMatchOverlay(
                    winnerName: winnerName,
                    onMenu: { goToMainMenu() },
                    onNext: {
                        vm.resetUI()
                        scene?.restartMatch()
                    }
                )
            }
        }
        .safeAreaInset(edge: .top) {
            hud
        }
        .onAppear {
            if scene == nil {
                let s = GameScene(
                    viewModel: vm,
                    player1Name: player1Name,
                    player2Name: player2Name,
                    player1IconAsset: player1IconAsset,
                    player2IconAsset: player2IconAsset,
                    isFriendMode: isFriendMode
                )
                s.scaleMode = .resizeFill
                s.gameState = gameState
                scene = s

                // Prevent Canvas/Previews from crashing if resources/atlases are not ready yet.
                let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                if !isPreview {
                    s.startMatch()
                }
            }
        }
    }

    private var hud: some View {
        HStack(spacing: 12) {
            scoreCapsule(
                title: player1Name,
                score: vm.leftScore,
                leadingAssetName: player1IconAsset,
                trailingAssetName: nil
            )

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                scoreCapsule(
                    title: player2Name,
                    score: vm.rightScore,
                    leadingAssetName: nil,
                    trailingAssetName: player2IconAsset
                )

                homeButton
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 74)
        .padding(.vertical, 6)
    }

    private var centerOverlay: some View {
        GeometryReader { geo in
            ZStack {
                // Vertical divider line in the middle of the screen
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 3)
                    .frame(height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Timer moved down (lower half)
                timerBadge(seconds: vm.timeLeft)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.56)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var homeButton: some View {
        Button { goToMainMenu() } label: {
            Image("home_button")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
        }
        .buttonStyle(.plain)
    }

    private func timerBadge(seconds: Int) -> some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
            Circle()
                .stroke(.white.opacity(0.55), lineWidth: 3)

            Text("\(seconds)s")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 72, height: 72)
    }

    private func scoreCapsule(
        title: String,
        score: Int,
        leadingAssetName: String?,
        trailingAssetName: String?
    ) -> some View {
        ZStack {
            // Use the asset exactly as drawn (no stretching)
            Image("baseBg_frame")
                .resizable()
                .scaledToFit()

            HStack(spacing: 12) {
                if let leadingAssetName, let img = optionalAsset(leadingAssetName) {
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }

                // Между иконкой и текстом оставляем явный зазор
                HStack(spacing: 0) {
                    Spacer()
                    Text(title)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text("\(score)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                }

                if let trailingAssetName, let img = optionalAsset(trailingAssetName) {
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
        }
        // Bigger capsule, no distortion
        .frame(width: 280, height: 68)
    }

    private func optionalAsset(_ name: String) -> Image? {
        // Базовая иконка игрока (дефолт)
        if name == "user_icon_base" {
            return Image("user_icon_base")
        }

        #if canImport(UIKit)
        if let ui = UIImage(named: name) {
            return Image(uiImage: ui)
        }
        return nil
        #else
        return nil
        #endif
    }
}

private struct WinMatchOverlay: View {
    let winnerName: String
    let onMenu: () -> Void
    let onNext: () -> Void

    var body: some View {
        ZStack {
            // Лёгкое затемнение поверх матча
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("\(winnerName) WIN!")
                    .font(.system(size: 66, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 6)

                HStack(spacing: 28) {
                    WinButton(title: "Menu", action: onMenu)
                    WinButton(title: "Next", action: onNext)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct WinButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image("button_bg")

                Text(title)
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GameHostView(
        player1Name: "Alice",
        player2Name: "Bob",
        player1IconAsset: "user_icon_base",
        player2IconAsset: "user_icon_base",
        onExitToMenu: {}
    )
    .environmentObject(GameState())
}
