import UIKit

final class FPCourseView: UIView, UIGestureRecognizerDelegate {
    private static let images: [String: UIImage] = {
        var prepared: [String: UIImage] = [:]
        for name in ["GrassRegular", "GrassCompact", "GrassEdgeTile", "CanalTile", "Flag", "GolfBall", "SpeedLine"] {
            if let image = UIImage(named: name) { prepared[name] = image.preparingForDisplay() ?? image }
        }
        return prepared
    }()
    let session: FPDemoSession
    var exclusions: [CGRect] = []
    var miniature = false
    var immersive = false
    var across = false
    var divisionRects:[CGRect] = []
    private var displaySignature=""
    private var previousBall:CGPoint?
    private var crossingPoint:CGPoint?
    var onPreview: ((FPShot?) -> Void)?
    var onRelease: ((FPShot?) -> Void)?
    var onCancel: (() -> Void)?
    var topClearance: CGFloat = 0
    var bottomClearance: CGFloat = 0
    private var pan: UIPanGestureRecognizer!
    private var touchOrigin = CGPoint.zero
    private var lastPhase: FPDemoSession.Phase = .ready
    private var lastEventSerial = -1
    private var lastTeeID = ""
    private var ripple: CGFloat = 0
    private var growingFlag = false
    private var flagStarted: CFTimeInterval = -.greatestFiniteMagnitude
    var flagGrowth: CGFloat { FPMotion.reduced ? 1:min(1,max(0.05,CGFloat((CACurrentMediaTime()-flagStarted)/FPMotion.flag))) }
    init(session: FPDemoSession) {
        self.session=session;super.init(frame:.zero)
        _ = Self.images
        backgroundColor = .clear;isOpaque=false
        accessibilityIdentifier="courseView";accessibilityLabel=FPL10n.text("course_accessibility")
        pan=UIPanGestureRecognizer(target:self,action:#selector(dragged));pan.maximumNumberOfTouches=1;pan.delegate=self;addGestureRecognizer(pan)
    }
    required init?(coder:NSCoder) { fatalError() }
    var projection:FPCourseProjection {
        if immersive && !miniature {
            var area=bounds.inset(by:safeAreaInsets).insetBy(dx:FPTheme.courseWallInset,dy:FPTheme.courseWallInset)
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                let top=max(area.minY,bounds.minY+topClearance)
                let bottom=min(area.maxY,bounds.maxY-bottomClearance)
                if bottom>top { area=CGRect(x:area.minX,y:top,width:area.width,height:bottom-top) }
            }
            return FPCourseProjection(area:area,across:across)
        }
        let area=CGRect(x:bounds.minX+16,y:bounds.minY+topClearance+12,width:max(1,bounds.width-32),height:max(1,bounds.height-topClearance-bottomClearance-24))
        return FPCourseProjection(area:FPRegionSnapshot.usable(area,excluding:exclusions),across:false)
    }
    var field:CGRect { projection.frame }
    func point(_ p:CGPoint)->CGPoint { projection.point(CGPoint(x:p.x,y:p.y*FPLevel.world.height)) }
    private func worldPoint(_ p:CGPoint)->CGPoint { projection.point(p) }
    private func worldRect(_ r:CGRect)->CGRect { projection.viewRect(r) }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard !miniature, session.canAim else { return false }
        let p=touch.location(in:self),b=point(session.ball)
        touchOrigin=p
        return hypot(p.x-b.x,p.y-b.y)<max(24,projection.scale*FPLevel.ballRadius)
    }
    @objc private func dragged(_ gesture:UIPanGestureRecognizer) {
        let current=gesture.location(in:self)
        let profile=session.inputProfile
        let screenShot=FPPullMath.shot(translation:CGPoint(x:current.x-touchOrigin.x,y:current.y-touchOrigin.y),maximum:min(profile.maximumDrag,field.height*0.3),deadZone:profile.deadZone,exponent:profile.exponent)
        let shot=screenShot.map { FPShot(direction:projection.worldVector($0.direction),power:$0.power) }
        switch gesture.state {
        case .began,.changed:onPreview?(shot)
        case .ended:onRelease?(shot)
        case .cancelled,.failed:onCancel?()
        default:break
        }
    }
    func refresh() {
        let feedback=session.chibiFeedback
        let animated=session.isChibi && !FPMotion.reduced && (feedback.isSwinging || flagGrowth<1 || (session.phase == .success && feedback.age<FPMotion.success))
        let chibi="\(session.ballTalkText)|\(session.gameMode)|\(session.chibiMood)|\(session.ballSkin)|\(String(describing:feedback.visibleCue))|\(feedback.age<FPChibiTuning.collisionDuration)|\(animated ? feedback.age:0)"
        let signature="\(bounds)|\(session.world.position)|\(String(describing:session.preview))|\(session.phase)|\(session.world.canal)|\(String(describing:session.world.divisionBanks))|\(session.penaltyActive)|\(session.speedLineReward)|\(session.eventAge<0.5)|\(immersive)|\(across)|\(session.teeID)|\(chibi)"
        if signature != displaySignature { displaySignature=signature;setNeedsDisplay() }
        let current=worldPoint(session.world.position)
        if immersive,session.phase == .rolling,let previous=previousBall {
            for seam in divisionRects where seam.contains(current) && !seam.contains(previous) {
                hingeRipple(at:current)
            }
        }
        previousBall=current
        if lastTeeID != session.teeID { lastTeeID=session.teeID;stopLargeMotion() }
        if session.phase != lastPhase {
            if session.phase == .sinking,session.lastEvent == "hole-capture" { showHoleFeedback() }
            if session.phase == .success,session.lastEvent != "scene-restored" { celebrate() }
            lastPhase=session.phase
        }
        if lastEventSerial != session.eventSerial {
            if session.lastEvent == "penalty" || session.lastEvent == "out-of-bounds" { showPenaltyFeedback() }
            lastEventSerial=session.eventSerial
        }
    }
    func teeOff() {
        guard !FPMotion.reduced,!miniature,field.width>1 else { return }
        // Reveal turf locally; controls and layout never animate with hinge movement.
        let mask=CAShapeLayer();mask.path=UIBezierPath(rect:bounds).cgPath;layer.mask=mask
        let reveal=CABasicAnimation(keyPath:"path");reveal.fromValue=UIBezierPath(rect:CGRect(x:0,y:bounds.maxY,width:bounds.width,height:0)).cgPath
        reveal.toValue=mask.path;reveal.duration=FPMotion.grass;mask.add(reveal,forKey:"grass")
        DispatchQueue.main.asyncAfter(deadline:.now()+FPMotion.grass) { [weak self,weak mask] in
            if self?.layer.mask === mask { self?.layer.mask=nil }
        }
        if session.isChibi { flagStarted=CACurrentMediaTime();setNeedsDisplay();return }
        let flag=CALayer();flag.contents=Self.images["Flag"]?.cgImage
        let cup=point(session.hole),size=max(22,min(60,projection.scale*0.19))
        flag.anchorPoint=CGPoint(x:0.45,y:0.84);flag.position=cup;flag.bounds=CGRect(x:0,y:0,width:size,height:size)
        growingFlag=true;layer.addSublayer(flag);setNeedsDisplay()
        let grow=CABasicAnimation(keyPath:"transform.scale.y");grow.fromValue=0.05;grow.toValue=1;grow.duration=FPMotion.flag;flag.add(grow,forKey:"flag")
        DispatchQueue.main.asyncAfter(deadline:.now()+FPMotion.flag) { [weak self] in flag.removeFromSuperlayer();self?.growingFlag=false;self?.setNeedsDisplay() }
    }
    func hingeRipple(at point:CGPoint?=nil) {
        guard !FPMotion.reduced else { return }
        let seam=divisionRects.first ?? field
        crossingPoint=point ?? CGPoint(x:seam.midX,y:seam.midY)
        ripple=1;setNeedsDisplay()
        DispatchQueue.main.asyncAfter(deadline:.now()+FPMotion.grass) { [weak self] in self?.ripple=0;self?.setNeedsDisplay() }
    }
    private func showHoleFeedback() {
        guard !FPMotion.reduced,!miniature else { return }
        let nudge=CAKeyframeAnimation(keyPath:"transform.translation.x")
        let distance=FPMotion.holeNudgeDistance
        nudge.values=[0,-distance,distance,-distance/2,0]
        nudge.duration=FPMotion.holeNudge
        layer.add(nudge,forKey:"hole-nudge")
    }
    private func celebrate() {
        guard !FPMotion.reduced,!miniature else { return }
        let center=point(session.hole)
        for i in 0..<14 {
            let particle=CAShapeLayer();particle.path=UIBezierPath(ovalIn:CGRect(x:-3,y:-3,width:6,height:6)).cgPath;particle.fillColor=(session.isChibi ? (i.isMultiple(of:2) ? FPChibiPalette.blush:FPChibiPalette.card):FPTheme.gold).cgColor;particle.position=center;layer.addSublayer(particle)
            let a=CGFloat(i)*2 * .pi/14
            let move=CABasicAnimation(keyPath:"position");move.fromValue=NSValue(cgPoint:center);move.toValue=NSValue(cgPoint:CGPoint(x:center.x+cos(a)*55,y:center.y+sin(a)*55))
            let fade=CABasicAnimation(keyPath:"opacity");fade.fromValue=1;fade.toValue=0
            let group=CAAnimationGroup();group.animations=[move,fade];group.duration=FPMotion.success;particle.add(group,forKey:"success")
            DispatchQueue.main.asyncAfter(deadline:.now()+FPMotion.success) { particle.removeFromSuperlayer() }
        }
    }
    func stopLargeMotion() {
        layer.removeAllAnimations();layer.mask=nil;layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        growingFlag=false;flagStarted = -.greatestFiniteMagnitude;ripple=0;setNeedsDisplay()
    }
    func showPenaltyFeedback() {
        guard !miniature,!FPMotion.reduced else { return }
        let border=CAShapeLayer();border.path=UIBezierPath(roundedRect:bounds.insetBy(dx:5,dy:5),cornerRadius:24).cgPath;border.strokeColor=FPTheme.red.cgColor;border.fillColor=UIColor.clear.cgColor;border.lineWidth=3;layer.addSublayer(border)
        DispatchQueue.main.asyncAfter(deadline:.now()+FPMotion.penalty) { border.removeFromSuperlayer() }
    }
    override func draw(_ rect:CGRect) {
        guard let c=UIGraphicsGetCurrentContext(),field.width>1 else { return }
        if session.isChibi { FPChibiArt.draw(in:c,view:self);drawAimBoundary(c);return }
        let f=field,radius=FPLevel.ballRadius*projection.scale
        if immersive && !miniature {
            FPTheme.grass.setFill();c.fill(bounds)
            Self.images["GrassRegular"]?.draw(in:bounds,blendMode:.normal,alpha:0.20)
        }
        let grass=immersive && !miniature ? UIBezierPath(rect:f):UIBezierPath(roundedRect:f,cornerRadius:14)
        if !immersive || miniature {
            c.saveGState();c.setShadow(offset:CGSize(width:0,height:6),blur:18,color:FPTheme.grassDeep.withAlphaComponent(0.25).cgColor)
            FPTheme.grassDeep.setFill();UIBezierPath(roundedRect:f.offsetBy(dx:0,dy:5),cornerRadius:14).fill();c.restoreGState()
            FPTheme.grass.setFill();grass.fill()
        }
        c.saveGState();grass.addClip()
        if !immersive || miniature {
            let bg=traitCollection.horizontalSizeClass == .regular ? "GrassRegular":"GrassCompact"
            Self.images[bg]?.draw(in:f,blendMode:.normal,alpha:0.34)
            if let tile=Self.images["GrassEdgeTile"] {
                UIColor(patternImage:tile).setFill();c.fill(CGRect(x:f.minX,y:f.minY,width:f.width,height:7));c.fill(CGRect(x:f.minX,y:f.maxY-7,width:f.width,height:7))
            }
        }
        for patch in session.level.sand {
            let area=worldRect(patch.cg);FPTheme.sand.setFill();UIBezierPath(roundedRect:area,cornerRadius:7).fill()
            c.setFillColor(FPTheme.gold.withAlphaComponent(0.35).cgColor)
            for i in 0..<25 { let x=area.minX+CGFloat((i*17)%29)/29*area.width,y=area.minY+CGFloat((i*13)%31)/31*area.height;c.fillEllipse(in:CGRect(x:x,y:y,width:1,height:1)) }
        }
        for water in session.level.hazards { FPTheme.water.setFill();UIBezierPath(rect:worldRect(water.cg)).fill() }
        for (id,rect) in session.world.solids {
            let area=worldRect(rect)
            if (id == "canal" || id.hasPrefix("division-")),let texture=Self.images["CanalTile"] { UIColor(patternImage:texture).setFill() }
            else { (id == "penalty" ? FPTheme.red.withAlphaComponent(0.65):FPTheme.sand).setFill() }
            UIBezierPath(rect:area).fill()
            FPTheme.grassDeep.setStroke();let edge=UIBezierPath(rect:area);edge.lineWidth=2;edge.stroke()
        }
        if session.speedLineReward,session.prediction.count>1 {
            c.setStrokeColor(FPTheme.gold.cgColor);c.setLineWidth(2.5);c.setLineDash(phase:0,lengths:[5,5])
            c.move(to:worldPoint(session.prediction[0]));session.prediction.dropFirst().forEach { c.addLine(to:worldPoint($0)) };c.strokePath();c.setLineDash(phase:0,lengths:[])
        }
        if session.phase == .rolling,!FPMotion.reduced,session.trail.count>1 {
            c.setStrokeColor((session.speedLineReward ? FPTheme.gold:UIColor.white.withAlphaComponent(0.45)).cgColor);c.setLineWidth(2)
            c.move(to:worldPoint(session.trail[0]));session.trail.dropFirst().forEach { c.addLine(to:worldPoint($0)) };c.strokePath()
        }
        c.restoreGState()
        if immersive { drawCrossings(c) }
        let cup=point(session.hole),b=point(session.ball)
        FPTheme.grassDeep.withAlphaComponent(0.35).setFill();UIBezierPath(ovalIn:CGRect(x:cup.x-radius*1.8,y:cup.y-radius*1.3,width:radius*3.6,height:radius*2.6)).fill()
        UIColor(named:"TextDark")!.setFill();UIBezierPath(ovalIn:CGRect(x:cup.x-radius*1.3,y:cup.y-radius,width:radius*2.6,height:radius*2)).fill()
        let flagSize=max(20,min(60,projection.scale*0.19))
        if !growingFlag { Self.images["Flag"]?.draw(in:CGRect(x:cup.x-flagSize*0.45,y:cup.y-flagSize*0.84,width:flagSize,height:flagSize)) }
        if let shot=session.preview {
            let length=(0.10+shot.power*0.22)*projection.scale
            let direction=projection.vector(shot.direction)
            let end=CGPoint(x:b.x+direction.dx*length,y:b.y+direction.dy*length)
            c.saveGState();grass.addClip();c.setStrokeColor(UIColor.white.cgColor);c.setLineWidth(3);c.setLineDash(phase:0,lengths:[5,5]);c.move(to:b);c.addLine(to:end);c.strokePath();c.setLineDash(phase:0,lengths:[])
            let a=atan2(end.y-b.y,end.x-b.x)
            c.move(to:CGPoint(x:end.x-cos(a-0.5)*10,y:end.y-sin(a-0.5)*10));c.addLine(to:end);c.addLine(to:CGPoint(x:end.x-cos(a+0.5)*10,y:end.y-sin(a+0.5)*10));c.strokePath();c.restoreGState()
        }
        if session.phase != .success && session.phase != .sinking {
            // PDF ball's visible circle is 70% of its canvas. Match visual radius to collider.
            let underFold=immersive && divisionRects.contains { $0.contains(b) }
            let size=radius*2/0.70*(underFold && !FPMotion.reduced ? 0.82:1)
            c.saveGState();c.setAlpha(underFold ? 0.60:1)
            Self.images["GolfBall"]?.draw(in:CGRect(x:b.x-size*0.5,y:b.y-size*0.46,width:size,height:size))
            c.restoreGState()
        }
        if (session.lastEvent == "canal-collision" && session.eventAge<0.5) || ripple>0 {
            let p=ripple>0 ? crossingPoint ?? worldPoint(session.eventPosition):worldPoint(session.eventPosition);FPTheme.gold.setStroke();let ring=UIBezierPath(ovalIn:CGRect(x:p.x-12,y:p.y-12,width:24,height:24));ring.lineWidth=3;ring.stroke()
        }
        if session.speedLineReward,!miniature { Self.images["SpeedLine"]?.withTintColor(FPTheme.gold,renderingMode:.alwaysOriginal).draw(in:CGRect(x:cup.x+14,y:cup.y-18,width:35,height:35)) }
        if session.phase == .resetting || session.penaltyActive {
            FPTheme.red.setStroke();let p=UIBezierPath(roundedRect:f.insetBy(dx:-3,dy:-3),cornerRadius:16);p.lineWidth=1;p.stroke()
        }
        drawAimBoundary(c)
    }
    private func drawAimBoundary(_ context:CGContext) {
        guard !miniature,session.phase == .aiming || session.phase == .charging else { return }
        context.saveGState()
        let outside=UIBezierPath(rect:bounds);outside.append(UIBezierPath(rect:field));outside.usesEvenOddFillRule=true
        UIColor.black.withAlphaComponent(0.12).setFill();outside.fill()
        context.setStrokeColor((session.isChibi ? FPChibiPalette.ink:FPTheme.light).cgColor)
        context.setLineWidth(3);context.stroke(field)
        context.setLineDash(phase:0,lengths:[5,4]);context.setLineWidth(1)
        context.stroke(field.insetBy(dx:FPLevel.ballRadius*projection.scale,dy:FPLevel.ballRadius*projection.scale))
        context.restoreGState()
    }
    private func drawCrossings(_ context:CGContext) {
        for division in divisionRects {
            let seam=division.intersection(field)
            guard !seam.isNull else { continue }
            FPTheme.water.withAlphaComponent(0.7).setFill();UIBezierPath(rect:seam).fill()
            let bridge=projection.bridge(in:projection.worldRect(seam))
            guard !bridge.isNull else { continue }
            let deck=worldRect(bridge).insetBy(dx:-3,dy:-3)
            FPTheme.sand.setFill();UIBezierPath(roundedRect:deck,cornerRadius:3).fill()
            context.setStrokeColor(FPTheme.grassDeep.withAlphaComponent(0.45).cgColor);context.setLineWidth(1)
            for i in 1..<7 {
                let f=CGFloat(i)/7
                if deck.width>deck.height { context.move(to:CGPoint(x:deck.minX+deck.width*f,y:deck.minY));context.addLine(to:CGPoint(x:deck.minX+deck.width*f,y:deck.maxY)) }
                else { context.move(to:CGPoint(x:deck.minX,y:deck.minY+deck.height*f));context.addLine(to:CGPoint(x:deck.maxX,y:deck.minY+deck.height*f)) }
            }
            context.strokePath()
        }
    }

}

/// Replays recorded world positions only; it never launches or steps the physics world.
final class FPShotReplayView: UIView {
    let session:FPDemoSession
    private let title=FPTheme.label(FPL10n.text("hole_in_one"),style:.title2,weight:.bold)
    private let subtitle=FPTheme.label(FPL10n.text("replay_slow"),style:.caption1)
    private let skip=UIButton(type:.system)
    private let canvas=FPReplayCanvas()
    init(session:FPDemoSession) {
        self.session=session;super.init(frame:.zero)
        accessibilityIdentifier="shotReplay";layer.cornerRadius=FPTheme.corner
        layer.shadowOpacity=FPTheme.shadowOpacity;layer.shadowRadius=18
        title.textAlignment = .center;subtitle.textAlignment = .center
        skip.setTitle(FPL10n.text("skip_replay"),for:.normal);skip.accessibilityIdentifier="skipReplay"
        skip.titleLabel?.font=FPTheme.font(.body);skip.titleLabel?.adjustsFontForContentSizeCategory=true
        skip.titleLabel?.numberOfLines=0;skip.titleLabel?.textAlignment = .center
        skip.addAction(UIAction { [weak session] _ in session?.finishReplay() },for:.touchUpInside)
        [title,subtitle,canvas,skip].forEach(addSubview)
        canvas.session=session;canvas.isUserInteractionEnabled=false
        isHidden=true
    }
    required init?(coder:NSCoder) { fatalError() }
    func refresh() {
        let wasHidden=isHidden;isHidden = !session.isReplaying
        guard !isHidden else { return }
        backgroundColor=session.isChibi ? FPChibiPalette.card:FPTheme.surface
        title.textColor=session.isChibi ? FPChibiPalette.ink:FPTheme.ink
        subtitle.textColor=session.isChibi ? FPChibiPalette.secondary:FPTheme.secondary
        subtitle.text=session.replayStatic ? FPL10n.text("replay_static"):FPL10n.text("replay_slow")
        skip.tintColor=title.textColor;canvas.setNeedsDisplay()
        if wasHidden { setNeedsLayout();UIAccessibility.post(notification:.announcement,argument:FPL10n.text("replay_hint")) }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontal=bounds.width>bounds.height*1.3
        let left:CGFloat=horizontal ? bounds.width*0.48:16
        let width=max(1,bounds.width-left-16)
        title.font=FPTheme.font(horizontal ? .headline:.title2,weight:.bold)
        let titleHeight=title.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height
        title.frame=CGRect(x:left,y:16,width:width,height:titleHeight)
        let subtitleHeight=subtitle.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height
        subtitle.frame=CGRect(x:left,y:title.frame.maxY+4,width:width,height:subtitleHeight)
        let skipHeight=max(FPTheme.target,(skip.titleLabel?.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height ?? 22)+12)
        skip.frame=CGRect(x:left,y:bounds.height-12-skipHeight,width:width,height:skipHeight)
        subtitle.isHidden=subtitle.frame.maxY+8>skip.frame.minY
        title.accessibilityHint=subtitle.isHidden ? subtitle.text:nil
        if horizontal { canvas.frame=CGRect(x:12,y:12,width:left-20,height:bounds.height-24) }
        else { canvas.frame=CGRect(x:12,y:subtitle.frame.maxY+8,width:bounds.width-24,height:max(0,skip.frame.minY-subtitle.frame.maxY-16)) }
    }
}

private final class FPReplayCanvas:UIView {
    weak var session:FPDemoSession?
    override init(frame:CGRect) { super.init(frame:frame);backgroundColor = .clear;isOpaque=false }
    required init?(coder:NSCoder) { fatalError() }
    override func draw(_ rect:CGRect) {
        guard let session,let c=UIGraphicsGetCurrentContext(),bounds.height>10,session.shotReplay.count>1 else { return }
        let projection=FPCourseProjection(area:bounds.insetBy(dx:28,dy:12),across:bounds.width>bounds.height*1.4)
        let field=projection.frame
        (session.isChibi ? FPChibiPalette.grass:FPTheme.grass).setFill()
        UIBezierPath(roundedRect:field,cornerRadius:12).fill()
        for patch in session.level.sand { FPTheme.sand.setFill();UIBezierPath(rect:projection.viewRect(patch.cg)).fill() }
        for patch in session.level.hazards { FPTheme.water.setFill();UIBezierPath(rect:projection.viewRect(patch.cg)).fill() }
        for (_,solid) in session.world.solids { (session.isChibi ? FPChibiPalette.edge:FPTheme.grassDeep).setFill();UIBezierPath(rect:projection.viewRect(solid)).fill() }
        let cup=projection.point(session.level.hole.cg),radius=max(4,FPLevel.ballRadius*projection.scale)
        FPTheme.fieldInk.setFill();UIBezierPath(ovalIn:CGRect(x:cup.x-radius*1.4,y:cup.y-radius*1.4,width:radius*2.8,height:radius*2.8)).fill()
        let samples=session.shotReplay,time=session.replayTime
        let prior=samples.lastIndex(where:{$0.time<=time}) ?? 0
        let a=samples[prior],b=samples[min(prior+1,samples.count-1)]
        let fraction=b.time>a.time ? min(1,max(0,(time-a.time)/(b.time-a.time))):1
        let position=CGPoint(x:a.point.x+(b.point.x-a.point.x)*fraction,y:a.point.y+(b.point.y-a.point.y)*fraction)
        c.saveGState();c.setStrokeColor((session.isChibi ? FPChibiPalette.ink:FPTheme.light).cgColor);c.setLineWidth(2)
        c.move(to:projection.point(samples[0].point))
        for sample in samples.prefix(prior+1).dropFirst() { c.addLine(to:projection.point(sample.point)) }
        let ball=projection.point(position);c.addLine(to:ball);c.strokePath();c.restoreGState()
        let sunk = time >= session.shotTime && !session.replayStatic
        if !sunk {
            if session.isChibi { FPChibiArt.ball(in:c,center:ball,radius:radius+2,skin:session.ballSkin,expression:.happy) }
            else { UIColor.white.setFill();UIBezierPath(ovalIn:CGRect(x:ball.x-radius,y:ball.y-radius,width:radius*2,height:radius*2)).fill() }
        }
        // Decorative bursts sit around the recorded course and stop with the presentation clock.
        guard !session.replayStatic,!FPMotion.reduced else { return }
        let age=session.replayElapsed ?? 0
        for burst in 0..<4 {
            let progress=(age+Double(burst)*0.27).truncatingRemainder(dividingBy:FPMotion.replayFireworkCycle)/FPMotion.replayFireworkCycle
            let center=CGPoint(x:burst.isMultiple(of:2) ? field.minX-10:field.maxX+10,y:burst<2 ? field.minY+field.height*0.25:field.maxY-field.height*0.25)
            c.setStrokeColor((burst.isMultiple(of:2) ? FPTheme.gold:FPChibiPalette.blush).withAlphaComponent(1-progress).cgColor);c.setLineWidth(2)
            for ray in 0..<10 {
                let angle=CGFloat(ray)*2 * .pi/10,distance=CGFloat(progress)*22
                c.move(to:CGPoint(x:center.x+cos(angle)*distance*0.45,y:center.y+sin(angle)*distance*0.45))
                c.addLine(to:CGPoint(x:center.x+cos(angle)*distance,y:center.y+sin(angle)*distance))
            }
            c.strokePath()
        }
    }
}
