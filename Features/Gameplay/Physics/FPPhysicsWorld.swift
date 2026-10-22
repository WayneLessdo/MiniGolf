import Foundation
import CoreGraphics

/// ponytail: one circular ball and static axis-aligned rectangles; add other shapes only when a level needs them.
struct FPPhysicsWorld: Codable {
    enum Event: Equatable { case collision(String), outOfBounds, stopped, captured }
    var level: FPLevel
    let tuning: FPTuning.Physics
    private var settledFor: TimeInterval = 0
    private(set) var position: CGPoint
    private(set) var velocity = CGVector.zero  // world y-down
    private(set) var safePosition: CGPoint
    private(set) var captured = false
    var canal: CGRect
    var extraObstacle: CGRect?
    var divisionBanks: [CGRect]?
    private var contacts = Set<String>()
    private var recentLaunches = Set<UUID>()
    var speed: CGFloat { hypot(velocity.dx, velocity.dy) }
    var moving: Bool { speed > 0 && !captured }
    var solids: [(String,CGRect)] {
        level.obstacles.enumerated().map { ("obstacle-\($0.offset)",$0.element.cg) }
        + [("canal",canal)] + (divisionBanks ?? []).enumerated().map { ("division-\($0.offset)",$0.element) } + (extraObstacle.map { [("penalty",$0)] } ?? [])
    }

    init(level: FPLevel, tuning: FPTuning.Physics) {
        self.level = level; self.tuning = tuning; position = level.start.cg; safePosition = level.start.cg; canal = level.canal.cg
    }
    mutating func launch(_ command: FPLaunch) {
        guard !moving, !captured, !recentLaunches.contains(command.id),
              command.velocity.dx.isFinite, command.velocity.dy.isFinite else { return }
        recentLaunches.insert(command.id)
        if recentLaunches.count > 128 { recentLaunches = [command.id] }
        let magnitude = hypot(command.velocity.dx, command.velocity.dy)
        guard magnitude > 0 else { return }
        let limit = min(magnitude, CGFloat(tuning.maximumSpeed)) / magnitude
        velocity = CGVector(dx: command.velocity.dx * limit, dy: -command.velocity.dy * limit)
        contacts.removeAll(); settledFor=0
    }
    mutating func restoreSafe() { position = safePosition; velocity = .zero; contacts.removeAll() }
    func legalRest(_ point: CGPoint) -> Bool {
        let r = FPLevel.ballRadius
        return FPLevel.world.insetBy(dx:r,dy:r).contains(point)
            && !solids.contains { $0.1.insetBy(dx:-r,dy:-r).contains(point) }
            && !level.hazards.contains { $0.cg.insetBy(dx:-r,dy:-r).contains(point) }
    }
    mutating func updateCanal(_ rect: CGRect) {
        guard !moving, !captured else { return }
        // Do not materialize a wall through the ball or the saved restart point.
        let expanded = rect.insetBy(dx:-FPLevel.ballRadius*2,dy:-FPLevel.ballRadius*2)
        guard !expanded.contains(position), !expanded.contains(safePosition),
              !expanded.contains(level.hole.cg) else { return }
        canal = rect
    }
    mutating func updateReservedBanks(_ rects:[CGRect]) {
        guard !moving,!captured,rects.count<=16,
              rects.allSatisfy({ !$0.isNull && $0.width>0 && $0.height>0 && FPLevel.world.contains($0) && !$0.insetBy(dx:-FPLevel.ballRadius*2,dy:-FPLevel.ballRadius*2).contains(position) && !$0.insetBy(dx:-FPLevel.ballRadius*2,dy:-FPLevel.ballRadius*2).contains(safePosition) && !$0.insetBy(dx:-FPLevel.ballRadius*2,dy:-FPLevel.ballRadius*2).contains(level.hole.cg) }) else { return }
        if (divisionBanks ?? []) != rects { contacts=contacts.filter { !$0.hasPrefix("division-") } }
        divisionBanks=rects
    }
    mutating func addPenaltyObstacle() -> Bool {
        let rect = level.penaltyObstacle.cg
        let keepClear = rect.insetBy(dx:-FPLevel.ballRadius*3,dy:-FPLevel.ballRadius*3)
        guard !keepClear.contains(position), !keepClear.contains(safePosition),
              !keepClear.contains(level.hole.cg), !rect.intersects(canal),!(divisionBanks ?? []).contains(where:{$0.intersects(rect)}),
              !level.hazards.contains(where: { $0.cg.intersects(rect) }) else { restoreSafe(); return false }
        extraObstacle = rect
        return true
    }

    mutating func step(_ dt: TimeInterval) -> [Event] {
        guard moving, dt.isFinite, dt > 0 else { return [] }
        var events: [Event] = []
        // Substeps cap travel at half a radius, preventing tunneling through thin rectangle banks.
        let interval = min(dt, 1.0/30)
        let count = max(1, Int(ceil(speed * interval / (FPLevel.ballRadius * 0.5))))
        let h = CGFloat(interval) / CGFloat(count)
        for _ in 0..<count {
            let previous = position
            position.x += velocity.dx*h; position.y += velocity.dy*h
            if level.hazards.contains(where: { $0.cg.contains(position) }) {
                restoreSafe(); events.append(.outOfBounds); return events
            }
            let hole = level.hole.cg
            let distance = hypot(position.x-hole.x,position.y-hole.y)
            if distance <= tuning.captureRadius && speed <= tuning.captureLimit(distance:distance) {
                position = hole; velocity = .zero; captured = true; events.append(.captured); return events
            }
            var touching = Set<String>()
            let radius = FPLevel.ballRadius
            let bounds = FPLevel.world.insetBy(dx:radius,dy:radius)
            if position.x < bounds.minX { position.x=bounds.minX; velocity=Self.reflected(velocity,normal:CGVector(dx:1,dy:0),restitution:restitution(at:position,wall:true)); touching.insert("left") }
            if position.x > bounds.maxX { position.x=bounds.maxX; velocity=Self.reflected(velocity,normal:CGVector(dx:-1,dy:0),restitution:restitution(at:position,wall:true)); touching.insert("right") }
            if position.y < bounds.minY { position.y=bounds.minY; velocity=Self.reflected(velocity,normal:CGVector(dx:0,dy:1),restitution:restitution(at:position,wall:true)); touching.insert("top") }
            if position.y > bounds.maxY { position.y=bounds.maxY; velocity=Self.reflected(velocity,normal:CGVector(dx:0,dy:-1),restitution:restitution(at:position,wall:true)); touching.insert("bottom") }
            for (id,rect) in solids {
                let nearest = CGPoint(x:min(rect.maxX,max(rect.minX,position.x)),y:min(rect.maxY,max(rect.minY,position.y)))
                var dx=position.x-nearest.x, dy=position.y-nearest.y
                let length=hypot(dx,dy)
                guard length < radius else { continue }
                if length > 0.000001 {
                    dx /= length; dy /= length
                    position.x += dx*(radius-length+0.00001); position.y += dy*(radius-length+0.00001)
                } else {
                    let exits: [(CGFloat,CGVector)] = [(abs(previous.x-rect.minX),CGVector(dx:-1,dy:0)),(abs(previous.x-rect.maxX),CGVector(dx:1,dy:0)),(abs(previous.y-rect.minY),CGVector(dx:0,dy:-1)),(abs(previous.y-rect.maxY),CGVector(dx:0,dy:1))]
                    let n=exits.min(by:{$0.0<$1.0})!.1;dx=n.dx;dy=n.dy
                    if dx < 0 { position.x=rect.minX-radius } else if dx > 0 { position.x=rect.maxX+radius }
                    if dy < 0 { position.y=rect.minY-radius } else if dy > 0 { position.y=rect.maxY+radius }
                }
                let impact=velocity.dx*dx+velocity.dy*dy
                if impact < 0 {
                    velocity=Self.reflected(velocity,normal:CGVector(dx:dx,dy:dy),restitution:(id == "canal" || id.hasPrefix("division-")) ? tuning.bank.restitution:restitution(at:position,wall:false))
                }
                touching.insert(id)
            }
            for id in touching.subtracting(contacts) { events.append(.collision(id)) }
            // Keep contacts until there is a real separation (rather than counting every integration frame).
            contacts = contacts.filter { id in
                if let rect=solids.first(where:{$0.0==id})?.1 { return rect.insetBy(dx:-radius-0.005,dy:-radius-0.005).contains(position) }
                switch id {
                case "left":return position.x < bounds.minX+0.005
                case "right":return position.x > bounds.maxX-0.005
                case "top":return position.y < bounds.minY+0.005
                default:return position.y > bounds.maxY-0.005
                }
            }.union(touching)
            let drag=material(at:position).drag
            let oldSpeed=speed, nextSpeed=oldSpeed*exp(-CGFloat(drag)*h)
            settledFor = nextSpeed < tuning.stopSpeed ? settledFor+Double(h):0
            if settledFor >= tuning.settleDuration || oldSpeed == 0 {
                settledFor=min(settledFor,tuning.settleDuration)
                velocity = .zero
                if legalRest(position) { safePosition=position }
                events.append(.stopped);return events
            }
            velocity.dx *= nextSpeed/oldSpeed;velocity.dy *= nextSpeed/oldSpeed
        }
        return events
    }

    func material(at point: CGPoint) -> FPTuning.Material {
        if level.sand.contains(where:{$0.cg.contains(point)}) { return tuning.sand }
        if ([canal]+(divisionBanks ?? [])).contains(where:{$0.insetBy(dx:-tuning.bankMargin-FPLevel.ballRadius,dy:-tuning.bankMargin-FPLevel.ballRadius).contains(point)}) { return tuning.bank }
        return tuning.grass
    }
    private func restitution(at point: CGPoint,wall: Bool) -> CGFloat {
        if !wall { return material(at:point).restitution }
        if level.sand.contains(where:{$0.cg.contains(point)}) { return tuning.sand.restitution }
        if ([canal]+(divisionBanks ?? [])).contains(where:{$0.insetBy(dx:-tuning.bankMargin-FPLevel.ballRadius,dy:-tuning.bankMargin-FPLevel.ballRadius).contains(point)}) { return tuning.bank.restitution }
        return tuning.wallRestitution
    }
    static func reflected(_ velocity: CGVector,normal: CGVector,restitution: CGFloat) -> CGVector {
        let dot=velocity.dx*normal.dx+velocity.dy*normal.dy
        guard dot<0 else { return velocity }
        // Attenuate the whole reflected vector: incident and reflected angles stay equal.
        return CGVector(dx:(velocity.dx-2*dot*normal.dx)*restitution,dy:(velocity.dy-2*dot*normal.dy)*restitution)
    }

    func validateRestoration() throws {
        let allowed=Set(["left","right","top","bottom"]+solids.map(\.0))
        let values=[position.x,position.y,safePosition.x,safePosition.y,velocity.dx,velocity.dy,canal.origin.x,canal.origin.y,canal.width,canal.height]
        guard values.allSatisfy(\.isFinite),FPLevel.world.contains(position),legalRest(safePosition),
              canal.width>0,canal.height>0,FPLevel.world.contains(canal),
              extraObstacle == nil || extraObstacle == level.penaltyObstacle.cg,
              speed<=tuning.maximumSpeed+0.000001,settledFor.isFinite,settledFor>=0,settledFor<=tuning.settleDuration+1.0/30+0.000001,
              contacts.isSubset(of:allowed),recentLaunches.count<=128,
              (divisionBanks ?? []).count<=16,(divisionBanks ?? []).allSatisfy({$0.width>0 && $0.height>0 && FPLevel.world.contains($0)}),
              !captured || (position == level.hole.cg && speed == 0)
        else { throw NSError(domain:"FoldPutt.Restoration",code:2,userInfo:[NSLocalizedDescriptionKey:FPL10n.text("error_snapshot_invalid")]) }
    }

    #if DEBUG
    /// Deterministic initial conditions for tests/capture. Results still come from step().
    mutating func stage(at point: CGPoint, velocity: CGVector = .zero) {
        precondition(legalRest(point))
        position=point;self.velocity=velocity;captured=false;contacts.removeAll()
    }
    #endif
}
