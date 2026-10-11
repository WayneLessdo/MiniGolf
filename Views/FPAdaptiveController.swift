import UIKit

final class FPAdaptiveController: UIViewController {
    private let session:FPDemoSession
    private let course: FPCourseController
    private let controls: FPControlsController
    private var host:UIViewController?
    private var mode=""
    private var layoutSignature=""
    private var lastDiagnosticTime:CFTimeInterval=0
    private var diagnosticSignature=""
    private var previousSize=CGSize.zero
    private let canal=UIView()
    private let regionLayer=CAShapeLayer()
    private var hingeInteraction:UIInteraction?
    private var previousHingeAngle:CGFloat?
    private var lastHingeEffect:CFTimeInterval=0
    init(session:FPDemoSession) {
        self.session=session;course=FPCourseController(session:session);controls=FPControlsController(session:session)
        super.init(nibName:nil,bundle:nil)
        session.changed = { [weak self] in self?.refresh() }
    }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad();view.backgroundColor=FPTheme.surface;view.accessibilityIdentifier="gameArrangement"
        canal.isUserInteractionEnabled=false
        canal.backgroundColor=UIImage(named:"CanalTile").map { UIColor(patternImage:$0) } ?? FPTheme.water
        controls.installScreenTap(in: view)
        controls.menu = { [weak self] in self?.makeMenu() ?? UIMenu() }
        regionLayer.fillColor=FPTheme.red.withAlphaComponent(0.15).cgColor;regionLayer.strokeColor=FPTheme.red.cgColor;regionLayer.lineWidth=1
        if #available(iOS 27.1, *) {
            let interaction=UIHingeInteraction { [weak self] _,update in
                guard let self,let angle=update.hinge?.angle else { return }
                if let old=self.previousHingeAngle,abs(old-angle)>0.08,CACurrentMediaTime()-self.lastHingeEffect>FPMotion.grass { self.course.course.hingeRipple();self.lastHingeEffect=CACurrentMediaTime() }
                self.previousHingeAngle=angle
            }
            view.addInteraction(interaction);hingeInteraction=interaction
        }
        registerForTraitChanges([UITraitHorizontalSizeClass.self,UITraitVerticalSizeClass.self,UITraitPreferredContentSizeCategory.self]) { (controller:FPAdaptiveController,_:UITraitCollection) in controller.view.setNeedsLayout() }
        NotificationCenter.default.addObserver(self, selector: #selector(motionChanged), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector:#selector(motionChanged),name:UIAccessibility.reduceTransparencyStatusDidChangeNotification,object:nil)
        NotificationCenter.default.addObserver(self,selector:#selector(motionChanged),name:UIAccessibility.voiceOverStatusDidChangeNotification,object:nil)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--handheld") { session.handheld=true }
        if ProcessInfo.processInfo.arguments.contains("--immersive") { session.immersivePreference=true }
        #endif
    }
    @objc private func motionChanged() {
        session.updateMotionPreference();course.course.stopLargeMotion();controls.refreshVisibility(immediate:true);course.refreshHUDVisibility(immediate:true)
    }
    func stopPresentation() { controls.pull.cancelTracking();course.course.stopLargeMotion() }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated);course.course.refresh() }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let snapshot=FPRegionSnapshot.read(in:view)
        let wanted=session.handheld ? "handheld":"immersive"
        if mode != wanted { install(wanted) }
        host?.view.frame=view.bounds
        host?.view.layoutIfNeeded()
        course.divisionRects=snapshot.divisions.map { view.convert($0,to:course.course) }
        course.exclusions=snapshot.exclusions.map { view.convert($0,to:course.view) }
        controls.exclusions=snapshot.exclusions.map { view.convert($0,to:controls.view) }
        course.view.setNeedsLayout();controls.view.setNeedsLayout()
        if previousSize != view.bounds.size { controls.pull.cancelTracking();session.cancel();previousSize=view.bounds.size }
        if mode != "immersive",let region=snapshot.divisions.first {
            // Decorative thickness is a visual token, not a fabricated hardware width.
            canal.frame=region.width<region.height ? CGRect(x:region.midX-max(8,region.width)/2,y:region.minY,width:max(8,region.width),height:region.height):CGRect(x:region.minX,y:region.midY-max(8,region.height)/2,width:region.width,height:max(8,region.height))
            canal.isHidden=false
        } else { canal.isHidden=true }
        let path=UIBezierPath();snapshot.exclusions.forEach { path.append(UIBezierPath(rect:$0)) };regionLayer.path=path.cgPath;regionLayer.isHidden = !session.showRegions
        writeDiagnostics(snapshot)
    }
    private func detach(_ child:UIViewController) {
        child.willMove(toParent:nil);child.view.removeFromSuperview();child.removeFromParent()
    }
    private func install(_ next:String) {
        session.cancel();controls.pull.cancelTracking()
        if let split=host as? UISplitViewController { split.setViewController(nil,for:.primary);split.setViewController(nil,for:.secondary) }
        if course.parent != nil { detach(course) };if controls.parent != nil { detach(controls) }
        if let host { detach(host) }
        mode=next
        course.immersive = next == "immersive";controls.floating = next == "immersive";controls.turnInput=false
        let controller:UIViewController
        if next == "regular" {
            let split=UISplitViewController(style:.doubleColumn)
            split.primaryEdge = .trailing
            split.presentsWithGesture=false
            split.displayModeButtonVisibility = .never
            split.showsSecondaryOnlyButton=false
            split.preferredSplitBehavior = .tile
            split.preferredDisplayMode = .oneBesideSecondary
            split.preferredPrimaryColumnWidthFraction=0.64
            split.minimumPrimaryColumnWidth=0
            split.maximumPrimaryColumnWidth = .greatestFiniteMagnitude
            split.setViewController(course,for:.primary)
            split.setViewController(controls,for:.secondary)
            controller=split
        } else {
            let layout=FPPlayLayoutController(course:course,controls:controls,handheld:next == "handheld",immersive:next == "immersive")
            let navigation=UINavigationController(rootViewController:layout)
            navigation.setNavigationBarHidden(true,animated:false)
            controller=navigation
        }
        host=controller;addChild(controller);view.insertSubview(controller.view,at:0);controller.didMove(toParent:self)
        view.addSubview(canal);view.layer.addSublayer(regionLayer)
        refresh()
    }
    private func refresh() {
        guard isViewLoaded else { return }
        overrideUserInterfaceStyle=session.isChibi ? .light:.unspecified
        view.backgroundColor=session.isChibi ? FPChibiPalette.paper:FPTheme.surface
        if session.isChibi { canal.backgroundColor=FPChibiPalette.water }
        else { canal.backgroundColor=UIImage(named:"CanalTile").map { UIColor(patternImage:$0) } ?? FPTheme.water }
        controls.refresh();course.refreshHeader();course.course.refresh()
        let regions=FPRegionSnapshot.read(in:view)
        let layout="\(session.handheld)|\(String(describing:session.immersivePreference))|\(session.teeID)|\(regions.divisions)|\(regions.activeDivisions)|\(regions.occlusions)"
        if layout != layoutSignature { layoutSignature=layout;view.setNeedsLayout() }
        #if DEBUG
        let diagnostic="\(session.phase)|\(session.strokes)|\(session.eventSerial)|\(session.restorationCount)|\(FPSound.enabled)|\(FPHaptics.enabled)|\(session.gameMode)|\(session.chibiMood)|\(session.ballSkin)|\(session.chibiFeedback.serial)|\(String(describing:session.chibiFeedback.visibleCue))"
        let now=CACurrentMediaTime()
        if diagnostic != diagnosticSignature || now-lastDiagnosticTime>0.25 {
            diagnosticSignature=diagnostic;lastDiagnosticTime=now;writeDiagnostics(regions)
        }
        #endif
    }
    private func makeMenu() -> UIMenu {
        UIMenu(title:"球场选项",children:session.presentationActions + [UIMenu(title:"选择地图 · 选择后重新开始",image:UIImage(systemName:"map"),children:session.levelActions)] + [FPSound.settingAction,FPHaptics.settingAction,
            UIAction(title:"掌机模式",image:UIImage(systemName:"gamecontroller"),state:session.handheld ? .on:.off) { [weak self] _ in self?.session.handheld.toggle();self?.view.setNeedsLayout() },
            UIAction(title:"重播开球",image:UIImage(systemName:"flag")) { [weak self] _ in self?.session.reset();self?.course.course.teeOff() },
            UIAction(title:"下一关",image:UIImage(systemName:"flag.checkered")) { [weak self] _ in self?.session.nextLevel() },
            
            UIAction(title:"显示安全区域",image:UIImage(systemName:"rectangle.dashed"),state:session.showRegions ? .on:.off) { [weak self] _ in self?.session.showRegions.toggle();self?.view.setNeedsLayout() }
        ])
    }
    private func writeDiagnostics(_ snapshot:FPRegionSnapshot) {
        #if DEBUG
        let s=view.safeAreaInsets
        var payload:[String:Any] = ["courseFrame":NSCoder.string(for: view.convert(course.view.bounds,from:course.view)),"courseExclusions":course.exclusions.map { NSCoder.string(for:$0) },"mode":mode,"bounds":NSCoder.string(for: view.bounds),"horizontalSizeClass":traitCollection.horizontalSizeClass.rawValue,"verticalSizeClass":traitCollection.verticalSizeClass.rawValue,"scale":traitCollection.displayScale,"insets":["top":s.top,"left":s.left,"bottom":s.bottom,"right":s.right],"division":snapshot.divisions.map { NSCoder.string(for: $0) },"activeDivision":snapshot.activeDivisions.map { NSCoder.string(for: $0) },"occlusion":snapshot.occlusions.map { NSCoder.string(for: $0) },"handheldSwitch":session.handheld,"phase":session.phase.rawValue,"strokes":session.strokes]
        let courseVisible=FPRegionSnapshot.isVisible(course.course,in:view),controlsVisible=FPRegionSnapshot.isVisible(controls.pull,in:view)
        payload["courseVisible"]=courseVisible;payload["controlsVisible"]=controlsVisible
        var violations:[String]=[]
        func inspect(_ element:UIView) {
            if let button=element as? UIButton,FPRegionSnapshot.isVisible(button,in:view),snapshot.exclusions.contains(where:{$0.intersects(button.convert(button.bounds,to:view))}) { violations.append(button.accessibilityLabel ?? "button") }
            element.subviews.forEach(inspect)
        }
        inspect(controls.view)
        payload["buttonRegionViolations"]=violations;payload["elapsed"]=session.elapsed
        payload["ballWorld"]=NSCoder.string(for:session.world.position)
        payload["ballUnderFold"]=course.immersive && course.course.divisionRects.contains { $0.contains(course.course.projection.point(session.world.position)) }
        payload["field"]=NSCoder.string(for:course.course.field);payload["across"]=course.course.projection.across
        payload["reservedBanks"]=(session.world.divisionBanks ?? []).map { NSCoder.string(for:$0) };payload["pullAlpha"]=controls.pull.alpha
        payload["controlsFrame"]=NSCoder.string(for:view.convert(controls.view.bounds,from:controls.view))
        payload["restorationCount"]=session.restorationCount;payload["worldVelocity"]=[session.world.velocity.dx,session.world.velocity.dy]
        payload["hudAlpha"]=controls.toolbar.alpha
        payload["pullFrame"]=NSCoder.string(for:controls.pull.convert(controls.pull.bounds,to:view))
        payload["scoreFrame"]=NSCoder.string(for:controls.scoreCard.convert(controls.scoreCard.bounds,to:view))
        payload["toolFrame"]=NSCoder.string(for:controls.toolbar.convert(controls.toolbar.bounds,to:view))
        payload["reduceMotion"]=FPMotion.reduced;payload["replaying"]=session.isReplaying;payload["pullEnabled"]=session.canAim;payload["replaySamples"]=session.shotReplay.count
        payload["gameMode"]=session.gameMode.rawValue;payload["chibiMood"]=session.chibiMood.rawValue;payload["ballSkin"]=session.ballSkin.rawValue
        payload["cue"]=session.chibiFeedback.visibleCue?.rawValue ?? "none";payload["nearMissCount"]=session.chibiFeedback.nearMissCount;payload["celebrationCount"]=session.chibiFeedback.celebrationCount
        payload["screenTapMaximumDuration"]=FPMotion.screenTapMaximumDuration
        payload["sceneSessionID"]=view.window?.windowScene?.session.persistentIdentifier
        let accessibleState="immersive=\(mode == "immersive");across=\(course.course.projection.across);pullAlpha=\(controls.pull.alpha);hudAlpha=\(controls.toolbar.alpha);level=\(session.level.id);phase=\(session.phase.rawValue);strokes=\(session.strokes);launch=\(session.lastLaunch?.id.uuidString ?? "none");restored=\(session.restorationCount);sound=\(FPSound.enabled);haptics=\(FPHaptics.enabled);courseVisible=\(courseVisible);controlsVisible=\(controlsVisible)"
        let proof=accessibleState+";replaying=\(session.isReplaying);pullEnabled=\(session.canAim)"+";gameMode=\(session.gameMode.rawValue);chibiMood=\(session.chibiMood.rawValue);ballSkin=\(session.ballSkin.rawValue);cue=\(session.chibiFeedback.visibleCue?.rawValue ?? "none");bounds=\(NSCoder.string(for:view.bounds));traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(s.top),\(s.left),\(s.bottom),\(s.right);division=\(snapshot.divisions);occlusion=\(snapshot.occlusions);reduceMotion=\(FPMotion.reduced)"
        if view.accessibilityValue != proof { view.accessibilityValue=proof }
        if let data=try? JSONSerialization.data(withJSONObject:payload,options:.prettyPrinted),let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first { try? data.write(to:dir.appendingPathComponent("layout-diagnostics.json"),options:.atomic) }
        #endif
    }
}

final class FPPlayLayoutController:UIViewController {
    let course:FPCourseController;let controls:FPControlsController;let handheld:Bool;let immersive:Bool
    init(course:FPCourseController,controls:FPControlsController,handheld:Bool,immersive:Bool=false) { self.course=course;self.controls=controls;self.handheld=handheld;self.immersive=immersive;super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad();view.accessibilityIdentifier="immersiveCanvas"
        for child in [course as UIViewController,controls as UIViewController] { addChild(child);view.addSubview(child.view);child.didMove(toParent:self) }
        controls.view.layer.shadowColor=UIColor.black.cgColor;controls.view.layer.shadowOpacity=course.session.isChibi ? 0:FPTheme.shadowOpacity;controls.view.layer.shadowRadius=18
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // A previous navigation host may receive one last layout during reparenting.
        guard course.parent === self, controls.parent === self else { return }
        let s=view.safeAreaInsets
        let safe=CGRect(x:s.left,y:s.top,width:max(0,view.bounds.width-s.left-s.right),height:max(0,view.bounds.height-s.top-s.bottom))
        let snap=FPRegionSnapshot.read(in:view)
        let horizontal=snap.activeDivisions.first { $0.width>$0.height }
        if immersive {
            course.overlayClearance=traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? FPTheme.pullDiameter+FPTheme.hudGutter:0
            course.view.frame=view.bounds
            controls.view.frame=view.bounds
            controls.exclusions=snap.exclusions.map { view.convert($0,to:controls.view) }
            controls.view.layoutIfNeeded()
            course.headerMaximumWidth=min(260,max(80,controls.toolbar.frame.minX-s.left-FPTheme.hudGutter*2))
            course.view.setNeedsLayout();course.view.layoutIfNeeded()
            controls.turnInput=course.course.across
            return
        }
        let targetHeight=min(safe.height*0.46, 280)
        course.overlayClearance=handheld ? 0:targetHeight+16
        let controlsArea:CGRect
        if handheld,let divider=horizontal {
            course.view.frame=CGRect(x:0,y:0,width:view.bounds.width,height:divider.minY)
            controlsArea=CGRect(x:safe.minX,y:divider.maxY,width:safe.width,height:max(0,safe.maxY-divider.maxY))
        } else if handheld {
            let y=safe.maxY-targetHeight
            course.view.frame=CGRect(x:0,y:0,width:view.bounds.width,height:y)
            controlsArea=CGRect(x:safe.minX,y:y,width:safe.width,height:targetHeight)
        } else {
            course.view.frame=view.bounds
            course.course.bottomClearance=targetHeight+s.bottom+16
            controlsArea=CGRect(x:safe.minX+12,y:safe.maxY-targetHeight,width:max(0,safe.width-24),height:targetHeight)
        }
        controls.view.frame=FPRegionSnapshot.usable(controlsArea,excluding:snap.exclusions)
        if !handheld {
            course.view.layoutIfNeeded()
            course.course.bottomClearance=targetHeight+s.bottom+16
            course.course.setNeedsDisplay()
        }
    }
}
