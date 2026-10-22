import XCTest
import UIKit
@testable import FoldPutt

final class FPPrototypeTests:XCTestCase {
    @MainActor func testMockLaunchContract() throws {
        let port = FPMockPhysicsPort()
        let session = try FPDemoSession(physics: port,metricsStore:nil)
        let shot = FPShot(direction: CGVector(dx: 0, dy: -1), power: 0.5)
        session.aim(shot); session.release(shot); session.release(shot)
        XCTAssertEqual(port.commands.count, 1)
        XCTAssertEqual(port.commands[0].velocity.dx, 0, accuracy: 0.0001)
        XCTAssertEqual(port.commands[0].velocity.dy, 0.775, accuracy: 0.0001)
        XCTAssertEqual(port.commands[0].angle, .pi / 2, accuracy: 0.0001)
        session.reset()
        session.aim(nil); session.release(nil)
        XCTAssertEqual(port.commands.count, 1)
    }
    func testDeadZoneAndClampedPower() {
        XCTAssertNil(FPPullMath.shot(translation:CGPoint(x:2,y:2),maximum:100))
        let shot=FPPullMath.shot(translation:CGPoint(x:0,y:200),maximum:100)!
        XCTAssertEqual(shot.power,1);XCTAssertEqual(shot.direction.dy,-1)
        XCTAssertNil(FPPullMath.shot(translation:CGPoint(x:20,y:0),maximum:5))
    }
    func testIndependentSafeRectangleAndDivisionAvoidance() {
        let safe=CGRect(x:37,y:21,width:640-37-11,height:400-21-49)
        let division=CGRect(x:290,y:0,width:32,height:400)
        let usable=FPRegionSnapshot.usable(safe,excluding:[division])
        XCTAssertFalse(usable.intersects(division));XCTAssertTrue(safe.contains(usable))
        XCTAssertEqual(FPRegionSnapshot.usable(safe,excluding:[]),safe)
    }
    @MainActor func testCancellationAndDuplicateRelease() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(nil);session.cancel();session.release(FPShot(direction:CGVector(dx:0,dy:-1),power:0.5))
        XCTAssertEqual(session.strokes,0)
        let shot=FPShot(direction:CGVector(dx:0,dy:-1),power:0.5)
        session.aim(shot);session.release(shot);session.release(shot)
        XCTAssertEqual(session.strokes,1)
        session.reset();XCTAssertEqual(session.ball,session.start)
    }
}

extension FPPrototypeTests {
    @MainActor func testQModeHasIdenticalTrajectoryAndRewards() throws {
        let ordinary=try FPDemoSession(metricsStore:nil),chibi=try FPDemoSession(metricsStore:nil)
        chibi.setPresentation(mode:.chibi,mood:.silly,skin:.peach)
        let shot=FPShot(direction:CGVector(dx:0,dy:-1),power:0.55)
        for session in [ordinary,chibi] { session.aim(shot);session.release(shot) }
        for _ in 0..<1200 {
            ordinary.advance(1.0/120);chibi.advance(1.0/120)
            XCTAssertEqual(ordinary.world.position,chibi.world.position)
            XCTAssertEqual(ordinary.world.velocity,chibi.world.velocity)
            XCTAssertEqual(ordinary.phase,chibi.phase)
        }
        XCTAssertEqual(chibi.phase,.success);XCTAssertEqual(ordinary.stars,chibi.stars)
        XCTAssertEqual(chibi.chibiFeedback.celebrationCount,1)
        chibi.continueAfterWin();XCTAssertEqual(chibi.gameMode,.chibi);XCTAssertEqual(chibi.ballSkin,.peach)
    }
    @MainActor func testPrivacyPausesLiveShotAcrossSceneReactivation() throws {
        let session = try FPDemoSession(metricsStore: nil)
        let shot = FPShot(direction: CGVector(dx: 0, dy: -1), power: 0.3)
        session.aim(shot); session.release(shot); session.advance(0.1)
        let position = session.world.position, velocity = session.world.velocity
        let elapsed = session.elapsed, launch = session.lastLaunch?.id
        session.beginPrivacy()
        session.resume() // 前后台往返不能让政策页背后的球局继续计时。
        session.advance(65)
        XCTAssertEqual(session.world.position, position)
        XCTAssertEqual(session.world.velocity, velocity)
        XCTAssertEqual(session.elapsed, elapsed)
        XCTAssertFalse(session.penaltyActive)
        XCTAssertFalse(session.canAim)
        session.finishPrivacy()
        XCTAssertEqual(session.lastLaunch?.id, launch)
        XCTAssertEqual(session.strokes, 1)
        session.advance(0.01)
        XCTAssertNotEqual(session.world.position, position)
        session.beginModeSelection(); session.beginPrivacy(); session.finishPrivacy(); session.advance(2)
        XCTAssertTrue(session.isChoosingMode)
        XCTAssertFalse(session.canAim)
    }
    @MainActor func testChoosingLookPausesAndPreservesLiveShot() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let shot=FPShot(direction:CGVector(dx:0,dy:-1),power:0.3)
        session.aim(shot);session.release(shot);session.advance(0.1)
        let position=session.world.position,velocity=session.world.velocity,elapsed=session.elapsed,launch=session.lastLaunch?.id
        session.beginModeSelection();session.resume();session.advance(2)
        XCTAssertEqual(session.elapsed,elapsed);XCTAssertEqual(session.world.position,position);XCTAssertFalse(session.canAim)
        session.finishModeSelection(.chibi)
        XCTAssertEqual(session.world.position,position);XCTAssertEqual(session.world.velocity,velocity)
        XCTAssertEqual(session.lastLaunch?.id,launch);XCTAssertEqual(session.strokes,1)
        session.advance(0.01);XCTAssertNotEqual(session.world.position,position)
    }
    @MainActor func testLookSnapshotAndLegacyCompatibility() throws {
        let session=try FPDemoSession(metricsStore:nil);session.setPresentation(mode:.chibi,mood:.silly,skin:.sesame)
        let activity=try session.restorationActivity(),restored=try FPDemoSession(metricsStore:nil)
        try restored.restore(activity)
        XCTAssertEqual(restored.gameMode,.chibi);XCTAssertEqual(restored.chibiMood,.silly);XCTAssertEqual(restored.ballSkin,.sesame)
        XCTAssertNil(restored.chibiFeedback.visibleCue);XCTAssertEqual(restored.chibiFeedback.celebrationCount,0)
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:try XCTUnwrap(activity.userInfo?["snapshot"] as? Data)) as? [String:Any])
        for key in ["gameMode","chibiMood","ballSkin"] { json.removeValue(forKey:key) }
        activity.userInfo=["snapshot":try JSONSerialization.data(withJSONObject:json)]
        let legacy=try FPDemoSession(metricsStore:nil);try legacy.restore(activity)
        XCTAssertEqual(legacy.gameMode,.classic);XCTAssertEqual(legacy.ballSkin,.rice)
    }
    func testFeedbackDeduplicatesAndNearMissOccursOncePerShot() {
        var feedback=FPChibiFeedback()
        feedback.receive("shot",serial:1,position:.zero,direction:nil)
        let cup=CGPoint(x:0.5,y:0.5)
        func advance(_ position:CGPoint) { feedback.advance(0.01,position:position,hole:cup,captureRadius:0.04,rolling:true,inSand:false) }
        advance(CGPoint(x:0.55,y:0.5));advance(CGPoint(x:0.6,y:0.5))
        XCTAssertEqual(feedback.visibleCue,.nearMiss);XCTAssertEqual(feedback.nearMissCount,1)
        advance(CGPoint(x:0.54,y:0.5));advance(CGPoint(x:0.62,y:0.5))
        XCTAssertEqual(feedback.nearMissCount,1)
        feedback.receive("hole-success",serial:2,position:cup,direction:nil)
        feedback.receive("hole-success",serial:2,position:cup,direction:nil)
        XCTAssertEqual(feedback.celebrationCount,1)
        feedback.receive("shot",serial:3,position:.zero,direction:nil)
        feedback.receive("hole-capture",serial:4,position:cup,direction:nil)
        advance(CGPoint(x:0.54,y:0.5));advance(CGPoint(x:0.62,y:0.5))
        XCTAssertEqual(feedback.nearMissCount,1);XCTAssertEqual(feedback.visibleCue,.captured)
    }
    func testSandCueOnlyOnEntryAndCollisionExpires() {
        var feedback=FPChibiFeedback()
        feedback.receive("shot",serial:1,position:.zero,direction:nil)
        feedback.advance(0.1,position:.zero,hole:CGPoint(x:1,y:1),captureRadius:0.04,rolling:true,inSand:true)
        XCTAssertEqual(feedback.visibleCue,.sand);let serial=feedback.serial
        feedback.advance(0.1,position:.zero,hole:CGPoint(x:1,y:1),captureRadius:0.04,rolling:true,inSand:true)
        XCTAssertEqual(serial,feedback.serial)
        feedback.receive("collision",serial:2,position:.zero,direction:nil);XCTAssertEqual(feedback.visibleCue,.collision)
        feedback.advance(2,position:.zero,hole:.zero,captureRadius:0.04,rolling:false,inSand:false)
        XCTAssertNil(feedback.visibleCue)
    }
}

extension FPPrototypeTests {
    @MainActor func testMapSelectionResetsEveryRoundInBothModes() throws {
        for mode in FPGameMode.allCases {
            let session=try FPDemoSession(metricsStore:nil);session.setPresentation(mode:mode)
            XCTAssertGreaterThanOrEqual(session.levels.count,3)
            for index in session.levels.indices {
                session.loadLevel(index)
                let shot=FPShot(direction:CGVector(dx:0,dy:-1),power:0.2)
                session.aim(shot);session.release(shot);session.advance(0.1)
                XCTAssertFalse(session.canAim)
                session.loadLevel(index)
                XCTAssertEqual(session.strokes,0);XCTAssertEqual(session.elapsed,0)
                XCTAssertEqual(session.world.position,session.level.start.cg);XCTAssertEqual(session.world.speed,0)
                XCTAssertEqual(session.phase,.ready);XCTAssertTrue(session.canAim)
                XCTAssertFalse(session.isReplaying);XCTAssertTrue(session.shotReplay.isEmpty)
                XCTAssertNil(session.lastLaunch);XCTAssertEqual(session.gameMode,mode)
                XCTAssertEqual(session.stars,0);XCTAssertEqual(session.collisions,0)
            }
        }
    }
    @MainActor func testRealHoleInOneReplayDelaysWinAndRestoresWithoutRescoring() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<1200 { session.advance(1.0/120);if session.phase == .success { break } }
        XCTAssertEqual(session.phase,.success);XCTAssertTrue(session.isReplaying)
        XCTAssertEqual(session.shotReplay.first?.point,session.level.start.cg)
        XCTAssertEqual(session.shotReplay.last?.point,session.level.hole.cg)
        XCTAssertGreaterThan(session.shotReplay.count,10)
        session.continueAfterWin();XCTAssertEqual(session.levelIndex,0)
        let restored=try FPDemoSession(metricsStore:nil)
        try restored.restore(session.restorationActivity())
        XCTAssertTrue(restored.isReplaying);XCTAssertEqual(restored.shotReplay.count,session.shotReplay.count)
        XCTAssertEqual(restored.strokes,1);XCTAssertEqual(restored.stars,3)
        restored.suspend();let age=restored.replayElapsed;restored.advance(2);XCTAssertEqual(restored.replayElapsed,age)
        restored.resume();restored.advance(restored.replayDuration+0.1)
        XCTAssertFalse(restored.isReplaying);XCTAssertTrue(restored.canContinueAfterWin)
        XCTAssertEqual(restored.events.filter{$0["event"] == "hole-success"}.count,0)
        restored.continueAfterWin();restored.continueAfterWin();XCTAssertEqual(restored.levelIndex,1)
    }
    @MainActor func testRollingLockIsTiedToPhysicsStoppedEvent() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let hud=FPControlsController(session:session);hud.loadViewIfNeeded()
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2));session.release(session.preview)
        hud.refresh();hud.refreshVisibility(immediate:true)
        XCTAssertFalse(hud.pull.enabled);XCTAssertTrue(hud.pull.accessibilityTraits.contains(.notEnabled))
        if !UIAccessibility.isReduceTransparencyEnabled { XCTAssertEqual(hud.pull.alpha,FPMotion.disabledPullAlpha,accuracy:0.00001) }
        let strokes=session.strokes;session.aim(FPShot(direction:CGVector(dx:1,dy:0),power:1));session.release(session.preview)
        XCTAssertEqual(session.strokes,strokes)
        for _ in 0..<1500 { session.advance(1.0/120);if session.canAim { break } }
        hud.refresh();hud.refreshVisibility(immediate:true)
        XCTAssertEqual(session.world.speed,0);XCTAssertTrue(hud.pull.enabled);XCTAssertEqual(hud.pull.alpha,1)
        XCTAssertEqual(session.lastEvent,"stopped")
    }
    @MainActor func testReplaySkipAndMapSwitchCannotLeakPreviousWin() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<1200 { session.advance(1.0/120);if session.isReplaying { break } }
        session.finishReplay();session.finishReplay();XCTAssertTrue(session.canContinueAfterWin)
        session.loadLevel(2);session.advance(20)
        XCTAssertEqual(session.phase,.ready);XCTAssertEqual(session.strokes,0);XCTAssertFalse(session.isReplaying)
        XCTAssertTrue(session.shotReplay.isEmpty)
    }
}


extension FPPrototypeTests {
    @MainActor func testReduceMotionDuringReplayUsesStaticPathAndThenWin() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<1200 { session.advance(1.0/120);if session.isReplaying { break } }
        let position=session.world.position,stars=session.stars
        session.updateMotionPreference(reduced:true)
        XCTAssertTrue(session.replayStatic);XCTAssertEqual(session.replayTime,session.shotTime)
        session.advance(FPMotion.replayStaticHold+0.01)
        XCTAssertTrue(session.canContinueAfterWin);XCTAssertEqual(session.world.position,position);XCTAssertEqual(session.stars,stars)
    }
    @MainActor func testMultipleStrokesFinishWithoutHoleInOneReplay() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.1));session.release(session.preview)
        for _ in 0..<1400 { session.advance(1.0/120);if session.canAim { break } }
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.5));session.release(session.preview)
        for _ in 0..<1400 { session.advance(1.0/120);if session.phase == .success { break } }
        XCTAssertEqual(session.phase,.success);XCTAssertEqual(session.strokes,2)
        XCTAssertFalse(session.isReplaying);XCTAssertTrue(session.canContinueAfterWin)
    }
    @MainActor func testCourseBoundaryRespectsEverySafeAreaEdge() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let controller=FPCourseController(session:session)
        controller.immersive=true
        let window=UIWindow(frame:CGRect(x:0,y:0,width:640,height:480));window.rootViewController=controller;window.makeKeyAndVisible()
        defer { window.isHidden=true;window.rootViewController=nil }
        controller.additionalSafeAreaInsets=UIEdgeInsets(top:37,left:23,bottom:19,right:51)
        controller.view.layoutIfNeeded();controller.viewDidLayoutSubviews()
        let course=controller.course
        for mode in FPGameMode.allCases {
            session.setPresentation(mode:mode)
            for across in [false,true] {
                course.across=across
                let safe=course.bounds.inset(by:course.safeAreaInsets).insetBy(dx:FPTheme.courseWallInset,dy:FPTheme.courseWallInset)
                XCTAssertTrue(safe.insetBy(dx:-0.001,dy:-0.001).contains(course.field))
            }
        }
    }
}

extension FPPrototypeTests {
    func testInactiveFoldsDoNotShrinkInteractiveContentOrDoubleMargins() {
        let area=CGRect(x:0,y:0,width:800,height:600)
        let fold=CGRect(x:390,y:0,width:20,height:600)
        let inactive=FPRegionSnapshot(divisions:[fold])
        XCTAssertEqual(inactive.divisions,[fold],"Keep the decorative course seam")
        XCTAssertEqual(FPRegionSnapshot.usable(area,excluding:inactive.exclusions),area)
        let active=FPRegionSnapshot(divisions:[fold],activeDivisions:[fold])
        let pane=FPRegionSnapshot.usable(area,excluding:active.exclusions)
        XCTAssertEqual(pane.width,390,"Reserved frames already contain interaction margins")
        XCTAssertFalse(pane.intersects(fold))
        let camera=CGRect(x:720,y:0,width:80,height:600)
        let withCamera=FPRegionSnapshot(divisions:[fold],occlusions:[camera])
        XCTAssertEqual(FPRegionSnapshot.usable(area,excluding:withCamera.exclusions),CGRect(x:0,y:0,width:720,height:600))
        let two=FPRegionSnapshot(divisions:[fold],activeDivisions:[fold],occlusions:[camera])
        let safe=FPRegionSnapshot.usable(area,excluding:two.exclusions)
        XCTAssertTrue(area.contains(safe));XCTAssertFalse(two.exclusions.contains{$0.intersects(safe)})
    }
}
