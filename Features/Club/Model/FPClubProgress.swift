import Foundation

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
    var garden: [FPFlower?] = Array(repeating:nil,count:FPClubRules.gardenSlots)
    var voice: FPClubVoice = .cozy
    var quotes = Set<FPClubQuote>()
    var best: [String:Int] = [:]
    var mastery = Set<String>()
    // Keep receipts across scene restoration; the scene checkpoint may precede its win.
    var completedRounds = Set<UUID>()
    var plantedCount: Int { garden.compactMap { $0 }.count }
}

/// App-wide collection; live ball/shot state remains scoped to its UISceneSession.
/// All mutations run on the main actor and reload first, so two scenes do not overwrite each other.
@MainActor final class FPClubProgressStore {
    static let key = "FoldPutt.club.progress.v1"
    static let didChange = Notification.Name("FoldPutt.club.didChange")
    private let defaults: UserDefaults?
    private(set) var state = FPClubProgress()
    init(defaults: UserDefaults?) { self.defaults=defaults;reload() }
    func reload() {
        guard let data=defaults?.data(forKey:Self.key),let value=try? JSONDecoder().decode(FPClubProgress.self,from:data),
              value.version == 1,value.seeds>=0,value.garden.count==FPClubRules.gardenSlots,
              value.best.values.allSatisfy({$0>0}) else { return }
        state=value
    }
    private func save() {
        if let data=try? JSONEncoder().encode(state) { defaults?.set(data,forKey:Self.key) }
        NotificationCenter.default.post(name:Self.didChange,object:self)
    }
    @discardableResult func complete(round:UUID,level:FPLevel,strokes:Int,collisions:Int) -> FPClubReward {
        reload()
        guard strokes>0,state.completedRounds.insert(round).inserted else { return FPClubReward(seedGranted:false,newMastery:false) }
        state.seeds += FPClubRules.seedsPerWin
        state.best[level.id]=min(state.best[level.id] ?? Int.max,strokes)
        let mastered=level.isPuzzle && strokes<=level.par && collisions>0
        let newMastery=mastered && state.mastery.insert(level.id).inserted
        save();return FPClubReward(seedGranted:true,newMastery:newMastery)
    }
    func discover(_ quote:FPClubQuote) {
        reload();guard state.quotes.insert(quote).inserted else { return };save()
    }
    func setVoice(_ voice:FPClubVoice) { reload();state.voice=voice;save() }
    @discardableResult func plant(_ flower:FPFlower,at index:Int)->Bool {
        reload();guard state.garden.indices.contains(index),state.garden[index]==nil,state.seeds>0 else { return false }
        state.garden[index]=flower;state.seeds-=1;save();return true
    }
    @discardableResult func uproot(at index:Int)->Bool {
        reload();guard state.garden.indices.contains(index),state.garden[index] != nil else { return false }
        state.garden[index]=nil;state.seeds+=1;save();return true
    }
}
