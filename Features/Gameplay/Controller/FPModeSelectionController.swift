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
    private let scroll=UIScrollView(),content=UIStackView(),cards=UIStackView(),utilities=UIStackView()
    private let brand=FPTheme.label(FPL10n.text("brand"),style:.caption1)
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
            content.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor,constant:12),
            content.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor,constant:-24),
            content.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor,constant:-40)
        ])
        brand.textColor=FPChibiPalette.secondary
        brand.accessibilityIdentifier="modeBrand"
        view.addSubview(brand)
        let title=label(FPL10n.text("choose_mood"),style:.largeTitle,weight:.bold)
        let subtitle=label(FPL10n.text("choose_mood_description"),style:.subheadline)
        subtitle.textColor=FPChibiPalette.secondary
        [title,subtitle].forEach { content.addArrangedSubview($0) }
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
        utilities.spacing = 0
        utilities.distribution = .fillEqually
        utilities.semanticContentAttribute = .forceLeftToRight
        utilities.addArrangedSubview(utilityButton("privacy", symbol: "hand.raised", id: "openPrivacy") { [weak self] in self?.session.requestPrivacy?() })
        utilities.addArrangedSubview(utilityButton("settings_language", symbol: "globe", id: "openLanguage") { [weak self] in self?.session.requestLanguage?() })
        view.addSubview(utilities)
        registerForTraitChanges([UITraitHorizontalSizeClass.self,UITraitVerticalSizeClass.self,UITraitPreferredContentSizeCategory.self]) { (controller:FPModeSelectionController,_:UITraitCollection) in controller.view.setNeedsLayout() }
    }
    private func utilityButton(_ key: String, symbol: String, id: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: symbol)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: FPTheme.utilityIconSize, weight: .medium)
        config.cornerStyle = .fixed
        config.background.cornerRadius = FPTheme.spacing / 2
        let visualInset = (FPTheme.utilityTarget-FPTheme.utilityVisualSize)/2
        config.background.backgroundInsets = NSDirectionalEdgeInsets(top: visualInset, leading: visualInset, bottom: visualInset, trailing: visualInset)
        config.background.strokeColor = FPChibiPalette.edge.withAlphaComponent(0.35)
        config.background.strokeWidth = 1
        config.baseForegroundColor = FPChibiPalette.ink
        config.baseBackgroundColor = FPChibiPalette.meadow
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.titleLabel?.font = FPTheme.font(.callout, weight: .semibold)
        button.titleLabel?.numberOfLines = 0; button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = id
        button.accessibilityLabel = FPL10n.text(key)
        button.largeContentTitle = FPL10n.text(key)
        button.showsLargeContentViewer = true
        button.addInteraction(UILargeContentViewerInteraction())
        button.isPointerInteractionEnabled = true
        button.heightAnchor.constraint(equalToConstant: FPTheme.utilityTarget).isActive = true
        button.widthAnchor.constraint(equalToConstant: FPTheme.utilityTarget).isActive = true
        button.layer.cornerRadius = FPTheme.spacing
        button.layer.cornerCurve = .continuous
        button.layer.shadowColor = FPChibiPalette.ink.cgColor
        button.layer.shadowOpacity = FPTheme.shadowOpacity
        button.layer.shadowOffset = CGSize(width: 0, height: 1.5); button.layer.shadowRadius = 0
        button.configurationUpdateHandler = { button in
            button.layer.shadowOffset = CGSize(width: 0, height: button.isHighlighted ? 0.5 : 1.5)
            var current = button.configuration
            current?.background.strokeWidth = button.isFocused ? 2 : 1
            button.configuration = current
        }
        return button
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
        // 品牌和工具同属固定顶栏，垂直居中；品牌大字号可换行，图标始终保留可点空间。
        let headerLeft = safe.midX-width/2+20
        let headerRight = safe.midX+width/2-20
        let utilitiesWidth = FPTheme.utilityTarget * 2
        // 背景边缘对齐模式卡片；透明热区可向右多出半个内缩量。
        let visualInset = (FPTheme.utilityTarget-FPTheme.utilityVisualSize)/2
        let utilitiesRight = headerRight+visualInset
        let brandWidth = max(0, utilitiesRight-utilitiesWidth-FPTheme.footerGap-headerLeft)
        let brandHeight = ceil(brand.sizeThatFits(CGSize(width: brandWidth, height: .greatestFiniteMagnitude)).height)
        let headerHeight = max(FPTheme.target, brandHeight)
        let headerTop = safe.minY+8
        brand.frame = CGRect(x: headerLeft, y: headerTop+(headerHeight-brandHeight)/2, width: brandWidth, height: brandHeight)
        utilities.frame = CGRect(x: utilitiesRight-utilitiesWidth, y: headerTop+(headerHeight-FPTheme.utilityTarget)/2, width: utilitiesWidth, height: FPTheme.utilityTarget)
        let contentTop = headerTop+headerHeight+8
        scroll.frame=CGRect(x:safe.midX-width/2,y:contentTop,width:width,height:max(0,safe.maxY-contentTop))
        cards.axis=traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular && width>=700 && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .horizontal:.vertical
        #if DEBUG
        let inset=view.safeAreaInsets
        view.accessibilityValue="language=\(FPL10n.language);direction=\(view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? "rtl":"ltr");bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(inset);division=\(regions.divisions);occlusion=\(regions.occlusions);brandFrame=\(brand.frame);utilitiesFrame=\(utilities.frame)"
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
