//
//  GameScene.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/28/25.
//

import SpriteKit
import SwiftUI

enum Side: CaseIterable { case left, right }

enum HamsterType {
    case normal, helmet2, helmet3
    var maxHP: Int { self == .normal ? 1 : (self == .helmet2 ? 2 : 3) }
}

// NOTE: This debug node is currently unused (you use HamsterSpriteNode).
// Keeping it for now since it doesn't break anything.
final class HamsterNode: SKShapeNode {
    let id = UUID()
    let side: Side
    let holeIndex: Int
    let type: HamsterType
    var hp: Int

    init(side: Side, holeIndex: Int, type: HamsterType, size: CGSize) {
        self.side = side
        self.holeIndex = holeIndex
        self.type = type
        self.hp = type.maxHP
        super.init()
        path = CGPath(roundedRect: CGRect(origin: .zero, size: size), cornerWidth: 14, cornerHeight: 14, transform: nil)
        lineWidth = 0

        // Цвет по типу (вместо ассетов)
        switch type {
        case .normal: fillColor = .white
        case .helmet2: fillColor = .cyan
        case .helmet3: fillColor = .yellow
        }

        // маленькая “каска” как индикатор hp
        let badge = SKLabelNode(text: "\(hp)")
        badge.name = "hpLabel"
        badge.fontName = "SFProRounded-Bold"
        badge.fontSize = 18
        badge.fontColor = .black
        badge.verticalAlignmentMode = .center
        badge.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(badge)

        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func applyHit() -> Bool {
        hp -= 1
        (childNode(withName: "hpLabel") as? SKLabelNode)?.text = "\(max(hp, 0))"
        // лёгкая “вибрация”
        run(.sequence([.scale(to: 0.92, duration: 0.04), .scale(to: 1.0, duration: 0.06)]))
        return hp <= 0
    }
}

final class GameScene: SKScene {
    /// Injected from SwiftUI (GameHostView). Used for achievements/coins persistence.
    weak var gameState: GameState?

    /// Match mode (vs friend or vs CPU) injected from SwiftUI.
    private let mode: GameViewModel.MatchSetup.Mode

    /// Which side the human player controls (relevant for vsCPU). Default: right.
    private let humanSide: GameViewModel.MatchSetup.HumanSide

    // MARK: - CPU tuning
    private let cpuReactionRange: ClosedRange<TimeInterval> = 0.45...0.90
    private let cpuAccuracy: Double = 0.55
    private let cpuMaxHitsPerSecond: Double = 2.0

    private var cpuNextActionAt: TimeInterval = 0
    private var cpuLastHitAt: TimeInterval = 0

    private var safeInsets: UIEdgeInsets = .zero

    private var safeRect: CGRect {
        // Scene coords are bottom-left origin.
        // NOTE: We also reserve a bit of extra space at the top for the SwiftUI HUD.
        let i = safeInsets
        let extraTop: CGFloat = 64

        let x = i.left
        let y = i.bottom
        let w = max(0, size.width - i.left - i.right)
        let h = max(0, size.height - i.top - i.bottom - extraTop)

        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func refreshSafeInsets() {
        guard let v = view else { return }
        let vi = v.safeAreaInsets
        let wi = v.window?.safeAreaInsets ?? .zero
        // Use the larger insets — window insets are often the reliable source for Dynamic Island.
        safeInsets = UIEdgeInsets(
            top: max(vi.top, wi.top),
            left: max(vi.left, wi.left),
            bottom: max(vi.bottom, wi.bottom),
            right: max(vi.right, wi.right)
        )
    }

    // MARK: Config (баланс)
    private let roundDuration: TimeInterval = 30
    private let targetScore = 25
    private let leadToWin = 3

    private let spawnIntervalRange: ClosedRange<TimeInterval> = 0.35...0.85
    private let visibleDurationRange: ClosedRange<TimeInterval> = 0.55...1.05
    private let pNormal = 0.70
    private let pHelmet2 = 0.20
    // pHelmet3 = остальное

    // MARK: UI / State
    private unowned let vm: GameViewModel

    // Данные игроков (приходят с экрана выбора режима)
    let player1Name: String
    let player2Name: String
    let player1IconAsset: String
    let player2IconAsset: String

    private var leftBoard = BoardNode(side: .left)
    private var rightBoard = BoardNode(side: .right)
    private var backgroundNode: SKSpriteNode?

    private var matchOver = false
    private var scores: (left: Int, right: Int) = (0, 0)

    private var now: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    private var roundEndAt: TimeInterval = 0
    private var lastWholeSecondLeft: Int = 30

    private var nextSpawnAt: [Side: TimeInterval] = [.left: 0, .right: 0]

    // Новый init: передаём данные игроков
    init(
        viewModel: GameViewModel,
        player1Name: String,
        player2Name: String,
        player1IconAsset: String,
        player2IconAsset: String,
        mode: GameViewModel.MatchSetup.Mode = .vsFriend,
        humanSide: GameViewModel.MatchSetup.HumanSide = .right
    ) {
        self.vm = viewModel
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.player1IconAsset = player1IconAsset
        self.player2IconAsset = player2IconAsset
        self.mode = mode
        self.humanSide = humanSide
        super.init(size: .zero)
    }

    // Старый init (backward-compatible)
    convenience init(viewModel: GameViewModel) {
        self.init(
            viewModel: viewModel,
            player1Name: "Player 1",
            player2Name: "Player 2",
            player1IconAsset: "user_icon_base",
            player2IconAsset: "user_icon_2",
            mode: .vsFriend
        )
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .clear

        refreshSafeInsets()
        // In SwiftUI/Previews, the view may not have final safe-area insets yet (Dynamic Island).
        // Refresh once more after the view is attached to the window.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshSafeInsets()
            self.layoutBoards()
        }

        // Background (fills the scene)
        if backgroundNode == nil {
            let bg = SKSpriteNode(texture: SKTexture(imageNamed: "game_background"))
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.size = size
            bg.zPosition = -100
            addChild(bg)
            backgroundNode = bg
        }

        addChild(leftBoard)
        addChild(rightBoard)
        layoutBoards()

        // Debug: проверяем, что данные игроков дошли до сцены
        print("GameScene players: \(player1Name) [\(player1IconAsset)] vs \(player2Name) [\(player2IconAsset)]")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        refreshSafeInsets()
        backgroundNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode?.size = size
        layoutBoards()
    }

    // MARK: Public controls
    func startMatch() {
        matchOver = false
        scores = (0, 0)
        vm.setScore(left: 0, right: 0)
        vm.setTime(Int(roundDuration))

        leftBoard.clearAll()
        rightBoard.clearAll()

        now = 0
        lastUpdateTime = 0
        cpuNextActionAt = 0
        cpuLastHitAt = 0
        startRound()
    }

    func restartMatch() {
        startMatch()
    }

    // MARK: Round
    private func startRound() {
        leftBoard.clearAll()
        rightBoard.clearAll()

        roundEndAt = now + roundDuration
        lastWholeSecondLeft = Int(roundDuration)

        scheduleNextSpawn(for: .left)
        scheduleNextSpawn(for: .right)

        vm.setTime(lastWholeSecondLeft)
    }

    private func endRound() {
        // По ТЗ: если победы нет — новый раунд
        if let winner = checkWinner() {
            finishMatch(winner: winner, reason: "условие победы")
        } else {
            startRound()
        }
    }

    // MARK: Update loop
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard !matchOver else { return }
        now += max(0, dt)

        // Таймер (обновляем по секундам)
        let secondsLeft = Int(max(0, roundEndAt - now).rounded(.down))
        if secondsLeft != lastWholeSecondLeft {
            lastWholeSecondLeft = secondsLeft
            Task { @MainActor in self.vm.setTime(secondsLeft) }
        }

        // despawn истёкших
        leftBoard.despawnExpired(now: now)
        rightBoard.despawnExpired(now: now)

        // spawn по расписанию
        maybeSpawn(on: .left)
        maybeSpawn(on: .right)
        maybeCPUMove()

        // конец раунда
        if now >= roundEndAt {
            endRound()
        }
    }

    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !matchOver, let t = touches.first else { return }
        let p = t.location(in: self)

        // 1) If tap hits a hamster, process a hit (respect vsCPU side restriction)
        if let hamster = nodes(at: p).compactMap({ $0 as? HamsterSpriteNode }).first {
            let side: Side = (hamster.parent === self.leftBoard) ? .left : .right
            if isHumanAllowedToHit(side: side) {
                handleHit(hamster)
            } else {
                runMissEffect(at: p)
            }
            return
        }

        // 2) Иначе: промах (можно сделать эффект)
        runMissEffect(at: p)
    }

    private func handleHit(_ hamster: HamsterSpriteNode) {
        // SFX: attempt/accepted hit (we play only if accepted below)
        let accepted = hamster.tryHit { [weak self, weak hamster] in
            guard let self else { return }
            // SFX: hit
            SoundManager.shared.play("hit", ext: "wav")

            // Determine side by which board contains the node.
            let side: Side = (hamster?.parent === self.leftBoard) ? .left : .right

            // Remove the hamster node after finishing hit.
            hamster?.removeFromParent()

            self.gameState?.recordHamsterDestroyed()
            self.addScore(for: side, delta: 1)

            if let winner = self.checkWinner() {
                self.finishMatch(winner: winner, reason: "условие победы")
            }
        }

        if !accepted {
            runMissEffect(at: hamster.position)
        }
    }

    // MARK: Scoring / win
    private func addScore(for side: Side, delta: Int) {
        if side == .left { scores.left += delta } else { scores.right += delta }
        Task { @MainActor in self.vm.setScore(left: self.scores.left, right: self.scores.right) }
    }

    private func checkWinner() -> Side? {
        if scores.left >= targetScore { return .left }
        if scores.right >= targetScore { return .right }

        if scores.left - scores.right >= leadToWin { return .left }
        if scores.right - scores.left >= leadToWin { return .right }

        return nil
    }

    private func finishMatch(winner: Side, reason: String) {
        guard !matchOver else { return }
        matchOver = true
        // SFX: win/lose only in VS CPU
        if mode == .vsCPU {
            if winner == cpuSide {
                SoundManager.shared.play("lose", ext: "wav")
            } else {
                SoundManager.shared.play("win", ext: "mp3")
            }
        }

        // ✅ Achievement: Play 100 matches with a friend
        if mode == .vsFriend {
            gameState?.recordFriendMatchPlayed()
        }

        // ✅ Coins earned only for a WIN vs CPU (counts toward "Collect 25,000 coins")
        if mode == .vsCPU {
            // cpuSide is the side controlled by the computer; if winner is NOT cpuSide, the human won.
            if winner != cpuSide {
                let rewardCoins = 100
                gameState?.addCoins(rewardCoins)
            }
        }

        Task { @MainActor in
            self.vm.endMatch(winner: winner, left: self.scores.left, right: self.scores.right, reason: reason)
        }
    }

    // MARK: - VS CPU helpers

    private var cpuSide: Side {
        return (humanSide == .left) ? .right : .left
    }

    private func isHumanAllowedToHit(side: Side) -> Bool {
        switch mode {
        case .vsFriend:
            return true
        case .vsCPU:
            return (humanSide == .right && side == .right) || (humanSide == .left && side == .left)
        }
    }

    private func maybeCPUMove() {
        guard !matchOver else { return }
        guard mode == .vsCPU else { return }

        // Rate limit CPU hits
        let minInterval = 1.0 / max(0.1, cpuMaxHitsPerSecond)
        if now - cpuLastHitAt < minInterval { return }

        if cpuNextActionAt == 0 {
            cpuNextActionAt = now + TimeInterval.random(in: cpuReactionRange)
        }
        guard now >= cpuNextActionAt else { return }

        let board = (cpuSide == .left) ? leftBoard : rightBoard
        let candidates = board.activeHamsters().filter { $0.state == .emerging || $0.state == .idle }

        guard let target = candidates.randomElement() else {
            cpuNextActionAt = now + TimeInterval.random(in: cpuReactionRange)
            return
        }

        if Double.random(in: 0..<1) <= cpuAccuracy {
            handleHit(target)
            cpuLastHitAt = now
        }

        cpuNextActionAt = now + TimeInterval.random(in: cpuReactionRange)
    }

    // MARK: Spawn
    private func maybeSpawn(on side: Side) {
        guard let t = nextSpawnAt[side], now >= t else { return }
        let board = (side == .left) ? leftBoard : rightBoard

        guard let hole = board.randomFreeHole() else {
            scheduleNextSpawn(for: side)
            return
        }

        let type = randomType()
        let visibleFor = TimeInterval.random(in: visibleDurationRange)
        board.spawnHamster(type: type, holeIndex: hole, now: now, visibleFor: visibleFor)

        scheduleNextSpawn(for: side)
    }

    private func scheduleNextSpawn(for side: Side) {
        nextSpawnAt[side] = now + TimeInterval.random(in: spawnIntervalRange)
    }

    private func randomType() -> HamsterType {
        let r = Double.random(in: 0..<1)
        if r < pNormal { return .normal }
        if r < pNormal + pHelmet2 { return .helmet2 }
        return .helmet3
    }

    // MARK: Layout & Effects
    private func layoutBoards() {
        let r = safeRect
        guard r.width > 0, r.height > 0 else { return }

        let padding: CGFloat = 18
        let gap: CGFloat = 18

        let boardW = (r.width - padding * 2 - gap) / 2
        let boardH = min(r.height * 0.72, boardW * 1.15)

        let yBias: CGFloat = -40
        var y = r.minY + (r.height - boardH) / 2 + yBias
        y = min(max(y, r.minY), r.maxY - boardH)

        leftBoard.position = CGPoint(x: r.minX + padding, y: y)
        rightBoard.position = CGPoint(x: r.minX + padding + boardW + gap, y: y)

        leftBoard.configure(size: CGSize(width: boardW, height: boardH))
        rightBoard.configure(size: CGSize(width: boardW, height: boardH))
    }

    private func runMissEffect(at p: CGPoint) {
        // SFX only, no visual debug markers
        SoundManager.shared.play("miss", ext: "mp3")
    }
}
