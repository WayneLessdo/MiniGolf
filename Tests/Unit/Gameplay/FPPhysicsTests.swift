import XCTest
import UIKit
@testable import FoldPutt

final class FPPhysicsTests: XCTestCase {
    private func levels() throws -> [FPLevel] { try FPLevel.loadAll() }
    private func shot(_ x: CGFloat, _ y: CGFloat, _ power: CGFloat, speed: CGFloat = 1.55) -> FPLaunch {
        FPLaunch(shot: FPShot(direction:CGVector(dx:x,dy:y),power:power), maximumSpeed:speed)
    }
    func testThreeValidatedLevelsAndMalformedData() throws {
        let all=try levels();XCTAssertEqual(all.count,9);XCTAssertEqual(all.filter(\.isPuzzle).count,6)
        let data=try JSONEncoder().encode(all[0])
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any]);json["friction"] = -1
        let bad=try JSONDecoder().decode(FPLevel.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertThrowsError(try bad.validate())
    }
    func testFrictionCaptureAndFramePartition() throws {
        let level=try levels()[0]
        var a=FPPhysicsWorld(level:level,tuning:try FPTuning.load().physics),b=a
        let launch=shot(0,-1,0.55)
        a.launch(launch);b.launch(launch)
        var captured=false
        for _ in 0..<600 { captured = a.step(1.0/120).contains(.captured) || captured }
        for _ in 0..<300 { _ = b.step(1.0/60) }
        XCTAssertTrue(captured);XCTAssertTrue(a.captured);XCTAssertEqual(a.position,level.hole.cg)
        XCTAssertEqual(a.position.x,b.position.x,accuracy:0.002)
        XCTAssertEqual(a.position.y,b.position.y,accuracy:0.002)
    }
    func testBoundsCanalAndStaticSnapshot() throws {
        var world=FPPhysicsWorld(level:try levels()[1],tuning:try FPTuning.load().physics)
        let bank=world.canal
        world.stage(at:CGPoint(x:bank.maxX+0.1,y:bank.midY))
        world.launch(shot(-1,0,1,speed:3))
        world.updateCanal(CGRect(x:0.5,y:0.5,width:0.08,height:0.5))
        XCTAssertEqual(world.canal,bank)
        var contacts=0
        for _ in 0..<30 { contacts += world.step(1.0/120).filter { $0 == .collision("canal") }.count }
        XCTAssertEqual(contacts,1);XCTAssertGreaterThan(world.velocity.dx,0)
        XCTAssertGreaterThanOrEqual(world.position.x,bank.maxX+FPLevel.ballRadius-0.001)
        world.restoreSafe();world.stage(at:CGPoint(x:0.95,y:0.3));world.launch(shot(1,0,0.5))
        var boundary=false
        for _ in 0..<40 { boundary = world.step(1.0/120).contains(.collision("right")) || boundary }
        XCTAssertTrue(boundary);XCTAssertLessThan(world.velocity.dx,0)
    }
    func testOutOfBoundsReturnsLastStablePointAndSandSlows() throws {
        let all=try levels()
        var world=FPPhysicsWorld(level:all[0],tuning:try FPTuning.load().physics);world.launch(shot(0,-1,0.2))
        for _ in 0..<1200 { _ = world.step(1.0/120) }
        let safe=world.safePosition;XCTAssertNotEqual(safe,all[0].start.cg)
        world.stage(at:CGPoint(x:0.8,y:0.95));world.launch(shot(1,0,0.6))
        var reset=false
        for _ in 0..<120 { reset = world.step(1.0/120).contains(.outOfBounds) || reset }
        XCTAssertTrue(reset);XCTAssertEqual(world.position,safe);XCTAssertEqual(world.speed,0)
        var sand=FPPhysicsWorld(level:all[2],tuning:try FPTuning.load().physics),grass=sand
        sand.stage(at:CGPoint(x:0.48,y:0.8));grass.stage(at:CGPoint(x:0.48,y:0.4))
        let launch=shot(1,0,0.3);sand.launch(launch);grass.launch(launch)
        for _ in 0..<12 { _ = sand.step(1.0/120);_ = grass.step(1.0/120) }
        XCTAssertLessThan(sand.speed,grass.speed)
    }
    func testNaturalCourseCrossesObstacleAndReturnsAtBoundaryWithoutRebound() throws {
        let level = try levels()[1]
        var world = FPPhysicsWorld(level: level, tuning: try FPTuning.load().physics)
        world.naturalFlight = true
        let canal = level.obstacles[0].cg
        world.stage(at: CGPoint(x: canal.maxX+0.14, y: canal.midY))
        world.launch(shot(-1,0,0.5))
        var hopped = false, bounced = false, returned = false, crossed = false
        for _ in 0..<1500 {
            let events = world.step(1.0/120)
            hopped = hopped || (world.hopProgress.map { $0 > 0 && $0 < 1 } ?? false)
            crossed = crossed || world.position.x < canal.minX-FPLevel.ballRadius
            bounced = bounced || events.contains { if case .collision = $0 { return true }; return false }
            returned = returned || events.contains(.outOfBounds)
            if !world.moving { break }
            XCTAssertLessThanOrEqual(world.velocity.dx, 0)
        }
        XCTAssertTrue(hopped); XCTAssertTrue(crossed); XCTAssertFalse(bounced)
        XCTAssertTrue(returned); XCTAssertEqual(world.position, world.safePosition)
    }
    @MainActor func testNaturalFlightRestoreAndPuzzleModeIsolation() throws {
        let session = try FPDemoSession(metricsStore: nil)
        XCTAssertEqual(session.world.naturalFlight, true)
        session.loadLevel(1)
        let shot = FPShot(direction: CGVector(dx: -1,dy: 0), power: 0.6)
        session.aim(shot); session.release(shot)
        for _ in 0..<120 { session.advance(1.0/120); if session.world.hopProgress != nil { break } }
        let saved = try session.restorationActivity()
        let restored = try FPDemoSession(metricsStore: nil)
        try restored.restore(saved)
        XCTAssertEqual(restored.world.position, session.world.position)
        XCTAssertEqual(restored.world.hopProgress, session.world.hopProgress)
        XCTAssertEqual(restored.world.naturalFlight, true)
        session.loadLevel(3); XCTAssertEqual(session.world.naturalFlight, false)
        session.loadLevel(0); session.setPresentation(mode: .chibi)
        XCTAssertEqual(session.world.naturalFlight, false)
    }

    func testDivisionProjectionAndFallback() {
        let fallback=CGRect(x:0.04,y:0.46,width:0.055,height:0.62)
        let field=CGRect(x:120,y:30,width:300,height:420)
        XCTAssertEqual(FPCanalMapping.collider(division:nil,field:field,fallback:fallback),fallback)
        let mapped=FPCanalMapping.collider(division:CGRect(x:70,y:0,width:40,height:500),field:field,fallback:fallback)
        XCTAssertTrue(FPLevel.world.contains(mapped));XCTAssertLessThan(mapped.maxX,0.2)
    }
    /// 展开内屏的中缝在球场里是一条带桥面的水道：球只能从桥面通过。
    /// 这里固定 P01 的两种场地校准，占用例与 UI 用例共用同一组球路。
    @MainActor func testPuzzleBankRouteCoversCleanAndFoldedCourse() throws {
        let tune=try FPTuning.load().physics
        let level=try XCTUnwrap(try levels().first { $0.id == "P01" })
        let area=CGRect(x:0,y:0,width:951,height:669).inset(by:UIEdgeInsets(top:0,left:0,bottom:34,right:84)).insetBy(dx:FPTheme.courseWallInset,dy:FPTheme.courseWallInset)
        let banks=FPCourseProjection(area:area,across:true).banks(for:CGRect(x:455.5,y:0,width:40,height:669))
        XCTAssertEqual(banks.count,2)
        func holesOut(_ direction:CGVector,_ power:CGFloat,withCanal:Bool)->Bool {
            var world=FPPhysicsWorld(level:level,tuning:tune)
            world.updateReservedBanks(withCanal ? banks:[])
            world.launch(FPLaunch(shot:FPShot(direction:direction,power:power),maximumSpeed:CGFloat(tune.maximumSpeed)))
            for _ in 0..<6000 {
                let events=world.step(1.0/120)
                if events.contains(.captured) { return true }
                if events.contains(.stopped) { return false }
            }
            return false
        }
        XCTAssertTrue(holesOut(CGVector(dx:-0.8660254037844386,dy:-0.5),1,withCanal:false),"无中缝的左墙借力球")
        XCTAssertTrue(holesOut(CGVector(dx:-0.5736,dy:-0.8192),0.72,withCanal:true),"折痕水道场地上的左墙借力球")
        XCTAssertFalse(holesOut(CGVector(dx:-0.8660254037844386,dy:-0.5),1,withCanal:true),"水道会挡住无中缝时的球路，两者需要各自校准")
    }

    @MainActor func testRealSessionRewardAndPenaltyAreSingleEvents() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<700 { session.advance(1.0/120) }
        XCTAssertEqual(session.phase,.success);XCTAssertEqual(session.stars,3);XCTAssertFalse(session.speedLineReward)
        for _ in 0..<700 { session.advance(1.0/120) }
        XCTAssertEqual(session.events.filter{$0["event"]=="hole-success"}.count,1)
        session.reset()
        for _ in 0..<7300 { session.advance(1.0/120) }
        XCTAssertTrue(session.penaltyActive);XCTAssertEqual(session.phase,.penalty)
        XCTAssertNotNil(session.world.extraObstacle)
        XCTAssertEqual(session.events.filter{$0["event"]=="penalty"}.count,1)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.3));session.release(session.preview)
        XCTAssertEqual(session.phase,.rolling)
    }
    @MainActor func testContactThresholdTriggersOnlyAfterMotionAndPauseStopsTimer() throws {
        let original=try levels()[0]
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(original)) as? [String:Any])
        json["collisionLimit"]=1;json["timeLimit"]=600
        let level=try JSONDecoder().decode(FPLevel.self,from:JSONSerialization.data(withJSONObject:json))
        let session=try FPDemoSession(levels:[level],metricsStore:nil)
        session.setPresentation(mode: .chibi)
        session.suspend();session.advance(10);XCTAssertEqual(session.elapsed,0)
        session.resume();session.aim(FPShot(direction:CGVector(dx:-1,dy:0),power:0.7));session.release(session.preview)
        for _ in 0..<900 { session.advance(1.0/120) }
        XCTAssertGreaterThanOrEqual(session.collisions,1);XCTAssertTrue(session.penaltyActive)
        XCTAssertEqual(session.events.filter{$0["event"]=="penalty"}.count,1)
    }
}
