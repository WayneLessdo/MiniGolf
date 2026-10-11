import XCTest

final class FPClubUITests:XCTestCase {
    @MainActor private func app(_ extra:[String]=[])->XCUIApplication {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--q-mode","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]+extra;app.launch()
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
        let skip=app.buttons["skipReplay"]
        if skip.waitForExistence(timeout:8) { skip.tap() }
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout:15),app.debugDescription)
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
        drag(app,dx:-0.8660254037844386,dy:-0.5,power:1);awaitWin(app)
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
