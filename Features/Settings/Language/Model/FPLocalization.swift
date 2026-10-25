import Foundation
import os

enum FPLanguage: String, CaseIterable {
    case english = "en", simplifiedChinese = "zh-Hans", turkish = "tr", arabic = "ar", portuguese = "pt", french = "fr", spanish = "es"
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .turkish: return "Türkçe"
        case .arabic: return "العربية"
        case .portuguese: return "Português"
        case .french: return "Français"
        case .spanish: return "Español"
        }
    }
}

/// 只保存 App 自身偏好，不改系统 AppleLanguages；空选择表示跟随系统。
final class FPLanguageManager: Sendable {
    static let shared = FPLanguageManager()
    static let didChange = Notification.Name("FoldPutt.languageDidChange")
    private static let bundles: [FPLanguage: Bundle] = Dictionary(uniqueKeysWithValues: FPLanguage.allCases.compactMap { language in
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"), let bundle = Bundle(path: path) else { return nil }
        return (language, bundle)
    })
    private static let preferenceKey = "FoldPutt.language"
    private struct State {
        let defaults: UserDefaults
        var selection: FPLanguage?
    }
    private let state: OSAllocatedUnfairLock<State>
    private let systemPreferences: @Sendable () -> [String]
    var selection: FPLanguage? { state.withLock { $0.selection } }
    init(defaults: UserDefaults = .standard, systemPreferences: @escaping @Sendable () -> [String] = { Locale.preferredLanguages }) {
        self.systemPreferences = systemPreferences
        // UserDefaults 的引用只在锁内访问；状态不会从锁的闭包逃逸。
        state = OSAllocatedUnfairLock(uncheckedState: State(defaults: defaults, selection: defaults.string(forKey: Self.preferenceKey).flatMap(FPLanguage.init(rawValue:))))
    }
    var language: FPLanguage {
        if let selection { return selection }
        let preferences = systemPreferences()
        let supported = FPLanguage.allCases.map(\.rawValue)
        let hasMatch = preferences.contains { preference in supported.contains { preference == $0 || preference.hasPrefix($0 + "-") } }
        guard hasMatch else { return .english }
        let resolved = Bundle.preferredLocalizations(from: supported, forPreferences: preferences).first
        return resolved.flatMap(FPLanguage.init(rawValue:)) ?? .english
    }
    var locale: Locale { Locale(identifier: language.rawValue) }
    var isRightToLeft: Bool { language == .arabic }
    func text(_ key: String) -> String {
        let bundle = Self.bundles[language] ?? .main
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
    @MainActor func select(_ language: FPLanguage?) {
        let changed = state.withLock { state in
            guard language != state.selection else { return false }
            state.selection = language
            if let language { state.defaults.set(language.rawValue, forKey: Self.preferenceKey) }
            else { state.defaults.removeObject(forKey: Self.preferenceKey) }
            return true
        }
        if changed { NotificationCenter.default.post(name: Self.didChange, object: self) }
    }
}

enum FPL10n {
    static var language: String { FPLanguageManager.shared.language.rawValue }
    static var locale: Locale { FPLanguageManager.shared.locale }
    static func text(_ key: String) -> String { FPLanguageManager.shared.text(key) }
    /// 完整句子支持位置占位符，译文可以调整语序。
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }
    static func number(_ value: Int) -> String { value.formatted(.number.grouping(.never).locale(locale)) }
}
