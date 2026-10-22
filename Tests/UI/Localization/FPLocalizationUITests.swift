import XCTest
import Darwin

final class FPLocalizationUITests: XCTestCase {
    private let labels:[String:[String]]=[
        "tr":["Klasik mod","Gizlilik Politikası","Bahçem","Sözler","Papatya","Kanal yankısı"],
        "ar":["النمط الكلاسيكي","سياسة الخصوصية","حديقتي","التعليقات","أقحوان","أصداء القناة"],
        "pt":["Modo clássico","Política de Privacidade","Jardim","Frases","Margarida","Ecos do canal"],
        "fr":["Mode classique","Politique de confidentialité","Jardin","Répliques","Pâquerette","Échos du canal"],
        "es":["Modo clásico","Política de privacidad","Jardín","Frases","Margarita","Ecos del canal"]
    ]
    @MainActor private func app(_ language:String,large:Bool=false)->XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app=XCUIApplication()
        app.launchArguments=["--ui-testing","--show-mode-picker","--reset-language","-AppleLanguages","(\(language))","-AppleLocale",language == "ar" ? "ar_SA":language == "pt" ? "pt_PT":language+"_"+language.uppercased(),"-UIPreferredContentSizeCategoryName",large ? "UICTContentSizeCategoryAccessibilityXXXL":"UICTContentSizeCategoryL"]
        app.launch();XCTAssertTrue(app.buttons["chooseMode-classic"].waitForExistence(timeout:10))
        XCTAssertEqual(app.buttons["chooseMode-classic"].label,labels[language]![0])
        return app
    }
    @MainActor private func reveal(_ button:XCUIElement,in app:XCUIApplication,up:Bool) {
        for _ in 0..<12 {
            if button.exists && button.isHittable { return }
            let scroll=app.scrollViews.firstMatch
            if up { scroll.swipeUp() } else { scroll.swipeDown() }
        }
        XCTAssertTrue(button.isHittable,app.debugDescription)
    }
    @MainActor private func capture(_ app:XCUIApplication,_ name:String) {
        let rotated=name.contains("largest-landscape")
        if rotated {
            // 等系统旋转的渲染提交完成，避免 beta XCTest 把过渡中的窗口截成黑边图。
            _=XCTWaiter.wait(for:[XCTestExpectation(description:"系统旋转渲染窗口")],timeout:1)
        }
        let picture=XCTAttachment(screenshot:app.screenshot());picture.name="l10n-"+name;picture.lifetime = .keepAlways;add(picture)
        let element=["languageSelection","privacyPolicy","clubCollection","modeSelection","gameArrangement"].map { app.descendants(matching:.any)[$0] }.first { $0.exists }
        let details=XCTAttachment(string:String(describing:element?.value ?? "")+"\nappFrame=\(app.frame)")
        details.name="l10n-"+name+"-layout";details.lifetime = .keepAlways;add(details)
        if rotated {
            print("FP_L10N_FRAME_READY:"+name);fflush(stdout)
            _=XCTWaiter.wait(for:[XCTestExpectation(description:"原生显示屏采集窗口")],timeout:4)
        }
    }
    @MainActor private func drag(_ app:XCUIApplication,power:Double=0.55) {
        let pull=app.descendants(matching:.any)["pullControl"]
        let config=String(describing:pull.value ?? "").split(separator:";").reduce(into:[String:Double]()) { values,item in
            let pair=item.split(separator:"=");if pair.count==2 { values[String(pair[0])]=Double(pair[1]) }
        }
        let dead=config["dead"] ?? 6,distance=dead+((config["max"] ?? 47)-dead)*pow(power,1/(config["exp"] ?? 1.45))
        let across=String(describing:app.descendants(matching:.any)["gameArrangement"].value ?? "").contains("across=true")
        let start=pull.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.3,thenDragTo:start.withOffset(across ? CGVector(dx:-distance,dy:0):CGVector(dx:0,dy:distance)))
    }
    @MainActor private func experience(_ language:String) {
        let app=app(language),expected=labels[language]!
        capture(app,language+"-mode")
        let privacy=app.buttons["openPrivacy"];reveal(privacy,in:app,up:true);privacy.tap()
        let policy=app.textViews["privacyText"];XCTAssertTrue(policy.waitForExistence(timeout:5))
        let policyText=String(describing:policy.value ?? "")
        XCTAssertTrue(policyText.contains("waynelessdo@gmail.com"));XCTAssertNil(policyText.range(of:"[\\p{Han}]",options:.regularExpression))
        capture(app,language+"-privacy");app.buttons["closePrivacy"].tap()
        let classic=app.buttons["chooseMode-classic"];reveal(classic,in:app,up:false);classic.tap()
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout:5));XCTAssertTrue(String(describing:root.value ?? "").contains("language="+language))
        XCTAssertTrue(String(describing:root.value ?? "").contains("direction="+(language == "ar" ? "rtl":"ltr")))
        let pull=app.descendants(matching:.any)["pullControl"],score=app.otherElements["scoreCard"]
        XCTAssertTrue(pull.isHittable);XCTAssertGreaterThanOrEqual(pull.frame.width,44)
        if language == "ar" { XCTAssertGreaterThan(pull.frame.midX,score.frame.midX) }
        capture(app,language+"-course");drag(app)
        let skip=app.buttons["skipReplay"],win=app.buttons["continueAfterWin"]
        let holed=XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in skip.exists || win.exists },object:app)
        XCTAssertEqual(XCTWaiter.wait(for:[holed],timeout:12),.completed,app.debugDescription)
        if skip.exists { capture(app,language+"-replay");skip.tap() }
        XCTAssertTrue(win.waitForExistence(timeout:5));capture(app,language+"-win")
        let shot=String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") }
        app.buttons["openClub"].tap();XCTAssertTrue(app.segmentedControls["clubSections"].waitForExistence(timeout:5))
        capture(app,language+"-puzzles")
        let tabs=app.segmentedControls["clubSections"]
        tabs.buttons[expected[2]].tap()
        let balance=app.staticTexts["gardenBalance"].label
        app.buttons["garden-slot-0"].tap()
        XCTAssertNotEqual(app.staticTexts["gardenBalance"].label,balance)
        XCTAssertTrue(app.buttons["garden-slot-0"].label.contains(expected[4]))
        capture(app,language+"-garden")
        tabs.buttons[expected[3]].tap();XCTAssertTrue(app.staticTexts["quote-shot"].exists)
        capture(app,language+"-quotes");app.buttons["closeClub"].tap()
        XCTAssertEqual(String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") },shot)
        app.buttons["selectCourse"].tap()
        let map=app.buttons.matching(NSPredicate(format:"label CONTAINS %@",expected[5])).firstMatch
        XCTAssertTrue(map.waitForExistence(timeout:3));capture(app,language+"-map-menu");map.tap()
        XCTAssertTrue(String(describing:root.value ?? "").contains("level=02"))
        app.terminate()
    }
    @MainActor func testLanguagePickerLargestTextAndRotation() {
        let app = app("ar", large: true)
        let entry = app.buttons["openLanguage"]; reveal(entry, in: app, up: true); entry.tap()
        XCTAssertTrue(app.cells["language-fr"].waitForExistence(timeout: 5))
        capture(app, "switch-ar-largest-language")
        XCUIDevice.shared.orientation = .landscapeLeft
        let french = app.cells["language-fr"]
        for _ in 0..<5 { if french.isHittable { break }; app.tables.firstMatch.swipeUp() }
        XCTAssertTrue(french.isHittable); french.tap()
        capture(app, "switch-fr-largest-landscape-language")
        XCTAssertTrue(app.buttons["closeLanguage"].isHittable)
        app.buttons["closeLanguage"].tap()
        let classic = app.buttons["chooseMode-classic"]; reveal(classic, in: app, up: true)
        XCTAssertEqual(classic.label, labels["fr"]![0])
        app.terminate(); XCUIDevice.shared.orientation = .portrait
    }
    @MainActor func testInAppLanguageSwitchPreservesGameAndRemembersChoice() {
        let app = app("tr")
        let languageEntry = app.buttons["openLanguage"]
        reveal(languageEntry, in: app, up: true); languageEntry.tap()
        XCTAssertTrue(app.cells["language-ar"].waitForExistence(timeout: 5))
        app.cells["language-ar"].tap()
        let selection = app.otherElements["languageSelection"]
        XCTAssertTrue(String(describing: selection.value ?? "").contains("direction=rtl"))
        capture(app, "switch-ar-language")
        app.buttons["closeLanguage"].tap()
        let classic = app.buttons["chooseMode-classic"]
        reveal(classic, in: app, up: false)
        XCTAssertEqual(classic.label, labels["ar"]![0]); classic.tap()
        let root = app.otherElements["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        capture(app, "switch-ar-course")
        // 小力击球，停稳后记录身份；切换语言不得新建球局。
        let pull = app.descendants(matching: .any)["pullControl"]
        let from = pull.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: 0, dy: 22)))
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = String(describing: root.value ?? "")
            return value.contains("strokes=1") && (value.contains("phase=ready") || value.contains("phase=penalty") || value.contains("phase=success"))
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 12), .completed)
        func identity() -> [String] {
            String(describing: root.value ?? "").split(separator: ";").filter {
                $0.hasPrefix("launch=") || $0.hasPrefix("round=") || $0.hasPrefix("strokes=") || $0.hasPrefix("level=")
            }.map(String.init)
        }
        let before = identity()
        app.buttons["courseOptions"].tap()
        app.buttons["اللغة"].tap()
        XCTAssertTrue(app.cells["language-fr"].waitForExistence(timeout: 5))
        app.cells["language-fr"].tap()
        XCTAssertTrue(String(describing: selection.value ?? "").contains("direction=ltr"))
        capture(app, "switch-fr-language")
        app.buttons["closeLanguage"].tap()
        XCTAssertEqual(identity(), before)
        XCTAssertTrue(String(describing: root.value ?? "").contains("language=fr"))
        capture(app, "switch-fr-course")
        // 同一进程刷新和重启读取使用同一个已保存偏好。
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-language" }
        app.launch()
        XCTAssertTrue(app.buttons["chooseMode-classic"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["chooseMode-classic"].label, labels["fr"]![0])
        let entry = app.buttons["openLanguage"]; reveal(entry, in: app, up: true); entry.tap()
        app.cells["language-system"].tap()
        app.buttons["closeLanguage"].tap()
        let restored = app.buttons["chooseMode-classic"]; reveal(restored, in: app, up: false)
        XCTAssertEqual(restored.label, labels["tr"]![0])
        app.terminate()
    }
    @MainActor func testTurkishExperience() { experience("tr") }
    @MainActor func testArabicExperience() { experience("ar") }
    @MainActor func testPortugueseExperience() { experience("pt") }
    @MainActor func testFrenchExperience() { experience("fr") }
    @MainActor func testSpanishExperience() { experience("es") }

    @MainActor private func largestText(_ language:String) {
        let app=app(language,large:true)
        let privacy=app.buttons["openPrivacy"];reveal(privacy,in:app,up:true);privacy.tap()
        XCTAssertTrue(app.textViews["privacyText"].waitForExistence(timeout:5));capture(app,language+"-largest-privacy")
        XCTAssertTrue(app.buttons["closePrivacy"].isHittable);app.buttons["closePrivacy"].tap()
        let classic=app.buttons["chooseMode-classic"];reveal(classic,in:app,up:false);classic.tap()
        XCTAssertTrue(app.buttons["openClub"].waitForExistence(timeout:5));app.buttons["openClub"].tap()
        app.segmentedControls["clubSections"].buttons[labels[language]![2]].tap()
        let plot=app.buttons["garden-slot-8"];reveal(plot,in:app,up:true);plot.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:3));capture(app,language+"-largest-no-seed-alert")
        app.alerts.buttons[language == "ar" ? "متابعة التصفح":"Continuer à explorer"].tap()
        XCUIDevice.shared.orientation = .landscapeRight
        let close=app.buttons["closeClub"]
        let settled=XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in close.exists && close.isHittable },object:app)
        XCTAssertEqual(XCTWaiter.wait(for:[settled],timeout:5),.completed);capture(app,language+"-largest-landscape")
        app.buttons["closeClub"].tap();XCTAssertTrue(app.buttons["openClub"].waitForExistence(timeout:3))
        XCUIDevice.shared.orientation = .portrait;app.terminate()
    }
    @MainActor func testArabicLargestTextAndLandscape() { largestText("ar") }
    @MainActor func testFrenchLargestTextAndLandscape() { largestText("fr") }

    @MainActor func testArabicChibiAppearanceAndWin() {
        let app=app("ar")
        let chibi=app.buttons["chooseMode-chibi"];reveal(chibi,in:app,up:true);chibi.tap()
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout:5));capture(app,"ar-chibi-course")
        app.buttons["courseOptions"].tap()
        let skins=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","مظهر الكرة")).firstMatch
        XCTAssertTrue(skins.waitForExistence(timeout:3));skins.tap()
        let peach=app.buttons["كرة الخوخ"];XCTAssertTrue(peach.waitForExistence(timeout:3));peach.tap()
        let changed=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value CONTAINS %@","ballSkin=peach"),object:root)
        XCTAssertEqual(XCTWaiter.wait(for:[changed],timeout:3),.completed)
        drag(app)
        let skip=app.buttons["skipReplay"],win=app.buttons["continueAfterWin"]
        let holed=XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in skip.exists || win.exists },object:app)
        XCTAssertEqual(XCTWaiter.wait(for:[holed],timeout:12),.completed)
        if skip.exists { skip.tap() }
        XCTAssertTrue(win.waitForExistence(timeout:5));capture(app,"ar-chibi-win")
        // Foundation 在阿语格式参数外插入方向隔离符；比较完整可见文案，不删除正式输出中的隔离符。
        let titles=app.staticTexts.allElementsBoundByIndex.map { element in
            String(String.UnicodeScalarView(element.label.unicodeScalars.filter { !(0x2066...0x2069).contains($0.value) }))
        }
        XCTAssertTrue(titles.contains("فوز! · وصلنا إلى البيت."),app.debugDescription)
        app.terminate()
    }

    @MainActor func testLanguageChangeKeepsSavedShot() {
        XCUIDevice.shared.orientation = .portrait
        let app=XCUIApplication()
        let base=["--ui-testing","--restore-scene","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]
        app.launchArguments=base+["--fresh-scene","-AppleLanguages","(tr)","-AppleLocale","tr_TR"]
        app.launch()
        let root=app.descendants(matching:.any)["gameArrangement"]
        XCTAssertTrue(root.waitForExistence(timeout:10));drag(app,power:0.2)
        let stopped=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value CONTAINS %@ AND value CONTAINS %@","phase=ready","strokes=1"),object:root)
        XCTAssertEqual(XCTWaiter.wait(for:[stopped],timeout:10),.completed)
        let shot=String(describing:root.value ?? "").split(separator:";").first { $0.hasPrefix("launch=") }
        XCTAssertNotEqual(shot,"launch=none");capture(app,"tr-before-language-change")
        XCUIDevice.shared.press(.home);XCTAssertTrue(app.wait(for:.runningBackground,timeout:5));app.terminate()
        app.launchArguments=base+["-AppleLanguages","(es)","-AppleLocale","es_ES"];app.launch()
        XCTAssertTrue(root.waitForExistence(timeout:10))
        let restored=String(describing:root.value ?? "")
        XCTAssertTrue(restored.contains("language=es"));XCTAssertTrue(restored.contains("strokes=1"))
        XCTAssertEqual(restored.split(separator:";").first { $0.hasPrefix("launch=") },shot)
        XCTAssertTrue(app.staticTexts["Práctica en el césped"].exists)
        capture(app,"es-after-language-change");app.terminate()
    }
}
