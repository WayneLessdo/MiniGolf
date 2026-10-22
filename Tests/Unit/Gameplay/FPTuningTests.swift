import XCTest
import UIKit
@testable import FoldPutt

final class FPTuningTests: XCTestCase {
    func testInputCurveBoundsAndInvalidValues() throws {
        let tuning=try FPTuning.load()
        for p in [tuning.compact,tuning.regular] {
            XCTAssertNil(FPPullMath.shot(translation:CGPoint(x:0,y:p.deadZone),maximum:p.maximumDrag,deadZone:p.deadZone,exponent:p.exponent))
            let quarter=FPPullMath.shot(translation:CGPoint(x:0,y:p.deadZone+(p.maximumDrag-p.deadZone)*0.25),maximum:p.maximumDrag,deadZone:p.deadZone,exponent:p.exponent)!
            XCTAssertLessThan(quarter.power,0.25)
            let maximum=FPPullMath.shot(translation:CGPoint(x:0,y:p.maximumDrag*2),maximum:p.maximumDrag,deadZone:p.deadZone,exponent:p.exponent)!
            XCTAssertEqual(maximum.power,1);XCTAssertEqual(maximum.direction.dy,-1)
        }
        XCTAssertNil(FPPullMath.shot(translation:CGPoint(x:CGFloat.nan,y:0),maximum:100))
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(tuning)) as? [String:Any])
        var compact=json["compact"] as! [String:Any];compact["maximumDrag"]=2;json["compact"]=compact
        let invalid=try JSONDecoder().decode(FPTuning.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertThrowsError(try invalid.validate())
    }
    func testExponentialTailAndConsistentReflection() throws {
        let tune=try FPTuning.load().physics,level=try FPLevel.loadAll()[0]
        var world=FPPhysicsWorld(level:level,tuning:tune)
        world.stage(at:CGPoint(x:0.5,y:0.8),velocity:CGVector(dx:0.03,dy:0))
        _=world.step(1.0/120)
        XCTAssertGreaterThan(world.speed,0.029);XCTAssertLessThan(world.speed,0.03)
        for e in [tune.grass.restitution,tune.sand.restitution,tune.bank.restitution,tune.wallRestitution] {
            let v=FPPhysicsWorld.reflected(CGVector(dx:1,dy:2),normal:CGVector(dx:-1,dy:0),restitution:e)
            XCTAssertEqual(v.dx,-e,accuracy:0.0001);XCTAssertEqual(v.dy,2*e,accuracy:0.0001)
        }
        XCTAssertGreaterThan(tune.sand.drag,tune.grass.drag)
        XCTAssertNotEqual(tune.bank.restitution,tune.grass.restitution)
    }
    func testSlowCaptureFastFlyPast() throws {
        let tune=try FPTuning.load().physics,level=try FPLevel.loadAll()[0]
        var slow=FPPhysicsWorld(level:level,tuning:tune),fast=slow
        let point=CGPoint(x:level.hole.x,y:level.hole.y+0.06)
        slow.stage(at:point,velocity:CGVector(dx:0,dy:-0.12));fast.stage(at:point,velocity:CGVector(dx:0,dy:-1.5))
        XCTAssertTrue(slow.step(1.0/120).contains(.captured))
        for _ in 0..<20 { _=fast.step(1.0/120) }
        XCTAssertFalse(fast.captured);XCTAssertLessThan(fast.position.y,level.hole.y)
        XCTAssertGreaterThan(tune.captureLimit(distance:0.01),tune.captureLimit(distance:0.08))
    }
    @MainActor func testBoostEarnUseExpireAndNoCrossLevelCarry() throws {
        let session=try FPDemoSession(metricsStore:nil)
        func win() {
            session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
            for _ in 0..<1000 { session.advance(1.0/120) }
            XCTAssertEqual(session.phase,.success)
        }
        win();XCTAssertFalse(session.speedLineReward)
        session.reset();XCTAssertTrue(session.speedLineReward);XCTAssertEqual(session.boostCounts["triggers"],1)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55))
        let position=session.world.position
        XCTAssertGreaterThan(session.prediction.count,2);XCTAssertEqual(session.world.position,position)
        session.cancel();XCTAssertTrue(session.speedLineReward)
        win();XCTAssertEqual(session.boostCounts["uses"],1);XCTAssertFalse(session.speedLineReward)
        session.reset();session.advance(session.tuning.boost.duration+0.1)
        XCTAssertFalse(session.speedLineReward);XCTAssertEqual(session.boostCounts["expired"],1)
        session.advance(1);XCTAssertEqual(session.boostCounts["expired"],1)
        session.loadLevel(1);XCTAssertEqual(session.boostSeconds,0);XCTAssertTrue(session.prediction.isEmpty)
    }
    @MainActor func testTransitionDoesNotResetShotOrPhysics() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.aim(FPShot(direction:CGVector(dx:0.3,dy:-1),power:0.8));session.release(session.preview)
        let id=session.lastLaunch!.id,canal=session.world.canal
        session.advance(1.0/120)
        let position=session.world.position
        session.setRegularInput(true)
        session.updateDivision(CGRect(x:0,y:300,width:600,height:40),field:CGRect(x:0,y:0,width:300,height:420))
        session.cancel();session.suspend();session.advance(1);session.resume()
        XCTAssertEqual(session.strokes,1);XCTAssertEqual(session.lastLaunch!.id,id)
        XCTAssertEqual(session.world.position,position);XCTAssertEqual(session.world.canal,canal)
        session.advance(1.0/120);XCTAssertNotEqual(session.world.position,position)
    }
    @MainActor func testSceneCheckpointContinuesSameRollingShotOnce() throws {
        let original=try FPDemoSession(metricsStore:nil)
        original.aim(FPShot(direction:CGVector(dx:0.25,dy:-1),power:0.8));original.release(original.preview)
        for _ in 0..<12 { original.advance(1.0/120) }
        let activity=try original.restorationActivity(),restored=try FPDemoSession(metricsStore:nil)
        XCTAssertTrue(try restored.restore(activity))
        XCTAssertEqual(restored.strokes,original.strokes);XCTAssertEqual(restored.lastLaunch,original.lastLaunch)
        XCTAssertEqual(restored.world.position,original.world.position);XCTAssertEqual(restored.world.velocity,original.world.velocity)
        XCTAssertEqual(restored.world.canal,original.world.canal)
        for _ in 0..<120 { original.advance(1.0/120);restored.advance(1.0/120) }
        XCTAssertEqual(restored.world.position,original.world.position);XCTAssertEqual(restored.collisions,original.collisions)
        let progressed=restored.world.position
        XCTAssertFalse(try restored.restore(activity));XCTAssertEqual(restored.world.position,progressed)
        XCTAssertEqual(restored.restorationCount,1)
    }
    @MainActor func testSceneCheckpointPreservesBoostCancelsOnlyUnreleasedDrag() throws {
        let original=try FPDemoSession(metricsStore:nil)
        original.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));original.release(original.preview)
        for _ in 0..<1000 { original.advance(1.0/120) }
        original.reset();original.advance(2);original.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.25))
        let restored=try FPDemoSession(metricsStore:nil);try restored.restore(original.restorationActivity())
        XCTAssertEqual(restored.phase,.ready);XCTAssertNil(restored.preview);XCTAssertEqual(restored.strokes,0)
        XCTAssertEqual(restored.world.position,original.world.position);XCTAssertEqual(restored.boostSeconds,original.boostSeconds)
        XCTAssertEqual(restored.boostCounts,original.boostCounts)
        restored.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2));restored.release(restored.preview)
        XCTAssertEqual(restored.boostCounts["uses"],1);XCTAssertEqual(restored.strokes,1)
    }
    @MainActor func testSceneCheckpointPreservesPenaltyAndRejectsCorruptionAtomically() throws {
        let original=try FPDemoSession(metricsStore:nil);original.advance(original.level.timeLimit+0.01)
        XCTAssertTrue(original.penaltyActive)
        let activity=try original.restorationActivity(),restored=try FPDemoSession(metricsStore:nil)
        try restored.restore(activity)
        XCTAssertTrue(restored.penaltyActive);XCTAssertEqual(restored.world.extraObstacle,original.world.extraObstacle)
        XCTAssertEqual(restored.elapsed,original.elapsed);XCTAssertEqual(restored.phase,.penalty)
        let data=try XCTUnwrap(activity.userInfo?["snapshot"] as? Data)
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        json["version"]=999
        let bad=NSUserActivity(activityType:FPDemoSession.restorationType)
        bad.userInfo=["snapshot":try JSONSerialization.data(withJSONObject:json)]
        XCTAssertThrowsError(try restored.restore(bad));XCTAssertEqual(restored.phase,.penalty)
        json["version"]=1;json["checkpoint"]=UUID().uuidString
        var world=json["world"] as! [String:Any];world["velocity"]=[999,0];json["world"]=world
        bad.userInfo=["snapshot":try JSONSerialization.data(withJSONObject:json)]
        XCTAssertThrowsError(try restored.restore(bad));XCTAssertEqual(restored.world.position,original.world.position)
        bad.userInfo=["snapshot":Data(repeating:0,count:65_537)]
        XCTAssertThrowsError(try restored.restore(bad))
    }
    @MainActor func testRightSplitAsymmetricInsetsAndReservedRegions() throws {
        let controller=FPControlsController(session:try FPDemoSession(metricsStore:nil))
        controller.loadViewIfNeeded()
        let old=controller.view!,host=FPRightInsetView(frame:CGRect(x:0,y:0,width:420,height:720))
        old.subviews.forEach { host.addSubview($0) };controller.view=host
        controller.exclusions=[CGRect(x:388,y:0,width:32,height:720),CGRect(x:300,y:0,width:88,height:70)]
        for insets in [UIEdgeInsets(top:17,left:9,bottom:31,right:83),UIEdgeInsets(top:17,left:83,bottom:31,right:9)] {
            host.testInsets=insets;controller.viewDidLayoutSubviews();host.layoutIfNeeded()
            let safe=host.bounds.inset(by:insets)
            for widget in [controller.pull as UIView,controller.toolbar,controller.scoreCard,controller.status].filter({!$0.isHidden}) {
                XCTAssertTrue(safe.contains(widget.frame),"\(widget.frame) outside \(safe)")
                XCTAssertFalse(controller.exclusions.contains { $0.intersects(widget.frame) })
            }
            let pull=host.convert(controller.pull.bounds,from:controller.pull)
            XCTAssertTrue(safe.contains(pull));XCTAssertGreaterThan(pull.height,44)
        }
    }
    @MainActor func testBothModesUseFullscreenCanvasDespiteOldImmersivePreference() throws {
        for size in [CGSize(width:390,height:844),CGSize(width:951,height:669)] {
            let session=try FPDemoSession(metricsStore:nil)
            session.immersivePreference=false
            let root=FPAdaptiveController(session:session),window=UIWindow(frame:CGRect(origin:.zero,size:size))
            window.rootViewController=root;window.makeKeyAndVisible()
            defer { window.isHidden=true;window.rootViewController=nil }
            root.view.frame=window.bounds;root.view.setNeedsLayout();root.view.layoutIfNeeded()
            let nav=try XCTUnwrap(root.children.first as? UINavigationController)
            let layout=try XCTUnwrap(nav.topViewController as? FPPlayLayoutController)
            XCTAssertTrue(layout.immersive)
            for mode in [FPGameMode.classic,.chibi] {
                let position=session.world.position,strokes=session.strokes
                session.setPresentation(mode:mode);root.view.layoutIfNeeded();layout.view.layoutIfNeeded()
                XCTAssertTrue(layout.course.immersive);XCTAssertTrue(layout.controls.floating)
                XCTAssertEqual(layout.course.view.frame,layout.view.bounds)
                XCTAssertEqual(layout.controls.view.frame,layout.view.bounds)
                XCTAssertEqual(session.world.position,position);XCTAssertEqual(session.strokes,strokes)
            }
        }
    }
    @MainActor func testPerimeterHUDAcrossRegionsAndGestureVisibility() throws {
        let session=try FPDemoSession(metricsStore:nil),controller=FPControlsController(session:session)
        controller.floating=true;controller.loadViewIfNeeded()
        let host=FPRightInsetView();controller.view.subviews.forEach { host.addSubview($0) };controller.view=host
        let cases:[(CGSize,UIEdgeInsets,[CGRect])]=[
            (CGSize(width:320,height:640),UIEdgeInsets(top:32,left:0,bottom:24,right:0),[]),
            (CGSize(width:874,height:402),UIEdgeInsets(top:0,left:62,bottom:21,right:62),[]),
            (CGSize(width:951,height:669),UIEdgeInsets(top:0,left:0,bottom:34,right:84),[CGRect(x:455.5,y:0,width:40,height:669),CGRect(x:867,y:0,width:84,height:120)]),
            (CGSize(width:669,height:951),UIEdgeInsets(top:82,left:0,bottom:34,right:0),[CGRect(x:0,y:455.5,width:669,height:40),CGRect(x:535,y:0,width:134,height:82)])]
        for (size,insets,regions) in cases {
            host.frame=CGRect(origin:.zero,size:size);host.testInsets=insets;controller.exclusions=regions
            controller.viewDidLayoutSubviews();host.layoutIfNeeded()
            let safe=host.bounds.inset(by:insets),widgets=[controller.pull as UIView,controller.toolbar,controller.scoreCard,controller.status].filter{!$0.isHidden}
            for v in widgets { XCTAssertTrue(safe.contains(v.frame));XCTAssertGreaterThan(v.frame.width,0);XCTAssertFalse(regions.contains{$0.intersects(v.frame)}) }
            for i in 0..<widgets.count { for j in (i+1)..<widgets.count { XCTAssertFalse(widgets[i].frame.intersects(widgets[j].frame)) } }
        }
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.3));controller.refresh();controller.refreshVisibility(immediate:true)
        let expected=FPMotion.hudAlpha(for:session.phase)
        XCTAssertEqual(controller.toolbar.alpha,expected)
        XCTAssertEqual(controller.pull.alpha,expected == 0 ? FPMotion.aimingPullAlpha:1,accuracy:0.00001)
        session.cancel();controller.refresh();controller.refreshVisibility(immediate:true)
        XCTAssertEqual(controller.pull.alpha,1);XCTAssertEqual(controller.toolbar.alpha,1)
    }
    @MainActor func testHUDSurfaceLeavesEmptyCourseSpaceInteractive() throws {
        let controller=FPControlsController(session:try FPDemoSession(metricsStore:nil))
        controller.loadViewIfNeeded();controller.view.frame=CGRect(x:0,y:0,width:375,height:812);controller.viewDidLayoutSubviews();controller.view.layoutIfNeeded()
        XCTAssertNil(controller.view.hitTest(CGPoint(x:187,y:300),with:nil))
        XCTAssertTrue(controller.view.hitTest(CGPoint(x:controller.pull.frame.midX,y:controller.pull.frame.midY),with:nil) === controller.pull)
    }
    @MainActor func testWinRequiresTapAndContinuesOnlyOnce() throws {
        let session=try FPDemoSession(metricsStore:nil)
        session.continueAfterWin();XCTAssertEqual(session.levelIndex,0)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        session.continueAfterWin();XCTAssertEqual(session.levelIndex,0)
        for _ in 0..<1000 { session.advance(1.0/120) }
        XCTAssertEqual(session.phase,.success);XCTAssertFalse(session.canAim)
        session.aim(nil);session.release(nil)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2));session.release(session.preview)
        XCTAssertEqual(session.phase,.success);XCTAssertEqual(session.levelIndex,0);XCTAssertEqual(session.strokes,1)
        session.continueAfterWin();session.continueAfterWin()
        XCTAssertEqual(session.levelIndex,1);XCTAssertEqual(session.phase,.ready);XCTAssertEqual(session.strokes,0)
        XCTAssertNil(session.lastLaunch);XCTAssertNil(session.preview);XCTAssertEqual(session.boostSeconds,0)
    }
    @MainActor func testNewCourseIsComplete() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let course=FPCourseView(session:session)
        course.frame=CGRect(x:0,y:0,width:375,height:500)
        course.refresh()
        XCTAssertNil(course.layer.mask)
        session.loadLevel(1);course.refresh()
        XCTAssertNil(course.layer.mask)
        XCTAssertTrue(course.layer.sublayers?.isEmpty ?? true)
    }
    @MainActor func testThemeFontScalesOnlyOnce() {
        for style in [UIFont.TextStyle.body,.headline,.caption1,.largeTitle] {
            XCTAssertEqual(FPTheme.font(style).pointSize,UIFont.preferredFont(forTextStyle:style).pointSize,accuracy:0.01)
        }
    }
    @MainActor func testHoleFeedbackStopsWithoutChangingTheGame() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let course=FPCourseView(session:session)
        course.frame=CGRect(x:0,y:0,width:375,height:500);course.refresh()
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<1000 {
            session.advance(1.0/120);course.refresh()
            if session.phase == .sinking { break }
        }
        XCTAssertEqual(session.phase,.sinking)
        XCTAssertEqual(course.layer.animation(forKey:"hole-nudge") == nil,FPMotion.reduced)
        XCTAssertEqual(session.events.filter { $0["event"] == "hole-capture" }.count,1)
        let position=session.world.position
        course.stopLargeMotion()
        XCTAssertNil(course.layer.animation(forKey:"hole-nudge"))
        XCTAssertEqual(session.world.position,position);XCTAssertEqual(session.strokes,1)
    }
    func testImmersiveProjectionIsUniformAndInputIsInverse() {
        for across in [false,true] {
            let p=FPCourseProjection(area:CGRect(x:12,y:12,width:927,height:645),across:across)
            let world=CGPoint(x:0.5,y:1.12),screen=p.point(world),back=p.worldPoint(screen)
            XCTAssertEqual(back.x,world.x,accuracy:0.000001);XCTAssertEqual(back.y,world.y,accuracy:0.000001)
            let a=p.point(.zero),x=p.point(CGPoint(x:1,y:0)),y=p.point(CGPoint(x:0,y:1))
            XCTAssertEqual(hypot(x.x-a.x,x.y-a.y),hypot(y.x-a.x,y.y-a.y),accuracy:0.000001)
            let direction=CGVector(dx:0.3,dy:-0.7)
            XCTAssertEqual(p.worldVector(p.vector(direction)),direction)
        }
    }
    func testBridgePassageAndSolidBanksFreezeDuringShot() throws {
        let p=FPCourseProjection(area:CGRect(x:0,y:0,width:1400,height:1000),across:true)
        let seam=CGRect(x:680,y:0,width:40,height:1000),banks=p.banks(for:seam)
        XCTAssertEqual(banks.count,2)
        var through=FPPhysicsWorld(level:try FPLevel.loadAll()[0],tuning:try FPTuning.load().physics)
        through.updateReservedBanks(banks)
        let shot=FPLaunch(shot:FPShot(direction:CGVector(dx:0,dy:-1),power:0.55),maximumSpeed:1.55)
        through.launch(shot);through.updateReservedBanks([])
        XCTAssertEqual(through.divisionBanks,banks)
        for _ in 0..<800 { _=through.step(1.0/120) }
        XCTAssertTrue(through.captured)
        var bounce=FPPhysicsWorld(level:try FPLevel.loadAll()[0],tuning:try FPTuning.load().physics)
        bounce.updateReservedBanks(banks)
        bounce.stage(at:CGPoint(x:0.2,y:0.82),velocity:CGVector(dx:0,dy:-0.7))
        var collision=false
        for _ in 0..<30 { collision = bounce.step(1.0/120).contains(.collision("division-0")) || collision }
        XCTAssertTrue(collision);XCTAssertGreaterThan(bounce.velocity.dy,0)
        let data=try JSONEncoder().encode(bounce)
        let restored=try JSONDecoder().decode(FPPhysicsWorld.self,from:data)
        XCTAssertEqual(restored.divisionBanks,banks);try restored.validateRestoration()
        for _ in 0..<1200 { _=bounce.step(1.0/120) }
        bounce.updateReservedBanks([]);try bounce.validateRestoration()
    }
    func testCaptureDistanceAndSpeedThresholdEdges() throws {
        let tuning=try FPTuning.load(),level=try FPLevel.loadAll()[0]
        for distance in [0.02,0.07] {
            let limit=tuning.physics.captureLimit(distance:distance)
            var slow=FPPhysicsWorld(level:level,tuning:tuning.physics),fast=slow
            let point=CGPoint(x:level.hole.x+distance,y:level.hole.y)
            slow.stage(at:point,velocity:CGVector(dx:0,dy:limit*0.8));fast.stage(at:point,velocity:CGVector(dx:0,dy:limit*1.2))
            XCTAssertTrue(slow.step(0.0001).contains(.captured));XCTAssertFalse(fast.step(0.0001).contains(.captured))
        }
        var outside=FPPhysicsWorld(level:level,tuning:tuning.physics)
        outside.stage(at:CGPoint(x:level.hole.x+tuning.physics.captureRadius+0.005,y:level.hole.y),velocity:CGVector(dx:0,dy:0.01))
        XCTAssertFalse(outside.step(0.0001).contains(.captured))
    }

}

@MainActor private final class FPRightInsetView:UIView {
    var testInsets=UIEdgeInsets.zero
    override var safeAreaInsets:UIEdgeInsets { testInsets }
}

extension FPTuningTests {
    @MainActor func testSafeAreaOnlyChangesCancelAimButPreserveLaunchedShot() throws {
        let session=try FPDemoSession(metricsStore:nil),root=FPAdaptiveController(session:session)
        root.loadViewIfNeeded()
        let host=FPRightInsetView(frame:CGRect(x:0,y:0,width:800,height:600))
        root.view.subviews.forEach { host.addSubview($0) };root.view=host
        root.viewDidLayoutSubviews()
        let shot=FPShot(direction:CGVector(dx:0,dy:-1),power:0.2)
        session.aim(shot);XCTAssertEqual(session.phase,.charging)
        host.testInsets=UIEdgeInsets(top:10,left:84,bottom:34,right:0)
        root.viewDidLayoutSubviews()
        XCTAssertEqual(session.phase,.ready);XCTAssertNil(session.preview);XCTAssertEqual(session.strokes,0)
        session.aim(shot);session.release(shot);session.advance(0.02)
        let point=session.world.position,velocity=session.world.velocity,id=session.lastLaunch?.id
        host.testInsets=UIEdgeInsets(top:10,left:0,bottom:34,right:84)
        root.viewDidLayoutSubviews()
        XCTAssertEqual(session.world.position,point);XCTAssertEqual(session.world.velocity,velocity)
        XCTAssertEqual(session.lastLaunch?.id,id);XCTAssertEqual(session.strokes,1)
    }
}
