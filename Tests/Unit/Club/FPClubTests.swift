import XCTest
import UIKit
import Security
@testable import FoldPutt

final class FPClubTests:XCTestCase {
    @MainActor private func hole(_ session:FPDemoSession) {
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));session.release(session.preview)
        for _ in 0..<1500 { session.advance(1.0/120);if session.phase == .success { break } }
    }
    @MainActor func testRealWinGrantsOneSeedAndReplayCannotRepeatReward() throws {
        let s=try FPDemoSession(metricsStore:nil);hole(s)
        XCTAssertEqual(s.phase,.success);XCTAssertEqual(s.club.state.seeds,1)
        XCTAssertTrue(s.club.state.quotes.contains(.shot));XCTAssertTrue(s.club.state.quotes.contains(.win))
        for _ in 0..<1500 { s.advance(1.0/120) };s.finishReplay();s.finishReplay()
        XCTAssertEqual(s.club.state.seeds,1)
        s.reset();XCTAssertNil(s.clubReward);XCTAssertEqual(s.club.state.seeds,1)
        hole(s);XCTAssertEqual(s.club.state.seeds,2)
    }
    @MainActor func testRestoringPreWinCheckpointDoesNotDoubleAwardAcrossInstances() throws {
        let name="FoldPutt.ClubTests."+UUID().uuidString,defaults=try XCTUnwrap(UserDefaults(suiteName:name))
        defer { defaults.removePersistentDomain(forName:name) }
        let s=try FPDemoSession(metricsStore:defaults)
        s.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));s.release(s.preview)
        for _ in 0..<1500 { s.advance(1.0/120);if s.phase == .sinking { break } }
        XCTAssertEqual(s.phase,.sinking);let checkpoint=try s.restorationActivity()
        for _ in 0..<60 { s.advance(1.0/120) };XCTAssertEqual(s.club.state.seeds,1)
        let restored=try FPDemoSession(metricsStore:defaults);try restored.restore(checkpoint)
        XCTAssertEqual(restored.roundID,s.roundID)
        for _ in 0..<60 { restored.advance(1.0/120) }
        XCTAssertEqual(restored.phase,.success);XCTAssertEqual(restored.club.state.seeds,1)
        XCTAssertEqual(restored.clubReward?.seedGranted,false)
        let after=try restored.restorationActivity(),again=try FPDemoSession(metricsStore:defaults)
        try again.restore(after);again.advance(20);XCTAssertEqual(again.club.state.seeds,1)
    }
    @MainActor func testGardenConservesSeedsAndPersistsAcrossScenes() throws {
        let name="FoldPutt.GardenTests."+UUID().uuidString,defaults=try XCTUnwrap(UserDefaults(suiteName:name))
        defer { defaults.removePersistentDomain(forName:name) }
        let a=FPClubProgressStore(defaults:defaults),b=FPClubProgressStore(defaults:defaults),level=try FPLevel.loadAll()[0]
        XCTAssertFalse(a.plant(.daisy,at:0));XCTAssertFalse(a.uproot(at:0))
        for _ in 0..<3 { _=a.complete(round:UUID(),level:level,strokes:2,collisions:0) }
        XCTAssertTrue(b.plant(.daisy,at:0));XCTAssertTrue(a.plant(.tulip,at:1));XCTAssertTrue(b.plant(.bluebell,at:2))
        XCTAssertFalse(a.plant(.daisy,at:2));XCTAssertFalse(a.plant(.daisy,at:3));XCTAssertFalse(a.plant(.daisy,at:99))
        XCTAssertTrue(a.uproot(at:1));XCTAssertFalse(a.uproot(at:1));XCTAssertTrue(b.plant(.tulip,at:8))
        let c=FPClubProgressStore(defaults:defaults)
        XCTAssertEqual(c.state.seeds,0);XCTAssertEqual(c.state.plantedCount,3)
        XCTAssertEqual(c.state.garden[0],.daisy);XCTAssertEqual(c.state.garden[8],.tulip)
    }
    @MainActor func testMasteryRequiresBounceAndParAndBestNeverGetsWorse() throws {
        let store=FPClubProgressStore(defaults:nil),level=try FPLevel.loadAll()[3],id=UUID()
        _=store.complete(round:id,level:level,strokes:1,collisions:0)
        XCTAssertFalse(store.state.mastery.contains(level.id))
        _=store.complete(round:UUID(),level:level,strokes:level.par+1,collisions:3)
        XCTAssertFalse(store.state.mastery.contains(level.id))
        let reward=store.complete(round:UUID(),level:level,strokes:level.par,collisions:1)
        XCTAssertTrue(reward.newMastery);XCTAssertEqual(store.state.best[level.id],1)
        _=store.complete(round:id,level:level,strokes:1,collisions:1)
        XCTAssertEqual(store.state.seeds,3);XCTAssertEqual(store.state.mastery.count,1)
    }
    @MainActor func testCollectionPausesRollingEvenWhenSceneResumes() throws {
        let s=try FPDemoSession(metricsStore:nil)
        s.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2));s.release(s.preview);s.advance(0.02)
        let position=s.world.position,strokes=s.strokes
        s.beginClub();s.resume();s.advance(10)
        XCTAssertFalse(s.canAim);XCTAssertEqual(s.world.position,position)
        s.setClubVoice(.quiet);XCTAssertEqual(s.ballTalkText,"");XCTAssertEqual(s.strokes,strokes)
        s.finishClub();s.advance(0.02);XCTAssertNotEqual(s.world.position,position)
        s.beginClub();s.loadLevel(3);s.resume();s.advance(200)
        XCTAssertEqual(s.elapsed,0);XCTAssertEqual(s.phase,.ready)
        s.finishClub();XCTAssertTrue(s.canAim)
    }
    @MainActor func testQuotesAndVoiceArePersistentWithoutChangingPhysics() throws {
        let s=try FPDemoSession(metricsStore:nil)
        s.setClubVoice(.silly)
        s.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.1));s.release(s.preview)
        XCTAssertEqual(s.ballTalkText,FPClubQuote.shot.text(.silly))
        for _ in 0..<1400 { s.advance(1.0/120);if s.canAim { break } }
        XCTAssertTrue(s.club.state.quotes.contains(.stopped))
        let position=s.world.position,strokes=s.strokes
        s.setClubVoice(.cozy);XCTAssertEqual(s.ballTalkText,FPClubQuote.stopped.text(.cozy))
        s.setClubVoice(.quiet);XCTAssertEqual(s.ballTalkText,"");XCTAssertEqual(s.world.position,position);XCTAssertEqual(s.strokes,strokes)
        for quote in FPClubQuote.allCases { s.club.discover(quote);s.club.discover(quote);XCTAssertFalse(quote.text(.silly).isEmpty);XCTAssertFalse(quote.text(.cozy).isEmpty);XCTAssertEqual(quote.text(.quiet),"") }
        XCTAssertEqual(s.club.state.quotes.count,6)
    }
    @MainActor func testBothModesShareUnlockedMapsAndFamilyContinuation() throws {
        let s=try FPDemoSession(metricsStore:nil)
        for mode in FPGameMode.allCases {
            s.setPresentation(mode:mode);s.loadLevel(2);s.nextLevel();XCTAssertEqual(s.level.id,"01")
            s.loadLevel(8);s.nextLevel();XCTAssertEqual(s.level.id,"P01")
            XCTAssertEqual(s.levelActions.count,9)
        }
    }
    // Search only independent world copies; accepted shots are then played through the real session.
    // This validates each authored map's standard-par bounce goal, not merely its JSON structure.
    @MainActor func testAllSixPuzzlesHavePlayableMasteryRoutes() throws {
        let s=try FPDemoSession(metricsStore:nil)
        var routes:[[String:Any]]=[]
        for index in s.levels.indices where s.levels[index].isPuzzle {
            s.loadLevel(index);var shots:[[String:Double]]=[]
            for _ in 0..<s.level.par {
                guard s.phase != .success else { break }
                let shot=try XCTUnwrap(Self.findShot(world:s.world,collisions:s.collisions),s.level.id)
                shots.append(["dx":shot.direction.dx,"dy":shot.direction.dy,"power":shot.power])
                s.aim(shot);s.release(s.preview)
                for _ in 0..<1600 { s.advance(1.0/120);if s.canAim || s.phase == .success { break } }
            }
            XCTAssertEqual(s.phase,.success,s.level.id+" not solved")
            XCTAssertTrue(s.club.state.mastery.contains(s.level.id),s.level.id+" no mastery")
            routes.append(["id":s.level.id,"strokes":s.strokes,"collisions":s.collisions,"shots":shots])
        }
        let data=try JSONSerialization.data(withJSONObject:routes,options:[.prettyPrinted,.sortedKeys])
        let attachment=XCTAttachment(data:data,uniformTypeIdentifier:"public.json");attachment.name="native-puzzle-routes";attachment.lifetime = .keepAlways;add(attachment)
    }
    private static func findShot(world:FPPhysicsWorld,collisions:Int)->FPShot? {
        let cell:CGFloat=0.05,width=21,height=29
        func key(_ p:CGPoint)->Int { Int(round(p.y/cell))*width+Int(round(p.x/cell)) }
        let goal=world.level.hole.cg
        var distance=[key(goal):CGFloat(0)],queue=[goal]
        var cursor=0
        while cursor<queue.count {
            let p=queue[cursor];cursor+=1
            for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)] {
                let x=Int(round(p.x/cell))+dx,y=Int(round(p.y/cell))+dy
                let next=CGPoint(x:CGFloat(x)*cell,y:CGFloat(y)*cell),k=y*width+x
                if x<0 || x>=width || y<0 || y>=height || distance[k] != nil || !world.legalRest(next) { continue }
                distance[k]=(distance[key(p)] ?? 0)+hypot(CGFloat(dx),CGFloat(dy))*cell;queue.append(next)
            }
        }
        var chosen:FPShot?,best=CGFloat.greatestFiniteMagnitude
        let direct=atan2(goal.y-world.position.y,goal.x-world.position.x)
        let angles=[direct]+(0..<72).map { CGFloat($0) * .pi/36 }
        for angle in angles { for band in 2...20 {
            let shot=FPShot(direction:CGVector(dx:cos(angle),dy:sin(angle)),power:CGFloat(band)/20)
            var copy=world,bounces=collisions,water=false
            copy.launch(FPLaunch(shot:shot,maximumSpeed:world.tuning.maximumSpeed))
            for _ in 0..<900 {
                for event in copy.step(1.0/120) { if case .collision = event { bounces+=1 };if event == .outOfBounds { water=true } }
                if !copy.moving { break }
            }
            if water { continue }
            if copy.captured { if bounces>0 { return shot };continue }
            let score=(distance[key(copy.position)] ?? 100)+hypot(copy.position.x-goal.x,copy.position.y-goal.y)*0.12+(bounces==0 ? 0.12:0)
            if score<best { best=score;chosen=shot }
        } }
        return chosen
    }
}

extension FPClubTests {
    @MainActor func testCollectionPreservesReadingAnchorAcrossReflow() throws {
        let session=try FPDemoSession(metricsStore:nil),club=FPClubController(session:session,section:.puzzles)
        let window=UIWindow(frame:CGRect(x:0,y:0,width:800,height:500))
        window.rootViewController=club;window.makeKeyAndVisible()
        defer { window.isHidden=true;window.rootViewController=nil }
        func layout() { club.view.setNeedsLayout();club.view.layoutIfNeeded() }
        func find(_ id:String,in view:UIView)->UIView? {
            if view.accessibilityIdentifier==id { return view }
            for child in view.subviews { if let result=find(id,in:child) { return result } }
            return nil
        }
        club.view.frame=window.bounds;layout()
        let scroll=try XCTUnwrap(find("clubScroll",in:club.view) as? UIScrollView)
        let card=try XCTUnwrap(find("puzzle-P04",in:club.view))
        scroll.setContentOffset(CGPoint(x:0,y:card.convert(card.bounds,to:scroll).minY+10),animated:false)
        club.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        window.frame=CGRect(x:0,y:0,width:420,height:800);club.view.frame=window.bounds;layout()
        let resized=try XCTUnwrap(find("puzzle-P04",in:club.view))
        XCTAssertTrue(resized.convert(resized.bounds,to:scroll).intersects(scroll.bounds),"Keep the same puzzle in view when text and window size change")
        XCTAssertGreaterThan(scroll.contentOffset.y,0)
        XCTAssertEqual(session.strokes,0);XCTAssertEqual(session.level.id,"01")
    }
}

@MainActor private final class FPTestProgressVault: FPProgressVault {
    var data: Data?
    var failRead = false, failWrite = false
    func read() throws -> Data? { if failRead { throw NSError(domain: "Test.Locked", code: 1) }; return data }
    func write(_ data: Data) throws { if failWrite { throw NSError(domain: "Test.Full", code: 2) }; self.data = data }
}

extension FPClubTests {
    @MainActor func testVaultMigrationKeepsPointsReceiptsAndSurvivesDefaultsRemoval() throws {
        let name = "FoldPutt.Vault." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let level = try FPLevel.loadAll()[0], round = UUID()
        let old = FPClubProgressStore(defaults: defaults)
        _ = old.complete(round: round, level: level, strokes: 1, collisions: 0)
        let vault = FPTestProgressVault()
        let migrated = FPClubProgressStore(defaults: defaults, vault: vault)
        XCTAssertEqual(migrated.state.points, 3); XCTAssertNotNil(vault.data)
        defaults.removePersistentDomain(forName: name)
        let reinstalled = FPClubProgressStore(defaults: defaults, vault: vault)
        XCTAssertEqual(reinstalled.state.points, 3)
        XCTAssertFalse(reinstalled.complete(round: round, level: level, strokes: 1, collisions: 0).seedGranted)
        XCTAssertEqual(reinstalled.state.points, 3)
        XCTAssertTrue(reinstalled.plant(.daisy, at: 0))
        XCTAssertEqual(FPClubProgressStore(defaults: defaults, vault: vault).state.garden[0], .daisy)
        XCTAssertEqual(reinstalled.state.points, 3)
    }
    @MainActor func testVaultFailuresNeverOverwriteOrAwardUnsavedPoints() throws {
        let vault = FPTestProgressVault(), level = try FPLevel.loadAll()[0], round = UUID()
        let store = FPClubProgressStore(defaults: nil, vault: vault)
        vault.failWrite = true
        XCTAssertFalse(store.complete(round: round, level: level, strokes: 1, collisions: 0).seedGranted)
        XCTAssertEqual(store.state.points, 0); XCTAssertFalse(store.state.completedRounds.contains(round))
        XCTAssertNotNil(store.persistenceError)
        vault.failWrite = false
        XCTAssertTrue(store.complete(round: round, level: level, strokes: 1, collisions: 0).seedGranted)
        let saved = vault.data
        vault.failRead = true
        XCTAssertFalse(store.complete(round: UUID(), level: level, strokes: 1, collisions: 0).seedGranted)
        XCTAssertEqual(vault.data, saved); XCTAssertEqual(store.state.points, 3)
    }
}

extension FPClubTests {
    @MainActor func testSystemKeychainRoundTripInSeparateStoreInstances() throws {
        let account = "test." + UUID().uuidString
        let vault = FPKeychainProgressVault(account: account)
        defer {
            SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.mavericklab.foldputt.progress",
                kSecAttrAccount as String: account] as CFDictionary)
        }
        XCTAssertNil(try vault.read())
        let first = FPClubProgressStore(defaults: nil, vault: vault)
        let id = UUID(), level = try FPLevel.loadAll()[0]
        XCTAssertTrue(first.complete(round: id, level: level, strokes: 1, collisions: 0).seedGranted)
        XCTAssertNil(first.persistenceError)
        let second = FPClubProgressStore(defaults: nil, vault: FPKeychainProgressVault(account: account))
        XCTAssertEqual(second.state.points, 3)
        XCTAssertFalse(second.complete(round: id, level: level, strokes: 1, collisions: 0).seedGranted)
        XCTAssertTrue(second.plant(.tulip, at: 1))
        XCTAssertEqual(FPClubProgressStore(defaults: nil, vault: vault).state.garden[1], .tulip)
    }
}
