import Foundation
import CoreGraphics

struct FPPoint: Codable {
    var x: Double
    var y: Double
    var cg: CGPoint { CGPoint(x: x, y: y) }
}
struct FPRect: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var cg: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}

struct FPLevel: Codable {
    let id: String
    let name: String
    let presentation: String
    let start: FPPoint
    let hole: FPPoint
    let par: Int
    let friction: Double
    let sandFriction: Double
    let restitution: Double
    let maxSpeed: Double
    let captureRadius: Double
    let captureSpeed: Double
    let timeLimit: Double
    let collisionLimit: Int
    let obstacles: [FPRect]
    let hazards: [FPRect]
    let sand: [FPRect]
    let canal: FPRect
    let penaltyObstacle: FPRect
    var localizedName: String {
        if let n = puzzleNumber, FPClubRules.puzzleNames.indices.contains(n - 1) { return FPClubRules.puzzleNames[n - 1] }
        switch id { case "01": return FPL10n.text("level_name_1"); case "02": return FPL10n.text("level_name_2"); default: return FPL10n.text("sand_trail") }
    }
    var isPuzzle: Bool { id.hasPrefix("P") }
    var puzzleNumber: Int? { isPuzzle ? Int(id.dropFirst()):nil }
    var mapDescription: String {
        if let n=puzzleNumber,FPClubRules.puzzleHints.indices.contains(n-1) { return FPClubRules.puzzleHints[n-1] }
        switch id { case "01":return FPL10n.text("map_description_1");case "02":return FPL10n.text("map_description_2");default:return FPL10n.text("map_description_3") }
    }
    var mapSymbol: String {
        if isPuzzle { return "arrow.triangle.turn.up.right.diamond" }
        switch id { case "01":return "leaf";case "02":return "water.waves";default:return "sun.max" }
    }
    static let world = CGRect(x: 0, y: 0, width: 1, height: 1.4)
    static let ballRadius: CGFloat = 0.022

    func validate() throws {
        func valid(_ rect: FPRect) -> Bool {
            [rect.x,rect.y,rect.width,rect.height].allSatisfy(\.isFinite) && rect.width > 0 && rect.height > 0 && Self.world.contains(rect.cg)
        }
        let scalar = [friction,sandFriction,restitution,maxSpeed,captureRadius,captureSpeed,timeLimit]
        guard !id.isEmpty, !name.isEmpty, par > 0, collisionLimit > 0,
              scalar.allSatisfy({ $0.isFinite && $0 > 0 }), restitution <= 1,
              maxSpeed <= 3, captureRadius > Double(Self.ballRadius), captureRadius < 0.2,
              Self.world.insetBy(dx: Self.ballRadius, dy: Self.ballRadius).contains(start.cg),
              Self.world.insetBy(dx: Self.ballRadius, dy: Self.ballRadius).contains(hole.cg),
              (obstacles + hazards + sand + [canal,penaltyObstacle]).allSatisfy(valid),
              !(obstacles + hazards + [canal]).contains(where: { $0.cg.insetBy(dx: -Self.ballRadius, dy: -Self.ballRadius).contains(start.cg) || $0.cg.insetBy(dx: -captureRadius, dy: -captureRadius).contains(hole.cg) })
        else { throw NSError(domain: "FoldPutt.Level", code: 1, userInfo: [NSLocalizedDescriptionKey: FPL10n.format("error_level",id)]) }
    }

    static func loadAll(bundle: Bundle = .main) throws -> [FPLevel] {
        try (["01-meadow","02-canal","03-sand"] + (1...6).map { String(format:"puzzle-%02d",$0) }).map { name in
            guard let url = bundle.url(forResource: name, withExtension: "json") else {
                throw NSError(domain: "FoldPutt.Level", code: 2, userInfo: [NSLocalizedDescriptionKey: FPL10n.format("error_level_missing",name)])
            }
            let level = try JSONDecoder().decode(FPLevel.self, from: Data(contentsOf: url))
            try level.validate()
            return level
        }
    }
}

enum FPCanalMapping {
    /// Project a hardware division to an inset, playable bank when the region is outside the course.
    static func collider(division: CGRect?, field: CGRect, fallback: CGRect) -> CGRect {
        guard let division, field.width > 0, field.height > 0 else { return fallback }
        if division.height > division.width {
            let projectedX = (division.midX - field.minX) / field.width
            let thickness = max(0.045, min(0.09, division.width / field.width))
            let x = min(0.88, max(0.035, projectedX - thickness / 2))
            return CGRect(x: x, y: fallback.minY, width: thickness, height: fallback.height)
        }
        let projectedY = (division.midY - field.minY) / field.height * FPLevel.world.height
        let thickness = max(0.045, min(0.09, division.height / field.height * FPLevel.world.height))
        let y = min(1.27, max(0.035, projectedY - thickness / 2))
        return CGRect(x: 0.12, y: y, width: 0.64, height: thickness)
    }
}
