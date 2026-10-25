import UIKit
import AVFoundation

// Player instances are only touched on this serial queue; UIKit never waits for audio activation.
final class FPSound: @unchecked Sendable {
    private let queue=DispatchQueue(label:"com.foldputt.sound")
    private var players: [String:AVAudioPlayer] = [:]
    private static let key = "FoldPutt.soundEnabled"
    @MainActor static var enabled: Bool {
        get { UserDefaults.standard.object(forKey:key) == nil || UserDefaults.standard.bool(forKey:key) }
        set { UserDefaults.standard.set(newValue,forKey:key) }
    }
    @MainActor static var settingAction: UIAction {
        UIAction(title:FPL10n.text("sound"),image:UIImage(systemName:enabled ? "speaker.wave.2":"speaker.slash"),state:enabled ? .on:.off) { _ in enabled.toggle() }
    }
    @MainActor func play(_ event:String) {
        guard Self.enabled,let name=["shot":"putt","hole-success":"hole"][event] else { return }
        queue.async { [self] in
        do {
            if players[name] == nil,let url=Bundle.main.url(forResource:name,withExtension:"wav") {
                try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default,options:.mixWithOthers)
                let player=try AVAudioPlayer(contentsOf:url);player.prepareToPlay();players[name]=player
            }
            players[name]?.currentTime=0;players[name]?.play()
        } catch { NSLog("FoldPutt sound unavailable: %@",error.localizedDescription) }
        }
    }
}

@MainActor final class FPHaptics {
    private static let key = "FoldPutt.hapticsEnabled"
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey:key) == nil || UserDefaults.standard.bool(forKey:key) }
        set { UserDefaults.standard.set(newValue,forKey:key) }
    }
    static var settingAction: UIAction {
        UIAction(title:FPL10n.text("haptics"),image:UIImage(systemName:"hand.tap"),state:enabled ? .on:.off) { _ in enabled.toggle() }
    }
    private let shot: UIImpactFeedbackGenerator
    private let capture: UIImpactFeedbackGenerator
    init(view: UIView, shotGenerator: UIImpactFeedbackGenerator? = nil, captureGenerator: UIImpactFeedbackGenerator? = nil) {
        // 持有与当前场景关联的反馈器，避免每次松手才创建一个未预热的临时对象。
        shot = shotGenerator ?? UIImpactFeedbackGenerator(style: .light, view: view)
        capture = captureGenerator ?? UIImpactFeedbackGenerator(style: .light, view: view)
    }
    func prepareShot() {
        guard Self.enabled else { return }
        shot.prepare()
    }
    func play(_ event: String) {
        // 触感与视觉动态分别控制；减少动态效果不应使已打开的触感开关失效。
        guard Self.enabled else { return }
        switch event {
        case "shot": shot.impactOccurred(intensity: FPMotion.shotHapticIntensity)
        case "hole-capture": capture.impactOccurred(intensity: FPMotion.holeHapticIntensity)
        default: break
        }
    }
}
