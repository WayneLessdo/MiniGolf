import XCTest
import Darwin

/// 使用真实入口、真实击球采集发布画面；不注入球位、奖励或关卡结果。
final class FPReleaseUITests: XCTestCase {
    @MainActor private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        let textSize = arguments.contains("-UIPreferredContentSizeCategoryName") ? [] : ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launchArguments = ["--ui-testing", "--show-mode-picker"] + textSize + arguments
        app.launch()
        XCTAssertTrue(app.buttons["chooseMode-classic"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String, holdForFramebuffer: Bool = false) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "store-" + name; image.lifetime = .keepAlways; add(image)
        let candidates = ["privacyPolicy", "clubCollection", "modeSelection", "gameArrangement"]
        let source = candidates.map { app.descendants(matching: .any)[$0] }.first { $0.exists }
        let details = XCTAttachment(string: String(describing: source?.value ?? "") + "\nappFrame=\(app.frame)")
        details.name = "store-" + name + "-layout"; details.lifetime = .keepAlways; add(details)
        if holdForFramebuffer {
            // 为 simctl 原始 framebuffer 采集保留稳定场景；不注入球位、奖励或渲染尺寸。
            print("FP_FRAMEBUFFER_READY:store-" + name); fflush(stdout)
            _ = XCTWaiter.wait(for: [XCTestExpectation(description: "原始显示屏采集窗口")], timeout: 5)
        }
    }

    @MainActor private func tapMenu(_ name: String, in app: XCUIApplication) {
        app.buttons["设置与演示"].tap()
        let item = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
        for _ in 0..<6 {
            if item.exists && item.isHittable { break }
            guard app.collectionViews.firstMatch.exists else { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(item.waitForExistence(timeout: 3), app.debugDescription)
        item.tap()
    }

    @MainActor private func drag(_ app: XCUIApplication, power: Double) {
        let pull = app.descendants(matching: .any)["pullControl"]
        let config = String(describing: pull.value ?? "").split(separator: ";").reduce(into: [String: Double]()) { result, item in
            let pair = item.split(separator: "=")
            if pair.count == 2 { result[String(pair[0])] = Double(pair[1]) }
        }
        let dead = config["dead"] ?? 6
        let distance = dead + ((config["max"] ?? 47) - dead) * pow(power, 1 / (config["exp"] ?? 1.45))
        let across = String(describing: app.descendants(matching: .any)["gameArrangement"].value ?? "").contains("across=true")
        let start = pull.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.3, thenDragTo: start.withOffset(across ? CGVector(dx: -distance, dy: 0) : CGVector(dx: 0, dy: distance)))
    }

    @MainActor func testPrivacyFromLaunchAndGamePreservesShot() {
        let app = launch()
        let entry = app.buttons["openPrivacy"]
        for _ in 0..<6 {
            if entry.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        let policy = app.textViews["privacyText"]
        XCTAssertTrue(policy.waitForExistence(timeout: 5))
        XCTAssertTrue(String(describing: policy.value ?? "").contains("不主动将游戏数据传送至开发者服务器"))
        XCTAssertTrue(String(describing: policy.value ?? "").contains("Wayne"))
        XCTAssertTrue(String(describing: policy.value ?? "").contains("waynelessdo@gmail.com"))
        capture(app, "privacy")
        policy.swipeUp(); policy.swipeUp()
        XCTAssertTrue(app.buttons["closePrivacy"].isHittable)
        app.buttons["closePrivacy"].tap()
        let classic = app.buttons["chooseMode-classic"]
        if !classic.isHittable { app.scrollViews.firstMatch.swipeDown() }
        classic.tap()
        let pull = app.descendants(matching: .any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout: 5))
        let root = app.descendants(matching: .any)["gameArrangement"]
        drag(app, power: 0.2)
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout: 5))
        let launchID = String(describing: root.value ?? "").split(separator: ";").first { $0.hasPrefix("launch=") }
        tapMenu("隐私政策", in: app)
        XCTAssertTrue(policy.waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(app.buttons["closePrivacy"].isHittable)
        capture(app, "privacy-landscape")
        app.buttons["closePrivacy"].tap()
        XCTAssertTrue(app.staticTexts["1 杆  /  PAR 3"].waitForExistence(timeout: 5))
        XCTAssertEqual(String(describing: root.value ?? "").split(separator: ";").first { $0.hasPrefix("launch=") }, launchID)
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor func testPrivacyLargestText() {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let entry = app.buttons["openPrivacy"]
        for _ in 0..<10 {
            if entry.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        let policy = app.textViews["privacyText"]
        XCTAssertTrue(policy.waitForExistence(timeout: 5))
        policy.swipeUp()
        capture(app, "privacy-largest-text")
        XCTAssertTrue(app.buttons["closePrivacy"].isHittable)
        app.buttons["closePrivacy"].tap()
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
    }

    @MainActor func testStoreScreenshotsFromRealNavigation() {
        let app = launch()
        capture(app, "01-mode-selection", holdForFramebuffer: true)
        app.buttons["chooseMode-classic"].tap()
        XCTAssertTrue(app.buttons["玩法与收藏"].waitForExistence(timeout: 5))
        capture(app, "02-classic-course", holdForFramebuffer: true)
        drag(app, power: 0.55)
        let skip = app.buttons["skipReplay"]
        XCTAssertTrue(skip.waitForExistence(timeout: 8), app.debugDescription)
        skip.tap()
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout: 5))
        capture(app, "07-real-win", holdForFramebuffer: true)
        tapMenu("切换游戏模式", in: app)
        let chibi = app.buttons["chooseMode-chibi"]
        if !chibi.isHittable { app.scrollViews.firstMatch.swipeUp() }
        chibi.tap()
        XCTAssertTrue(app.buttons["玩法与收藏"].waitForExistence(timeout: 5))
        app.buttons["重开"].tap()
        capture(app, "03-chibi-course", holdForFramebuffer: true)
        app.buttons["玩法与收藏"].tap()
        XCTAssertTrue(app.segmentedControls["clubSections"].waitForExistence(timeout: 5))
        capture(app, "04-puzzles", holdForFramebuffer: true)
        app.segmentedControls["clubSections"].buttons["我的花园"].tap()
        app.buttons["garden-slot-0"].tap()
        XCTAssertTrue(app.staticTexts["gardenBalance"].label.contains("已种 1/9"))
        capture(app, "05-garden", holdForFramebuffer: true)
        app.segmentedControls["clubSections"].buttons["嘴硬语录"].tap()
        capture(app, "06-quotes", holdForFramebuffer: true)
        app.buttons["closeClub"].tap()
    }
}
