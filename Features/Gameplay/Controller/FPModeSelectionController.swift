import UIKit

/// One scene owns one session; choosing a look never constructs a second game.
final class FPGameRootController: UIViewController {
    let session: FPDemoSession
    private lazy var game = FPAdaptiveController(session: session)
    private let showPicker: Bool
    private weak var languageController: FPLanguageController?
    init(session: FPDemoSession, showPicker: Bool = true) {
        self.session=session;self.showPicker=showPicker;super.init(nibName:nil,bundle:nil)
        session.requestClub = { [weak self] section in
            DispatchQueue.main.async { [weak self] in self?.showClub(section) }
        }
        session.requestModeSelection = { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.showModes() }
        }
        session.requestLanguage = { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.showLanguage() }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: FPLanguageManager.didChange, object: nil)
        session.requestPrivacy = { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.showPrivacy() }
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        applyLanguageDirection()
        if showPicker { showModes() } else { showGame(session.gameMode) }
    }
    private func applyLanguageDirection() {
        view.semanticContentAttribute = FPLanguageManager.shared.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
    }
    private func showLanguage() {
        guard presentedViewController == nil else { return }
        session.beginLanguageSelection()
        if children.contains(where: { $0 === game }) { game.stopPresentation() }
        let controller = FPLanguageController()
        languageController = controller
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .fullScreen
        navigation.view.semanticContentAttribute = view.semanticContentAttribute
        navigation.navigationBar.semanticContentAttribute = view.semanticContentAttribute
        controller.finished = { [weak self, weak navigation] in
            navigation?.dismiss(animated: !FPMotion.reduced) {
                self?.languageController = nil
                self?.session.finishLanguageSelection(resumeClock: self?.view.window?.windowScene?.activationState == .foregroundActive)
            }
        }
        present(navigation, animated: !FPMotion.reduced)
    }
    @objc private func languageChanged() {
        guard isViewLoaded else { return }
        applyLanguageDirection()
        let choosingMode = session.isChoosingMode
        if children.contains(where: { $0 === game }) { game.stopPresentation() }
        // 只重建界面，继续持有同一个 session、球局及物理世界。
        game = FPAdaptiveController(session: session)
        if choosingMode { showModes() } else { install(game) }
        if let languageController { languageController.refreshLanguage() }
        else if presentedViewController != nil {
            // 另一场景改语言时，关闭已失效的译文页面，保持当前球局。
            dismiss(animated: false) { [weak self] in
                guard let self else { return }
                let active = self.view.window?.windowScene?.activationState == .foregroundActive
                self.session.finishClub(resumeClock: false)
                self.session.finishPrivacy(resumeClock: active)
            }
        }
    }
    private func showClub(_ section:FPClubSection) {
        guard presentedViewController == nil,!session.isChoosingMode else { return }
        session.beginClub();game.stopPresentation()
        let club=FPClubController(session:session,section:section)
        let navigation=UINavigationController(rootViewController:club)
        navigation.modalPresentationStyle = .fullScreen
        navigation.view.semanticContentAttribute = view.semanticContentAttribute
        navigation.navigationBar.semanticContentAttribute = view.semanticContentAttribute
        club.finished = { [weak self,weak navigation] in
            navigation?.dismiss(animated:!FPMotion.reduced) { self?.session.finishClub(resumeClock:self?.view.window?.windowScene?.activationState == .foregroundActive) }
        }
        present(navigation,animated:!FPMotion.reduced)
    }
    private func showPrivacy() {
        guard presentedViewController == nil else { return }
        session.beginPrivacy()
        if children.contains(where: { $0 === game }) { game.stopPresentation() }
        let policy = FPPrivacyController()
        let navigation = UINavigationController(rootViewController: policy)
        navigation.modalPresentationStyle = .fullScreen
        navigation.view.semanticContentAttribute = view.semanticContentAttribute
        navigation.navigationBar.semanticContentAttribute = view.semanticContentAttribute
        policy.finished = { [weak self, weak navigation] in
            navigation?.dismiss(animated: !FPMotion.reduced) {
                self?.session.finishPrivacy(resumeClock: self?.view.window?.windowScene?.activationState == .foregroundActive)
            }
        }
        present(navigation, animated: !FPMotion.reduced)
    }
    func showModes() {
        session.beginModeSelection()
        if children.contains(where: { $0 === game }) { game.stopPresentation() }
        let picker=FPModeSelectionController(session:session)
        picker.selected = { [weak self] mode in self?.showGame(mode) }
        let navigation=UINavigationController(rootViewController:picker)
        navigation.view.semanticContentAttribute = view.semanticContentAttribute
        navigation.navigationBar.semanticContentAttribute = view.semanticContentAttribute
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
        let brand=label(FPL10n.text("brand"),style:.caption1)
        brand.textColor=FPChibiPalette.secondary
        let title=label(FPL10n.text("choose_mood"),style:.largeTitle,weight:.bold)
        let subtitle=label(FPL10n.text("choose_mood_description"),style:.subheadline)
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
            ? FPL10n.format("continue_progress",session.level.id,FPL10n.number(session.strokes))
            : FPL10n.text("mode_details")
        let footnote=label(detail,style:.footnote);footnote.textColor=FPChibiPalette.secondary
        content.addArrangedSubview(footnote)
        let privacy = UIButton(type: .system)
        privacy.setTitle(FPL10n.text("privacy"), for: .normal)
        privacy.titleLabel?.font = FPTheme.font(.body)
        privacy.titleLabel?.adjustsFontForContentSizeCategory = true
        privacy.accessibilityIdentifier = "openPrivacy"
        privacy.heightAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        privacy.addAction(UIAction { [weak self] _ in self?.session.requestPrivacy?() }, for: .touchUpInside)
        content.addArrangedSubview(privacy)
        let language = UIButton(type: .system)
        language.setTitle(FPL10n.text("settings_language"), for: .normal)
        language.titleLabel?.font = FPTheme.font(.body)
        language.titleLabel?.adjustsFontForContentSizeCategory = true
        language.accessibilityIdentifier = "openLanguage"
        language.heightAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        language.addAction(UIAction { [weak self] _ in self?.session.requestLanguage?() }, for: .touchUpInside)
        content.addArrangedSubview(language)
        registerForTraitChanges([UITraitHorizontalSizeClass.self,UITraitVerticalSizeClass.self,UITraitPreferredContentSizeCategory.self]) { (controller:FPModeSelectionController,_:UITraitCollection) in controller.view.setNeedsLayout() }
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange();view.setNeedsLayout()
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
        view.accessibilityValue="language=\(FPL10n.language);direction=\(view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? "rtl":"ltr");bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(inset);division=\(regions.divisions);occlusion=\(regions.occlusions)"
        #endif
    }
}

private final class FPModeCard: UIButton {
    init(mode: FPGameMode) {
        super.init(frame:.zero)
        accessibilityIdentifier="chooseMode-"+mode.rawValue
        accessibilityLabel=mode.title
        accessibilityHint=mode == .classic ? FPL10n.text("classic_description"):FPL10n.text("chibi_description")
        backgroundColor=FPChibiPalette.card;layer.cornerRadius=24;layer.borderWidth=1;layer.borderColor=FPChibiPalette.edge.withAlphaComponent(0.3).cgColor
        let stack=UIStackView();stack.axis = .vertical;stack.spacing=10;stack.isUserInteractionEnabled=false;stack.translatesAutoresizingMaskIntoConstraints=false;addSubview(stack)
        let preview=FPModePreviewView(mode:mode);preview.heightAnchor.constraint(equalToConstant:128).isActive=true
        preview.layer.cornerRadius=16;preview.clipsToBounds=true
        let title=FPTheme.label(mode.title,style:.title2,weight:.semibold);title.textColor=FPChibiPalette.ink
        let subtitle=FPTheme.label(mode == .classic ? FPL10n.text("classic_feature_description"):FPL10n.text("chibi_feature_description"),style:.subheadline);subtitle.textColor=FPChibiPalette.secondary
        let action=FPTheme.label(mode == .classic ? FPL10n.text("classic_start"):FPL10n.text("chibi_start"),style:.callout,weight:.semibold);action.textColor=FPChibiPalette.ink
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
