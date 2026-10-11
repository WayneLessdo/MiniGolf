import UIKit

final class FPPullControl: UIView, UIGestureRecognizerDelegate {
    var onPreview: ((FPShot?) -> Void)?
    var onRelease: ((FPShot?) -> Void)?
    var onCancel: (() -> Void)?
    var floatingTrack=false { didSet { if oldValue != floatingTrack { paint() } } }
    var accessibilityDirection=CGVector(dx:0,dy:-1)
    var enabled = true { didSet {
        accessibilityTraits = enabled ? [.adjustable]:[.adjustable,.notEnabled]
        if oldValue != enabled { paint() }
    } }
    var inputProfile: FPTuning.Input?
    var chibi=false { didSet { if oldValue != chibi { paint() } } }
    var skin:FPBallSkin = .rice { didSet { if oldValue != skin { paint() } } }
    var reaction:FPChibiArt.Expression = .happy
    var visualRoll:CGFloat = 0
    private let portrait=FPChibiPortrait()
    private let lock=UIImageView(image:UIImage(systemName:"lock.fill"))
    var preview: FPShot? { didSet { paint() } }
    private var translation = CGPoint.zero
    private var touchOrigin = CGPoint.zero
    private var active = false
    private let ring = CAShapeLayer()
    private let arc = CAShapeLayer()
    private let dot = CAShapeLayer()
    private var pan: UIPanGestureRecognizer!
    var panRecognizer: UIGestureRecognizer { pan }
    private var maximum: CGFloat { inputProfile?.maximum(in:bounds.size) ?? 100 }
    private var deadZone: CGFloat { inputProfile?.deadZone ?? 6 }
    private var exponent: CGFloat { inputProfile?.exponent ?? 1.45 }
    private var centerPoint: CGPoint { CGPoint(x:bounds.midX,y:bounds.midY) }
    override init(frame:CGRect) {
        super.init(frame:frame)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: FPPullControl, _: UITraitCollection) in view.paint() }
        accessibilityLabel = "拉杆"; accessibilityIdentifier = "pullControl"
        isAccessibilityElement = true; accessibilityTraits = [.adjustable]
        accessibilityHint = "从圆心向后拖动，松手击球"
        for l in [ring,arc,dot] { layer.addSublayer(l) }
        portrait.isUserInteractionEnabled=false;portrait.backgroundColor = .clear;portrait.isHidden=true;addSubview(portrait)
        lock.tintColor=FPTheme.ink;lock.contentMode = .scaleAspectFit;lock.isUserInteractionEnabled=false;addSubview(lock)
        pan=UIPanGestureRecognizer(target:self,action:#selector(panned))
        pan.maximumNumberOfTouches=1; pan.delegate=self; addGestureRecognizer(pan)
        accessibilityCustomActions = [UIAccessibilityCustomAction(name:"演示轻推") { [weak self] _ in
            guard let self, self.enabled else { return false }
            let shot=FPShot(direction:self.accessibilityDirection,power:0.45)
            self.onPreview?(shot);self.onRelease?(shot);return true
        }]
    }
    required init?(coder:NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); paint() }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let p=touch.location(in:self)
        touchOrigin=p
        return enabled && hypot(p.x-centerPoint.x,p.y-centerPoint.y)<=max(28,min(bounds.width,bounds.height)*0.22)
    }
    @objc private func panned(_ gesture:UIPanGestureRecognizer) {
        let current=gesture.location(in:self)
        translation=CGPoint(x:current.x-touchOrigin.x,y:current.y-touchOrigin.y)
        let shot=FPPullMath.shot(translation:translation,maximum:maximum,deadZone:deadZone,exponent:exponent)
        switch gesture.state {
        case .began,.changed: active=true;onPreview?(shot)
        case .ended: active=false;onRelease?(shot);translation = .zero
        case .cancelled,.failed: active=false;onCancel?();translation = .zero
        default: break
        };paint()
    }
    func cancelTracking() { pan.isEnabled=false;pan.isEnabled=true;active=false;translation = .zero;paint() }
    private func paint() {
        CATransaction.begin();CATransaction.setDisableActions(true)
        let radius=min(bounds.width,bounds.height)*0.35
        let c=centerPoint
        ring.path=UIBezierPath(arcCenter:c,radius:radius,startAngle:0,endAngle:2 * .pi,clockwise:true).cgPath
        ring.strokeColor=(floatingTrack ? FPTheme.light.withAlphaComponent(0.55):FPTheme.grassDeep.withAlphaComponent(0.2)).cgColor;ring.fillColor=(floatingTrack ? FPTheme.surface.withAlphaComponent(0.22):UIColor.clear).cgColor;ring.lineWidth=8
        let power=active ? FPPullMath.shot(translation:translation,maximum:maximum,deadZone:deadZone,exponent:exponent)?.power ?? 0 : preview?.power ?? 0
        arc.path=UIBezierPath(arcCenter:c,radius:radius,startAngle:-.pi/2,endAngle:-.pi/2+power*2 * .pi,clockwise:true).cgPath
        let low=inputProfile?.lowBand ?? 0.33,high=inputProfile?.highBand ?? 0.72
        arc.strokeColor=(power<low ? FPTheme.grassDeep:power<high ? FPTheme.gold:FPTheme.red).cgColor;arc.fillColor=UIColor.clear.cgColor;arc.lineWidth=8;arc.lineCap = .round
        let displayPull: CGPoint
        if !active, let preview {
            let length=deadZone+pow(preview.power,1/exponent)*(maximum-deadZone)
            displayPull=CGPoint(x:-preview.direction.dx*length,y:-preview.direction.dy*length)
        } else { displayPull=translation }
        let d=hypot(displayPull.x,displayPull.y), factor=d>0 ? min(1,radius*0.65/d):0
        let p=CGPoint(x:c.x+displayPull.x*factor,y:c.y+displayPull.y*factor)
        dot.path=UIBezierPath(ovalIn:CGRect(x:p.x-18,y:p.y-18,width:36,height:36)).cgPath
        dot.fillColor=(floatingTrack ? FPTheme.light:FPTheme.ink).cgColor
        if chibi {
            ring.strokeColor=FPChibiPalette.edge.withAlphaComponent(0.22).cgColor;ring.fillColor=FPChibiPalette.card.withAlphaComponent(0.6).cgColor
            arc.strokeColor=(power<high ? FPChibiPalette.edge:FPChibiPalette.blush).cgColor
        }
        dot.isHidden=chibi;portrait.isHidden = !chibi
        portrait.frame=CGRect(x:p.x-23,y:p.y-23,width:46,height:46);portrait.skin=skin;portrait.power=power
        portrait.expression=power>FPChibiTuning.strongPull ? .strong:power>0 ? .focused:reaction;portrait.roll=visualRoll;portrait.setNeedsDisplay()
        lock.frame=CGRect(x:c.x-9,y:c.y+23,width:18,height:18);lock.isHidden=enabled
        accessibilityValue="力度 \(Int(power*100))% · \(power<low ? "精准":power<high ? "标准":"强力")"
        if !enabled { accessibilityValue="暂不可击球" }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            accessibilityValue="max=\(maximum);dead=\(deadZone);exp=\(exponent);power=\(power)"
        }
        #endif
        CATransaction.commit()
    }
}
