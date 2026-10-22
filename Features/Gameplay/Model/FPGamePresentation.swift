import UIKit

enum FPGameMode: String, Codable, CaseIterable {
    case classic, chibi
    var title: String { self == .classic ? FPL10n.text("mode_classic") : FPL10n.text("mode_chibi") }
}

enum FPChibiMood: String, Codable, CaseIterable {
    case cozy, silly
    var title: String { self == .cozy ? FPL10n.text("voice_cozy") : FPL10n.text("voice_silly") }
}

enum FPBallSkin: String, Codable, CaseIterable {
    case rice, peach, sesame
    var title: String {
        switch self { case .rice: return FPL10n.text("skin_rice"); case .peach: return FPL10n.text("skin_peach"); case .sesame: return FPL10n.text("skin_sesame") }
    }
}

/// Presentation only. These values never enter FPPhysicsWorld or reward calculations.
enum FPChibiTuning {
    static let swing: TimeInterval = 0.24
    static let cueDuration: TimeInterval = 1.35
    static let nearDuration: TimeInterval = 2.0
    static let collisionDuration: TimeInterval = 0.45
    static let sandCooldown: TimeInterval = 1.2
    static let nearRadiusMultiplier: CGFloat = 1.8
    static let nearRecedeDistance: CGFloat = 0.018
    static let strongPull: CGFloat = 0.72
    static let spectatorDistance: CGFloat = 26
}

struct FPChibiFeedback {
    enum Cue: String { case putt, sand, collision, nearMiss, captured, success, returnToCourse }
    private(set) var cue: Cue?
    private(set) var age: TimeInterval = 0
    private(set) var serial = 0
    private(set) var position = CGPoint.zero
    private(set) var swingAge: TimeInterval = .greatestFiniteMagnitude
    private(set) var shotOrigin = CGPoint.zero
    private(set) var shotDirection = CGVector(dx: 0, dy: -1)
    private(set) var nearMissCount = 0
    private(set) var celebrationCount = 0
    private var lastEventSerial = -1
    private var nearestDistance: CGFloat = .greatestFiniteMagnitude
    private var nearShown = false
    private var sandElapsed: TimeInterval = .greatestFiniteMagnitude
    private var wasInSand = false

    var duration: TimeInterval { cue == .nearMiss ? FPChibiTuning.nearDuration : FPChibiTuning.cueDuration }
    var visibleCue: Cue? { age < duration ? cue : nil }
    var isSwinging: Bool { swingAge < FPChibiTuning.swing }

    mutating func receive(_ event: String, serial eventSerial: Int, position: CGPoint, direction: CGVector?) {
        guard eventSerial > lastEventSerial else { return }
        lastEventSerial = eventSerial
        switch event {
        case "tee-off", "scene-restored":
            self = FPChibiFeedback();lastEventSerial = eventSerial
        case "shot":
            shotOrigin = position;shotDirection = direction ?? CGVector(dx:0,dy:-1);swingAge = 0
            nearestDistance = .greatestFiniteMagnitude;nearShown = false;wasInSand = false;sandElapsed = .greatestFiniteMagnitude
            show(.putt,at:position)
        case "collision", "canal-collision": show(.collision,at:position)
        case "hole-capture": nearShown = true;show(.captured,at:position)
        case "hole-success": celebrationCount += 1;show(.success,at:position)
        case "out-of-bounds": nearShown = true;show(.returnToCourse,at:position)
        default: break
        }
    }

    mutating func advance(_ dt: TimeInterval, position: CGPoint, hole: CGPoint, captureRadius: CGFloat, rolling: Bool, inSand: Bool) {
        guard dt.isFinite,dt > 0 else { return }
        age = min(60,age+dt);swingAge = min(60,swingAge+dt);sandElapsed = min(60,sandElapsed+dt)
        guard rolling else { return }
        let distance = hypot(position.x-hole.x,position.y-hole.y)
        nearestDistance = min(nearestDistance,distance)
        if !nearShown,nearestDistance < captureRadius*FPChibiTuning.nearRadiusMultiplier,
           distance > nearestDistance+FPChibiTuning.nearRecedeDistance {
            nearShown = true;nearMissCount += 1;show(.nearMiss,at:position)
        } else if inSand && !wasInSand && sandElapsed > FPChibiTuning.sandCooldown,
                  visibleCue != .nearMiss {
            sandElapsed = 0;show(.sand,at:position)
        }
        wasInSand = inSand
    }

    private mutating func show(_ next: Cue, at point: CGPoint) { cue=next;position=point;age=0;serial += 1 }

    func text(mood: FPChibiMood) -> String {
        guard let cue=visibleCue else { return "" }
        switch cue {
        case .putt: return mood == .cozy ? FPL10n.text("hole_sound") : FPL10n.text("go")
        case .sand: return FPL10n.text("sand_sound")
        case .collision: return mood == .cozy ? FPL10n.text("bounce_sound") : FPL10n.text("bonk")
        case .nearMiss: return mood == .cozy ? FPL10n.text("quote_near_miss_cozy") : FPL10n.text("passing")
        case .captured: return FPL10n.text("water_sound")
        case .success: return mood == .cozy ? FPL10n.text("good_shot") : FPL10n.text("planned")
        case .returnToCourse: return mood == .cozy ? FPL10n.text("retrieved") : FPL10n.text("walk_complete")
        }
    }
}

@MainActor enum FPChibiPalette {
    static let paper = UIColor(red:0.97,green:0.95,blue:0.89,alpha:1)
    static let card = UIColor(red:1,green:0.985,blue:0.935,alpha:1)
    static let grass = UIColor(red:0.73,green:0.81,blue:0.57,alpha:1)
    static let meadow = UIColor(red:0.86,green:0.90,blue:0.73,alpha:1)
    static let edge = UIColor(red:0.43,green:0.53,blue:0.34,alpha:1)
    static let ink = UIColor(red:0.20,green:0.30,blue:0.23,alpha:1)
    static let secondary = UIColor(red:0.36,green:0.41,blue:0.30,alpha:1)
    static let blush = UIColor(red:0.91,green:0.65,blue:0.55,alpha:1)
    static let sand = UIColor(red:0.90,green:0.82,blue:0.62,alpha:1)
    static let water = UIColor(red:0.64,green:0.79,blue:0.76,alpha:1)
    static func ball(_ skin: FPBallSkin) -> UIColor {
        switch skin {
        case .rice: return UIColor(red:1,green:0.985,blue:0.89,alpha:1)
        case .peach: return UIColor(red:0.97,green:0.78,blue:0.71,alpha:1)
        case .sesame: return UIColor(red:0.83,green:0.85,blue:0.77,alpha:1)
        }
    }
    static func handwriting(_ style: UIFont.TextStyle, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        // 非中文使用系统字体，避免中文书法字体的回退破坏阿语连写和行高。
        guard FPL10n.language.hasPrefix("zh") else { return UIFont.preferredFont(forTextStyle:style,compatibleWith:traits) }
        let size=UIFont.preferredFont(forTextStyle:style,compatibleWith:traits).pointSize
        return UIFont(name:"STKaiti",size:size) ?? UIFont(name:"Kaiti SC",size:size) ?? FPTheme.font(style)
    }
}

extension FPDemoSession {
    var presentationActions: [UIMenuElement] {
        let choose=UIAction(title:FPL10n.text("change_mode"),image:UIImage(systemName:"paintpalette")) { [weak self] _ in self?.requestModeSelection?() }
        guard isChibi else { return [choose] }
        let moods=FPChibiMood.allCases.map { mood in
            UIAction(title:mood.title,state:chibiMood == mood ? .on:.off) { [weak self] _ in self?.setPresentation(mode:.chibi,mood:mood) }
        }
        let skins=FPBallSkin.allCases.map { skin in
            UIAction(title:skin.title,state:ballSkin == skin ? .on:.off) { [weak self] _ in self?.setPresentation(mode:.chibi,skin:skin) }
        }
        return [choose,UIMenu(title:FPL10n.format("ball_mood",chibiMood.title),image:UIImage(systemName:"face.smiling"),children:moods),UIMenu(title:FPL10n.format("ball_skin",ballSkin.title),image:UIImage(systemName:"circle.lefthalf.filled"),children:skins)]
    }
}
