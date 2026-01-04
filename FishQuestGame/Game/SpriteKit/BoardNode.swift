//
//  BoardNode.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/28/25.
//

import SpriteKit

final class BoardNode: SKNode {
    let side: Side

    private var boardSize: CGSize = .zero
    private var holeFrames: [CGRect] = []           // 9 rects in local coords
    private var holes: [SKSpriteNode] = []          // визуал лунок (текстуры)
    private let holeTexture = SKTexture(imageNamed: "hole")
    private var hamstersByHole: [Int: (node: HamsterSpriteNode, despawnAt: TimeInterval)] = [:]

    init(side: Side) {
        self.side = side
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(size: CGSize) {
        boardSize = size
        removeAllChildren()
        holes.removeAll()
        holeFrames = makeGridFrames(size: size, rows: 3, cols: 3, gap: 10)

        // фон борда
        let bg = SKShapeNode(rect: CGRect(origin: .zero, size: size), cornerRadius: 18)
        bg.fillColor = .darkGray
        bg.alpha = 0.0
        bg.lineWidth = 0
        addChild(bg)

        // лунки (текстуры)
        for (i, r) in holeFrames.enumerated() {
            let hole = SKSpriteNode(texture: holeTexture)
            hole.name = "hole_\(i)"
            hole.zPosition = 1
            hole.position = CGPoint(x: r.midX, y: r.midY)
            // Slightly inset within the cell so holes/hamsters are smaller but stay equal-sized.
            let inset = min(r.width, r.height) * 0.12
            hole.size = r.insetBy(dx: inset, dy: inset).size
            addChild(hole)
            holes.append(hole)
        }
    }

    func clearAll() {
        for (_, pair) in hamstersByHole {
            // SFX: hamster disappears
            SoundManager.shared.play("hide", ext: "wav")
            pair.node.removeFromParent()
        }
        hamstersByHole.removeAll()
    }

    func randomFreeHole() -> Int? {
        let free = (0...8).filter { hamstersByHole[$0] == nil }
        return free.randomElement()
    }

    // MARK: - AI helpers
    /// Returns currently active hamster nodes on this board (for CPU targeting).
    func activeHamsters() -> [HamsterSpriteNode] {
        hamstersByHole.values.map { $0.node }
    }

    func spawnHamster(type: HamsterType, holeIndex: Int, now: TimeInterval, visibleFor: TimeInterval) {
        guard let rect = holeFrames[safe: holeIndex], hamstersByHole[holeIndex] == nil else { return }

        // NOTE: for now we ignore `type` because you currently have only Normal + Hit atlases.
        // Later we can map `type` to different atlases (Helmet2/Helmet3).
        let hamster = HamsterSpriteNode(scale: 1.0)
        hamster.position = CGPoint(x: rect.midX, y: rect.midY)
        hamster.zPosition = 6

        // Make the hamster slightly larger than the hole for better visual readability.
        let scaleUp: CGFloat = 1.0 // tweak 1.05–1.25 if needed
        if holeIndex < holes.count {
            let s = holes[holeIndex].size
            hamster.size = CGSize(width: s.width * scaleUp, height: s.height * scaleUp)
        } else {
            hamster.size = CGSize(width: rect.width * scaleUp, height: rect.height * scaleUp)
        }

        // Lift the hamster slightly so it visually sits "in" the hole (art usually has extra empty pixels).
        // Tune the factor if needed (0.10–0.20).
        hamster.position.y += hamster.size.height * 0.18

        addChild(hamster)
        // SFX: hamster pops up
        SoundManager.shared.play("pop", ext: "wav")

        // Treat `visibleFor` as the time the hamster stays "available" (idle) before retreating.
        hamster.playSpawnCycle(idleDuration: visibleFor) { [weak self, weak hamster] in
            guard let self else { return }
            // Free the hole when the cycle finishes.
            self.hamstersByHole[holeIndex] = nil
            // SFX: hamster hides
            SoundManager.shared.play("hide", ext: "wav")
            hamster?.removeFromParent()
        }

        // Safety timeout (in case actions get interrupted): expire a bit after the expected cycle.
        let safety = 1.0
        hamstersByHole[holeIndex] = (hamster, now + visibleFor + safety)
    }

    func despawnExpired(now: TimeInterval) {
        let expired = hamstersByHole.filter { $0.value.despawnAt <= now }
        guard !expired.isEmpty else { return }

        for (hole, pair) in expired {
            pair.node.removeAllActions()
            // SFX: hamster hides (expired)
            SoundManager.shared.play("hide", ext: "wav")
            pair.node.removeFromParent()
            hamstersByHole[hole] = nil
        }
    }

    private func makeGridFrames(size: CGSize, rows: Int, cols: Int, gap: CGFloat) -> [CGRect] {
        let totalGapX = gap * CGFloat(cols + 1)
        let totalGapY = gap * CGFloat(rows + 1)

        let cellW = (size.width - totalGapX) / CGFloat(cols)
        let cellH = (size.height - totalGapY) / CGFloat(rows)

        var rects: [CGRect] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let x = gap + CGFloat(c) * (cellW + gap)
                let y = gap + CGFloat(rows - 1 - r) * (cellH + gap)
                rects.append(CGRect(x: x, y: y, width: cellW, height: cellH))
            }
        }
        return rects
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
}
