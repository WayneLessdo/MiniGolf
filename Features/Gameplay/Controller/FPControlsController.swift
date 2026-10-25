import UIKit

final class FPControlsController: UIViewController, UIGestureRecognizerDelegate {
    var exclusions: [CGRect] = []
    var floating=false { didSet { pull.floatingTrack=floating;if isViewLoaded { view.backgroundColor=floating ? .clear:FPTheme.surface } } }
    var turnInput=false { didSet {
        if oldValue != turnInput,isViewLoaded { pull.cancelTracking();session.cancel();view.setNeedsLayout() }
        pull.accessibilityDirection=turnInput ? CGVector(dx:1,dy:0):CGVector(dx:0,dy:-1)
    } }
    let session: FPDemoSession
    let pull = FPPullControl()
    let status = FPTheme.label("",style:.caption1,weight:.medium)
    let score = FPTheme.label("",style:.title3,weight:.bold)
    private let par = FPTheme.label("",style:.caption1,weight:.semibold)
    let scoreCard = UIStackView()
    let toolbar = UIStackView()
    private let starRow = UIStackView()
    var menu: (() -> UIMenu)?
    private var screenTapOrigin=CGPoint.zero
    private var screenTapStarted:TimeInterval=0
    private var styledMode:FPGameMode?
    init(session:FPDemoSession) { self.session=session;super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError() }
    override func loadView() { view=FPHUDSurfaceView() }
    override func viewDidLoad() {
        super.viewDidLoad();view.backgroundColor=floating ? .clear:FPTheme.surface
        starRow.axis = .horizontal;starRow.spacing=6;starRow.alignment = .center
        for _ in 0..<3 {
            let star=UIImageView(image:UIImage(systemName:"star"));star.tintColor=FPTheme.gold;star.contentMode = .scaleAspectFit;star.isAccessibilityElement=false
            star.widthAnchor.constraint(equalToConstant:16).isActive=true;star.heightAnchor.constraint(equalToConstant:16).isActive=true;starRow.addArrangedSubview(star)
        }
        score.textAlignment = .center;par.textAlignment = .center;par.isAccessibilityElement=false
        scoreCard.axis = .vertical;scoreCard.spacing=4;scoreCard.alignment = .center
        scoreCard.isLayoutMarginsRelativeArrangement=true;scoreCard.directionalLayoutMargins=NSDirectionalEdgeInsets(top:10,leading:10,bottom:10,trailing:10)
        scoreCard.backgroundColor=FPTheme.surface.withAlphaComponent(0.92);scoreCard.layer.cornerRadius=18;scoreCard.accessibilityIdentifier="scoreCard"
        [score,par,starRow].forEach { scoreCard.addArrangedSubview($0) }
        toolbar.spacing=FPTheme.hudGap;toolbar.distribution = .fillEqually
        let reset=FPTheme.icon("arrow.counterclockwise",label:FPL10n.text("restart")) { [weak self] in self?.session.reset() }
        reset.accessibilityIdentifier="resetRound"
        let mapButton=FPTheme.icon("map",label:FPL10n.text("select_map")) {}
        mapButton.accessibilityIdentifier="selectCourse"
        mapButton.showsMenuAsPrimaryAction=true
        mapButton.accessibilityHint=FPL10n.text("select_map_hint")
        mapButton.menu=UIMenu(title:FPL10n.text("select_map_restart"),children:[UIDeferredMenuElement.uncached { [weak self] completion in
            self?.pull.cancelTracking();self?.session.cancel();completion(self?.session.levelActions ?? [])
        }])
        let menuButton=FPTheme.icon("slider.horizontal.3",label:FPL10n.text("settings_demo")) {}
        menuButton.accessibilityIdentifier="courseOptions"
        menuButton.showsMenuAsPrimaryAction=true
        menuButton.menu=UIMenu(title:FPL10n.text("course_options"),children:[UIDeferredMenuElement.uncached { [weak self] completion in
            self?.pull.cancelTracking();self?.session.cancel();completion(self?.menu?().children ?? [])
        }])
        let clubButton=FPTheme.icon("leaf.circle",label:FPL10n.text("gameplay_collection")) { [weak self] in self?.session.requestClub?(.puzzles) }
        clubButton.accessibilityIdentifier="openClub"
        for button in [reset,mapButton,clubButton,menuButton] {
            var config=UIButton.Configuration.filled();config.image=button.configuration?.image
            config.baseForegroundColor=FPTheme.ink;config.baseBackgroundColor=FPTheme.surface.withAlphaComponent(0.92);config.cornerStyle = .medium
            config.preferredSymbolConfigurationForImage=UIImage.SymbolConfiguration(pointSize:22,weight:.regular)
            button.configuration=config;button.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory=false
            toolbar.addArrangedSubview(button)
        }
        [pull,scoreCard,toolbar,status].forEach { view.addSubview($0) }
        pull.onPreview = { [weak self] shot in guard let self else { return };self.session.aim(self.worldShot(shot)) }
        pull.onRelease = { [weak self] shot in guard let self else { return };self.session.release(self.worldShot(shot)) }
        pull.onCancel = { [weak session] in session?.cancel() }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller:FPControlsController,_:UITraitCollection) in controller.view.setNeedsLayout() }
        refresh()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe=view.bounds.inset(by:view.safeAreaInsets).insetBy(dx:FPTheme.hudGutter,dy:FPTheme.hudGutter)
        guard safe.width>0,safe.height>0 else { return }
        let cardWidth=min(FPTheme.scoreCardWidth,safe.width*0.48)
        let cardSize=scoreCard.systemLayoutSizeFitting(CGSize(width:cardWidth,height:0),withHorizontalFittingPriority:.required,verticalFittingPriority:.fittingSizeLevel)
        let toolCount=CGFloat(toolbar.arrangedSubviews.count)
        let rtl=view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let toolLength=FPTheme.target*toolCount+FPTheme.hudGap*(toolCount-1)
        let vertical=safe.height>=toolLength+cardSize.height+FPTheme.hudGutter*3
        toolbar.axis=vertical ? .vertical:.horizontal
        let toolSize=vertical ? CGSize(width:FPTheme.target,height:toolLength):CGSize(width:toolLength,height:FPTheme.target)
        let toolRect=FPRegionSnapshot.placed(toolSize,near:CGPoint(x:rtl ? safe.minX:safe.maxX-toolSize.width,y:safe.minY),in:safe,excluding:exclusions)
        toolbar.frame=toolRect
        let pullSize=CGSize(width:FPTheme.pullDiameter,height:FPTheme.pullDiameter)
        let pullRect=FPRegionSnapshot.placed(pullSize,near:CGPoint(x:rtl ? safe.maxX-pullSize.width:safe.minX,y:safe.maxY-pullSize.height),in:safe,excluding:exclusions+[toolRect])
        if pull.frame != pullRect { pull.cancelTracking();session.cancel() }
        pull.frame=pullRect
        scoreCard.frame=FPRegionSnapshot.placed(CGSize(width:cardWidth,height:cardSize.height),near:CGPoint(x:rtl ? safe.minX:safe.maxX-cardWidth,y:safe.maxY-cardSize.height),in:safe,excluding:exclusions+[toolRect,pull.frame])
        status.isHidden=traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        if status.isHidden { status.frame = .zero;return }
        let textWidth=min(safe.width*0.48,FPTheme.statusWidth)
        let statusSize=status.sizeThatFits(CGSize(width:textWidth,height:safe.height))
        let hintOrigin=turnInput ? CGPoint(x:pull.frame.minX,y:pull.frame.minY-statusSize.height-FPTheme.hudGap):CGPoint(x:rtl ? safe.minX:safe.maxX-textWidth,y:scoreCard.frame.minY-statusSize.height-FPTheme.hudGap)
        status.frame=FPRegionSnapshot.placed(CGSize(width:textWidth,height:statusSize.height),near:hintOrigin,in:safe,excluding:exclusions+[toolRect,pull.frame,scoreCard.frame])
    }
    func refresh() {
        guard isViewLoaded else { return }
        if styledMode != session.gameMode {
            styledMode=session.gameMode
            let ink=session.isChibi ? FPChibiPalette.ink:FPTheme.ink
            let card=session.isChibi ? FPChibiPalette.card:FPTheme.surface
            score.textColor=ink;par.textColor=ink;scoreCard.backgroundColor=card.withAlphaComponent(0.94)
            scoreCard.layer.borderWidth=session.isChibi ? 1:0;scoreCard.layer.borderColor=FPChibiPalette.edge.withAlphaComponent(0.3).cgColor
            for case let button as UIButton in toolbar.arrangedSubviews {
                var config=button.configuration;config?.baseForegroundColor=ink;config?.baseBackgroundColor=card.withAlphaComponent(0.94);button.configuration=config
            }
            for case let star as UIImageView in starRow.arrangedSubviews { star.tintColor=session.isChibi ? FPChibiPalette.edge:FPTheme.gold }
        }
        view.backgroundColor=floating ? .clear:session.isChibi ? FPChibiPalette.paper:FPTheme.surface
        view.layer.shadowOpacity=session.isChibi ? 0:FPTheme.shadowOpacity
        pull.chibi=session.isChibi;pull.skin=session.ballSkin
        let cue=session.chibiFeedback.visibleCue
        pull.reaction=cue == .nearMiss ? .curious:cue == .collision && session.chibiFeedback.age<FPChibiTuning.collisionDuration ? .dizzy:.happy
        pull.visualRoll=session.isChibi && session.phase == .rolling && !FPMotion.reduced ? sin((session.world.position.x+session.world.position.y)*30)*0.3:0
        let oldText=score.accessibilityLabel,oldStatus=status.text
        // 窄控区以数字呈现杆数，完整单位保留在辅助阅读标签中，避免长译文被拆字。
        score.text=FPL10n.number(session.strokes);par.text=FPL10n.format("par",FPL10n.number(session.level.par))
        score.accessibilityLabel=FPL10n.format("strokes_par",FPL10n.number(session.strokes),FPL10n.number(session.level.par));score.accessibilityValue=FPL10n.format("stars",FPL10n.number(session.stars))
        status.text=session.status + (!session.isChibi && !session.ballTalkText.isEmpty ? "\n"+session.ballTalkText:"");status.textColor=session.isChibi ? FPChibiPalette.ink:FPTheme.fieldInk
        pull.enabled=session.canAim;pull.accessibilityHint=session.status
        session.setRegularInput(traitCollection.horizontalSizeClass == .regular);pull.inputProfile=session.inputProfile
        pull.preview=session.preview.map { FPShot(direction:turnInput ? CGVector(dx:-$0.direction.dy,dy:$0.direction.dx):$0.direction,power:$0.power) }
        for (index,view) in starRow.arrangedSubviews.enumerated() {
            if let star=view as? UIImageView { star.image=UIImage(systemName:index<session.stars ? "star.fill":"star");star.alpha=index<session.stars ? 1:0.45 }
        }
        if oldText != score.accessibilityLabel || oldStatus != status.text { view.setNeedsLayout() }
        refreshVisibility()
    }
    func refreshVisibility(immediate:Bool=false) {
        guard isViewLoaded else { return }
        let alpha:CGFloat = session.isReplaying ? 0:FPMotion.hudAlpha(for:session.phase)
        let pullAlpha:CGFloat = session.isReplaying ? 0:session.canAim ? (alpha == 0 ? (session.isChibi ? 0.72:FPMotion.aimingPullAlpha):1) : (UIAccessibility.isReduceTransparencyEnabled ? 1:FPMotion.disabledPullAlpha)
        for (element,target) in [(scoreCard as UIView,alpha),(toolbar,alpha),(status,alpha),(pull,pullAlpha)] {
            if immediate || FPMotion.reduced || session.isReplaying { element.layer.removeAllAnimations();element.alpha=target }
            else if element.alpha != target { UIView.animate(withDuration:FPMotion.controlFade,delay:0,options:[.beginFromCurrentState,.allowUserInteraction]) { element.alpha=target } }
        }
    }
    private func worldShot(_ shot:FPShot?)->FPShot? {
        shot.map { FPShot(direction:turnInput ? CGVector(dx:$0.direction.dy,dy:-$0.direction.dx):$0.direction,power:$0.power) }
    }
    func installScreenTap(in host:UIView) {
        let tap=UITapGestureRecognizer(target:self,action:#selector(screenTapped(_:)));tap.delegate=self;host.addGestureRecognizer(tap)
    }
    func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldReceive touch:UITouch)->Bool {
        guard session.canContinueAfterWin,let touched=touch.view else { return false }
        screenTapOrigin=touch.location(in:gestureRecognizer.view);screenTapStarted=touch.timestamp
        var ancestor:UIView?=touched
        while let current=ancestor { if current is UIControl { return false };ancestor=current.superview }
        return true
    }
    @objc private func screenTapped(_ tap:UITapGestureRecognizer) {
        let p=tap.location(in:tap.view)
        guard hypot(p.x-screenTapOrigin.x,p.y-screenTapOrigin.y)<=session.inputProfile.deadZone,
              ProcessInfo.processInfo.systemUptime-screenTapStarted<=FPMotion.screenTapMaximumDuration else { return }
        session.continueAfterWin()
    }
}

// Empty HUD space passes through to the course's direct ball gesture.
final class FPHUDSurfaceView:UIView {
    override func hitTest(_ point:CGPoint,with event:UIEvent?)->UIView? {
        guard let hit=super.hitTest(point,with:event) else { return nil }
        var current:UIView?=hit
        while let candidate=current,candidate !== self {
            if candidate is UIControl || candidate is FPPullControl { return hit }
            current=candidate.superview
        }
        return nil
    }
}

final class FPCourseController: UIViewController {
    var divisionRects: [CGRect] = []
    var exclusions: [CGRect] = []
    var overlayClearance: CGFloat = 0
    var headerMaximumWidth:CGFloat = 260
    var immersive=false { didSet { course.immersive=immersive } }
    let course: FPCourseView
    private let header = UIStackView()
    private let winCard=UIStackView()
    private lazy var replayCard=FPShotReplayView(session:session)
    private let winTitle=FPTheme.label(FPL10n.text("win"),style:.largeTitle,weight:.bold)
    private let winScore=FPTheme.label("",style:.headline,weight:.semibold)
    private let winHint=UIButton(type:.system)
    private var winHintHeight:NSLayoutConstraint?
    private var showingWin=false
    private let winIcon=UIImageView(image:UIImage(systemName:"trophy.fill"))
    private let winPortrait=FPChibiPortrait()
    private var styleSignature=""
    private let nameLabel=FPTheme.label(FPL10n.text("grass"),style:.title2,weight:.bold)
    private let subLabel=FPTheme.label("THE QUIET GREEN  /  01",style:.caption1,weight:.semibold)
    let session:FPDemoSession
    init(session:FPDemoSession) { self.session=session;course=FPCourseView(session:session);super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad();view.backgroundColor=FPTheme.grass.withAlphaComponent(0.18);view.addSubview(course)
        header.axis = .vertical;header.spacing=4;header.addArrangedSubview(subLabel);header.addArrangedSubview(nameLabel);view.addSubview(header)
        subLabel.textColor=FPTheme.fieldInk;nameLabel.textColor=FPTheme.fieldInk
        winIcon.tintColor=FPTheme.gold;winIcon.contentMode = .scaleAspectFit
        winIcon.heightAnchor.constraint(equalToConstant:40).isActive=true
        winPortrait.backgroundColor = .clear;winPortrait.widthAnchor.constraint(equalToConstant:72).isActive=true;winPortrait.heightAnchor.constraint(equalToConstant:72).isActive=true;winPortrait.isHidden=true
        winCard.axis = .vertical;winCard.spacing=8;winCard.alignment = .center
        winCard.isLayoutMarginsRelativeArrangement=true;winCard.directionalLayoutMargins=NSDirectionalEdgeInsets(top:20,leading:20,bottom:20,trailing:20)
        [winIcon,winPortrait,winTitle,winScore,winHint].forEach { winCard.addArrangedSubview($0) }
        winHint.setTitle(FPL10n.text("next_level_hint"),for:.normal)
        winHint.titleLabel?.font=FPTheme.font(.subheadline)
        winHint.titleLabel?.adjustsFontForContentSizeCategory=true
        winHint.titleLabel?.numberOfLines=0;winHint.titleLabel?.textAlignment = .center
        winHintHeight=winHint.heightAnchor.constraint(equalToConstant:FPTheme.target);winHintHeight?.isActive=true
        winHint.accessibilityIdentifier="continueAfterWin"
        winHint.addAction(UIAction { [weak session] _ in session?.continueAfterWin() },for:.touchUpInside)
        winScore.textAlignment = .center
        winCard.backgroundColor=FPTheme.surface;winCard.layer.cornerRadius=FPTheme.corner
        winCard.layer.shadowColor=UIColor.black.cgColor;winCard.layer.shadowOpacity=FPTheme.shadowOpacity;winCard.layer.shadowRadius=16
        winCard.isHidden=true
        winCard.isAccessibilityElement=false;winCard.accessibilityIdentifier="winFeedback"
        view.addSubview(winCard);view.addSubview(replayCard)
        course.onPreview = { [weak session] in session?.aim($0) };course.onRelease = { [weak session] in session?.release($0) };course.onCancel = { [weak session] in session?.cancel() }
    }
    func refreshHUDVisibility(immediate:Bool=false) {
        let alpha:CGFloat = session.isReplaying ? 0:FPMotion.hudAlpha(for:session.phase)
        if immediate || FPMotion.reduced || session.isReplaying {
            header.layer.removeAllAnimations();header.alpha=alpha
            if showingWin { winCard.layer.removeAllAnimations();winCard.alpha=1 }
        }
        else if header.alpha != alpha { UIView.animate(withDuration:FPMotion.controlFade,delay:0,options:[.beginFromCurrentState,.allowUserInteraction]) { self.header.alpha=alpha } }
    }
    func refreshHeader() {
        guard isViewLoaded else { return }
        refreshHUDVisibility();replayCard.refresh()
        let appearance="\(session.gameMode)|\(session.chibiMood)|\(session.ballSkin)"
        let rewardText=session.clubReward.map { ($0.seedGranted ? FPL10n.text("seed_reward"):FPL10n.text("seed_saved")) + ($0.newMastery ? FPL10n.text("badge_new"):"") } ?? ""
        let scoreText=FPL10n.format("strokes_stars",FPL10n.number(session.strokes),FPL10n.number(session.stars)) + (rewardText.isEmpty ? "":"\n"+rewardText)
        let won=session.canContinueAfterWin
        let changed=nameLabel.text != session.level.localizedName || winScore.text != scoreText || won != showingWin || appearance != styleSignature
        guard changed else { return }
        styleSignature=appearance
        view.backgroundColor=session.isChibi ? FPChibiPalette.paper:FPTheme.grass.withAlphaComponent(0.18)
        let ink=session.isChibi ? FPChibiPalette.ink:FPTheme.ink
        nameLabel.textColor=session.isChibi ? ink:FPTheme.fieldInk;subLabel.textColor=nameLabel.textColor
        winTitle.text=session.isChibi ? FPL10n.format("win_detail",session.chibiWinTitle):FPL10n.text("win")
        winTitle.textAlignment = .center;winTitle.textColor=ink;winScore.textColor=ink
        winHint.setTitle(session.isChibi ? FPL10n.text("next_level_arrow"):FPL10n.text("next_level_hint"),for:.normal)
        winHint.tintColor=session.isChibi ? FPChibiPalette.ink:UIColor.tintColor
        winCard.backgroundColor=session.isChibi ? FPChibiPalette.card:FPTheme.surface
        winCard.layer.borderWidth=session.isChibi ? 1.5:0;winCard.layer.borderColor=FPChibiPalette.edge.withAlphaComponent(0.6).cgColor
        winPortrait.skin=session.ballSkin;winPortrait.setNeedsDisplay()
        nameLabel.text=session.level.localizedName
        subLabel.text=session.isChibi ? FPL10n.format("club_section",session.level.id):"FOLD / PUTT · \(session.level.id)"
        winScore.text=scoreText
        let announcement=FPL10n.format("result_announcement",winTitle.text ?? FPL10n.text("win"),FPL10n.number(session.strokes),FPL10n.number(session.stars))
        if winCard.accessibilityLabel != announcement { winCard.accessibilityLabel=announcement }
        if won != showingWin {
            showingWin=won;winCard.isHidden = !won
            if won {
                winCard.alpha=FPMotion.reduced ? 1:0
                if !FPMotion.reduced { UIView.animate(withDuration:FPMotion.flag) { self.winCard.alpha=1 } }
                UIAccessibility.post(notification:.announcement,argument:winCard.accessibilityLabel)
            }
        }
        view.setNeedsLayout()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();course.frame=view.bounds
        let largeShort=traitCollection.verticalSizeClass == .compact && traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        nameLabel.isHidden=largeShort;winIcon.isHidden=largeShort || session.isChibi;winPortrait.isHidden=largeShort || !session.isChibi;winScore.isHidden=largeShort
        winTitle.font=session.isChibi ? FPChibiPalette.handwriting(largeShort ? .headline:.title1,compatibleWith:traitCollection):FPTheme.font(largeShort ? .headline:.largeTitle,weight:.bold)
        let s=view.safeAreaInsets
        let available=CGRect(x:s.left+24,y:s.top+16,width:max(0,view.bounds.width-s.left-s.right-48),height:max(0,view.bounds.height-s.top-s.bottom-32-overlayClearance))
        let usable=FPRegionSnapshot.usable(available,excluding:exclusions)
        let headerSize=header.systemLayoutSizeFitting(CGSize(width:min(headerMaximumWidth,available.width),height:100),withHorizontalFittingPriority:.required,verticalFittingPriority:.fittingSizeLevel)
        let headerWidth=min(headerMaximumWidth,available.width)
        let headerX=view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? available.maxX-headerWidth:available.minX
        let headerArea=FPRegionSnapshot.usable(CGRect(x:headerX,y:available.minY,width:headerWidth,height:headerSize.height),excluding:exclusions)
        let size=header.systemLayoutSizeFitting(CGSize(width:headerArea.width,height:100),withHorizontalFittingPriority:.required,verticalFittingPriority:.fittingSizeLevel)
        header.frame=CGRect(x:headerArea.minX,y:headerArea.minY,width:headerArea.width,height:size.height)
        nameLabel.text=session.level.localizedName
        subLabel.text=largeShort ? FPL10n.format("pair",session.level.id,session.level.localizedName):session.isChibi ? FPL10n.format("club_section",session.level.id):"FOLD / PUTT · \(session.level.id)"
        course.exclusions=exclusions
        course.topClearance=s.top+size.height+24;course.bottomClearance=s.bottom+12+overlayClearance
        let regions=FPRegionSnapshot.read(in:course)
        course.divisionRects=divisionRects.isEmpty ? regions.divisions:divisionRects
        if immersive {
            course.across = course.bounds.width>course.bounds.height && !course.divisionRects.contains { $0.width>$0.height }
            session.updateDivision(nil,field:course.field)
            let banks=course.divisionRects.flatMap { course.projection.banks(for:$0) }
            let cameras=regions.occlusions.map { course.projection.worldRect($0) }.filter { !$0.isNull && $0.width>0 && $0.height>0 }
            session.updateReservedBanks(banks+cameras)
        } else {
            session.updateReservedBanks([])
            session.updateDivision(course.divisionRects.first,field:course.field)
        }
        course.setNeedsDisplay()
        let cardWidth=max(0,usable.width*0.88)
        let hintWidth=max(1,cardWidth-winCard.directionalLayoutMargins.leading-winCard.directionalLayoutMargins.trailing)
        let hintHeight=winHint.titleLabel?.sizeThatFits(CGSize(width:hintWidth,height:.greatestFiniteMagnitude)).height ?? 0
        winHintHeight?.constant=max(FPTheme.target,hintHeight+16)
        let cardSize=winCard.systemLayoutSizeFitting(CGSize(width:cardWidth,height:0),withHorizontalFittingPriority:.required,verticalFittingPriority:.fittingSizeLevel)
        winCard.frame=CGRect(x:usable.midX-cardWidth/2,y:max(usable.minY,usable.midY-cardSize.height/2),width:cardWidth,height:min(usable.height,cardSize.height))
        let replayUsable=FPRegionSnapshot.usable(view.bounds.inset(by:s).insetBy(dx:16,dy:16),excluding:exclusions)
        let replayWidth=min(replayUsable.width>replayUsable.height*1.3 ? 640:420,replayUsable.width)
        replayCard.frame=CGRect(x:replayUsable.midX-replayWidth/2,y:replayUsable.midY-min(460,replayUsable.height)/2,width:replayWidth,height:min(460,replayUsable.height))
        view.bringSubviewToFront(winCard);view.bringSubviewToFront(replayCard)
    }
}
