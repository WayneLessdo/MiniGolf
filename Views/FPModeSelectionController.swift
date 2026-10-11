import UIKit

/// One scene owns one session; choosing a look never constructs a second game.
final class FPGameRootController: UIViewController {
    let session: FPDemoSession
    private lazy var game = FPAdaptiveController(session: session)
    private let showPicker: Bool
    init(session: FPDemoSession, showPicker: Bool = true) {
        self.session=session;self.showPicker=showPicker;super.init(nibName:nil,bundle:nil)
        session.requestClub = { [weak self] section in
            DispatchQueue.main.async { [weak self] in self?.showClub(section) }
        }
        session.requestModeSelection = { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.showModes() }
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        if showPicker { showModes() } else { showGame(session.gameMode) }
    }
    private func showClub(_ section:FPClubSection) {
        guard presentedViewController == nil,!session.isChoosingMode else { return }
        session.beginClub();game.stopPresentation()
        let club=FPClubController(session:session,section:section)
        let navigation=UINavigationController(rootViewController:club)
        navigation.modalPresentationStyle = .fullScreen
        club.finished = { [weak self,weak navigation] in
            navigation?.dismiss(animated:!FPMotion.reduced) { self?.session.finishClub(resumeClock:self?.view.window?.windowScene?.activationState == .foregroundActive) }
        }
        present(navigation,animated:!FPMotion.reduced)
    }
    func showModes() {
        session.beginModeSelection()
        if children.contains(where: { $0 === game }) { game.stopPresentation() }
        let picker=FPModeSelectionController(session:session)
        picker.selected = { [weak self] mode in self?.showGame(mode) }
        let navigation=UINavigationController(rootViewController:picker)
        navigation.setNavigationBarHidden(true,animated:false)
        install(navigation)
    }
    private func showGame(_ mode: FPGameMode) {
        session.finishModeSelection(mode)
        install(game)
        game.view.setNeedsLayout()
        UIAccessibility.post(notification:.screenChanged,argument:nil)
    }
    private func install(_ child: UIViewController) {
        for previous in children {
            previous.willMove(toParent:nil);previous.view.removeFromSuperview();previous.removeFromParent()
        }
        addChild(child);view.addSubview(child.view);child.view.frame=view.bounds;child.didMove(toParent:self)
        view.setNeedsLayout()
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews();children.first?.view.frame=view.bounds }
}

final class FPModeSelectionController: UIViewController {
    let session: FPDemoSession
    var selected: ((FPGameMode) -> Void)?
    private let scroll=UIScrollView(),content=UIStackView(),cards=UIStackView()
    init(session: FPDemoSession) { self.session=session;super.init(nibName:nil,bundle:nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad();overrideUserInterfaceStyle = .light
        view.backgroundColor=FPChibiPalette.paper;view.accessibilityIdentifier="modeSelection"
        scroll.contentInsetAdjustmentBehavior = .never;view.addSubview(scroll)
        content.axis = .vertical;content.spacing=22;content.translatesAutoresizingMaskIntoConstraints=false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor,constant:20),
            content.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor,constant:-20),
            content.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor,constant:24),
            content.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor,constant:-24),
            content.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor,constant:-40)
        ])
        let brand=label("FoldPutt  /  小草坪俱乐部",style:.caption1)
        brand.textColor=FPChibiPalette.secondary
        let title=label("今天，想怎么打？",style:.largeTitle,weight:.bold)
        let subtitle=label("选择一种心情，开始一小局。\n向后拉杆，松手击球。",style:.subheadline)
        subtitle.textColor=FPChibiPalette.secondary
        [brand,title,subtitle].forEach { content.addArrangedSubview($0) }
        cards.spacing=16;cards.axis = .vertical;cards.distribution = .fillEqually
        for mode in FPGameMode.allCases {
            let card=FPModeCard(mode:mode)
            card.addAction(UIAction { [weak self] _ in self?.selected?(mode) },for:.touchUpInside)
            cards.addArrangedSubview(card)
        }
        content.addArrangedSubview(cards)
        let detail=session.strokes>0 || session.restorationCount>0
            ? "继续第 \(session.level.id) 关 · \(session.strokes) 杆\n切换画风，保留当前进度。"
            : "普通模式保留熟悉的球场。\nQ 版模式里，小球和风景都有一点小情绪。"
        let footnote=label(detail,style:.footnote);footnote.textColor=FPChibiPalette.secondary
        content.addArrangedSubview(footnote)
        registerForTraitChanges([UITraitHorizontalSizeClass.self,UITraitVerticalSizeClass.self,UITraitPreferredContentSizeCategory.self]) { (controller:FPModeSelectionController,_:UITraitCollection) in controller.view.setNeedsLayout() }
    }
    private func label(_ text:String,style:UIFont.TextStyle,weight:UIFont.Weight = .regular)->UILabel {
        let label=FPTheme.label(text,style:style,weight:weight);label.textColor=FPChibiPalette.ink;return label
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let regions=FPRegionSnapshot.read(in:view)
        let safe=FPRegionSnapshot.usable(view.safeAreaLayoutGuide.layoutFrame,excluding:regions.exclusions)
        let width=min(860,safe.width)
        scroll.frame=CGRect(x:safe.midX-width/2,y:safe.minY,width:width,height:safe.height)
        cards.axis=traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular && width>=700 && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .horizontal:.vertical
        #if DEBUG
        let inset=view.safeAreaInsets
        view.accessibilityValue="bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(inset);division=\(regions.divisions);occlusion=\(regions.occlusions)"
        #endif
    }
}

private final class FPModeCard: UIButton {
    init(mode: FPGameMode) {
        super.init(frame:.zero)
        accessibilityIdentifier="chooseMode-"+mode.rawValue
        accessibilityLabel=mode.title
        accessibilityHint=mode == .classic ? "保留原有球场风格，开始或继续对局":"进入手绘球场，体验八个小心思"
        backgroundColor=FPChibiPalette.card;layer.cornerRadius=24;layer.borderWidth=1;layer.borderColor=FPChibiPalette.edge.withAlphaComponent(0.3).cgColor
        let stack=UIStackView();stack.axis = .vertical;stack.spacing=10;stack.isUserInteractionEnabled=false;stack.translatesAutoresizingMaskIntoConstraints=false;addSubview(stack)
        let preview=FPModePreviewView(mode:mode);preview.heightAnchor.constraint(equalToConstant:128).isActive=true
        preview.layer.cornerRadius=16;preview.clipsToBounds=true
        let title=FPTheme.label(mode.title,style:.title2,weight:.semibold);title.textColor=FPChibiPalette.ink
        let subtitle=FPTheme.label(mode == .classic ? "真实草地 · 熟悉的拉杆手感":"手绘小草坪 · 8 个可爱小心思",style:.subheadline);subtitle.textColor=FPChibiPalette.secondary
        let action=FPTheme.label(mode == .classic ? "进入普通模式  →":"和糯米团子出发  →",style:.callout,weight:.semibold);action.textColor=FPChibiPalette.ink
        [preview,title,subtitle,action].forEach { $0.isAccessibilityElement=false;stack.addArrangedSubview($0) }
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:leadingAnchor,constant:18),stack.trailingAnchor.constraint(equalTo:trailingAnchor,constant:-18),stack.topAnchor.constraint(equalTo:topAnchor,constant:18),stack.bottomAnchor.constraint(equalTo:bottomAnchor,constant:-18),heightAnchor.constraint(greaterThanOrEqualToConstant:FPTheme.target)])
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isHighlighted: Bool { didSet { backgroundColor=isHighlighted ? FPChibiPalette.meadow:FPChibiPalette.card } }
}

private final class FPModePreviewView: UIView {
    let mode: FPGameMode
    init(mode: FPGameMode) { self.mode=mode;super.init(frame:.zero);isOpaque=true }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        guard let context=UIGraphicsGetCurrentContext() else { return }
        if mode == .classic {
            FPTheme.grass.setFill();context.fill(bounds)
            UIImage(named:"GrassRegular")?.draw(in:bounds,blendMode:.normal,alpha:0.7)
            UIImage(named:"GolfBall")?.draw(in:CGRect(x:bounds.width*0.28-27,y:bounds.midY-27,width:54,height:54))
            UIImage(named:"Flag")?.draw(in:CGRect(x:bounds.width*0.69-30,y:bounds.midY-43,width:70,height:70))
        } else {
            FPChibiPalette.meadow.setFill();context.fill(bounds)
            FPChibiArt.ball(in:context,center:CGPoint(x:bounds.width*0.32,y:bounds.midY),radius:36,skin:.rice,expression:.happy)
            FPChibiArt.spectator(in:context,center:CGPoint(x:bounds.width*0.73,y:bounds.midY+10),size:27,kind:0,cheer:0)
            FPChibiArt.flower(in:context,at:CGPoint(x:bounds.width*0.58,y:bounds.midY-25),size:7)
        }
    }
}
