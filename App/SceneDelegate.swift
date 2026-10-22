import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var session: FPDemoSession?
    private var restored = false
    private let sound=FPSound()
    private var allowsRestoration: Bool {
        let args=ProcessInfo.processInfo.arguments
        return !args.contains("--capture") && (!args.contains("--ui-testing") || args.contains("--restore-scene"))
    }
    func scene(_ scene: UIScene, willConnectTo connection: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-language") { FPLanguageManager.shared.select(nil) }
        #endif
        let window = UIWindow(windowScene: scene)
        let session: FPDemoSession
        do {
            let testRun=ProcessInfo.processInfo.arguments.contains("--ui-testing") || ProcessInfo.processInfo.arguments.contains("--capture")
            session = try FPDemoSession(metricsStore:testRun ? nil:.standard); self.session = session
            session.eventObserved = { [weak self] event in self?.sound.play(event); FPHaptics.play(event) }
        }
        catch {
            let failure = UIViewController(); failure.view.backgroundColor = .systemBackground
            let label = UILabel(); label.text = error.localizedDescription; label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false; failure.view.addSubview(label)
            NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: failure.view.centerXAnchor),label.centerYAnchor.constraint(equalTo: failure.view.centerYAnchor),label.widthAnchor.constraint(lessThanOrEqualTo:failure.view.widthAnchor,multiplier:0.8)])
            window.rootViewController = failure; window.makeKeyAndVisible(); self.window=window;return
        }
        if allowsRestoration {
            for activity in [FPSceneCheckpoint.load(connection.persistentIdentifier),connection.stateRestorationActivity].compactMap({$0}) {
                if restore(activity,scene:scene) { break }
            }
        }
        session.suspend()
        var showPicker=true
        #if DEBUG
        let launchArgs=ProcessInfo.processInfo.arguments
        showPicker=launchArgs.contains("--show-mode-picker") || (!launchArgs.contains("--ui-testing") && !launchArgs.contains("--capture") && !launchArgs.contains("--q-mode"))
        if launchArgs.contains("--q-mode") { session.setPresentation(mode:.chibi,mood:launchArgs.contains("--silly") ? .silly:.cozy,skin:launchArgs.contains("--peach") ? .peach:.rice) }
        #endif
        let root=FPGameRootController(session:session,showPicker:showPicker)
        window.rootViewController=root
        #if DEBUG
        if let flag=launchArgs.firstIndex(of:"--half-window"),launchArgs.count>flag+1 {
            window.rootViewController=FPTuningWindowFixture(child:root,side:launchArgs[flag+1])
        }
        #endif
        window.makeKeyAndVisible(); self.window = window
        session.startClock()
        #if DEBUG
        let args=ProcessInfo.processInfo.arguments
        if let i=args.firstIndex(of:"--capture"),args.count>i+1 {
            let name=args[i+1]
            let levelIndex=args.firstIndex(of:"--level").flatMap { args.count>$0+1 ? Int(args[$0+1]):nil } ?? 0
            session.captureReady = { [weak window,weak session] event in
                DispatchQueue.main.asyncAfter(deadline:.now()+(name == "hole-success" ? FPMotion.flag:0.06)) {
                    guard let window,let session,let folder=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first else { return }
                    window.layoutIfNeeded()
                    let format=UIGraphicsImageRendererFormat();format.scale=window.traitCollection.displayScale
                    let image=UIGraphicsImageRenderer(bounds:window.bounds,format:format).image { _ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true) }
                    try? image.pngData()?.write(to:folder.appendingPathComponent("physics-capture.png"))
                    let proof:[String:Any] = ["fixture":true,"scenario":name,"event":event,"level":session.level.id,"phase":session.phase.rawValue,"strokes":session.strokes,"stars":session.stars,"boostSeconds":session.boostSeconds,"boostCounts":session.boostCounts,"variant":session.tuning.variant,"collisions":session.collisions,"events":session.events,"canal":NSCoder.string(for:session.world.canal),"velocity":[session.world.velocity.dx,session.world.velocity.dy]]
                    if let data=try? JSONSerialization.data(withJSONObject:proof,options:.prettyPrinted) { try? data.write(to:folder.appendingPathComponent("physics-capture.json")) }
                }
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+0.6) { session.prepareCapture(name,level:levelIndex) }
        }
        #endif
    }
    func sceneWillResignActive(_ scene: UIScene) { session?.suspend();save(scene) }
    func sceneDidEnterBackground(_ scene: UIScene) { save(scene) }
    func sceneDidBecomeActive(_ scene: UIScene) { session?.startClock();session?.resume() }
    func sceneDidDisconnect(_ scene: UIScene) {
        session?.suspend();save(scene);session?.stopClock()
        window=nil;session=nil;restored=false
    }
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? { save(scene);return scene.session.stateRestorationActivity }
    func scene(_ scene:UIScene,restoreInteractionStateWith activity:NSUserActivity) { restore(activity,scene:scene) }
    private func save(_ scene:UIScene) {
        guard allowsRestoration,let session else { return }
        do {
            let activity=try session.restorationActivity()
            scene.session.stateRestorationActivity=activity
            if let data=activity.userInfo?["snapshot"] as? Data { try FPSceneCheckpoint.save(data,id:scene.session.persistentIdentifier) }
        }
        catch { NSLog("FoldPutt checkpoint failed: %@",error.localizedDescription) }
    }
    @discardableResult private func restore(_ activity:NSUserActivity,scene:UIScene) -> Bool {
        guard allowsRestoration,!ProcessInfo.processInfo.arguments.contains("--fresh-scene"),!restored,let session,
              activity.activityType == FPDemoSession.restorationType,activity.userInfo?["snapshot"] is Data else { return false }
        do { try session.restore(activity);restored=true;return true }
        catch {
            // Keep the rejected payload for diagnosis before the next checkpoint replaces it.
            if let data=activity.userInfo?["snapshot"] as? Data,data.count<=65_536 {
                var info=scene.session.userInfo ?? [:];info["rejectedFoldPuttSnapshot"]=data;scene.session.userInfo=info
            }
            session.restorationNotice=FPL10n.text("progress_restore_failed")
            NSLog("FoldPutt restore rejected: %@",error.localizedDescription)
            return false
        }
    }
}

/// The file is scoped by UISceneSession identity, not a global "current game".
/// UIKit may omit its activity after a force-quit; the last background checkpoint is still recoverable.
@MainActor enum FPSceneCheckpoint {
    private static func url(_ id:String) -> URL {
        FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
            .appendingPathComponent("SceneCheckpoints",isDirectory:true).appendingPathComponent(id).appendingPathExtension("json")
    }
    static func save(_ data:Data,id:String) throws {
        let destination=url(id)
        try FileManager.default.createDirectory(at:destination.deletingLastPathComponent(),withIntermediateDirectories:true)
        try data.write(to:destination,options:.atomic)
        #if DEBUG
        NSLog("FP scene saved %@ bytes %ld",id,data.count)
        #endif
    }
    static func load(_ id:String) -> NSUserActivity? {
        let source=url(id)
        guard let size=try? source.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<=65_536,
              let data=try? Data(contentsOf:source) else { return nil }
        let activity=NSUserActivity(activityType:FPDemoSession.restorationType);activity.userInfo=["snapshot":data];return activity
    }
    static func discard(_ id:String) {
        #if DEBUG
        NSLog("FP scene discarded %@",id)
        #endif
        try? FileManager.default.removeItem(at:url(id))
    }
}

#if DEBUG
/// Explicit test harness, not a claim that the OS created Split View.
private final class FPTuningWindowFixture: UIViewController {
    let child:UIViewController
    var side:String
    let bar=UIStackView()
    init(child:UIViewController,side:String) { self.child=child;self.side=side;super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad();view.backgroundColor = .secondarySystemBackground
        addChild(child);view.addSubview(child.view);child.didMove(toParent:self)
        child.traitOverrides.horizontalSizeClass = .regular
        child.traitOverrides.verticalSizeClass = .regular
        child.additionalSafeAreaInsets=UIEdgeInsets(top:11,left:7,bottom:17,right:23)
        child.view.clipsToBounds=true
        bar.axis = .horizontal;bar.distribution = .fillEqually
        for (id,title) in [("left",FPL10n.text("fixture_left")),("right",FPL10n.text("fixture_right")),("full",FPL10n.text("fixture_full"))] {
            let button=UIButton(type:.system);button.setTitle(title,for:.normal)
            button.addAction(UIAction { [weak self] _ in self?.side=id;self?.view.setNeedsLayout() },for:.touchUpInside)
            bar.addArrangedSubview(button)
        }
        view.addSubview(bar)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width=side == "full" ? view.bounds.width:view.bounds.width/2
        child.view.frame=CGRect(x:side == "right" ? view.bounds.width-width:0,y:0,width:width,height:max(1,view.bounds.height-64))
        bar.frame=CGRect(x:0,y:view.bounds.height-64,width:view.bounds.width,height:48)
    }
}
#endif
