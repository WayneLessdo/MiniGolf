import UIKit

struct FPRegionSnapshot {
    var divisions: [CGRect] = []
    var activeDivisions: [CGRect] = []
    var occlusions: [CGRect] = []
    var exclusions: [CGRect] { divisions + occlusions }
    @MainActor static func read(in view: UIView) -> FPRegionSnapshot {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--simulate-division"),["gameArrangement","immersiveCanvas"].contains(view.accessibilityIdentifier ?? "") {
            let b=view.bounds
            let division=CGRect(x:b.width*0.8,y:0,width:18,height:b.height)
            let camera=CGRect(x:max(0,b.width-58),y:0,width:40,height:64)
            return FPRegionSnapshot(divisions:[division],activeDivisions:[division],occlusions:[camera])
        }
        #endif
        guard #available(iOS 27.1, *) else { return FPRegionSnapshot() }
        let divisions = view.reservedRegions(kind: .division, options: .includeInactive)
        return FPRegionSnapshot(divisions: divisions.map(\.frame),
                                activeDivisions: divisions.filter(\.isActive).map(\.frame),
                                occlusions: view.reservedRegions(kind: .occlusion).map(\.frame))
    }
    @MainActor static func isVisible(_ content:UIView,in container:UIView) -> Bool {
        guard content.window === container.window,content.window != nil else { return false }
        var current:UIView?=content
        var rect=content.convert(content.bounds,to:container)
        while let ancestor=current {
            if ancestor.isHidden || ancestor.alpha<=0.01 { return false }
            if ancestor.clipsToBounds { rect=rect.intersection(ancestor.convert(ancestor.bounds,to:container)) }
            current=ancestor.superview
        }
        return !rect.isNull && rect.width>1 && rect.height>1
    }
    /// Keep each HUD group near its preferred edge, using the actual reserved rectangles.
    @MainActor static func placed(_ size:CGSize,near origin:CGPoint,in safe:CGRect,excluding regions:[CGRect])->CGRect {
        let desired=CGRect(origin:origin,size:size)
        var candidates=[desired,
                        CGRect(x:safe.minX,y:safe.minY,width:size.width,height:size.height),
                        CGRect(x:safe.maxX-size.width,y:safe.minY,width:size.width,height:size.height),
                        CGRect(x:safe.minX,y:safe.maxY-size.height,width:size.width,height:size.height),
                        CGRect(x:safe.maxX-size.width,y:safe.maxY-size.height,width:size.width,height:size.height)]
        for r in regions {
            candidates += [CGRect(x:r.minX-size.width-FPTheme.hudGap,y:origin.y,width:size.width,height:size.height),
                           CGRect(x:r.maxX+FPTheme.hudGap,y:origin.y,width:size.width,height:size.height),
                           CGRect(x:origin.x,y:r.minY-size.height-FPTheme.hudGap,width:size.width,height:size.height),
                           CGRect(x:origin.x,y:r.maxY+FPTheme.hudGap,width:size.width,height:size.height)]
        }
        return candidates.map { r in CGRect(x:min(safe.maxX-size.width,max(safe.minX,r.minX)),y:min(safe.maxY-size.height,max(safe.minY,r.minY)),width:size.width,height:size.height) }
            .filter { candidate in safe.contains(candidate) && !regions.contains(where:{candidate.intersects($0)}) }
            .min { hypot($0.minX-origin.x,$0.minY-origin.y)<hypot($1.minX-origin.x,$1.minY-origin.y) } ?? .zero
    }
    /// Choose a continuous interactive rectangle, never mirror left/right insets.
    static func usable(_ rect: CGRect, excluding exclusions: [CGRect]) -> CGRect {
        var candidates = [rect]
        for raw in exclusions {
            let region = raw.insetBy(dx: -8, dy: -8)
            candidates = candidates.flatMap { area -> [CGRect] in
                let hit = area.intersection(region)
                guard !hit.isNull else { return [area] }
                return [CGRect(x:area.minX,y:area.minY,width:hit.minX-area.minX,height:area.height),
                        CGRect(x:hit.maxX,y:area.minY,width:area.maxX-hit.maxX,height:area.height),
                        CGRect(x:area.minX,y:area.minY,width:area.width,height:hit.minY-area.minY),
                        CGRect(x:area.minX,y:hit.maxY,width:area.width,height:area.maxY-hit.maxY)]
                    .filter { $0.width > 0 && $0.height > 0 }
            }
        }
        return candidates.max(by: { $0.width*$0.height < $1.width*$1.height }) ?? .zero
    }
}

/// Similarity transform: one scale for ball, terrain, collision and aiming. No device/orientation lookup.
struct FPCourseProjection {
    let frame:CGRect
    let scale:CGFloat
    let across:Bool
    init(area:CGRect,across:Bool) {
        self.across=across
        let size=across ? CGSize(width:FPLevel.world.height,height:1):FPLevel.world.size
        scale=max(0,min(area.width/size.width,area.height/size.height))
        frame=CGRect(x:area.midX-size.width*scale/2,y:area.midY-size.height*scale/2,width:size.width*scale,height:size.height*scale)
    }
    func point(_ world:CGPoint)->CGPoint {
        across ? CGPoint(x:frame.minX+(FPLevel.world.height-world.y)*scale,y:frame.minY+world.x*scale):CGPoint(x:frame.minX+world.x*scale,y:frame.minY+world.y*scale)
    }
    func worldPoint(_ screen:CGPoint)->CGPoint {
        guard scale>0 else { return .zero }
        return across ? CGPoint(x:(screen.y-frame.minY)/scale,y:FPLevel.world.height-(screen.x-frame.minX)/scale):CGPoint(x:(screen.x-frame.minX)/scale,y:(screen.y-frame.minY)/scale)
    }
    func vector(_ world:CGVector)->CGVector { across ? CGVector(dx:-world.dy,dy:world.dx):world }
    func worldVector(_ screen:CGVector)->CGVector { across ? CGVector(dx:screen.dy,dy:-screen.dx):screen }
    private func rect(_ a:CGPoint,_ b:CGPoint)->CGRect { CGRect(x:min(a.x,b.x),y:min(a.y,b.y),width:abs(a.x-b.x),height:abs(a.y-b.y)) }
    func viewRect(_ world:CGRect)->CGRect { rect(point(world.origin),point(CGPoint(x:world.maxX,y:world.maxY))) }
    func worldRect(_ screen:CGRect)->CGRect { rect(worldPoint(screen.origin),worldPoint(CGPoint(x:screen.maxX,y:screen.maxY))).intersection(FPLevel.world) }
    func bridge(in seam:CGRect)->CGRect {
        if seam.width>=seam.height { return seam.intersection(CGRect(x:0.34,y:0,width:0.32,height:FPLevel.world.height)) }
        return seam.intersection(CGRect(x:0,y:FPLevel.world.midY-0.16,width:1,height:0.32))
    }
    func banks(for division:CGRect)->[CGRect] {
        let seam=worldRect(division)
        guard !seam.isNull,seam.width>0,seam.height>0 else { return [] }
        let passage=bridge(in:seam)
        guard !passage.isNull else { return [seam] }
        let banks=seam.width>=seam.height
            ? [CGRect(x:seam.minX,y:seam.minY,width:passage.minX-seam.minX,height:seam.height),CGRect(x:passage.maxX,y:seam.minY,width:seam.maxX-passage.maxX,height:seam.height)]
            : [CGRect(x:seam.minX,y:seam.minY,width:seam.width,height:passage.minY-seam.minY),CGRect(x:seam.minX,y:passage.maxY,width:seam.width,height:seam.maxY-passage.maxY)]
        return banks.filter { $0.width>0 && $0.height>0 }
    }
}
