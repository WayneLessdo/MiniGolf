import XCTest
import Darwin

/// 使用真实入口、真实击球采集发布画面；不注入球位、奖励或关卡结果。
final class FPReleaseUITests: XCTestCase {
    @MainActor private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        let textSize = arguments.contains("-UIPreferredContentSizeCategoryName") ? [] : ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launchArguments = ["--ui-testing", "--show-mode-picker", "--reset-language", "-AppleLanguages", "(zh-Hans)"] + textSize + arguments
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
        app.buttons["courseOptions"].tap()
        let item = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
        for _ in 0..<6 {
            if item.exists && item.isHittable { break }
            guard app.collectionViews.firstMatch.exists else { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(item.waitForExistence(timeout: 3), app.debugDescription)
        item.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: item)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 3), .completed)
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
        XCTAssertTrue(String(describing: policy.value ?? "").contains("https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy-zh-Hans"))
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
        // 等到横屏布局且按钮可点，再验证关闭行为；截图呈现状态另行核对。
        let landscapeReady = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height && app.buttons["closePrivacy"].isHittable
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscapeReady], timeout: 5), .completed)
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

    @MainActor func testEnglishHeaderIconsAndFeedbackSettings() {
        let app = launch(["-AppleLanguages", "(en)"])
        XCTAssertEqual(app.buttons["chooseMode-classic"].label, "Classic mode")
        let language = app.buttons["openLanguage"], privacy = app.buttons["openPrivacy"]
        for _ in 0..<6 { if language.isHittable && privacy.isHittable { break }; app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(language.isHittable); XCTAssertTrue(privacy.isHittable)
        XCTAssertEqual(language.frame.midY, privacy.frame.midY, accuracy: 1)
        XCTAssertGreaterThanOrEqual(language.frame.height, 44)
        XCTAssertGreaterThanOrEqual(abs(language.frame.midX-privacy.frame.midX), language.frame.width)
        XCTAssertLessThan(language.frame.maxY, app.frame.height * 0.3)
        let beforeScroll = language.frame
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertEqual(language.frame, beforeScroll)
        XCTAssertTrue(language.isHittable); XCTAssertTrue(privacy.isHittable)
        capture(app, "header-icons")
        language.tap()
        let english = app.cells["language-en"]
        XCTAssertTrue(english.waitForExistence(timeout: 5)); english.tap()
        capture(app, "updated-language")
        app.buttons["closeLanguage"].tap()
        let classic = app.buttons["chooseMode-classic"]
        for _ in 0..<6 { if classic.isHittable { break }; app.scrollViews.firstMatch.swipeDown() }
        classic.tap()
        let root = app.descendants(matching: .any)["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        tapMenu("Sound effects", in: app)
        let soundOff = String(describing: root.value ?? "").contains("sound=false")
        tapMenu("Haptics", in: app)
        let hapticsOff = String(describing: root.value ?? "").contains("haptics=false")
        capture(app, "updated-settings")
        // 独立切换并恢复默认，避免影响其他验收流程。
        tapMenu("Sound effects", in: app); tapMenu("Haptics", in: app)
        XCTAssertNotEqual(String(describing: root.value ?? "").contains("sound=false"), soundOff)
        XCTAssertNotEqual(String(describing: root.value ?? "").contains("haptics=false"), hapticsOff)
        let clubButton = app.buttons["openClub"]
        let available = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: clubButton)
        XCTAssertEqual(XCTWaiter.wait(for: [available], timeout: 3), .completed)
        clubButton.tap()
        let close = app.buttons["closeClub"]
        let presented = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            close.exists && close.isHittable && close.frame.maxY < app.frame.height * 0.2
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [presented], timeout: 5), .completed)
        let garden = app.segmentedControls["clubSections"].buttons["My garden"]
        garden.tap()
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"), object: garden)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 3), .completed)
        XCTAssertTrue(app.staticTexts["pointsBalance"].waitForExistence(timeout: 5))
        capture(app, "updated-points")
        app.terminate()
    }

    @MainActor func testEnglishStoreScreenshotsFromRealNavigation() {
        let app = launch(["-AppleLanguages", "(en)"])
        capture(app, "en-01-mode-selection")
        app.buttons["chooseMode-classic"].tap()
        XCTAssertTrue(app.buttons["openClub"].waitForExistence(timeout: 5))
        capture(app, "en-02-classic-course")
        drag(app, power: 0.55)
        let skip = app.buttons["skipReplay"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10), app.debugDescription); skip.tap()
        XCTAssertTrue(app.buttons["continueAfterWin"].waitForExistence(timeout: 5))
        capture(app, "en-07-real-win")
        tapMenu("Change game mode", in: app)
        let chibi = app.buttons["chooseMode-chibi"]
        for _ in 0..<6 { if chibi.isHittable { break }; app.scrollViews.firstMatch.swipeUp() }
        chibi.tap()
        app.buttons["Restart"].tap()
        capture(app, "en-03-chibi-course")
        app.buttons["openClub"].tap()
        XCTAssertTrue(app.segmentedControls["clubSections"].waitForExistence(timeout: 5))
        capture(app, "en-04-puzzles")
        app.segmentedControls["clubSections"].buttons["My garden"].tap()
        app.buttons["garden-slot-0"].tap()
        capture(app, "en-05-garden")
        app.segmentedControls["clubSections"].buttons["Little ball quotes"].tap()
        capture(app, "en-06-quotes")
        app.buttons["closeClub"].tap(); app.terminate()
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


extension FPReleaseUITests {
    @MainActor func testClassicClubFromActualPullAndPinnedHeader() {
        let app = launch(["-AppleLanguages", "(en)"])
        XCTAssertTrue(app.buttons["openPrivacy"].isHittable)
        XCTAssertTrue(app.buttons["openLanguage"].isHittable)
        capture(app, "build8-home")
        app.buttons["chooseMode-classic"].tap()
        let pull = app.descendants(matching: .any)["pullControl"]
        XCTAssertTrue(pull.waitForExistence(timeout: 5))
        let start = pull.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        print("FP_CLASSIC_PULL_READY"); fflush(stdout)
        start.press(forDuration: 0.3, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 27)), withVelocity: .slow, thenHoldForDuration: 3)
        let state = app.descendants(matching: .any)["gameArrangement"]
        XCTAssertTrue(String(describing: state.value ?? "").contains("strokes=1"))
        capture(app, "build8-after-real-pull")
        app.terminate()
    }
    @MainActor func testHeaderIconsRemainVisibleLargestTextAndRTL() {
        let app = launch(["-AppleLanguages", "(ar)", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        for orientation in [UIDeviceOrientation.portrait, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let language = app.buttons["openLanguage"], privacy = app.buttons["openPrivacy"]
            XCTAssertTrue(language.waitForExistence(timeout: 5))
            XCTAssertTrue(language.isHittable); XCTAssertTrue(privacy.isHittable)
            XCTAssertGreaterThanOrEqual(language.frame.width, 44)
            XCTAssertGreaterThanOrEqual(language.frame.height, 44)
            XCTAssertGreaterThan(language.frame.midX, app.frame.midX)
            XCTAssertEqual(app.staticTexts["modeBrand"].frame.midY, language.frame.midY, accuracy: 1)
            let before = language.frame
            app.scrollViews.firstMatch.swipeUp()
            XCTAssertEqual(language.frame, before)
            capture(app, "header-rtl-largest-" + (orientation == .portrait ? "portrait" : "landscape"))
        }
        XCUIDevice.shared.orientation = .portrait; app.terminate()
    }
}


extension FPReleaseUITests {
    @MainActor func testBrandAndIconsSharePinnedHeader() {
        let app = launch()
        let brand = app.staticTexts["modeBrand"], language = app.buttons["openLanguage"], privacy = app.buttons["openPrivacy"]
        XCTAssertTrue(brand.waitForExistence(timeout: 5))
        XCTAssertEqual(brand.frame.midY, language.frame.midY, accuracy: 1)
        XCTAssertEqual(privacy.frame.midY, language.frame.midY, accuracy: 1)
        XCTAssertLessThanOrEqual(brand.frame.maxX + 10, privacy.frame.minX)
        XCTAssertTrue(privacy.isHittable); XCTAssertTrue(language.isHittable)
        capture(app, "build9-same-row-chinese")
        let before = brand.frame
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertEqual(brand.frame, before)
        XCTAssertTrue(language.isHittable); XCTAssertTrue(privacy.isHittable)
        privacy.tap()
        XCTAssertTrue(app.textViews["privacyText"].waitForExistence(timeout: 5))
        app.buttons["closePrivacy"].tap()
        language.tap()
        XCTAssertTrue(app.cells["language-en"].waitForExistence(timeout: 5))
        app.cells["language-en"].tap(); app.buttons["closeLanguage"].tap()
        XCTAssertEqual(app.staticTexts["modeBrand"].frame.midY, app.buttons["openLanguage"].frame.midY, accuracy: 1)
        capture(app, "build9-same-row-english")
        app.buttons["openLanguage"].tap()
        XCTAssertTrue(app.cells["language-zh-Hans"].waitForExistence(timeout: 5))
        app.cells["language-zh-Hans"].tap(); app.buttons["closeLanguage"].tap()
        capture(app, "header-final-chinese")
        app.terminate()
    }
}
