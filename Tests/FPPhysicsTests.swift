import XCTest
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
    func testDivisionProjectionAndFallback() {
        let fallback=CGRect(x:0.04,y:0.46,width:0.055,height:0.62)
        let field=CGRect(x:120,y:30,width:300,height:420)
        XCTAssertEqual(FPCanalMapping.collider(division:nil,field:field,fallback:fallback),fallback)
        let mapped=FPCanalMapping.collider(division:CGRect(x:70,y:0,width:40,height:500),field:field,fallback:fallback)
        XCTAssertTrue(FPLevel.world.contains(mapped));XCTAssertLessThan(mapped.maxX,0.2)
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
        session.suspend();session.advance(10);XCTAssertEqual(session.elapsed,0)
        session.resume();session.aim(FPShot(direction:CGVector(dx:-1,dy:0),power:0.7));session.release(session.preview)
        for _ in 0..<900 { session.advance(1.0/120) }
        XCTAssertGreaterThanOrEqual(session.collisions,1);XCTAssertTrue(session.penaltyActive)
        XCTAssertEqual(session.events.filter{$0["event"]=="penalty"}.count,1)
    }
}
