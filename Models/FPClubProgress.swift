import Foundation

enum FPClubVoice: String, Codable, CaseIterable {
    case silly, cozy, quiet
    var title: String { switch self { case .silly:return "有点皮";case .cozy:return "软乎乎";case .quiet:return "安静打球" } }
}

enum FPFlower: String, Codable, CaseIterable {
    case daisy, tulip, bluebell
    var title: String { switch self { case .daisy:return "小雏菊";case .tulip:return "郁金香";case .bluebell:return "蓝风铃" } }
}

enum FPClubQuote: String, Codable, CaseIterable {
    case shot, collision, nearMiss, water, stopped, win
    var title: String {
        switch self { case .shot:return "小小出发";case .collision:return "借墙一弹";case .nearMiss:return "与洞擦肩";case .water:return "水边散步";case .stopped:return "停下看风景";case .win:return "漂亮到家" }
    }
    func text(_ voice: FPClubVoice) -> String {
        guard voice != .quiet else { return "" }
        let silly = voice == .silly
        switch self {
        case .shot:return silly ? "走你！职业选手气质已上线。":"小小地出发。"
        case .collision:return silly ? "我在测量墙壁。":"叩，借一点墙的力。"
        case .nearMiss:return silly ? "路过，给洞一点心理准备。":"刚刚在叫我吗？"
        case .water:return silly ? "这是我的水下训练计划。":"捡回来啦，再试一次。"
        case .stopped:return silly ? "停这里，主要是看看风景。":"歇一歇，再靠近一点。"
        case .win:return silly ? "计划之内！刚才都是铺垫。":"到家啦，今天也很棒。"
        }
    }
}

enum FPClubRules {
    static let gardenSlots = 9
    static let seedsPerWin = 1
    static let quoteDuration: TimeInterval = 2.4
    static let quoteCooldown: TimeInterval = 1.8
    static let puzzleNames = ["借左墙的力", "转角有光", "穿过窄门", "绕过沙洲", "回廊两侧", "远方的旗"]
    static let puzzleHints = ["先沿左侧借墙，回弹后靠近球洞。", "挡板上方留了一条路，试试先绕到边上。", "先对准中间缺口；一杆过门后，再轻推。", "沙地会减速，绕开沙洲或分两杆前进。", "两面墙之间有路，先决定下一杆停在哪里。", "把整张球场分成几段，先通关，再减少杆数。"]
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
