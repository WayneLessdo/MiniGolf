import XCTest
@testable import FoldPutt

final class FPLocalizationTests: XCTestCase {
    func testRegionalPreferencesResolveToRequestedBaseLanguages() {
        let languages=["zh-Hans","en","tr","ar","pt","fr","es"]
        for (preference,base) in [("tr-TR","tr"),("ar-SA","ar"),("pt-BR","pt"),("pt-PT","pt"),("fr-CA","fr"),("es-MX","es")] {
            XCTAssertEqual(Bundle.preferredLocalizations(from:languages,forPreferences:[preference]).first,base)
        }
    }
    func testAllCompiledLanguagesHaveCompleteFormatSafeResources() throws {
        let languages=["zh-Hans","en","tr","ar","pt","fr","es"]
        var source:[String:String]=[:]
        let expression=try NSRegularExpression(pattern:"%(?:(\\d+)\\$)?@")
        func slots(_ value:String)->[Int] {
            let value=value.replacingOccurrences(of:"%%",with:"") as NSString
            return expression.matches(in:value as String,range:NSRange(location:0,length:value.length)).enumerated().map { index,match in
                match.range(at:1).location == NSNotFound ? index+1:Int(value.substring(with:match.range(at:1)))!
            }.sorted()
        }
        for language in languages {
            let directory=try XCTUnwrap(Bundle.main.url(forResource:language,withExtension:"lproj"),language)
            let data=try Data(contentsOf:directory.appendingPathComponent("Localizable.strings"))
            let strings=try XCTUnwrap(PropertyListSerialization.propertyList(from:data,format:nil) as? [String:String])
            if language == "zh-Hans" { source=strings;XCTAssertGreaterThan(strings.count,180) }
            XCTAssertEqual(Set(strings.keys),Set(source.keys),language)
            for (key,value) in strings {
                XCTAssertFalse(value.isEmpty,"\(language): \(key)")
                XCTAssertEqual(slots(value),slots(source[key] ?? ""),"\(language): \(key)")
                if language != "zh-Hans" {
                    XCTAssertNil(value.range(of:"[\\p{Han}]",options:.regularExpression),"\(language): \(key)")
                }
                let count=slots(value).max() ?? 0
                if count>0 {
                    let arguments=(1...count).map { "ARG\($0)" as CVarArg }
                    let result=String(format:value,locale:Locale(identifier:language),arguments:arguments)
                    for index in 1...count { XCTAssertTrue(result.contains("ARG\(index)"),"\(language): \(key)") }
                    XCTAssertFalse(result.contains("%@"))
                }
            }
            let policy=try XCTUnwrap(strings["privacy_policy_body"])
            XCTAssertTrue(policy.contains("waynelessdo@gmail.com"));XCTAssertTrue(policy.contains("Wayne"))
            XCTAssertFalse(policy.contains("@qq.com"))
        }
    }

    @MainActor func testManualLanguagePersistsAndSystemDefaultCanBeRestored() throws {
        let suite = "FoldPutt.language.test." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = FPLanguageManager(defaults: defaults, systemPreferences: { ["fr-CA"] })
        XCTAssertNil(manager.selection); XCTAssertEqual(manager.language, .french)
        let originalSystemLanguages = defaults.object(forKey: "AppleLanguages") as? [String]
        manager.select(.arabic)
        XCTAssertTrue(manager.isRightToLeft)
        XCTAssertEqual(manager.text("settings_language"), "اللغة")
        XCTAssertEqual(defaults.object(forKey: "AppleLanguages") as? [String], originalSystemLanguages)
        let relaunched = FPLanguageManager(defaults: defaults, systemPreferences: { ["tr-TR"] })
        XCTAssertEqual(relaunched.selection, .arabic)
        relaunched.select(nil)
        XCTAssertEqual(relaunched.language, .turkish); XCTAssertFalse(relaunched.isRightToLeft)
        XCTAssertNil(FPLanguageManager(defaults: defaults).selection)
    }
    @MainActor func testEnglishSelectionAndUnsupportedSystemFallback() throws {
        let name = "FoldPutt.English." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let manager = FPLanguageManager(defaults: defaults, systemPreferences: { ["en-US"] })
        XCTAssertEqual(manager.language, .english)
        XCTAssertEqual(manager.text("settings_language"), "Language")
        manager.select(.english)
        XCTAssertEqual(FPLanguageManager(defaults: defaults, systemPreferences: { ["ar-SA"] }).language, .english)
        manager.select(nil)
        XCTAssertEqual(FPLanguageManager(defaults: defaults, systemPreferences: { ["ja-JP"] }).language, .english)
        XCTAssertEqual(FPLanguageManager(defaults: defaults, systemPreferences: { ["de-DE", "pt-BR"] }).language, .portuguese)
    }

    @MainActor func testLanguagePickerPausesPhysicsAndKeepsRoundAndLaunch() throws {
        let session = try FPDemoSession(metricsStore: nil)
        session.aim(FPShot(direction: CGVector(dx: 0, dy: -1), power: 0.2))
        session.release(FPShot(direction: CGVector(dx: 0, dy: -1), power: 0.2))
        session.advance(0.1)
        let position = session.world.position, round = session.roundID, launch = session.lastLaunch?.id
        let strokes = session.strokes
        session.beginLanguageSelection(); session.resume(); session.advance(1)
        XCTAssertFalse(session.canAim); XCTAssertTrue(session.isChoosingLanguage)
        XCTAssertEqual(session.world.position, position)
        XCTAssertEqual(session.roundID, round); XCTAssertEqual(session.lastLaunch?.id, launch)
        XCTAssertEqual(session.strokes, strokes)
        session.finishLanguageSelection(resumeClock: false); session.advance(1)
        XCTAssertEqual(session.world.position, position)
        session.resume(); session.advance(0.1)
        XCTAssertNotEqual(session.world.position, position)
        XCTAssertEqual(session.roundID, round); XCTAssertEqual(session.strokes, strokes)
    }

    @MainActor func testLocalizedDisplayDoesNotChangeLevelIdentityOrSavedProgress() throws {
        let session=try FPDemoSession(metricsStore:nil)
        let ids=session.levels.map(\.id),names=session.levels.map(\.name)
        session.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2))
        session.release(FPShot(direction:CGVector(dx:0,dy:-1),power:0.2));session.advance(0.1)
        let activity=try session.restorationActivity()
        let restored=try FPDemoSession(metricsStore:nil);try restored.restore(activity)
        XCTAssertEqual(restored.levels.map(\.id),ids);XCTAssertEqual(restored.levels.map(\.name),names)
        XCTAssertEqual(restored.strokes,1);XCTAssertEqual(restored.world.position,session.world.position)
        XCTAssertEqual(restored.lastLaunch?.id,session.lastLaunch?.id)
    }
}
