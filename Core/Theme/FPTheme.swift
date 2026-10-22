import UIKit

@MainActor enum FPTheme {
    static let grass = UIColor(named: "Grass")!
    static let grassDeep = UIColor(named: "GrassDeep")!
    static let sand = UIColor(named: "Sand")!
    static let gold = UIColor(named: "RewardGold")!
    static let red = UIColor(named: "PenaltyRed")!
    static let water = UIColor(named: "Water")!
    static let surface = UIColor(named: "Surface")!
    static let ink = UIColor(named: "TextPrimary")!
    static let secondary = UIColor(named: "TextSecondary")!
    static let fieldInk = UIColor(named:"TextDark")!
    static let light = UIColor(named:"TextLight")!
    static let courseWallInset:CGFloat = 16
    static let hudGutter:CGFloat = 14
    static let hudGap:CGFloat = 8
    static let pullDiameter:CGFloat = 108
    static let scoreCardWidth:CGFloat = 136
    static let statusWidth:CGFloat = 180
    static let corner: CGFloat = 26
    static let spacing: CGFloat = 16
    static let target: CGFloat = 48
    static let shadowOpacity: Float = 0.1
    static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle:style)
        let descriptor=base.fontDescriptor.addingAttributes([.traits:[UIFontDescriptor.TraitKey.weight:weight.rawValue]])
        return UIFont(descriptor:descriptor,size:0)
    }
    static func label(_ text: String, style: UIFont.TextStyle = .body, weight: UIFont.Weight = .regular) -> UILabel {
        let label = UILabel()
        label.text = text; label.font = font(style, weight: weight)
        label.textColor = ink; label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .natural
        return label
    }
    static func icon(_ name: String, label: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.image = UIImage(systemName: name)
        config.baseForegroundColor = ink
        config.baseBackgroundColor = grassDeep.withAlphaComponent(0.12)
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.accessibilityLabel = label
        button.accessibilityIdentifier = label
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: target).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: target).isActive = true
        return button
    }
}

@MainActor enum FPMotion {
    static let screenTapMaximumDuration: TimeInterval = 0.3
    static let holeNudge: TimeInterval = 0.18
    static let holeNudgeDistance: CGFloat = 2
    static let holeHapticIntensity: CGFloat = 0.35
    static let controlFade: TimeInterval = 0.15
    static let aimingPullAlpha: CGFloat = 0.14
    static let disabledPullAlpha: CGFloat = 0.35
    static let replaySpeed: Double = 0.5
    static let replaySampleInterval: TimeInterval = 1.0/30
    static let replayStaticHold: TimeInterval = 0.8
    static let replayFireworkCycle: TimeInterval = 1.2
    static func hudAlpha(for phase:FPDemoSession.Phase)->CGFloat {
        let aiming=phase == .aiming || phase == .charging
        return aiming && !UIAccessibility.isVoiceOverRunning && !UIAccessibility.isReduceTransparencyEnabled ? 0:1
    }
    static let grass: TimeInterval = 0.6
    static let flag: TimeInterval = 0.4
    static let success: TimeInterval = 0.8
    static let penalty: TimeInterval = 0.3
    static var reduced: Bool { UIAccessibility.isReduceMotionEnabled }
}
