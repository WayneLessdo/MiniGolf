import Foundation
import Security

enum FPClubVoice: String, Codable, CaseIterable {
    case silly, cozy, quiet
    var title: String { switch self { case .silly:return FPL10n.text("voice_silly");case .cozy:return FPL10n.text("voice_cozy");case .quiet:return FPL10n.text("voice_quiet") } }
}

enum FPFlower: String, Codable, CaseIterable {
    case daisy, tulip, bluebell
    var title: String { switch self { case .daisy:return FPL10n.text("flower_daisy");case .tulip:return FPL10n.text("flower_tulip");case .bluebell:return FPL10n.text("flower_bluebell") } }
}

enum FPClubQuote: String, Codable, CaseIterable {
    case shot, collision, nearMiss, water, stopped, win
    var title: String {
        switch self { case .shot:return FPL10n.text("small_departure");case .collision:return FPL10n.text("bounce");case .nearMiss:return FPL10n.text("near_miss");case .water:return FPL10n.text("water_walk");case .stopped:return FPL10n.text("scenery");case .win:return FPL10n.text("home_beautiful") }
    }
    func text(_ voice: FPClubVoice) -> String {
        guard voice != .quiet else { return "" }
        let silly = voice == .silly
        switch self {
        case .shot:return silly ? FPL10n.text("quote_shot_silly"):FPL10n.text("quote_shot_cozy")
        case .collision:return silly ? FPL10n.text("quote_collision_silly"):FPL10n.text("quote_collision_cozy")
        case .nearMiss:return silly ? FPL10n.text("quote_near_miss_silly"):FPL10n.text("quote_near_miss_cozy")
        case .water:return silly ? FPL10n.text("quote_water_silly"):FPL10n.text("quote_water_cozy")
        case .stopped:return silly ? FPL10n.text("quote_stopped_silly"):FPL10n.text("quote_stopped_cozy")
        case .win:return silly ? FPL10n.text("quote_win_silly"):FPL10n.text("quote_win_cozy")
        }
    }
}

enum FPClubRules {
    static let gardenSlots = 9
    static let seedsPerWin = 1
    static let quoteDuration: TimeInterval = 2.4
    static let quoteCooldown: TimeInterval = 1.8
    static var puzzleNames: [String] { [FPL10n.text("puzzle_name_1"), FPL10n.text("puzzle_name_2"), FPL10n.text("puzzle_name_3"), FPL10n.text("puzzle_name_4"), FPL10n.text("puzzle_name_5"), FPL10n.text("puzzle_name_6")] }
    static var puzzleHints: [String] { [FPL10n.text("puzzle_hint_1"), FPL10n.text("puzzle_hint_2"), FPL10n.text("puzzle_hint_3"), FPL10n.text("puzzle_hint_4"), FPL10n.text("puzzle_hint_5"), FPL10n.text("puzzle_hint_6")] }
}

struct FPClubReward: Codable, Equatable {
    let seedGranted: Bool
    let newMastery: Bool
}

struct FPClubProgress: Codable {
    var version = 1
    var seeds = 0
    var savedPoints: Int?
    var points: Int { savedPoints ?? best.count }
    var garden: [FPFlower?] = Array(repeating:nil,count:FPClubRules.gardenSlots)
    var voice: FPClubVoice = .cozy
    var quotes = Set<FPClubQuote>()
    var best: [String:Int] = [:]
    var mastery = Set<String>()
    // Keep receipts across scene restoration; the scene checkpoint may precede its win.
    var completedRounds = Set<UUID>()
    var plantedCount: Int { garden.compactMap { $0 }.count }
}

/// 可替换存储用于验证迁移、锁定和写入失败；正式环境使用系统 Keychain。
@MainActor protocol FPProgressVault {
    func read() throws -> Data?
    func write(_ data: Data) throws
}

@MainActor struct FPKeychainProgressVault: FPProgressVault {
    let account: String
    init(account: String = "club.progress.v1") { self.account = account }
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.mavericklab.foldputt.progress",
         kSecAttrAccount as String: account]
    }
    func read() throws -> Data? {
        var request = query
        request[kSecReturnData as String] = true; request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return data
    }
    func write(_ data: Data) throws {
        let attributes: [String: Any] = [kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
}

/// App-wide collection; live ball/shot state remains scoped to its UISceneSession.
/// All mutations run on the main actor and reload first, so two scenes do not overwrite each other.
@MainActor final class FPClubProgressStore {
    static let key = "FoldPutt.club.progress.v1"
    static let didChange = Notification.Name("FoldPutt.club.didChange")
    private let defaults: UserDefaults?
    private let vault: (any FPProgressVault)?
    private var committed = FPClubProgress()
    private(set) var persistenceError: Error?
    private(set) var state = FPClubProgress()
    init(defaults: UserDefaults?, vault: (any FPProgressVault)? = nil) {
        self.defaults = defaults
        self.vault = vault ?? (defaults === UserDefaults.standard ? FPKeychainProgressVault() : nil)
        reload()
    }
    func reload() {
        do {
            let secure = try vault?.read()
            guard let data = secure ?? defaults?.data(forKey: Self.key) else { persistenceError = nil; return }
            let value = try JSONDecoder().decode(FPClubProgress.self, from: data)
            guard value.version == 1, value.seeds >= 0, value.points >= 0,
                  value.garden.count == FPClubRules.gardenSlots, value.best.values.allSatisfy({ $0 > 0 }) else {
                throw NSError(domain: "FoldPutt.Progress", code: 1)
            }
            // 只有成功读取“无记录”才迁移，钥匙串锁定/损坏时不能用旧缓存覆盖它。
            if vault != nil && secure == nil { try vault?.write(data) }
            state = value; committed = value; persistenceError = nil
        } catch { persistenceError = error; NSLog("FoldPutt progress read failed: %@", error.localizedDescription) }
    }
    @discardableResult private func save() -> Bool {
        do {
            let data = try JSONEncoder().encode(state)
            try vault?.write(data)
            defaults?.set(data, forKey: Self.key)
            committed = state; persistenceError = nil
            NotificationCenter.default.post(name: Self.didChange, object: self)
            return true
        } catch {
            state = committed; persistenceError = error
            NSLog("FoldPutt progress save failed: %@", error.localizedDescription)
            NotificationCenter.default.post(name: Self.didChange, object: self)
            return false
        }
    }
    @discardableResult func complete(round:UUID,level:FPLevel,strokes:Int,collisions:Int) -> FPClubReward {
        reload()
        guard persistenceError == nil, strokes>0,state.completedRounds.insert(round).inserted else { return FPClubReward(seedGranted:false,newMastery:false) }
        let earned = strokes < level.par ? 3 : strokes == level.par ? 2 : 1
        guard state.points <= Int.max-earned, state.seeds < Int.max else { state = committed; return FPClubReward(seedGranted:false,newMastery:false) }
        state.savedPoints = state.points + earned
        state.seeds += FPClubRules.seedsPerWin
        state.best[level.id]=min(state.best[level.id] ?? Int.max,strokes)
        let mastered=level.isPuzzle && strokes<=level.par && collisions>0
        let newMastery=mastered && state.mastery.insert(level.id).inserted
        guard save() else { return FPClubReward(seedGranted:false,newMastery:false) }
        return FPClubReward(seedGranted:true,newMastery:newMastery)
    }
    func discover(_ quote:FPClubQuote) {
        reload();guard persistenceError == nil, state.quotes.insert(quote).inserted else { return };save()
    }
    func setVoice(_ voice:FPClubVoice) { reload();guard persistenceError == nil else { return };state.voice=voice;save() }
    @discardableResult func plant(_ flower:FPFlower,at index:Int)->Bool {
        reload();guard persistenceError == nil, state.garden.indices.contains(index),state.garden[index]==nil,state.seeds>0 else { return false }
        state.garden[index]=flower;state.seeds-=1;return save()
    }
    @discardableResult func uproot(at index:Int)->Bool {
        reload();guard persistenceError == nil, state.garden.indices.contains(index),state.garden[index] != nil else { return false }
        state.garden[index]=nil;state.seeds+=1;return save()
    }
}
