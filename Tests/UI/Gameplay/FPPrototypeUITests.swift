import XCTest

final class FPPrototypeUITests:XCTestCase {
    @MainActor func testMapReplayAndRollingFeedbackBothModes() {
        for chibi in [false,true] {
            let app=XCUIApplication();app.launchArguments=["--ui-testing","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]+(chibi ? ["--q-mode"]:[]);app.launch()
            let root=app.descendants(matching:.any)["gameArrangement"]
            XCTAssertTrue(root.waitForExistence(timeout:10))
            let prefix=chibi ? "chibi":"classic"
            for (index,name) in ["青草练习","运河回响","沙地余韵"].enumerated() {
                app.buttons["选择地图"].tap()
                let item=app.buttons.matching(NSPredicate(format:"label CONTAINS %@",name)).firstMatch
                XCTAssertTrue(item.waitForExistence(timeout:3),app.debugDescription)
                if index == 0 { capture(app,name:prefix+"-map-picker") }
                item.tap()
                expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","level=0\(index+1)","strokes=0"),evaluatedWith:root);waitForExpectations(timeout:4)
                capture(app,name:prefix+"-map-\(index+1)")
            }
            app.buttons["选择地图"].tap();app.buttons.matching(NSPredicate(format:"label CONTAINS %@","青草练习")).firstMatch.tap()
            let pull=app.descendants(matching:.any)["pullControl"]
            qDrag(app,power:0.2)
            expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","phase=rolling","pullEnabled=false"),evaluatedWith:root);waitForExpectations(timeout:3)
            capture(app,name:prefix+"-rolling-disabled")
            expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","phase=ready","pullEnabled=true"),evaluatedWith:root);waitForExpectations(timeout:10)
            capture(app,name:prefix+"-stopped-ready")
            XCTAssertTrue(pull.isHittable)
            // Selecting the same map must reset the completed shot as well.
            app.buttons["选择地图"].tap();app.buttons.matching(NSPredicate(format:"label CONTAINS %@","青草练习")).firstMatch.tap()
            expectation(for:NSPredicate(format:"value CONTAINS %@","strokes=0"),evaluatedWith:root);waitForExpectations(timeout:4)
            qDrag(app,power:0.55)
            let replay=app.buttons["skipReplay"]
            XCTAssertTrue(replay.waitForExistence(timeout:8),app.debugDescription)
            XCTAssertFalse(app.buttons["continueAfterWin"].exists)
            capture(app,name:prefix+"-hole-in-one-replay")
            XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:15))
            capture(app,name:prefix+"-win-after-replay")
            app.buttons["continueAfterWin"].tap()
            expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","level=02","strokes=0"),evaluatedWith:root);waitForExpectations(timeout:4)
            app.terminate()
        }
    }
    @MainActor func testAimingBoundaryCaptureBothModes() {
        for chibi in [false,true] {
            let app=XCUIApplication();app.launchArguments=["--ui-testing","--capture","aiming","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]+(chibi ? ["--q-mode"]:[]);app.launch()
            let root=app.descendants(matching:.any)["gameArrangement"]
            XCTAssertTrue(root.waitForExistence(timeout:10))
            expectation(for:NSPredicate(format:"value CONTAINS %@","phase=charging"),evaluatedWith:root);waitForExpectations(timeout:6)
            capture(app,name:chibi ? "chibi-aiming-boundary-fixture":"classic-aiming-boundary-fixture")
            app.terminate()
        }
    }
    @MainActor func testReplayLargeTextLandscapeAndReservedRegionFixtures() {
        for landscape in [false,true] {
            XCUIDevice.shared.orientation=landscape ? .landscapeRight:.portrait
            let app=XCUIApplication();app.launchArguments=["--ui-testing","--q-mode","--capture","hole-success","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]+(landscape ? []:["--simulate-division"]);app.launch()
            let skip=app.buttons["skipReplay"]
            XCTAssertTrue(skip.waitForExistence(timeout:10));XCTAssertTrue(skip.isHittable)
            capture(app,name:landscape ? "replay-large-landscape-fixture":"replay-large-reserved-fixture")
            skip.tap();XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:3))
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }
    @MainActor func testFullscreenClassicAndChibiReview() {
        for chibi in [false,true] {
            let app=XCUIApplication()
            app.launchArguments=["--ui-testing","--capture","tee-off","--level","2","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]+(chibi ? ["--q-mode"]:[])
            app.launch()
            let root=app.descendants(matching:.any)["gameArrangement"]
            XCTAssertTrue(root.waitForExistence(timeout:10))
            expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","immersive=true","level=03"),evaluatedWith:root);waitForExpectations(timeout:8)
            XCTAssertTrue(app.descendants(matching:.any)["pullControl"].isHittable)
            XCTAssertTrue(app.buttons["courseOptions"].isHittable)
            capture(app,name:chibi ? "fullscreen-chibi-review":"fullscreen-classic-review")
            app.terminate()
        }
    }
    @MainActor func testQFeedbackCaptureFixtures() {
        for scenario in ["strong-pull","swing","near-miss","sand","canal-collision"] {
            let app=XCUIApplication();app.launchArguments=["--ui-testing","--q-mode","--capture",scenario,"-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"];app.launch()
            let root=app.descendants(matching:.any)["gameArrangement"]
            XCTAssertTrue(root.waitForExistence(timeout:10))
            let cue=scenario == "strong-pull" ? "phase=charging":scenario == "swing" ? "cue=putt":scenario == "near-miss" ? "cue=nearMiss":scenario == "sand" ? "cue=sand":"cue=collision"
            expectation(for:NSPredicate(format:"value CONTAINS %@",cue),evaluatedWith:root);waitForExpectations(timeout:10)
            capture(app,name:"q-fixture-"+scenario)
            app.terminate()
        }
    }
    @MainActor func testQModePickerRealPuttAndNextLevel() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--show-mode-picker","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"];app.launch()
        let classic=app.buttons["chooseMode-classic"],chibi=app.buttons["chooseMode-chibi"]
        XCTAssertTrue(classic.waitForExistence(timeout:10));XCTAssertTrue(chibi.exists)
        capture(app,name:"q-mode-picker")
        classic.tap()
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout:5));XCTAssertTrue(String(describing:root.value ?? "").contains("gameMode=classic"))
        capture(app,name:"ordinary-mode-preserved")
        app.buttons["courseOptions"].tap();tapOption("切换游戏模式",in:app)
        XCTAssertTrue(chibi.waitForExistence(timeout:5))
        if !chibi.isHittable { app.scrollViews.firstMatch.swipeUp() }
        chibi.tap()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:5));XCTAssertTrue(pull.isHittable)
        XCTAssertTrue(String(describing:root.value ?? "").contains("gameMode=chibi"))
        capture(app,name:"q-mode-ready")
        qDrag(app,power:0.55)
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:12),app.debugDescription)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        XCTAssertTrue(app.staticTexts["WIN! · 到家啦。"].exists)
        Thread.sleep(forTimeInterval:0.9) // Capture the completed 0.4s card / 0.8s celebration.
        capture(app,name:"q-mode-real-win")
        app.buttons["continueAfterWin"].tap()
        expectation(for:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","level=02","gameMode=chibi"),evaluatedWith:root)
        waitForExpectations(timeout:5)
        XCTAssertTrue(pull.isHittable);capture(app,name:"q-mode-next-level")
    }
    @MainActor func testQAppearanceMenuPreservesShot() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--q-mode","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"];app.launch()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:10));qDrag(app,power:0.2)
        let root=app.descendants(matching:.any)["gameArrangement"]
        expectation(for:NSPredicate(format:"value CONTAINS %@","phase=ready"),evaluatedWith:root);waitForExpectations(timeout:10)
        let launch=String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") }
        app.buttons["courseOptions"].tap()
        option("小球心情 · 软乎乎",in:app).tap();tapOption("有点皮",in:app)
        expectation(for:NSPredicate(format:"value CONTAINS %@","chibiMood=silly"),evaluatedWith:root);waitForExpectations(timeout:3)
        app.buttons["courseOptions"].tap()
        option("小球外观 · 糯米团子",in:app).tap();tapOption("桃桃丸子",in:app)
        expectation(for:NSPredicate(format:"value CONTAINS %@","ballSkin=peach"),evaluatedWith:root);waitForExpectations(timeout:3)
        XCTAssertEqual(String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") },launch)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        capture(app,name:"q-mode-peach-silly")
        app.buttons["courseOptions"].tap();tapOption("切换游戏模式",in:app)
        let classic=app.buttons["chooseMode-classic"];XCTAssertTrue(classic.waitForExistence(timeout:5));classic.tap()
        XCTAssertTrue(pull.waitForExistence(timeout:5));XCTAssertTrue(pull.isHittable)
        XCTAssertEqual(String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") },launch)
        XCTAssertTrue(String(describing:root.value ?? "").contains("gameMode=classic"))
    }
    @MainActor func testQPickerWithAccessibilityText() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--show-mode-picker","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        let classic=app.buttons["chooseMode-classic"],chibi=app.buttons["chooseMode-chibi"]
        XCTAssertTrue(classic.waitForExistence(timeout:10))
        for _ in 0..<6 { if chibi.isHittable { break };app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(chibi.isHittable);capture(app,name:"q-mode-large-text-picker");chibi.tap()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:5));XCTAssertTrue(pull.isHittable)
        XCTAssertTrue(app.buttons["courseOptions"].isHittable)
        capture(app,name:"q-mode-large-text")
    }
    @MainActor private func qDrag(_ app:XCUIApplication,power:Double) {
        let pull=app.descendants(matching:.any)["pullControl"]
        let config=String(describing:pull.value ?? "").split(separator:";").reduce(into:[String:Double]()) { dict,item in
            let pair=item.split(separator:"=");if pair.count==2 { dict[String(pair[0])]=Double(pair[1]) }
        }
        let dead=config["dead"] ?? 6,maximum=config["max"] ?? 47,exponent=config["exp"] ?? 1.45
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,dead+(maximum-dead)*pow(power,1/exponent))))
    }
    @MainActor private func capture(_ app:XCUIApplication,name:String) {
        let image=XCTAttachment(screenshot:XCUIScreen.main.screenshot());image.name=name;image.lifetime = .keepAlways;add(image)
        let game=app.descendants(matching:.any)["gameArrangement"]
        let source=game.exists ? game:app.descendants(matching:.any)["modeSelection"]
        let proof=XCTAttachment(string:String(describing:source.value ?? ""))
        proof.name=name+"-layout";proof.lifetime = .keepAlways;add(proof)
    }
    @MainActor private func backswing(_ app:XCUIApplication,_ distance:CGFloat)->CGVector {
        let across=String(describing:app.descendants(matching:.any)["gameArrangement"].value ?? "").contains("across=true")
        return across ? CGVector(dx:-distance,dy:0):CGVector(dx:0,dy:distance)
    }
    @MainActor func testImmersiveCanvasKeepsInputAndProgress() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--immersive"];app.launch()
        let pull=app.descendants(matching:.any)["pullControl"],root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(pull.waitForExistence(timeout:10));XCTAssertTrue(pull.isHittable)
        XCTAssertTrue(String(describing:root.value ?? "").contains("immersive=true"))
        XCTAssertTrue(String(describing:root.value ?? "").contains("pullAlpha=1.0"))
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,23)))
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5))
        XCTAssertTrue(String(describing:root.value ?? "").contains("courseVisible=true"))
        app.buttons["courseOptions"].tap();tapOption("掌机模式",in:app)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        let capture=XCTAttachment(screenshot:app.screenshot());capture.name="immersive-return-same-shot";capture.lifetime = .keepAlways;add(capture)
    }
    @MainActor func testAimingHUDIsTransparent() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--capture","aiming"];app.launch()
        let root=app.descendants(matching:.any)["gameArrangement"]
        let aiming=NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","pullAlpha=0.14","hudAlpha=0.0")
        expectation(for:aiming,evaluatedWith:root);waitForExpectations(timeout:10)
        capture(app,name:"perimeter-aiming")
    }
    @MainActor func testSceneRelaunchPreservesShotAndVisibleCourse() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--restore-scene","--fresh-scene"];app.launch()
        let reminder=XCUIApplication(bundleIdentifier:"com.apple.springboard").alerts.firstMatch
        if reminder.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Apple")).firstMatch.exists,reminder.buttons["以后"].exists { reminder.buttons["以后"].tap() }
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:10));XCTAssertTrue(pull.isHittable)
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,23)))
        guard app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5) else { XCTFail("Initial real pull did not launch");return }
        let root=app.descendants(matching:.any)["gameArrangement"]
        func value()->String { String(describing:root.value ?? "") }
        let launch=value().split(separator:";").first { $0.hasPrefix("launch=") }
        guard let launch,launch != "launch=none" else { XCTFail("No valid shot ID before restoration");return }
        // On Duo the generic Home button can target the other display. Activate a second app instead.
        let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences");settings.launch()
        guard app.wait(for:.runningBackground,timeout:10) else { XCTFail("Game did not enter the background");return }
        app.terminate()
        app.launchArguments=["--ui-testing","--restore-scene"];app.launch()
        let systemAlert=XCUIApplication(bundleIdentifier:"com.apple.springboard").alerts.firstMatch
        if systemAlert.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Apple")).firstMatch.exists,systemAlert.buttons["以后"].exists { systemAlert.buttons["以后"].tap() }
        XCTAssertTrue(pull.waitForExistence(timeout:10))
        let reachable=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:pull)
        XCTAssertEqual(XCTWaiter.wait(for:[reachable],timeout:10),.completed)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        XCTAssertEqual(value().split(separator:";").first { $0.hasPrefix("launch=") },launch)
        XCTAssertTrue(value().contains("restored=1"),value())
        XCTAssertTrue(value().contains("courseVisible=true"),value())
        XCTAssertTrue(value().contains("controlsVisible=true"),value())
        let image=XCTAttachment(screenshot:app.screenshot());image.name="scene-relaunch-same-shot";image.lifetime = .keepAlways;add(image)
    }
    @MainActor func testHalfWindowKeepsShot() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--half-window","left","--simulate-division"];app.launch()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:10));XCTAssertTrue(pull.isHittable,app.debugDescription)
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,22)))
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5),app.debugDescription)
        let left=XCTAttachment(screenshot:app.screenshot());left.name="half-left-fixture-after-shot";left.lifetime = .keepAlways;add(left)
        app.buttons["夹具：右半窗"].tap()
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        XCTAssertTrue(pull.isHittable,app.debugDescription)
        let right=XCTAttachment(screenshot:app.screenshot());right.name="half-right-fixture-same-shot";right.lifetime = .keepAlways;add(right)
    }
    @MainActor func testTuningWinBoostPenaltyFlow() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:10))
        func drag(power:Double) {
            let config=String(describing:pull.value ?? "").split(separator:";").reduce(into:[String:Double]()) { d,item in
                let p=item.split(separator:"=");if p.count==2 { d[String(p[0])]=Double(p[1]) }
            }
            let dead=config["dead"] ?? 6,maximum=config["max"] ?? 47,exponent=config["exp"] ?? 1.45
            let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
            start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,dead+(maximum-dead)*pow(power,1/exponent))))
        }
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(String(describing:root.value ?? "").contains("courseVisible=true"))
        XCTAssertTrue(String(describing:root.value ?? "").contains("controlsVisible=true"))
        drag(power:0.55)
        // 一杆进洞先回放，使用真实“跳过回放”入口后才验收结算与奖励。
        let replay=app.buttons["skipReplay"]
        XCTAssertTrue(replay.waitForExistence(timeout:8),app.debugDescription)
        replay.tap()
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","漂亮入洞！")).firstMatch.exists)
        app.buttons["重开"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","预测线就绪")).firstMatch.waitForExistence(timeout:5))
        let boost=XCTAttachment(screenshot:app.screenshot());boost.name="boost-earned-retry";boost.lifetime = .keepAlways;add(boost)
        drag(power:0.2)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5))
        // Actual 60-second rule, no timer injection or forced penalty state.
        XCTAssertTrue(app.staticTexts["轻残局 · 同样拉杆继续"].waitForExistence(timeout:65))
        let penalty=XCTAttachment(screenshot:app.screenshot());penalty.name="actual-timeout-penalty";penalty.lifetime = .keepAlways;add(penalty)
    }
    @MainActor func testFirstHoleWithRealPull() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"];app.launch()
        let pull=app.descendants(matching:.any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout:10));XCTAssertTrue(pull.isHittable)
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        // Approximately 55% power; release goes through the same input and physics as normal play.
        let config=String(describing:pull.value ?? "").split(separator:";").reduce(into:[String:Double]()) { dict,item in
            let pair=item.split(separator:"=");if pair.count==2 { dict[String(pair[0])]=Double(pair[1]) }
        }
        let dead=config["dead"] ?? 6,maximum=config["max"] ?? 47,exponent=config["exp"] ?? 1.45
        let distance: CGFloat = dead+(maximum-dead)*pow(0.55,1/exponent)
        start.press(forDuration:0.3,thenDragTo:start.withOffset(backswing(app,distance)))
        let result=app.buttons["continueAfterWin"]
        XCTAssertTrue(result.waitForExistence(timeout:10),app.debugDescription)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].exists)
        XCTAssertTrue(app.descendants(matching:.any)["winFeedback"].exists)
        let root=app.descendants(matching:.any)["gameArrangement"]
        let next=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        next.press(forDuration:0.3,thenDragTo:next.withOffset(backswing(app,23)))
        XCTAssertTrue(String(describing:root.value ?? "").contains("level=01"),String(describing:root.value))
        XCTAssertTrue(String(describing:root.value ?? "").contains("strokes=1"),String(describing:root.value))
        app.buttons["courseOptions"].tap()
        XCTAssertTrue(option("音效",in:app).exists)
        dismissPopup(app)
        let menuClosed=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:option("音效",in:app))
        XCTAssertEqual(XCTWaiter.wait(for:[menuClosed],timeout:3),.completed)
        XCTAssertTrue(String(describing:root.value ?? "").contains("level=01"))
        XCTAssertTrue(String(describing:root.value ?? "").contains("strokes=1"))
        capture(app,name:"normal-play-first-hole")
        app.coordinate(withNormalizedOffset:CGVector(dx:0.15,dy:0.2)).tap()
        let nextHole=NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","level=02","strokes=0")
        expectation(for:nextHole,evaluatedWith:root);waitForExpectations(timeout:5)
        capture(app,name:"tap-next-complete-course")
    }
    @MainActor private func dismissPopup(_ app:XCUIApplication) {
        guard let menu=[app.collectionViews.firstMatch,app.scrollViews.firstMatch,app.tables.firstMatch].first(where:{$0.exists}) else { XCTFail("No popup to dismiss");return }
        let r=menu.frame,a=app.frame
        let point:CGPoint
        if r.minX-a.minX>=12 { point=CGPoint(x:r.minX-10,y:r.midY) }
        else if a.maxX-r.maxX>=12 { point=CGPoint(x:r.maxX+10,y:r.midY) }
        else { point=CGPoint(x:a.midX,y:max(a.minY+2,r.minY-12)) }
        app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:point.x-a.minX,dy:point.y-a.minY)).tap()
        let dismissed=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:menu)
        _ = XCTWaiter.wait(for:[dismissed],timeout:2)
    }
    @MainActor private func option(_ name:String,in app:XCUIApplication)->XCUIElement {
        let item=app.descendants(matching:.any).matching(NSPredicate(format:"label == %@",name)).firstMatch
        if let list=[app.scrollViews.firstMatch,app.collectionViews.firstMatch,app.tables.firstMatch].first(where:{$0.exists}) {
            for _ in 0..<10 {
                if item.exists && item.isHittable { break }
                list.swipeUp(velocity:.slow)
            }
        }
        if !item.exists {
            let debug=XCTAttachment(string:app.debugDescription);debug.name="missing-option-"+name;debug.lifetime = .keepAlways;add(debug)
        }
        return item
    }
    @MainActor private func tapOption(_ name:String,in app:XCUIApplication) {
        let item=option(name,in:app)
        let menu=[app.collectionViews.firstMatch,app.scrollViews.firstMatch,app.tables.firstMatch].first(where:{$0.exists})
        item.tap()
        if let menu {
            let dismissed=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:menu)
            _ = XCTWaiter.wait(for:[dismissed],timeout:2)
        }
    }
    @MainActor func testOptionsInLandscape() {
        XCUIDevice.shared.orientation = .landscapeRight
        defer { XCUIDevice.shared.orientation = .portrait }
        testOptionsScrollOutsideDismissAndHapticsToggle()
    }
    @MainActor func testOptionsScrollOutsideDismissAndHapticsToggle() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        let menu=app.buttons["courseOptions"]
        XCTAssertTrue(menu.waitForExistence(timeout:10))
        let pull=app.descendants(matching:.any)["pullControl"]
        let initial=pull.frame
        menu.tap()
        // 地图现在位于原生子菜单中；此处验收当前弹层的真实入口。
        XCTAssertTrue(option("选择地图 · 选择后重新开始",in:app).exists,app.debugDescription)
        capture(app,name:"options-popup")
        let anchored=pull.frame
        XCTAssertEqual(pull.frame.width,initial.width,accuracy:0.5)
        XCTAssertEqual(pull.frame.height,initial.height,accuracy:0.5)
        dismissPopup(app)
        XCTAssertFalse(option("音效",in:app).exists)
        let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:pull)
        XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:3),.completed)
        XCTAssertEqual(pull.frame.width,initial.width,accuracy:0.5)
        XCTAssertEqual(pull.frame.height,initial.height,accuracy:0.5)
        XCTAssertEqual(pull.frame,anchored)
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(String(describing:root.value ?? "").contains("strokes=0"))
        let original=String(describing:root.value ?? "").contains("haptics=true")
        menu.tap();tapOption("触感",in:app)
        expectation(for:NSPredicate(format:"value CONTAINS %@","haptics=\(!original)"),evaluatedWith:root);waitForExpectations(timeout:3)
        menu.tap();tapOption("触感",in:app)
        expectation(for:NSPredicate(format:"value CONTAINS %@","haptics=\(original)"),evaluatedWith:root);waitForExpectations(timeout:3)
        menu.tap();tapOption("下一关",in:app)
        let restored=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:pull)
        XCTAssertEqual(XCTWaiter.wait(for:[restored],timeout:3),.completed)
        XCTAssertEqual(pull.frame.width,initial.width,accuracy:0.5)
        XCTAssertEqual(pull.frame.height,initial.height,accuracy:0.5)
        XCTAssertTrue(String(describing:root.value ?? "").contains("strokes=0"))
        capture(app,name:"options-closed-pull-visible")
    }
    @MainActor func testPullAndHandheldMenu() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        let pull=app.descendants(matching: .any)["pullControl"]
        guard pull.waitForExistence(timeout:10) else { XCTFail(app.debugDescription); return }
        XCTAssertTrue(pull.isHittable)
        qDrag(app,power:0.2)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5), app.debugDescription)
        let menu=app.buttons["courseOptions"]
        XCTAssertTrue(menu.exists)
        let root=app.descendants(matching:.any)["gameArrangement"]
        // 先等这次真实轻推停球，避免在一杆进洞回放隐藏 HUD 时点选项。
        expectation(for:NSPredicate(format:"value CONTAINS %@","phase=ready"),evaluatedWith:root)
        waitForExpectations(timeout:10)
        let originalSound=String(describing:root.value ?? "").contains("sound=true")
        menu.tap();tapOption("音效",in:app)
        XCTAssertTrue(String(describing:root.value ?? "").contains("sound=\(!originalSound)"))
        menu.tap();tapOption("音效",in:app)
        XCTAssertTrue(String(describing:root.value ?? "").contains("sound=\(originalSound)"))
        menu.tap();tapOption("掌机模式",in:app)
        XCTAssertTrue(pull.waitForExistence(timeout:5))
        XCTAssertTrue(pull.isHittable)
        menu.tap();tapOption("下一关",in:app)
        XCTAssertTrue(app.staticTexts["0 杆  /  PAR 3"].waitForExistence(timeout:5))
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.lifetime = .keepAlways;add(attachment)
    }
}
