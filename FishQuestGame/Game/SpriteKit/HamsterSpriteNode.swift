//
//  HamsterSpriteNode.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/29/25.
//

import SpriteKit

final class HamsterSpriteNode: SKSpriteNode {

    enum State { case hole, emerging, idle, retreating, hit }

    private(set) var state: State = .hole
    let id = UUID()

    // Textures
    private let upFrames: [SKTexture]
    private let downFrames: [SKTexture]
    private let idleTexture: SKTexture
    private let hitFrames: [SKTexture]
    private let holeTexture: SKTexture

    // Display sizes: hole art is usually shorter than the hamster art.
    private let holeDisplaySize: CGSize
    private let hamsterDisplaySize: CGSize

    // BoardNode sets `position` using hole geometry. When hamster art is taller than hole art,
    // keeping the same center makes the hamster look like it sinks below the hole.
    // We keep a base Y and apply an offset when showing hamster frames.
    private var baseY: CGFloat?

    private var hamsterYOffset: CGFloat {
        // Raise by half of the height difference so bottoms align visually.
        (hamsterDisplaySize.height - holeDisplaySize.height) * 0.5
    }

    private let actionKey = "HamsterAction"

    /// - Important: expects:
    ///   HamsterNormal.atlas: hamster_up_01.., hamster_idle
    ///   HamsterHit.atlas: hamster_hit_01..
    ///   Environment.atlas: hole
    init(scale: CGFloat = 1.0) {
        // Use imageNamed so textures are found reliably when stored in Assets.xcassets.
        // This avoids Preview/Simulator issues with SKTextureAtlas naming.
        func tex(_ name: String) -> SKTexture { SKTexture(imageNamed: name) }

        let idle = tex("hamster_idle")
        let hole = tex("hole")

        let up: [SKTexture] = [
            tex("hamster_up_01"),
            tex("hamster_up_02"),
            tex("hamster_up_03")
        ]

        let hit: [SKTexture] = [
            tex("hamster_hit_01"),
            tex("hamster_hit_02"),
            tex("hamster_hit_03"),
            tex("hamster_hit_04"),
            tex("hamster_hit_05")
        ]

        // Never allow empty arrays to reach SKAction.animate (it will crash).
        self.upFrames = up.isEmpty ? [idle] : up
        self.downFrames = (up.isEmpty ? [idle] : up).reversed()
        self.idleTexture = idle
        self.hitFrames = hit.isEmpty ? [idle] : hit
        self.holeTexture = hole

        // Keep separate sizes to avoid squashing hamster textures into the (usually smaller) hole size.
        self.holeDisplaySize = hole.size()
        // Use the tallest/most representative hamster size (idle is usually the full sprite).
        self.hamsterDisplaySize = idle.size()

        // Initialize with hamster size so hamster frames render at correct aspect.
        super.init(texture: holeTexture, color: .clear, size: idle.size())

        self.state = .hole
        self.size = holeDisplaySize
        self.setScale(scale)
        self.zPosition = 10
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Anim API

    /// hole -> up -> idle (idleDuration) -> down -> hole
    func playSpawnCycle(
        timePerFrameUp: TimeInterval = 0.06,
        timePerFrameDown: TimeInterval = 0.06,
        idleDuration: TimeInterval = 1.0,
        onFinished: (() -> Void)? = nil
    ) {
        guard state == .hole else { return }

        state = .emerging
        removeAction(forKey: actionKey)
        baseY = position.y

        let showHole = SKAction.run { [weak self] in
            guard let self else { return }
            self.texture = self.holeTexture
            self.size = self.holeDisplaySize
            if let baseY = self.baseY {
                self.position.y = baseY
            }
        }

        let setHamsterSize = SKAction.run { [weak self] in
            guard let self else { return }
            self.size = self.hamsterDisplaySize
            if self.baseY == nil { self.baseY = self.position.y }
            if let baseY = self.baseY {
                self.position.y = baseY + self.hamsterYOffset * self.yScale
            }
        }

        let emerge = SKAction.animate(with: upFrames, timePerFrame: timePerFrameUp)

        let setIdle = SKAction.run { [weak self] in
            guard let self else { return }
            self.texture = self.idleTexture
            self.state = .idle
        }

        let wait = SKAction.wait(forDuration: idleDuration)

        let retreatMark = SKAction.run { [weak self] in self?.state = .retreating }
        let retreat = SKAction.animate(with: downFrames, timePerFrame: timePerFrameDown)

        let backToHole = SKAction.run { [weak self] in
            guard let self else { return }
            self.texture = self.holeTexture
            self.size = self.holeDisplaySize
            if let baseY = self.baseY {
                self.position.y = baseY
            }
            self.state = .hole
            onFinished?()
        }

        let seq = SKAction.sequence([
            showHole,
            setHamsterSize,
            emerge,
            setIdle,
            wait,
            retreatMark,
            retreat,
            backToHole
        ])

        run(seq, withKey: actionKey)
    }

    /// If hamster is visible, interrupt everything and play hit frames -> hole.
    /// Returns true if hit was accepted.
    func tryHit(
        timePerFrame: TimeInterval = 0.04,
        onFinished: (() -> Void)? = nil
    ) -> Bool {
        // Разрешаем удар, если хомяк “видим”
        guard state == .emerging || state == .idle else { return false }

        state = .hit
        removeAction(forKey: actionKey)
        if baseY == nil { baseY = position.y }
        self.size = hamsterDisplaySize
        if let baseY {
            position.y = baseY + hamsterYOffset * yScale
        }

        let hit = SKAction.animate(with: hitFrames, timePerFrame: timePerFrame)
        let backToHole = SKAction.run { [weak self] in
            guard let self else { return }
            self.texture = self.holeTexture
            self.size = self.holeDisplaySize
            if let baseY = self.baseY {
                self.position.y = baseY
            }
            self.state = .hole
            onFinished?()
        }

        run(.sequence([hit, backToHole]), withKey: actionKey)
        return true
    }
}
