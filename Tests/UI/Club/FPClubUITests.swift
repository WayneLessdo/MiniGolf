import XCTest

final class FPClubUITests:XCTestCase {
    @MainActor private func app(_ extra:[String]=[])->XCUIApplication {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--q-mode","--reset-language","-AppleLanguages","(zh-Hans)","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]+extra;app.launch()
        XCTAssertTrue(app.buttons["玩法与收藏"].waitForExistence(timeout:10));return app
    }
    @MainActor private func capture(_ app:XCUIApplication,_ name:String) {
        let image=XCTAttachment(screenshot:XCUIScreen.main.screenshot());image.name=name;image.lifetime = .keepAlways;add(image)
        let club=app.descendants(matching:.any)["clubCollection"],root=app.descendants(matching:.any)["gameArrangement"]
        let proof=XCTAttachment(string:String(describing:(club.exists ? club:root).value ?? ""));proof.name=name+"-layout";proof.lifetime = .keepAlways;add(proof)
    }
    @MainActor private func drag(_ app:XCUIApplication,dx:Double=0,dy:Double = -1,power:Double) {
        let pull=app.descendants(matching:.any)["pullControl"]
        let config=String(describing:pull.value ?? "").split(separator:";").reduce(into:[String:Double]()) { dict,item in
            let pair=item.split(separator:"=");if pair.count==2 { dict[String(pair[0])]=Double(pair[1]) }
        }
        let dead=config["dead"] ?? 6,maximum=config["max"] ?? 47,exponent=config["exp"] ?? 1.45
        let distance=dead+(maximum-dead)*pow(power,1/exponent)
        let root=String(describing:app.descendants(matching:.any)["gameArrangement"].value ?? "")
        let across=root.contains("across=true")
        let offset=across ? CGVector(dx:dy*distance,dy:-dx*distance):CGVector(dx:-dx*distance,dy:-dy*distance)
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(offset))
    }
    @MainActor private func awaitWin(_ app:XCUIApplication) {
        XCTAssertTrue(win(app,timeout:8),app.debugDescription)
    }
    /// 等待真实进洞；成功返回 true，未进洞返回 false 交给调用方重开再试。
    @MainActor private func win(_ app:XCUIApplication,timeout:TimeInterval)->Bool {
        let skip=app.buttons["skipReplay"],result=app.buttons["continueAfterWin"]
        // 验收用户可见的回放/结算入口，避免依赖不同系统对调试容器 value 的快照刷新时机。
        // 同时覆盖减少动态效果下已结束的短回放。
        let holed=XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in skip.exists || result.exists },object:app)
        guard XCTWaiter.wait(for:[holed],timeout:timeout) == .completed else { return false }
        if skip.exists { skip.tap() }
        return result.waitForExistence(timeout:8)
    }
    @MainActor func testRealWinGardenTransplantAndQuoteBook() {
        let app=app();capture(app,"club-native-ready")
        drag(app,power:0.55);awaitWin(app);capture(app,"club-real-win-seed")
        app.buttons["玩法与收藏"].tap()
        XCTAssertTrue(app.segmentedControls["clubSections"].waitForExistence(timeout:3))
        capture(app,"club-puzzles")
        app.segmentedControls["clubSections"].buttons["我的花园"].tap()
        let balance=app.staticTexts["gardenBalance"]
        XCTAssertTrue(balance.label.contains("种子 1 颗"))
        app.buttons["garden-slot-0"].tap();XCTAssertTrue(balance.label.contains("已种 1/9"))
        capture(app,"club-garden-planted")
        app.buttons["garden-slot-0"].tap();app.alerts.buttons["收回种子"].tap()
        app.buttons["flower-bluebell"].tap();app.buttons["garden-slot-1"].tap()
        XCTAssertTrue(app.buttons["garden-slot-1"].label.contains("蓝风铃"));XCTAssertTrue(balance.label.contains("种子 0 颗"))
        app.segmentedControls["clubSections"].buttons["嘴硬语录"].tap()
        app.buttons["voice-silly"].tap();capture(app,"club-voice-options")
        let scroll=app.scrollViews["clubScroll"];scroll.swipeUp();capture(app,"club-collected-quotes")
        XCTAssertTrue(app.staticTexts["quote-shot"].exists)
        scroll.swipeDown();app.buttons["voice-quiet"].tap()
        app.buttons["closeClub"].tap()
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:3))
        app.buttons["玩法与收藏"].tap();app.segmentedControls["clubSections"].buttons["我的花园"].tap()
        XCTAssertTrue(app.buttons["garden-slot-1"].label.contains("蓝风铃"));capture(app,"club-garden-restored")
        app.buttons["closeClub"].tap();app.buttons["continueAfterWin"].tap()
        let root=app.descendants(matching:.any)["gameArrangement"]
        expectation(for:NSPredicate(format:"value CONTAINS %@","level=02"),evaluatedWith:root);waitForExpectations(timeout:5)
    }
    @MainActor func testActualBankShotEarnsMasteryAndPausesInClub() {
        let app=app();app.buttons["玩法与收藏"].tap();app.buttons["puzzle-P01"].tap()
        let root=app.descendants(matching:.any)["gameArrangement"]
        expectation(for:NSPredicate(format:"value CONTAINS %@","level=P01"),evaluatedWith:root);waitForExpectations(timeout:4)
        capture(app,"club-puzzle-P01-course")
        // 中缝在展开内屏是一条带桥面的水道，会改掉 P01 的唯一借墙球路；
        // 两种场地各用一条校准过的借左墙球路，未进洞就用“重开”回到同一发球位再试下一杆。
        let hasCrease=String(describing:root.value ?? "").contains("division=[(")
        let routes:[(dx:Double,dy:Double,power:Double)] = hasCrease
            ? [(-0.5736,-0.8192,0.72),(-0.5446,-0.8387,0.713),(-0.5878,-0.8090,0.703),(-0.6018,-0.7986,0.703),(-0.5150,-0.8572,0.703)]
            : [(-0.8660254037844386,-0.5,1)]
        var mastered=false
        for route in routes {
            drag(app,dx:route.dx,dy:route.dy,power:route.power)
            if win(app,timeout:12) { mastered=true;break }
            app.buttons["重开"].tap()
            _=app.descendants(matching:.any)["gameArrangement"].waitForExistence(timeout:3)
        }
        XCTAssertTrue(mastered,app.debugDescription)
        capture(app,"club-bank-shot-mastery")
        app.buttons["玩法与收藏"].tap()
        XCTAssertTrue(String(describing:app.buttons["puzzle-P01"].value ?? "").contains("已精通"))
        capture(app,"club-puzzle-completed")
        app.buttons["puzzle-P03"].tap();drag(app,power:0.15)
        app.buttons["玩法与收藏"].tap();app.segmentedControls["clubSections"].buttons["我的花园"].tap()
        capture(app,"club-paused-live-shot")
        app.buttons["closeClub"].tap()
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout:5))
    }
    @MainActor func testRotationKeepsCollectionAnchorAndCurrentRound() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app=app();drag(app,power:0.15)
        let game=app.descendants(matching:.any)["gameArrangement"]
        let before=String(describing:game.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") }
        XCTAssertNotEqual(before,"launch=none")
        app.buttons["玩法与收藏"].tap()
        let scroll=app.scrollViews["clubScroll"]
        scroll.swipeUp()
        let visible=(1...6).map { app.buttons[String(format:"puzzle-P%02d",$0)] }
            .filter { $0.exists && $0.frame.intersection(scroll.frame).height>=44 }
            .sorted { $0.frame.minY<$1.frame.minY }
        guard let anchor=visible.first else { XCTFail("No visible puzzle after scrolling");return }
        let id=anchor.identifier
        capture(app,"duofit-collection-before-rotation")
        XCUIDevice.shared.orientation = .landscapeRight
        let kept=app.buttons[id]
        let visibleAfter=XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in
            kept.exists && kept.frame.intersection(scroll.frame).height>0
        },object:nil)
        XCTAssertEqual(XCTWaiter.wait(for:[visibleAfter],timeout:5),.completed)
        capture(app,"duofit-collection-after-rotation")
        XCTAssertTrue(app.buttons["closeClub"].isHittable);app.buttons["closeClub"].tap()
        XCTAssertTrue(app.buttons["玩法与收藏"].waitForExistence(timeout:3))
        let after=String(describing:game.value ?? "")
        XCTAssertEqual(after.split(separator:";").first { $0.hasPrefix("launch=") },before)
        XCTAssertTrue(after.contains("strokes=1"));XCTAssertTrue(after.contains("controlsVisible=true"))
        capture(app,"duofit-round-after-rotation")
    }
    @MainActor func testCurrentDisplayCollectionScreenshots() {
        let app=app();app.buttons["玩法与收藏"].tap()
        for title in ["反弹课题","我的花园","嘴硬语录"] {
            app.segmentedControls["clubSections"].buttons[title].tap()
            XCTAssertTrue(app.buttons["closeClub"].isHittable)
            capture(app,"duofit-current-"+title)
            // XCUIScreen.main can refer to Duo's inactive outer display.
            // Keep the application's own window capture as a second, verifiable source.
            let shot=XCTAttachment(screenshot:app.screenshot())
            shot.name="duofit-window-"+title;shot.lifetime = .keepAlways;add(shot)
            print("DUOFIT_FRAME_READY:"+title)
            _=XCTWaiter.wait(for:[XCTestExpectation(description:"Framebuffer capture interval")],timeout:4)
        }
        app.buttons["closeClub"].tap()
    }
    @MainActor func testCollectionLargeTextAndLandscape() {
        for landscape in [false,true] {
            XCUIDevice.shared.orientation=landscape ? .landscapeRight:.portrait
            let app=app(["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"])
            app.buttons["玩法与收藏"].tap()
            XCTAssertTrue(app.buttons["closeClub"].isHittable)
            for title in ["反弹课题","我的花园","嘴硬语录"] {
                app.segmentedControls["clubSections"].buttons[title].tap()
                XCTAssertTrue(app.buttons["closeClub"].isHittable)
                capture(app,"club-large-\(landscape ? "wide":"tall")-\(title)")
                if title == "我的花园" {
                    let lastPlot=app.buttons["garden-slot-8"]
                    let scroll=app.scrollViews["clubScroll"]
                    // isHittable can include a sliver clipped by the scroll view. Tap a
                    // visible 44pt region, so oversized accessibility cards work too.
                    for _ in 0..<30 {
                        let frame=lastPlot.frame,viewport=scroll.frame.insetBy(dx:4,dy:4)
                        if lastPlot.isHittable && frame.intersection(viewport).height >= 44 { break }
                        // Short, held drags avoid flinging past a card in a short landscape viewport.
                        let upward=frame.midY>viewport.midY
                        let start=scroll.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:upward ? 0.8:0.2))
                        let end=scroll.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:upward ? 0.2:0.8))
                        start.press(forDuration:0.05,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.15)
                    }
                    let visible=lastPlot.frame.intersection(scroll.frame.insetBy(dx:4,dy:4))
                    XCTAssertTrue(lastPlot.isHittable && visible.height>=44,"Last garden plot must remain reachable with large text: \(lastPlot.frame), scroll: \(scroll.frame)")
                    capture(app,"club-large-\(landscape ? "wide":"tall")-before-last-plot")
                    let point=scroll.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:visible.midX-scroll.frame.minX,dy:visible.midY-scroll.frame.minY))
                    point.tap()
                    let alert=app.alerts["先带一颗种子回来"]
                    XCTAssertTrue(alert.waitForExistence(timeout:3),app.debugDescription)
                    if alert.exists { alert.buttons["继续看看"].tap() }
                    capture(app,"club-large-\(landscape ? "wide":"tall")-last-plot")
                }
            }
            app.buttons["closeClub"].tap();XCTAssertTrue(app.buttons["玩法与收藏"].isHittable);app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
