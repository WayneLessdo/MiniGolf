import Foundation
import CoreGraphics

/// World-space shot intent. Angle is radians, x-right/y-up, unrelated to hinge angle.
struct FPLaunch: Equatable, Codable {
    let id: UUID
    let velocity: CGVector
    let angle: CGFloat
    let power: CGFloat

    init(shot: FPShot, maximumSpeed: CGFloat = 1.2) {
        id = UUID()
        power = min(1, max(0, shot.power))
        let magnitude = hypot(shot.direction.dx, shot.direction.dy)
        let dx = magnitude > 0 ? shot.direction.dx / magnitude : 0
        let dy = magnitude > 0 ? -shot.direction.dy / magnitude : 0
        velocity = CGVector(dx: dx * maximumSpeed * power, dy: dy * maximumSpeed * power)
        angle = atan2(dy, dx)
    }
}

@MainActor protocol FPPhysicsPort: AnyObject {
    func launch(_ command: FPLaunch)
}

/// Records input only: deliberately no integration, collision or level rules.
@MainActor final class FPMockPhysicsPort: FPPhysicsPort {
    private(set) var commands: [FPLaunch] = []
    func launch(_ command: FPLaunch) {
        commands.append(command)
        if commands.count > 128 { commands.removeFirst() }
    }
}

