//
//  ModeSelectionView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/29/25.
//

import SwiftUI

struct ModeSelectionView: View {
    // Управление показом этого экрана (источник навигации — MainMenuView)
    @Binding var showModeSelection: Bool

    @EnvironmentObject private var gameState: GameState

    private struct MatchPayload: Identifiable {
        let id = UUID()
        let p1Name: String
        let p2Name: String
        let p1Icon: String
        let p2Icon: String
    }

    @State private var matchPayload: MatchPayload? = nil

    private enum ScreenState {
        case mode
        case player1
        case player2
    }

    @State private var screenState: ScreenState = .mode

    // Draft (то, что вводим сейчас)
    @State private var draftName: String = ""

    // Сохранённые данные игроков
    @State private var player1Name: String = ""
    @State private var player2Name: String = ""
    @State private var player1IconIndex: Int = 0
    @State private var player2IconIndex: Int = 0

    // Иконки персонажей (0 — базовая)
    private let userIcons: [String] = [
        "user_icon_base",
        "user_icon_2",
        "user_icon_3",
        "user_icon_4"
    ]

    @State private var selectedIconIndex: Int = 0

    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            // Фон: во весь экран, вне safe area
            Image("game_background")
                .ignoresSafeArea()

            // Контент: внутри safe area
            VStack(spacing: 0) {
//                Spacer()
                // Верхняя панель
                HStack {
                    Spacer()
                    Button {
                        // Сразу возвращаемся в MainMenuView
                        showModeSelection = false
                    } label: {
                        Image("home_button")
                    }
                    .buttonStyle(.plain)

                    Spacer(/*minLength: 300*/)

                    BalanceView(coins: gameState.coins)
                    Spacer()
                }
//                .frame(maxWidth: .infinity, alignment: .center)

//                Spacer()

                // Заголовок
                Text(titleText)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Color(red: 64.0/255.0, green: 145.0/255.0, blue: 63.0/255.0))
                    .shadow(radius: 3)

//                Spacer()

                // Выбор персонажа: стрелки + аватар по центру
                HStack(alignment: .center, spacing: 24) {
                    Button {
                        selectPrevIcon()
                    } label: {
                        Image("leftFlip_button")
                    }
                    .buttonStyle(.plain)

                    ZStack {
                        Image("user_icon_base")

                        Image(userIcons[selectedIconIndex])
                    }

                    Button {
                        selectNextIcon()
                    } label: {
                        Image("rightFlip_button")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)

//                Spacer()

                // Имя
                ZStack {
                    Image("baseBg_frame")

                    if screenState == .mode {
                        Text("Name")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        TextField("Enter name", text: $draftName)
                            .focused($isNameFocused)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .onSubmit {
                                isNameFocused = false
                            }
                            .padding(.horizontal, 18)
                    }
                }

//                Spacer()

                // Режимы
                HStack(spacing: 28) {
                    switch screenState {
                    case .mode:
                        ModeButton(title: "VS CPU", isEnabled: false) {
                            // disabled
                        }

                        ModeButton(title: "VS FRIEND", isEnabled: true) {
                            startVsFriend()
                        }

                    case .player1:
                        ModeButton(title: "Add", isEnabled: canSubmitName) {
                            addPlayer1()
                        }

                    case .player2:
                        ModeButton(title: "Play", isEnabled: canSubmitName) {
                            addPlayer2AndPlay()
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(item: $matchPayload) { payload in
            GameHostView(
                player1Name: payload.p1Name,
                player2Name: payload.p2Name,
                player1IconAsset: payload.p1Icon,
                player2IconAsset: payload.p2Icon,
                isFriendMode: true,
                onExitToMenu: {
                    // Мгновенно возвращаемся в MainMenuView (закрываем всю цепочку)
                    showModeSelection = false
                }
            )
            .environmentObject(gameState)
        }
    }

    private var titleText: String {
        switch screenState {
        case .mode: return "Mode"
        case .player1: return "Player 1"
        case .player2: return "Player 2"
        }
    }

    private var canSubmitName: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startVsFriend() {
        // Переходим в создание Player 1
        screenState = .player1
        matchPayload = nil
        draftName = ""
        isNameFocused = true
    }

    private func addPlayer1() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        player1Name = name
        player1IconIndex = selectedIconIndex

        // Переходим в создание Player 2
        screenState = .player2
        draftName = ""
        isNameFocused = true
    }

    private func addPlayer2AndPlay() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        // Сохраняем игрока 2
        player2Name = name
        player2IconIndex = selectedIconIndex

        isNameFocused = false

        // Snapshot данных матча (чтобы SwiftUI не успел открыть экран со старыми state)
        let p1 = player1Name.trimmingCharacters(in: .whitespacesAndNewlines)
        let p2 = name
        let i1 = userIcons.indices.contains(player1IconIndex) ? userIcons[player1IconIndex] : "user_icon_base"
        let i2 = userIcons.indices.contains(selectedIconIndex) ? userIcons[selectedIconIndex] : "user_icon_base"

        matchPayload = MatchPayload(
            p1Name: p1.isEmpty ? "Player 1" : p1,
            p2Name: p2.isEmpty ? "Player 2" : p2,
            p1Icon: i1,
            p2Icon: i2
        )
    }

    private func selectPrevIcon() {
        if selectedIconIndex == 0 {
            selectedIconIndex = userIcons.count - 1
        } else {
            selectedIconIndex -= 1
        }
    }

    private func selectNextIcon() {
        if selectedIconIndex == userIcons.count - 1 {
            selectedIconIndex = 0
        } else {
            selectedIconIndex += 1
        }
    }
}

// MARK: - Subviews

private struct BalanceView: View {
    let coins: Int

    var body: some View {
        ZStack {
            Image("user_balance")
 
            Text("\(coins)")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(radius: 1)
                // в ассете слева монета — сдвигаем текст вправо
                .offset(x: 16)
        }
    }
}

private struct ModeButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
 
    @State private var isPressed = false

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            ZStack {
                Image("button_bg")

                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .padding(.horizontal, 18)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.38)
        .scaleEffect(isPressed ? 0.985 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    ModeSelectionView(showModeSelection: .constant(true))
        .environmentObject(GameState())
        .previewInterfaceOrientation(.landscapeLeft)
}
