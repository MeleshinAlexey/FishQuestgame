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
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    private struct MatchPayload: Identifiable {
        let id = UUID()
        let p1Name: String
        let p2Name: String
        let p1Icon: String
        let p2Icon: String
        let mode: GameViewModel.MatchSetup.Mode
    }

    @State private var matchPayload: MatchPayload? = nil

    private enum ScreenState {
        case mode
        case player1
        case player2
    }

    @State private var screenState: ScreenState = .mode
    @State private var isVsCPU: Bool = false

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

    // MARK: - Localization (explicit bundle lookup for in-app language)
    private func L(_ key: String) -> String {
        if let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: langBundle, value: key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    var body: some View {
        ZStack {
            // Фон: во весь экран, вне safe area
            Image("game_background")
                .resizable()
                .ignoresSafeArea()

            // Контент: внутри safe area
            VStack(spacing: 0) {
                Spacer()
                // Верхняя панель
                GeometryReader { geo in
                    HStack {
                        Spacer()
                        Button {
                            SoundManager.shared.playButton()
                            // Сразу возвращаемся в MainMenuView
                            showModeSelection = false
                        } label: {
                            Image("home_button")
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: geo.size.width * 0.4)

                        BalanceView(coins: gameState.coins)
                        Spacer()
                    }
                    .padding(.top, 6)
                }
                .frame(height: 64)

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
                        SoundManager.shared.playButton()
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
                        SoundManager.shared.playButton()
                        selectNextIcon()
                    } label: {
                        Image("rightFlip_button")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)

//                Spacer()

                // Имя
                GeometryReader { geo in
                    // Keep the name field responsive and make sure the prompt fits.
                    let w = geo.size.width
                    let frameW = min(520, max(280, w * 0.62))
                    let frameH: CGFloat = 74

                    ZStack {
                        Image("baseBg_frame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: frameW, height: frameH)

                        if screenState == .mode {
                            Text(L("mode.name"))
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .allowsTightening(true)
                                .padding(.horizontal, 22)
                                .frame(width: frameW, height: frameH)
                        } else {
                            ZStack {
                                // Actual input
                                TextField("", text: $draftName)
                                    .focused($isNameFocused)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .submitLabel(.done)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .allowsTightening(true)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 22)
                                    .frame(width: frameW, height: frameH)
                                    .onSubmit {
                                        isNameFocused = false
                                    }

                                // Custom placeholder that can scale/tighten
                                if draftName.isEmpty {
                                    Text(L("mode.enter_name"))
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.white.opacity(0.55))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.45)
                                        .allowsTightening(true)
                                        .padding(.horizontal, 22)
                                        .frame(width: frameW, height: frameH)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 86)

//                Spacer()

                // Режимы
                HStack(spacing: 28) {
                    switch screenState {
                    case .mode:
                        ModeButton(title: L("mode.vs_cpu"), isEnabled: true) {
                            startVsCPU()
                        }

                        ModeButton(title: L("mode.vs_friend"), isEnabled: true) {
                            startVsFriend()
                        }

                    case .player1:
                        ModeButton(title: L("mode.add"), isEnabled: canSubmitName) {
                            addPlayer1()
                        }

                    case .player2:
                        ModeButton(title: L("common.play"), isEnabled: canSubmitName) {
                            addPlayer2AndPlay()
                        }
                    }
                }
                Spacer()
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
                mode: payload.mode,
                onExitToMenu: {
                    // 1) закрываем GameHostView (item-based fullScreenCover)
                        matchPayload = nil

                        // 2) сбрасываем локальное состояние, чтобы следующий заход начинался нормально
                        screenState = .mode
                        draftName = ""
                        selectedIconIndex = 0
                        isNameFocused = false

                        // 3) закрываем ModeSelectionView -> возвращаемся в MainMenuView
                        showModeSelection = false
                }
            )
            .environmentObject(gameState)
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .id(appLanguage)
    }

    private var titleText: String {
        switch screenState {
        case .mode: return L("mode.title")
        case .player1: return L("mode.player1")
        case .player2: return L("mode.player2")
        }
    }

    private var canSubmitName: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startVsFriend() {
        isVsCPU = false
        // Переходим в создание Player 1
        screenState = .player1
        matchPayload = nil
        draftName = ""
        isNameFocused = true
    }

    private func startVsCPU() {
        isVsCPU = true
        // VS CPU: only Player 1 is entered, Player 2 is CPU
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
        isNameFocused = false

        let p1 = name
        let i1 = userIcons.indices.contains(player1IconIndex)
            ? userIcons[player1IconIndex]
            : "user_icon_base"

        if isVsCPU {
            // Immediately start match vs CPU
            matchPayload = MatchPayload(
                p1Name: L("mode.cpu_name"),
                p2Name: p1.isEmpty ? L("mode.player1_default") : p1,
                p1Icon: "cpu_icon",
                p2Icon: i1,
                mode: .vsCPU
            )
        } else {
            // Continue to Player 2 setup (VS FRIEND)
            screenState = .player2
            draftName = ""
            isNameFocused = true
        }
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
            p1Name: p1.isEmpty ? L("mode.player1_default") : p1,
            p2Name: p2.isEmpty ? L("mode.player2_default") : p2,
            p1Icon: i1,
            p2Icon: i2,
            mode: .vsFriend
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
                .resizable()
                .scaledToFit()
 
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
            SoundManager.shared.playButton()
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
