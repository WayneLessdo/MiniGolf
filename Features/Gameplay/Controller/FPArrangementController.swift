import UIKit

/// Navigation root on iOS 27.1+. The system owns regular pane geometry.
@available(iOS 27.1, *)
final class FPArrangementController: UIArrangementViewController {
    private let session: FPDemoSession
    private let course: FPCourseController
    private let controls: FPControlsController
    private var singlePane: FPPlayLayoutController?
    private var mode = ""
    private var previousBounds = CGRect.zero
    private var previousAngle: CGFloat?
    private var previousHingeState: UIHinge.Status?
    private var lastHingeEffect: CFTimeInterval = 0
    private var isConfiguring = false
    private var usingOverlay = false
    private var overlayCheckPending = false
    private var arrangementBounds = CGRect.zero
    private let canal = UIView()
    private let regionLayer = CAShapeLayer()

    init(session: FPDemoSession) {
        self.session = session
        course = FPCourseController(session: session)
        controls = FPControlsController(session: session)
        super.init()
        session.changed = { [weak self] in self?.refresh() }
    }
    required init?(coder: NSCoder) { fatalError("Use init(session:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FPTheme.surface
        view.accessibilityIdentifier="gameArrangement"
        canal.isUserInteractionEnabled = false
        canal.backgroundColor = UIImage(named: "CanalTile").map(UIColor.init(patternImage:)) ?? FPTheme.water
        view.addSubview(canal)
        regionLayer.fillColor = FPTheme.red.withAlphaComponent(0.15).cgColor
        regionLayer.strokeColor = FPTheme.red.cgColor
        view.layer.addSublayer(regionLayer)
        controls.installScreenTap(in: view)
        controls.menu = { [weak self] in self?.makeMenu() ?? UIMenu() }
        view.addInteraction(UIHingeInteraction { [weak self] _, update in
            guard let self, let hinge = update.hinge else { return }
            // Hinge values never feed configure(), constraints, score, or physics.
            let stateChanged = self.previousHingeState != nil && self.previousHingeState != hinge.status
            let moved = self.previousAngle.map { abs($0 - hinge.angle) > 0.08 } ?? false
            let now = CACurrentMediaTime()
            if !FPMotion.reduced && now - self.lastHingeEffect > FPMotion.grass {
                if stateChanged && hinge.status == .fullyOpen && self.session.phase == .ready {
                    self.course.course.teeOff()
                    self.lastHingeEffect = now
                } else if moved {
                    self.course.course.hingeRipple()
                    if self.session.phase == .penalty { self.course.course.showPenaltyFeedback() }
                    self.lastHingeEffect = now
                }
            }
            self.previousAngle = hinge.angle
            self.previousHingeState = hinge.status
        })
        NotificationCenter.default.addObserver(self, selector: #selector(motionChanged),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        #if DEBUG
        session.handheld = ProcessInfo.processInfo.arguments.contains("--handheld")
        #endif
        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) {
            (controller: FPArrangementController, _: UITraitCollection) in controller.view.setNeedsLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        course.course.refresh()
    }

    override func viewDidLayoutSubviews() {
        guard !isConfiguring else { super.viewDidLayoutSubviews(); return }
        let regions=FPRegionSnapshot.read(in:view)
        let horizontalFold=regions.activeDivisions.contains { $0.width>$0.height }
        let horizontalDivision=regions.divisions.contains { $0.width>$0.height }
        let regularMode = horizontalFold ? "regular-folded" : horizontalDivision ? "regular-overlay" : mode == "regular-overlay" && arrangementBounds == view.bounds ? "regular-overlay":"regular-arrangement"
        let next = session.handheld ? "handheld-manual" : traitCollection.horizontalSizeClass == .regular ? regularMode : "compact"
        if next != mode { configure(next) }
        if mode == "regular-arrangement", arrangementBounds != view.bounds {
            if usingOverlay { configure(next) }
            else { updateArrangement(horizontalSplit()) }
        }
        arrangementBounds=view.bounds
        super.viewDidLayoutSubviews()

        let snapshot = FPRegionSnapshot.read(in: view)
        if mode == "regular-arrangement", !usingOverlay, !overlayCheckPending {
            overlayCheckPending=true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.overlayCheckPending=false
                guard self.mode == "regular-arrangement",!self.usingOverlay else { return }
                if self.state(for:.secondary)?.isHidden == true {
                    self.configure("regular-overlay")
                    self.view.setNeedsLayout()
                }
            }
        }
        if previousBounds != view.bounds {
            controls.pull.cancelTracking()
            session.cancel()
            previousBounds = view.bounds
        }
        course.divisionRects = snapshot.divisions.map { view.convert($0,to:course.course) }
        let courseExclusions = snapshot.exclusions.map { view.convert($0, to: course.view) }
        let controlsExclusions = snapshot.exclusions.map { view.convert($0, to: controls.view) }
        if course.exclusions != courseExclusions { course.exclusions = courseExclusions; course.view.setNeedsLayout() }
        if controls.exclusions != controlsExclusions { controls.exclusions = controlsExclusions; controls.view.setNeedsLayout() }

        if let region = snapshot.divisions.first {
            let width = max(8, region.width), height = max(8, region.height)
            canal.frame = CGRect(x: region.midX - width / 2, y: region.midY - height / 2, width: width, height: height)
            canal.isHidden = false
        } else { canal.isHidden = true }
        view.bringSubviewToFront(canal)
        let path = UIBezierPath()
        snapshot.exclusions.forEach { path.append(UIBezierPath(rect: $0)) }
        regionLayer.path = path.cgPath
        regionLayer.isHidden = !session.showRegions
        writeDiagnostics(snapshot)
    }

    private func configure(_ next: String) {
        isConfiguring = true
        defer { isConfiguring = false }
        session.cancel()
        controls.pull.cancelTracking()
        setViewController(nil, for: .primary)
        setViewController(nil, for: .secondary)
        for child in [course as UIViewController, controls as UIViewController] where child.parent != nil {
            child.willMove(toParent: nil); child.view.removeFromSuperview(); child.removeFromParent()
        }
        if let pane=singlePane { pane.willMove(toParent:nil);pane.view.removeFromSuperview();pane.removeFromParent() }
        singlePane = nil
        usingOverlay = next == "regular-overlay"
        mode = next
        if next == "regular-arrangement" {
            course.overlayClearance = 0
            // Physical content/control order only. Child text keeps its own semantics.
            traitOverrides.layoutDirection = .rightToLeft
            view.semanticContentAttribute = .forceRightToLeft
            course.traitOverrides.layoutDirection = .leftToRight
            controls.traitOverrides.layoutDirection = .leftToRight
            course.view.semanticContentAttribute = .forceLeftToRight
            controls.view.semanticContentAttribute = .forceLeftToRight
            usingOverlay=false
            updateArrangement(horizontalSplit())
            setViewController(course, for: .primary)
            setViewController(controls, for: .secondary)
        } else if next == "regular-folded" {
            traitOverrides.remove(UITraitLayoutDirection.self)
            view.semanticContentAttribute = .unspecified
            course.overlayClearance=0
            var overlay=UIOverlayArrangement()
            var top=overlay.defaultViewProperties;top.edge = .top
            var bottom=overlay.defaultViewProperties;bottom.edge = .bottom
            overlay.setViewProperties(top,for:.primary);overlay.setViewProperties(bottom,for:.secondary)
            updateArrangement(overlay)
            setViewController(course,for:.primary);setViewController(controls,for:.secondary)
        } else {
            traitOverrides.remove(UITraitLayoutDirection.self)
            view.semanticContentAttribute = .unspecified
            let pane = FPPlayLayoutController(course: course, controls: controls, handheld: next != "compact")
            singlePane = pane
            // A full-height split minimum cannot fit either side of an active fold.
            // Overlay keeps the single content container visible across reserved regions.
            updateArrangement(UIOverlayArrangement())
            setViewController(pane,for:.primary)
        }
        refresh()
    }

    private func horizontalSplit() -> UISplitArrangement {
        var split=UISplitArrangement().axes(.horizontal)
        var properties=split.defaultViewProperties
        properties.width.preferred = .fractional(0.5)
        split.setViewProperties(properties,for:.primary)
        return split
    }

    private func refresh() {
        controls.refresh(); course.refreshHeader(); course.course.refresh(); view.setNeedsLayout()
    }
    @objc private func motionChanged() { session.updateMotionPreference();course.course.stopLargeMotion() }

    private func makeMenu() -> UIMenu {
        UIMenu(title: FPL10n.text("course_options"), children: session.levelActions + [FPSound.settingAction,FPHaptics.settingAction,
            UIAction(title: FPL10n.text("handheld"), image: UIImage(systemName: "gamecontroller"), state: session.handheld ? .on : .off) { [weak self] _ in self?.session.handheld.toggle(); self?.view.setNeedsLayout() },
            UIAction(title: FPL10n.text("replay_tee"), image: UIImage(systemName: "flag")) { [weak self] _ in self?.session.reset(); self?.course.course.teeOff() },
            UIAction(title: FPL10n.text("next_level"), image: UIImage(systemName: "flag.checkered")) { [weak self] _ in self?.session.nextLevel() },
            
            UIAction(title: FPL10n.text("show_regions"), image: UIImage(systemName: "rectangle.dashed"), state: session.showRegions ? .on : .off) { [weak self] _ in self?.session.showRegions.toggle(); self?.view.setNeedsLayout() }
        ])
    }
    private func writeDiagnostics(_ snapshot: FPRegionSnapshot) {
        #if DEBUG
        let s = view.safeAreaInsets
        let courseRect = view.convert(course.view.bounds, from: course.view)
        let controlsRect = view.convert(controls.view.bounds, from: controls.view)
        var violations: [String] = []
        func inspect(_ current: UIView) {
            guard !current.isHidden,current.alpha>0 else { return }
            if let button = current as? UIButton, !button.isHidden, button.alpha > 0 {
                let rect = view.convert(button.bounds, from: button)
                if snapshot.exclusions.contains(where: { $0.intersects(rect) }) { violations.append(button.accessibilityLabel ?? "button") }
            }
            current.subviews.forEach(inspect)
        }
        inspect(controls.view)
        var payload: [String: Any] = [
            "container": "UIArrangementViewController", "mode": mode, "arrangement":mode == "regular-folded" ? "overlay-top-bottom":singlePane != nil ? "single-pane-overlay":"split-horizontal", "boostSeconds":session.boostSeconds,"boostCounts":session.boostCounts,"variant":session.tuning.variant,"regionSource":ProcessInfo.processInfo.arguments.contains("--simulate-division") ? "synthetic-debug-fixture":"system",
            "primary": singlePane == nil ? "FPCourseController":"FPPlayLayoutController",
            "fallbackContainer":singlePane == nil ? "none":"FPPlayLayoutController",
            "secondary": singlePane == nil ? "FPControlsController":"none",
            "windowFrame":NSCoder.string(for:view.convert(view.bounds,to:view.window)),"bounds": NSCoder.string(for: view.bounds), "courseFrame": NSCoder.string(for: courseRect),
            "controlsFrame": NSCoder.string(for: controlsRect), "buttonRegionViolations": violations,
            "courseVisible":FPRegionSnapshot.isVisible(course.course,in:view),"controlsVisible":FPRegionSnapshot.isVisible(controls.pull,in:view),
            "courseField":NSCoder.string(for:course.course.field),
            "primaryHidden":state(for:.primary)?.isHidden ?? true,"secondaryHidden":state(for:.secondary)?.isHidden ?? true,
            "restorationCount":session.restorationCount,"soundEnabled":FPSound.enabled,"worldVelocity":[session.world.velocity.dx,session.world.velocity.dy],
            "sceneSessionID":view.window?.windowScene?.session.persistentIdentifier ?? "none",
            "horizontalSizeClass": traitCollection.horizontalSizeClass.rawValue,
            "verticalSizeClass": traitCollection.verticalSizeClass.rawValue, "scale": traitCollection.displayScale,
            "insets": ["top": s.top, "left": s.left, "bottom": s.bottom, "right": s.right],
            "division": snapshot.divisions.map { NSCoder.string(for: $0) },
            "activeDivision": snapshot.activeDivisions.map { NSCoder.string(for: $0) },
            "occlusion": snapshot.occlusions.map { NSCoder.string(for: $0) },
            "handheldSwitch": session.handheld, "phase": session.phase.rawValue, "strokes": session.strokes,
            "collisionReservation": NSCoder.string(for: session.world.canal),
            "ball":NSCoder.string(for:session.world.position), "elapsed":session.elapsed, "events":session.events, "collisionImplemented": true, "level":session.level.id, "event":session.lastEvent, "collisions":session.collisions, "stars":session.stars, "penalty":session.penaltyActive
        ]
        if let launch = session.lastLaunch {
            payload["lastLaunch"] = ["id": launch.id.uuidString, "vx": launch.velocity.dx,
                                     "vy": launch.velocity.dy, "angleRadians": launch.angle, "power": launch.power]
        }
        let accessibleState="level=\(session.level.id);phase=\(session.phase.rawValue);strokes=\(session.strokes);launch=\(session.lastLaunch?.id.uuidString ?? "none");restored=\(session.restorationCount);sound=\(FPSound.enabled);haptics=\(FPHaptics.enabled);courseVisible=\(FPRegionSnapshot.isVisible(course.course,in:view));controlsVisible=\(FPRegionSnapshot.isVisible(controls.pull,in:view))"
        let proof=accessibleState+";bounds=\(NSCoder.string(for:view.bounds));traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(s.top),\(s.left),\(s.bottom),\(s.right);division=\(snapshot.divisions);occlusion=\(snapshot.occlusions);reduceMotion=\(FPMotion.reduced)"
        if view.accessibilityValue != proof { view.accessibilityValue=proof }
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? data.write(to: directory.appendingPathComponent("layout-diagnostics.json"), options: .atomic)
        }
        #endif
    }
}
