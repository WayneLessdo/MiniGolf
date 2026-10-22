import CoreGraphics

struct FPShot {
    let direction: CGVector
    let power: CGFloat
}

enum FPPullMath {
    static let deadZone: CGFloat = 6
    static func shot(translation: CGPoint, maximum: CGFloat, deadZone: CGFloat = deadZone, exponent: CGFloat = 1) -> FPShot? {
        let distance = hypot(translation.x, translation.y)
        guard translation.x.isFinite, translation.y.isFinite, maximum.isFinite, deadZone.isFinite, exponent.isFinite, deadZone >= 0, exponent >= 1, maximum > deadZone, distance > deadZone else { return nil }
        return FPShot(direction: CGVector(dx: -translation.x / distance, dy: -translation.y / distance),
                      power: pow(min(1, (distance - deadZone) / (maximum - deadZone)), exponent))
    }
}
