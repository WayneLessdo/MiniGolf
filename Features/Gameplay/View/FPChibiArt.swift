import UIKit

/// All geometry is projected from the existing world. Artwork never writes to the simulation.
@MainActor enum FPChibiArt {
    enum Expression { case happy, focused, strong, dizzy, curious }

    static func oval(_ rect: CGRect, fill: UIColor, stroke: UIColor? = nil, width: CGFloat = 1.5) {
        let path=UIBezierPath(ovalIn:rect);fill.setFill();path.fill()
        if let stroke { stroke.setStroke();path.lineWidth=width;path.stroke() }
    }
    static func line(_ points: [CGPoint], color: UIColor = FPChibiPalette.ink, width: CGFloat = 1.5) {
        guard let first=points.first else { return }
        let path=UIBezierPath();path.move(to:first);points.dropFirst().forEach { path.addLine(to:$0) }
        path.lineWidth=width;path.lineCapStyle = .round;path.lineJoinStyle = .round;color.setStroke();path.stroke()
    }
    static func ball(in c: CGContext, center: CGPoint, radius: CGFloat, skin: FPBallSkin, expression: Expression, roll: CGFloat = 0, power: CGFloat = 0) {
        guard radius>0 else { return }
        c.saveGState();c.translateBy(x:center.x,y:center.y);c.rotate(by:roll);c.scaleBy(x:radius,y:radius)
        oval(CGRect(x:-0.86,y:0.64,width:1.8,height:0.43),fill:FPChibiPalette.ink.withAlphaComponent(0.13))
        oval(CGRect(x:-1,y:-1,width:2,height:2),fill:FPChibiPalette.ball(skin),stroke:FPChibiPalette.ink,width:0.065)
        oval(CGRect(x:-0.63,y:-0.74,width:0.55,height:0.24),fill:.white.withAlphaComponent(0.65))
        let cheek:CGFloat=0.28+power*0.14
        for x:CGFloat in [-0.66,0.66] {
            oval(CGRect(x:x-cheek/2,y:0.08,width:cheek,height:cheek*0.65),fill:FPChibiPalette.blush.withAlphaComponent(0.65))
        }
        switch expression {
        case .dizzy:
            for x:CGFloat in [-0.32,0.32] {
                line([CGPoint(x:x-0.12,y:-0.16),CGPoint(x:x+0.12,y:0.03)],width:0.07)
                line([CGPoint(x:x+0.12,y:-0.16),CGPoint(x:x-0.12,y:0.03)],width:0.07)
            }
        case .strong:
            line([CGPoint(x:-0.5,y:-0.2),CGPoint(x:-0.24,y:-0.06),CGPoint(x:-0.48,y:0.03)],width:0.075)
            line([CGPoint(x:0.5,y:-0.2),CGPoint(x:0.24,y:-0.06),CGPoint(x:0.48,y:0.03)],width:0.075)
            oval(CGRect(x:0.7,y:-0.77,width:0.19,height:0.32),fill:FPChibiPalette.water,stroke:FPChibiPalette.ink,width:0.035)
        default:
            let offset:CGFloat=expression == .curious ? 0.1:0
            for x:CGFloat in [-0.32,0.32] { oval(CGRect(x:x-0.065+offset,y:-0.18,width:0.13,height:expression == .focused ? 0.18:0.23),fill:FPChibiPalette.ink) }
        }
        if expression == .happy {
            let mouth=UIBezierPath();mouth.move(to:CGPoint(x:-0.17,y:0.24));mouth.addQuadCurve(to:CGPoint(x:0.17,y:0.24),controlPoint:CGPoint(x:0,y:0.48));mouth.lineWidth=0.055;FPChibiPalette.ink.setStroke();mouth.stroke()
        } else if expression == .strong || expression == .focused {
            line([CGPoint(x:-0.1,y:0.3),CGPoint(x:0.1,y:0.3)],width:0.06)
        } else { oval(CGRect(x:-0.085,y:0.23,width:0.17,height:0.13),fill:FPChibiPalette.ink) }
        if skin == .sesame {
            for p in [CGPoint(x:-0.58,y:-0.64),CGPoint(x:0.25,y:-0.76),CGPoint(x:0.64,y:-0.4)] {
                line([p,CGPoint(x:p.x+0.045,y:p.y+0.05)],color:FPChibiPalette.secondary,width:0.05)
            }
        }
        c.restoreGState()
    }

    static func flower(in c: CGContext, at p: CGPoint, size: CGFloat) {
        line([p,CGPoint(x:p.x+2,y:p.y+size*2)],color:FPChibiPalette.edge,width:1)
        for i in 0..<5 {
            let a=CGFloat(i)*2 * .pi/5
            oval(CGRect(x:p.x+cos(a)*size*0.6-size*0.48,y:p.y+sin(a)*size*0.6-size*0.48,width:size*0.96,height:size*0.96),fill:FPChibiPalette.card)
        }
        oval(CGRect(x:p.x-size*0.28,y:p.y-size*0.28,width:size*0.56,height:size*0.56),fill:FPChibiPalette.blush)
    }

    static func spectator(in c: CGContext, center: CGPoint, size: CGFloat, kind: Int, cheer: CGFloat) {
        c.saveGState();c.translateBy(x:center.x,y:center.y-cheer*5);c.scaleBy(x:size,y:size)
        if kind == 0 {
            oval(CGRect(x:-0.7,y:-0.65,width:1.4,height:1.4),fill:FPChibiPalette.card,stroke:FPChibiPalette.ink,width:0.055)
            let beak=UIBezierPath();beak.move(to:CGPoint(x:0.59,y:-0.1));beak.addLine(to:CGPoint(x:0.93,y:0.02));beak.addLine(to:CGPoint(x:0.61,y:0.13));beak.close();FPChibiPalette.blush.setFill();beak.fill()
            oval(CGRect(x:0.29,y:-0.25,width:0.09,height:0.13),fill:FPChibiPalette.ink)
            line([CGPoint(x:-0.35,y:0.16),CGPoint(x:-0.1,y:0.31-cheer*0.6),CGPoint(x:0.04,y:0.14)],width:0.05)
            for x:CGFloat in [-0.25,0.25] { line([CGPoint(x:x,y:0.7),CGPoint(x:x-0.05,y:0.9),CGPoint(x:x+0.12,y:0.9)],width:0.045) }
            line([CGPoint(x:-0.2,y:-0.63),CGPoint(x:-0.28,y:-0.88)],width:0.04)
        } else {
            let stem=UIBezierPath(roundedRect:CGRect(x:-0.31,y:-0.1,width:0.62,height:0.93),cornerRadius:0.22)
            FPChibiPalette.card.setFill();stem.fill();stem.lineWidth=0.055;FPChibiPalette.ink.setStroke();stem.stroke()
            let cap=UIBezierPath();cap.move(to:CGPoint(x:-0.83,y:0));cap.addCurve(to:CGPoint(x:0.83,y:0),controlPoint1:CGPoint(x:-0.62,y:-1.17),controlPoint2:CGPoint(x:0.62,y:-1.17));cap.close();FPChibiPalette.blush.setFill();cap.fill();cap.lineWidth=0.055;cap.stroke()
            for x:CGFloat in [-0.34,0.25] { oval(CGRect(x:x,y:-0.5,width:0.19,height:0.14),fill:FPChibiPalette.card) }
            for x:CGFloat in [-0.14,0.14] { oval(CGRect(x:x,y:0.25,width:0.06,height:0.1),fill:FPChibiPalette.ink) }
            if cheer>0 { line([CGPoint(x:-0.32,y:0.5),CGPoint(x:-0.6,y:0.15)],width:0.05);line([CGPoint(x:0.32,y:0.5),CGPoint(x:0.6,y:0.15)],width:0.05) }
        }
        c.restoreGState()
    }

    static func club(in c: CGContext, at origin: CGPoint, direction: CGVector, radius: CGFloat, pull: CGFloat, follow: CGFloat, classic: Bool = false) {
        c.saveGState();c.translateBy(x:origin.x,y:origin.y)
        c.rotate(by:atan2(direction.dy,direction.dx) + .pi/2)
        let distance=radius*1.9+pull*24-follow*24
        c.translateBy(x:0,y:distance);c.rotate(by:-pull*0.28+follow*0.35)
        line([CGPoint(x:4,y:0),CGPoint(x:24,y:44)],color:classic ? FPTheme.fieldInk : FPChibiPalette.ink,width:3)
        line([CGPoint(x:20,y:34),CGPoint(x:25,y:45)],color:classic ? FPTheme.gold : FPChibiPalette.blush,width:6)
        let head=UIBezierPath(roundedRect:CGRect(x:-radius*1.2,y:-3,width:radius*2.5,height:7),cornerRadius:3)
        (classic ? FPTheme.surface : FPChibiPalette.card).setFill();head.fill();(classic ? FPTheme.fieldInk : FPChibiPalette.ink).setStroke();head.lineWidth=1.7;head.stroke()
        c.restoreGState()
    }

    static func draw(in c: CGContext, view: FPCourseView) {
        let session=view.session,p=view.projection,f=p.frame,r=FPLevel.ballRadius*p.scale
        let feedback=session.chibiFeedback,reduced=FPMotion.reduced
        let fullscreen=view.immersive && !view.miniature
        (fullscreen ? FPChibiPalette.grass:FPChibiPalette.paper).setFill();c.fill(view.bounds)
        let grass=fullscreen ? UIBezierPath(rect:f):UIBezierPath(roundedRect:f,cornerRadius:7)
        if !fullscreen {
            c.saveGState();c.setShadow(offset:CGSize(width:0,height:5),blur:0,color:FPChibiPalette.edge.withAlphaComponent(0.35).cgColor)
            FPChibiPalette.grass.setFill();grass.fill();c.restoreGState()
        }
        if !fullscreen { FPChibiPalette.edge.setStroke();grass.lineWidth=2;grass.stroke() }
        // Texture covers the canvas; the existing world projection still defines collision bounds.
        let textureArea=fullscreen ? view.bounds:f
        for i in 0..<75 {
            let x=textureArea.minX+CGFloat((i*47+13)%101)/101*textureArea.width,y=textureArea.minY+CGFloat((i*29+9)%103)/103*textureArea.height
            line([CGPoint(x:x-2,y:y),CGPoint(x:x,y:y+2),CGPoint(x:x+1,y:y-2)],color:FPChibiPalette.edge.withAlphaComponent(0.24),width:0.8)
        }
        c.saveGState();grass.addClip()
        for patch in session.level.sand {
            let area=p.viewRect(patch.cg);let shape=UIBezierPath(roundedRect:area,cornerRadius:4)
            FPChibiPalette.sand.setFill();shape.fill();FPChibiPalette.edge.withAlphaComponent(0.4).setStroke();shape.lineWidth=1;shape.stroke()
            for i in 0..<16 { let x=area.minX+CGFloat((i*17+2)%29)/29*area.width,y=area.minY+CGFloat((i*13+3)%31)/31*area.height;oval(CGRect(x:x,y:y,width:1.3,height:1.3),fill:FPChibiPalette.secondary.withAlphaComponent(0.4)) }
        }
        for water in session.level.hazards { terrain(p.viewRect(water.cg),water:true,c:c) }
        for (id,rect) in session.world.solids {
            let area=p.viewRect(rect),water=id == "canal" || id.hasPrefix("division-")
            terrain(area,water:water,c:c,penalty:id == "penalty")
        }
        if view.immersive {
            for division in view.divisionRects {
                let seam=division.intersection(f);guard !seam.isNull else { continue }
                terrain(seam,water:true,c:c)
                let bridge=p.bridge(in:p.worldRect(seam))
                if !bridge.isNull { terrain(p.viewRect(bridge),water:false,c:c) }
            }
        }
        if session.speedLineReward,session.prediction.count>1 {
            c.setLineDash(phase:0,lengths:[4,5]);line(session.prediction.map { p.point($0) },color:FPChibiPalette.ink.withAlphaComponent(0.65),width:2);c.setLineDash(phase:0,lengths:[])
        }
        if session.phase == .rolling,!reduced,session.trail.count>1 {
            line(session.trail.map { p.point($0) },color:FPChibiPalette.card.withAlphaComponent(0.6),width:2)
        }
        let b=p.point(session.world.position),cup=p.point(session.level.hole.cg)
        oval(CGRect(x:cup.x-r*1.8,y:cup.y-r*1.3,width:r*3.6,height:r*2.6),fill:FPChibiPalette.edge)
        oval(CGRect(x:cup.x-r*1.3,y:cup.y-r,width:r*2.6,height:r*2),fill:FPChibiPalette.ink)
        if feedback.visibleCue == .nearMiss {
            for x:CGFloat in [-0.45,0.45] { oval(CGRect(x:cup.x+r*x-1,y:cup.y-2,width:2,height:3),fill:FPChibiPalette.card) }
        }
        let flagHeight=max(24,min(58,p.scale*0.17))
        let growth=view.flagGrowth
        c.saveGState();c.translateBy(x:cup.x,y:cup.y);c.scaleBy(x:1,y:growth)
        line([.zero,CGPoint(x:0,y:-flagHeight)],width:2)
        let flag=UIBezierPath();flag.move(to:CGPoint(x:1,y:-flagHeight));flag.addQuadCurve(to:CGPoint(x:flagHeight*0.58,y:-flagHeight+7),controlPoint:CGPoint(x:flagHeight*0.3,y:-flagHeight+8));flag.addLine(to:CGPoint(x:flagHeight*0.52,y:-flagHeight+21));flag.addQuadCurve(to:CGPoint(x:1,y:-flagHeight+14),controlPoint:CGPoint(x:flagHeight*0.25,y:-flagHeight+22));flag.close();FPChibiPalette.blush.setFill();flag.fill();flag.lineWidth=1.4;FPChibiPalette.ink.setStroke();flag.stroke();c.restoreGState()
        if let shot=session.preview {
            let d=p.vector(shot.direction),length=(0.10+shot.power*0.22)*p.scale
            c.setLineDash(phase:0,lengths:[3,6]);line([b,CGPoint(x:b.x+d.dx*length,y:b.y+d.dy*length)],color:FPChibiPalette.card,width:3);c.setLineDash(phase:0,lengths:[])
            club(in:c,at:b,direction:d,radius:r,pull:shot.power,follow:0)
        } else if feedback.isSwinging,!reduced {
            let t=CGFloat(feedback.swingAge/FPChibiTuning.swing),d=p.vector(feedback.shotDirection)
            club(in:c,at:p.point(feedback.shotOrigin),direction:d,radius:r,pull:0,follow:sin(t * .pi))
        }
        if session.phase != .success && session.phase != .sinking {
            let power=session.preview?.power ?? 0
            let expression:Expression=power>FPChibiTuning.strongPull ? .strong:session.preview != nil ? .focused:feedback.visibleCue == .nearMiss ? .curious:feedback.visibleCue == .collision && feedback.age<FPChibiTuning.collisionDuration ? .dizzy:.happy
            let roll:CGFloat=session.phase == .rolling && !reduced ? sin((session.world.position.x+session.world.position.y)*30)*0.3:0
            ball(in:c,center:b,radius:r,skin:session.ballSkin,expression:expression,roll:roll,power:power)
        }
        c.restoreGState()
        if !view.miniature {
            let cheer:CGFloat=session.phase == .success ? (reduced ? 1:feedback.age<FPMotion.success ? abs(sin(CGFloat(feedback.age/FPMotion.success) * .pi*3)):0.3):0
            let spectatorSize:CGFloat=min(21,max(12,p.scale*0.06))
            for (i,center) in [CGPoint(x:f.minX-FPChibiTuning.spectatorDistance,y:f.midY-24),CGPoint(x:f.maxX+FPChibiTuning.spectatorDistance,y:f.midY+30)].enumerated() {
                let desired=CGRect(x:center.x-spectatorSize,y:center.y-spectatorSize,width:spectatorSize*2,height:spectatorSize*2)
                let terrainAreas=session.world.solids.map { p.viewRect($0.1) }+session.level.hazards.map { p.viewRect($0.cg) }+session.level.sand.map { p.viewRect($0.cg) }
                let area=fullscreen ? FPRegionSnapshot.placed(desired.size,near:desired.origin,in:view.bounds.inset(by:view.safeAreaInsets).insetBy(dx:4,dy:4),excluding:view.exclusions+terrainAreas):desired
                if area.width>0,view.bounds.insetBy(dx:4,dy:4).contains(area),!view.exclusions.contains(where:{$0.intersects(area)}) {
                    let placedCenter=CGPoint(x:area.midX,y:area.midY)
                    spectator(in:c,center:placedCenter,size:spectatorSize,kind:i,cheer:cheer);flower(in:c,at:CGPoint(x:placedCenter.x-5,y:placedCenter.y+48),size:4)
                }
            }
            let text=session.club.state.voice == .quiet ? "" : session.preview.map { $0.power>FPChibiTuning.strongPull ? (session.chibiMood == .cozy ? FPL10n.text("hold_breath"):FPL10n.text("cheeks_hint")):(session.chibiMood == .cozy ? FPL10n.text("pull_gently"):FPL10n.text("aim_silly")) } ?? session.ballTalkText
            if !text.isEmpty,session.phase != .success { cue(text,near:b,in:view,c:c) }
        }
        if session.penaltyActive || session.phase == .resetting {
            FPChibiPalette.blush.setStroke();let border=UIBezierPath(roundedRect:f.insetBy(dx:-3,dy:-3),cornerRadius:9);border.lineWidth=2;border.stroke()
        }
    }
    private static func terrain(_ area: CGRect, water: Bool, c: CGContext, penalty: Bool = false) {
        (water ? FPChibiPalette.water:penalty ? FPChibiPalette.blush:FPChibiPalette.sand).setFill();c.fill(area)
        FPChibiPalette.edge.setStroke();let edge=UIBezierPath(rect:area);edge.lineWidth=1.5;edge.stroke()
        c.saveGState();c.clip(to:area)
        if water {
            for i in 0..<8 { let y=area.minY+CGFloat(i)*18+8;line([CGPoint(x:area.minX+4,y:y),CGPoint(x:area.midX,y:y+2),CGPoint(x:area.maxX-3,y:y)],color:FPChibiPalette.card.withAlphaComponent(0.65),width:1) }
        } else {
            for i in 1..<6 { let x=area.minX+area.width*CGFloat(i)/6;line([CGPoint(x:x,y:area.minY+2),CGPoint(x:x,y:area.maxY-2)],color:FPChibiPalette.edge.withAlphaComponent(0.3),width:1) }
        }
        c.restoreGState()
    }
    private static func cue(_ text:String,near point:CGPoint,in view:FPCourseView,c:CGContext) {
        let style=NSMutableParagraphStyle();style.alignment = .center
        let attributes:[NSAttributedString.Key:Any]=[.font:FPChibiPalette.handwriting(.callout,compatibleWith:view.traitCollection),.foregroundColor:FPChibiPalette.ink,.paragraphStyle:style]
        let safe=FPRegionSnapshot.usable(view.field.insetBy(dx:8,dy:8),excluding:view.exclusions)
        guard safe.width>40 else { return }
        let measured=(text as NSString).boundingRect(with:CGSize(width:max(1,safe.width-24),height:200),options:.usesLineFragmentOrigin,attributes:attributes,context:nil)
        let size=CGSize(width:min(safe.width,ceil(measured.width)+24),height:ceil(measured.height)+16)
        let area=FPRegionSnapshot.placed(size,near:CGPoint(x:point.x-size.width/2,y:point.y-size.height-22),in:safe,excluding:view.exclusions)
        guard area.width>0 else { return }
        FPChibiPalette.card.setFill();let card=UIBezierPath(roundedRect:area,cornerRadius:12);card.fill();FPChibiPalette.edge.withAlphaComponent(0.4).setStroke();card.lineWidth=1;card.stroke()
        (text as NSString).draw(in:area.insetBy(dx:12,dy:8),withAttributes:attributes)
    }
}

final class FPChibiPortrait: UIView {
    var skin:FPBallSkin = .rice
    var expression:FPChibiArt.Expression = .happy
    var power:CGFloat = 0
    var roll:CGFloat = 0
    override func draw(_ rect:CGRect) {
        guard let c=UIGraphicsGetCurrentContext() else { return }
        FPChibiArt.ball(in:c,center:CGPoint(x:bounds.midX,y:bounds.midY),radius:min(bounds.width,bounds.height)*0.43,skin:skin,expression:expression,roll:roll,power:power)
    }
}
