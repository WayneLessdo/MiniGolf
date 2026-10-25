import UIKit

@MainActor final class FPDemoSession {
    enum Phase: String, Codable { case ready, aiming, charging, rolling, sinking, success, penalty, resetting }
    let levels: [FPLevel]
    let club: FPClubProgressStore
    private(set) var roundID = UUID()
    private(set) var clubReward: FPClubReward?
    private(set) var isBrowsingClub = false
    var requestClub: ((FPClubSection) -> Void)?
    var requestLanguage: (() -> Void)?
    private(set) var isChoosingLanguage = false
    func beginLanguageSelection() { suspend(); isChoosingLanguage = true; changed?() }
    func finishLanguageSelection(resumeClock: Bool = true) { isChoosingLanguage = false; if resumeClock { resume() }; changed?() }
    var requestPrivacy: (() -> Void)?
    private(set) var isReadingPrivacy = false
    func beginPrivacy() { suspend();isReadingPrivacy=true;changed?() }
    func finishPrivacy(resumeClock:Bool = true) { isReadingPrivacy=false;if resumeClock { resume() };changed?() }
    private var talkQuote: FPClubQuote?
    private var talkAge: TimeInterval = .greatestFiniteMagnitude
    var ballTalkText: String { talkAge < FPClubRules.quoteDuration ? talkQuote?.text(club.state.voice) ?? "":"" }
    func beginClub() { suspend();isBrowsingClub=true;changed?() }
    func finishClub(resumeClock:Bool = true) { isBrowsingClub=false;if resumeClock { resume() };changed?() }
    func setClubVoice(_ voice:FPClubVoice) {
        club.setVoice(voice);if voice != .quiet { chibiMood=voice == .cozy ? .cozy:.silly };changed?()
    }
    private func recordQuote(_ quote:FPClubQuote) {
        club.discover(quote)
        if talkAge>=FPClubRules.quoteCooldown || quote == .win || quote == .water { talkQuote=quote;talkAge=0 }
    }
    let tuning: FPTuning
    private(set) var regularInput = false
    var inputProfile: FPTuning.Input { regularInput ? tuning.regular:tuning.compact }
    func setRegularInput(_ regular: Bool) { regularInput=regular }
    private(set) var levelIndex = 0
    var level: FPLevel { levels[levelIndex] }
    private(set) var world: FPPhysicsWorld
    private let recorder: FPPhysicsPort?
    private(set) var lastLaunch: FPLaunch?
    private(set) var phase: Phase = .ready
    private(set) var strokes = 0
    private(set) var stars = 0
    private(set) var boostSeconds: TimeInterval = 0
    var speedLineReward: Bool { boostSeconds > 0 }
    private(set) var prediction: [CGPoint] = []
    private(set) var boostCounts: [String:Int] = [:]
    private let metricsStore: UserDefaults?
    private var metricsKey: String { "FoldPutt.tuning."+tuning.variant }
    private(set) var penaltyActive = false
    private(set) var collisions = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var lastEvent = "tee-off"
    private(set) var eventAge: TimeInterval = 0
    private(set) var eventSerial = 0
    private(set) var eventPosition = CGPoint.zero
    private(set) var events: [[String: String]] = []
    var ball: CGPoint { normalized(world.position) }
    var start: CGPoint { normalized(level.start.cg) }
    var hole: CGPoint { normalized(level.hole.cg) }
    var preview: FPShot?
    var handheld = false
    var immersivePreference: Bool?
    var showRegions = false
    private(set) var gameMode: FPGameMode = .classic
    private(set) var chibiMood: FPChibiMood = .cozy
    private(set) var ballSkin: FPBallSkin = .rice
    private(set) var chibiFeedback = FPChibiFeedback()
    private(set) var isChoosingMode = false
    var requestModeSelection: (() -> Void)?
    var isChibi: Bool { gameMode == .chibi }
    func setPresentation(mode: FPGameMode, mood: FPChibiMood? = nil, skin: FPBallSkin? = nil) {
        cancel();gameMode=mode
        world.naturalFlight = mode == .classic && !level.isPuzzle
        if let mood { chibiMood=mood;club.setVoice(mood == .cozy ? .cozy:.silly) };if let skin { ballSkin=skin }
        changed?()
    }
    func beginModeSelection() { suspend();isChoosingMode=true }
    func finishModeSelection(_ mode: FPGameMode) { setPresentation(mode:mode);isChoosingMode=false;resume();changed?() }
    var chibiWinTitle: String {
        if chibiMood == .silly { return collisions>0 ? FPL10n.text("planned"):FPL10n.text("off_work") }
        return strokes<=level.par ? FPL10n.text("home"):FPL10n.text("quote_win_detour")
    }
    private(set) var restorationCount = 0
    private var restoredCheckpoint: UUID?
    var restorationNotice: String?
    var changed: (() -> Void)?
    var eventObserved: ((String) -> Void)?
    private var link: CADisplayLink?
    private var clock: CFTimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var stageRemaining: TimeInterval = 0
    private var pendingPenalty = false
    private var pendingCanal: CGRect?
    private var pendingReservedBanks:[CGRect]?
    private var observedDivision: (CGRect?, CGRect)?
    private var cueIdentifier: String?
    private var suspended = false
    private(set) var trail: [CGPoint] = []
    struct ReplaySample: Codable {
        let time: TimeInterval
        let point: CGPoint
    }
    private(set) var shotReplay: [ReplaySample] = []
    private(set) var shotTime: TimeInterval = 0
    private(set) var replayElapsed: TimeInterval?
    private(set) var replayStatic = false
    var isReplaying: Bool { replayElapsed != nil }
    var canContinueAfterWin: Bool { phase == .success && !isReplaying }
    var replayDuration: TimeInterval {
        replayStatic ? FPMotion.replayStaticHold : (shotReplay.last?.time ?? 0)/FPMotion.replaySpeed + FPMotion.success
    }
    var replayTime: TimeInterval { replayStatic ? shotTime : min(shotTime,(replayElapsed ?? 0)*FPMotion.replaySpeed) }
    func finishReplay() { guard isReplaying else { return };replayElapsed=nil;changed?() }
    func updateMotionPreference(reduced:Bool = FPMotion.reduced) {
        if reduced,isReplaying { replayStatic=true;replayElapsed=0 }
        changed?()
    }
    private func recordReplay(force:Bool=false) {
        guard force || shotTime-(shotReplay.last?.time ?? 0)>=FPMotion.replaySampleInterval else { return }
        if shotReplay.count>=512 { shotReplay=shotReplay.enumerated().filter { $0.offset.isMultiple(of:2) }.map(\.element) }
        shotReplay.append(ReplaySample(time:shotTime,point:world.position))
    }
    private var target: FPDisplayLinkTarget?
    #if DEBUG
    private(set) var captureScenario: String?
    private var captureDeadline: TimeInterval = 0
    var captureReady: ((String) -> Void)?
    private var capturedFixture = false
    #endif

    init(physics: FPPhysicsPort? = nil, levels: [FPLevel]? = nil, tuning: FPTuning? = nil, metricsStore: UserDefaults? = .standard) throws {
        let loaded = try levels ?? FPLevel.loadAll()
        guard !loaded.isEmpty else { throw NSError(domain:"FoldPutt.Level",code:3) }
        let settings=try tuning ?? FPTuning.load()
        self.tuning=settings;self.metricsStore=metricsStore;self.club=FPClubProgressStore(defaults:metricsStore)
        boostCounts=metricsStore?.dictionary(forKey:"FoldPutt.tuning."+settings.variant) as? [String:Int] ?? [:]
        self.levels=loaded;world=FPPhysicsWorld(level:loaded[0],tuning:settings.physics);world.naturalFlight = !loaded[0].isPuzzle;recorder=physics
    }
    func normalized(_ p: CGPoint) -> CGPoint { CGPoint(x:p.x,y:p.y/FPLevel.world.height) }
    var canAim: Bool { !isChoosingMode && !isBrowsingClub && !isReadingPrivacy && !isChoosingLanguage && (phase == .ready || phase == .aiming || phase == .charging || phase == .penalty) }
    var status: String {
        if let restorationNotice { return restorationNotice }
        switch phase {
        case .ready:return speedLineReward ? FPL10n.format("prediction_ready",FPL10n.number(Int(ceil(boostSeconds)))):FPL10n.text("pull_hint")
        case .aiming:return FPL10n.text("pull_direction")
        case .charging:return FPL10n.format("release_power",FPL10n.number(Int((preview?.power ?? 0)*100)))
        case .rolling:return lastEvent == "canal-collision" && eventAge < 1 ? FPL10n.text("level_name_2"):FPL10n.text("ball_rolling")
        case .sinking:return FPL10n.text("holed")
        case .success:if isReplaying { return FPL10n.text("replay_title") };return FPL10n.format("win_stars",FPL10n.number(stars))
        case .penalty:return FPL10n.text("penalty_hint")
        case .resetting:return FPL10n.text("out_of_bounds")
        }
    }
    func startClock() {
        guard link == nil else { return }
        let target=FPDisplayLinkTarget { [weak self] in self?.tick() };self.target=target
        link=CADisplayLink(target:target,selector:#selector(FPDisplayLinkTarget.step));clock=CACurrentMediaTime()
        link?.add(to:.main,forMode:.common)
    }
    private func tick() {
        let now=CACurrentMediaTime(),delta=min(0.10,max(0,now-clock));clock=now
        guard !suspended else { return }
        accumulator += delta
        while accumulator >= 1.0/120 { advance(1.0/120);accumulator -= 1.0/120 }
        changed?()
    }
    var aimingBegan: (() -> Void)?
    func aim(_ shot: FPShot?) {
        guard canAim else { return }
        if phase != .aiming && phase != .charging { aimingBegan?() }
        restorationNotice=nil
        preview=shot;phase=shot == nil ? .aiming:.charging;updatePrediction();changed?()
    }
    func cancel() {
        guard phase == .aiming || phase == .charging else { return }
        preview=nil;prediction=[];phase=penaltyActive ? .penalty:.ready;changed?()
    }
    func release(_ shot: FPShot?) {
        guard phase == .aiming || phase == .charging else { return }
        guard let shot, shot.power.isFinite,shot.power>0,
              shot.direction.dx.isFinite,shot.direction.dy.isFinite else { cancel();return }
        if let pendingCanal { world.updateCanal(pendingCanal) }
        if let pendingReservedBanks { world.updateReservedBanks(pendingReservedBanks) }
        let launch=FPLaunch(shot:shot,maximumSpeed:tuning.physics.maximumSpeed)
        guard hypot(launch.velocity.dx,launch.velocity.dy)>0 else { cancel();return }
        if speedLineReward { boostSeconds=0;prediction=[];recordBoost("uses");emit("boost-used") }
        strokes += 1;lastLaunch=launch;recorder?.launch(launch);world.launch(launch)
        phase = .rolling;preview=nil;trail=[];shotTime=0;shotReplay=[ReplaySample(time:0,point:world.position)];replayElapsed=nil;emit("shot");changed?()
    }
    func updateDivision(_ rect: CGRect?, field: CGRect) {
        observedDivision=(rect,field)
        let proposed=FPCanalMapping.collider(division:rect,field:field,fallback:level.canal.cg)
        pendingCanal=proposed
        // Freeze the bank for the entire shot and all active aiming gestures.
        if phase == .ready || phase == .penalty { world.updateCanal(proposed) }
    }
    func updateReservedBanks(_ banks:[CGRect]) {
        pendingReservedBanks=banks
        if phase == .ready || phase == .penalty { world.updateReservedBanks(banks) }
    }
    func advance(_ dt: TimeInterval) {
        guard !suspended,dt.isFinite,dt>0 else { return }
        eventAge += dt;talkAge=min(FPClubRules.quoteDuration+1,talkAge+dt)
        if let age=replayElapsed {
            if FPMotion.reduced && !replayStatic { replayStatic=true;replayElapsed=0 }
            else { replayElapsed=age+dt }
            if (replayElapsed ?? 0)>=replayDuration { replayElapsed=nil }
        }
        if boostSeconds>0 {
            boostSeconds=max(0,boostSeconds-dt)
            if boostSeconds == 0 { prediction=[];recordBoost("expired");emit("boost-expired") }
        }
        if phase != .success && phase != .sinking { elapsed += dt }
        if !penaltyActive && elapsed >= level.timeLimit { pendingPenalty=true }
        if phase == .rolling {
            let oldPosition=world.position
            let result=world.step(dt)
            shotTime += dt;recordReplay(force:!result.isEmpty)
            if hypot(world.position.x-oldPosition.x,world.position.y-oldPosition.y)>0.0001 {
                trail.append(world.position);if trail.count>48 { trail.removeFirst() }
            }
            for event in result {
                switch event {
                case .collision(let id):
                    collisions += 1;emit(id == "canal" || id.hasPrefix("division-") ? "canal-collision":"collision")
                    if !penaltyActive && collisions>=level.collisionLimit { pendingPenalty=true }
                case .outOfBounds:phase = .resetting;stageRemaining=0.8;emit("out-of-bounds")
                case .stopped:phase=penaltyActive ? .penalty:.ready;emit("stopped")
                case .captured:phase = .sinking;stageRemaining=0.22;pendingPenalty=false;emit("hole-capture")
                }
            }
        } else if phase == .sinking {
            stageRemaining=max(0,stageRemaining-dt)
            if stageRemaining <= 0 {
                phase = .success;stars=strokes<level.par ? 3:strokes==level.par ? 2:1
                boostSeconds=0;prediction=[]
                if strokes == 1,shotReplay.count>1 { replayElapsed=0;replayStatic=FPMotion.reduced }
                clubReward=club.complete(round:roundID,level:level,strokes:strokes,collisions:collisions)
                emit("hole-success")
            }
        } else if phase == .resetting {
            stageRemaining=max(0,stageRemaining-dt)
            if stageRemaining<=0 { phase=penaltyActive ? .penalty:.ready }
        }
        if pendingPenalty && (phase == .ready || phase == .penalty) {
            penaltyActive=true;pendingPenalty=false
            _ = world.addPenaltyObstacle();phase = .penalty;emit("penalty")
        }
        let previousNearMisses=chibiFeedback.nearMissCount
        chibiFeedback.advance(dt,position:world.position,hole:level.hole.cg,captureRadius:CGFloat(level.captureRadius),
                              rolling:phase == .rolling,inSand:level.sand.contains { $0.cg.contains(world.position) })
        if chibiFeedback.nearMissCount>previousNearMisses { recordQuote(.nearMiss) }
        #if DEBUG
        if let captureScenario, !capturedFixture {
            captureDeadline -= dt
            if ["tee-off","aiming","strong-pull","swing","seam-crossing"].contains(captureScenario),captureDeadline<=0 {
                finishFixture(captureScenario)
            }
            if captureScenario == "near-miss",chibiFeedback.visibleCue == .nearMiss { finishFixture(captureScenario) }
            if captureScenario == "sand",chibiFeedback.visibleCue == .sand { finishFixture(captureScenario) }
        }
        #endif
    }
    private func emit(_ event: String) {
        switch event {
        case "shot":recordQuote(.shot)
        case "collision","canal-collision":recordQuote(.collision)
        case "out-of-bounds":recordQuote(.water)
        case "stopped":recordQuote(.stopped)
        case "hole-success":recordQuote(.win)
        default:break
        }
        lastEvent=event;eventAge=0;eventSerial += 1;eventPosition=world.position
        chibiFeedback.receive(event,serial:eventSerial,position:world.position,direction:preview?.direction ?? lastLaunch.map { CGVector(dx:$0.velocity.dx,dy:-$0.velocity.dy) })
        events.append(["event":event,"level":level.id,"stroke":String(strokes),"time":String(format:"%.3f",elapsed)])
        if events.count>100 { events.removeFirst() }
        eventObserved?(event)
        #if DEBUG
        if !capturedFixture,captureScenario == "boost",event == "hole-success" {
            DispatchQueue.main.asyncAfter(deadline:.now()+0.9) { [weak self] in
                guard let self,self.captureScenario == "boost",self.phase == .success else { return }
                self.reset();self.captureScenario="boost"
                self.aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55))
                DispatchQueue.main.asyncAfter(deadline:.now()+0.75) { [weak self] in self?.finishFixture("boost") }
            }
        }
        if !capturedFixture, let wanted=captureScenario,
           (wanted == event || (wanted == "penalty" && event == "penalty") || (wanted == "seam-collision" && event == "canal-collision")) { finishFixture(wanted) }
        #endif
    }
    func reset() {
        let earned=phase == .success && stars>=tuning.boost.requiredStars
        loadLevel(levelIndex)
        if earned {
            boostSeconds=tuning.boost.duration;recordBoost("triggers");emit("boost-granted");changed?()
        }
    }
    private func recordBoost(_ name: String) {
        boostCounts[name,default:0] += 1
        metricsStore?.set(boostCounts,forKey:metricsKey)
    }
    private func updatePrediction() {
        prediction=[]
        guard speedLineReward,let preview else { return }
        var copy=world
        if let pendingCanal { copy.updateCanal(pendingCanal) }
        if let pendingReservedBanks { copy.updateReservedBanks(pendingReservedBanks) }
        copy.launch(FPLaunch(shot:preview,maximumSpeed:tuning.physics.maximumSpeed))
        prediction=[copy.position]
        for _ in 0..<Int(tuning.boost.predictionSeconds/tuning.boost.predictionStep) {
            let events=copy.step(tuning.boost.predictionStep)
            prediction.append(copy.position)
            if events.contains(.outOfBounds) || events.contains(.captured) || !copy.moving { break }
        }
    }
    func loadLevel(_ index: Int) {
        guard levels.indices.contains(index) else { return }
        suspended=isChoosingLanguage || isBrowsingClub || isReadingPrivacy || isChoosingMode;restorationNotice=nil
        roundID=UUID();clubReward=nil;talkQuote=nil;talkAge = .greatestFiniteMagnitude
        #if DEBUG
        captureScenario=nil;capturedFixture=false
        #endif
        levelIndex=index;world=FPPhysicsWorld(level:level,tuning:tuning.physics);world.naturalFlight = gameMode == .classic && !level.isPuzzle;strokes=0;stars=0;boostSeconds=0;prediction=[]
        preview=nil;phase = .ready;penaltyActive=false;pendingPenalty=false;collisions=0;elapsed=0;stageRemaining=0
        pendingCanal=nil;pendingReservedBanks=nil;lastLaunch=nil;trail=[];shotReplay=[];shotTime=0;replayElapsed=nil;replayStatic=false;accumulator=0;cueIdentifier=UUID().uuidString
        if let (division,field)=observedDivision { updateDivision(division,field:field) }
        emit("tee-off");changed?()
    }
    var levelActions: [UIAction] {
        levels.enumerated().map { index, level in
            UIAction(title:FPL10n.format("map_title",FPL10n.number(index+1),level.localizedName),subtitle:level.mapDescription,image:UIImage(systemName:level.mapSymbol),state:levelIndex == index ? .on:.off) { [weak self] _ in self?.loadLevel(index) }
        }
    }
    func continueAfterWin() {
        guard canContinueAfterWin else { return }
        nextLevel()
    }
    func nextLevel() {
        let family=levels.indices.filter { levels[$0].isPuzzle == level.isPuzzle }
        guard let current=family.firstIndex(of:levelIndex),!family.isEmpty else { return }
        loadLevel(family[(current+1)%family.count])
    }
    func suspend() { cancel();suspended=true }
    func resume() { guard !isChoosingMode,!isBrowsingClub,!isReadingPrivacy,!isChoosingLanguage else { return };suspended=false;clock=CACurrentMediaTime() }
    var teeID: String { level.id + (cueIdentifier ?? "initial") }

    // Only UIKit session state is persisted. No global scene/window lookup is needed.
    struct Snapshot: Codable {
        let version: Int
        let checkpoint: UUID
        let variant: String
        let levelID: String
        let world: FPPhysicsWorld
        let launch: FPLaunch?
        let phase: Phase
        let strokes: Int
        let stars: Int
        let boostSeconds: TimeInterval
        let boostCounts: [String:Int]
        let penaltyActive: Bool
        let collisions: Int
        let elapsed: TimeInterval
        let accumulator: TimeInterval
        let stageRemaining: TimeInterval
        let pendingPenalty: Bool
        let handheld: Bool
        let immersivePreference: Bool?
        let cueIdentifier: String?
        // Optional additions keep existing v1 snapshots readable.
        let gameMode: FPGameMode?
        let chibiMood: FPChibiMood?
        let ballSkin: FPBallSkin?
        let shotReplay: [ReplaySample]?
        let shotTime: TimeInterval?
        let replayElapsed: TimeInterval?
        let replayStatic: Bool?
        let roundID: UUID?
        let clubReward: FPClubReward?
    }
    static let restorationType="com.foldputt.scene.game.v1"
    func restorationActivity() throws -> NSUserActivity {
        let savedPhase:Phase = phase == .aiming || phase == .charging ? (penaltyActive ? .penalty:.ready):phase
        let snapshot=Snapshot(version:1,checkpoint:UUID(),variant:tuning.variant,levelID:level.id,world:world,launch:lastLaunch,
                              phase:savedPhase,strokes:strokes,stars:stars,boostSeconds:boostSeconds,boostCounts:boostCounts,
                              penaltyActive:penaltyActive,collisions:collisions,elapsed:elapsed,accumulator:accumulator,
                              stageRemaining:stageRemaining,pendingPenalty:pendingPenalty,handheld:handheld,immersivePreference:immersivePreference,cueIdentifier:cueIdentifier,
                              gameMode:gameMode,chibiMood:chibiMood,ballSkin:ballSkin,shotReplay:shotReplay,shotTime:shotTime,replayElapsed:replayElapsed,replayStatic:replayStatic,roundID:roundID,clubReward:clubReward)
        let activity=NSUserActivity(activityType:Self.restorationType)
        activity.title=FPL10n.text("current_game")
        activity.isEligibleForHandoff=false;activity.isEligibleForSearch=false;activity.isEligibleForPublicIndexing=false
        activity.userInfo=["snapshot":try JSONEncoder().encode(snapshot)]
        return activity
    }
    @discardableResult func restore(_ activity:NSUserActivity) throws -> Bool {
        guard activity.activityType == Self.restorationType,let data=activity.userInfo?["snapshot"] as? Data,data.count<=65_536
        else { throw NSError(domain:"FoldPutt.Restoration",code:1) }
        let saved=try JSONDecoder().decode(Snapshot.self,from:data)
        let encoder=JSONEncoder();encoder.outputFormatting = [.sortedKeys]
        guard saved.version==1,saved.variant==tuning.variant,let index=levels.firstIndex(where:{$0.id==saved.levelID}),
              try encoder.encode(saved.world.level)==encoder.encode(levels[index]),
              try encoder.encode(saved.world.tuning)==encoder.encode(tuning.physics),
              saved.strokes>=0,saved.collisions>=0,(0...3).contains(saved.stars),
              saved.boostCounts.keys.allSatisfy({["triggers","uses","expired"].contains($0)}),saved.boostCounts.values.allSatisfy({$0>=0}),
              [saved.elapsed,saved.boostSeconds,saved.accumulator,saved.stageRemaining].allSatisfy({$0.isFinite && $0>=0}),
              saved.boostSeconds<=tuning.boost.duration,saved.accumulator<1.0/120+0.000001,saved.stageRemaining<=1,
              saved.phase != .aiming,saved.phase != .charging,
              (saved.phase == .sinking || saved.phase == .success) == saved.world.captured,
              (saved.phase == .rolling) == saved.world.moving,
              saved.phase != .rolling || (saved.strokes>0 && saved.launch != nil)
        else { throw NSError(domain:"FoldPutt.Restoration",code:3,userInfo:[NSLocalizedDescriptionKey:FPL10n.text("error_snapshot_version")]) }
        if let launch=saved.launch {
            guard [launch.power,launch.angle,launch.velocity.dx,launch.velocity.dy].allSatisfy(\.isFinite),
                  (0...1).contains(launch.power),hypot(launch.velocity.dx,launch.velocity.dy)<=tuning.physics.maximumSpeed+0.000001
            else { throw NSError(domain:"FoldPutt.Restoration",code:4) }
        }
        let samples=saved.shotReplay ?? []
        guard samples.count<=512,(saved.shotTime ?? 0).isFinite,(saved.shotTime ?? 0)>=0,
              samples.allSatisfy({ $0.time.isFinite && $0.time>=0 && $0.time<=(saved.shotTime ?? 0) && FPLevel.world.contains($0.point) }),
              zip(samples,samples.dropFirst()).allSatisfy({ $0.time <= $1.time }),
              saved.replayElapsed == nil || (saved.phase == .success && saved.strokes == 1 && samples.count>1 && saved.replayElapsed!.isFinite && saved.replayElapsed!>=0 && saved.replayElapsed!<=(saved.shotTime ?? 0)/FPMotion.replaySpeed+FPMotion.success)
        else { throw NSError(domain:"FoldPutt.Restoration",code:5) }
        try saved.world.validateRestoration()
        if restoredCheckpoint == saved.checkpoint { return false }
        // Validation is complete before any live state changes; no launch/reward event is replayed.
        roundID=saved.roundID ?? UUID();clubReward=saved.clubReward;talkQuote=nil;talkAge = .greatestFiniteMagnitude
        levelIndex=index;world=saved.world;lastLaunch=saved.launch;phase=saved.phase
        strokes=saved.strokes;stars=saved.stars;boostSeconds=saved.boostSeconds;boostCounts=saved.boostCounts
        penaltyActive=saved.penaltyActive;collisions=saved.collisions;elapsed=saved.elapsed
        accumulator=saved.accumulator;stageRemaining=saved.stageRemaining;pendingPenalty=saved.pendingPenalty
        handheld=saved.handheld;immersivePreference=saved.immersivePreference;cueIdentifier=saved.cueIdentifier;preview=nil;prediction=[];trail=[]
        gameMode=saved.gameMode ?? .classic;chibiMood=saved.chibiMood ?? .cozy;ballSkin=saved.ballSkin ?? .rice;chibiFeedback=FPChibiFeedback()
        pendingCanal=nil;pendingReservedBanks=nil;observedDivision=nil;restoredCheckpoint=saved.checkpoint;restorationCount += 1
        shotReplay=samples;shotTime=saved.shotTime ?? 0;replayElapsed=saved.replayElapsed;replayStatic=saved.replayStatic ?? false
        lastEvent="scene-restored";clock=CACurrentMediaTime();restorationNotice=nil
        changed?();return true
    }
    func stopClock() { link?.invalidate();link=nil;target=nil;clock=0 }

    #if DEBUG
    /// Test-only starting positions; every terminal state is produced by the actual world/rules.
    func prepareCapture(_ scenario: String, level index: Int) {
        loadLevel(index);captureScenario=scenario;capturedFixture=false;captureDeadline = .greatestFiniteMagnitude
        // Let the real 0.6s turf / 0.4s flag sequence finish before staging a physics event.
        DispatchQueue.main.asyncAfter(deadline:.now()+0.75) { [weak self] in
            guard let self,self.captureScenario == scenario else { return }
            self.stageCapture(scenario)
        }
    }
    private func stageCapture(_ scenario: String) {
        captureDeadline=0.12
        switch scenario {
        case "aiming":aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55))
        case "strong-pull":aim(FPShot(direction:CGVector(dx:0.1,dy:-0.995),power:0.9))
        case "swing":
            aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));release(preview);captureDeadline=0.075
        case "near-miss":
            world.stage(at:CGPoint(x:level.hole.cg.x+CGFloat(level.captureRadius)*1.25,y:level.hole.cg.y+0.17))
            aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.6));release(preview)
        case "sand":
            let patch=level.sand[0].cg
            world.stage(at:CGPoint(x:patch.midX,y:patch.maxY+0.06))
            aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.4));release(preview)
        case "hole-success", "boost":
            world.stage(at:CGPoint(x:level.hole.cg.x,y:level.hole.cg.y+0.14))
            aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.28));release(preview)
        case "seam-crossing", "seam-collision":
            guard let bank=world.divisionBanks?.first else { finishFixture("missing-division");return }
            let x:CGFloat=scenario == "seam-crossing" ? 0.5:bank.midX
            world.stage(at:CGPoint(x:x,y:bank.maxY+0.14))
            aim(FPShot(direction:CGVector(dx:0,dy:-1),power:0.55));release(preview)
            captureDeadline=0.25
        case "out-of-bounds":
            let h=level.hazards[0].cg
            world.stage(at:CGPoint(x:h.minX-0.08,y:h.midY))
            aim(FPShot(direction:CGVector(dx:1,dy:0),power:0.6));release(preview)
        case "canal-collision":
            let bank=world.canal
            if bank.height>bank.width {
                world.stage(at:CGPoint(x:bank.maxX+0.1,y:bank.midY))
                aim(FPShot(direction:CGVector(dx:-1,dy:0),power:0.5))
            } else {
                let fromBelow=bank.midY<FPLevel.world.midY
                world.stage(at:CGPoint(x:bank.midX,y:fromBelow ? bank.maxY+0.1:bank.minY-0.1))
                aim(FPShot(direction:CGVector(dx:0,dy:fromBelow ? -1:1),power:0.5))
            }
            release(preview)
        case "penalty":elapsed=level.timeLimit-0.05
        default:break
        }
    }
    private func finishFixture(_ event: String) {
        guard !capturedFixture else { return }
        capturedFixture=true;suspended=true
        changed?()
        captureReady?(event)
    }
    #endif
}

@MainActor private final class FPDisplayLinkTarget: NSObject {
    let callback: () -> Void
    init(_ callback: @escaping () -> Void) { self.callback=callback }
    @objc func step() { callback() }
}
