import UIKit

enum FPClubSection: Int, CaseIterable {
    case puzzles, garden, quotes
    var title: String { switch self { case .puzzles:return FPL10n.text("puzzles");case .garden:return FPL10n.text("garden");case .quotes:return FPL10n.text("silly_quotes") } }
}

/// Collection pages own no game loop. Presenting this controller pauses the existing scene.
final class FPClubController: UIViewController {
    let session: FPDemoSession
    var finished: (() -> Void)?
    private var section: FPClubSection
    private var flower: FPFlower = .daisy
    private let tabs=UISegmentedControl(items:FPClubSection.allCases.map(\.title))
    private let scroll=UIScrollView()
    private let content=UIStackView()
    private var columns=3
    private var pendingAnchor:(id:String,fraction:CGFloat)?
    private func identifiedContent(in parent:UIView)->[UIView] {
        parent.subviews.flatMap { child in
            (child.accessibilityIdentifier == nil ? []:[child]) + identifiedContent(in:child)
        }
    }
    private func readingAnchor()->(id:String,fraction:CGFloat)? {
        guard scroll.contentOffset.y>0 else { return nil }
        return identifiedContent(in:content).compactMap { item -> (String,CGRect)? in
            let rect=item.convert(item.bounds,to:scroll)
            guard rect.height>0,rect.intersects(scroll.bounds),let id=item.accessibilityIdentifier else { return nil }
            return (id,rect)
        }.sorted { $0.1.minY<$1.1.minY }.first.map { ($0.0,max(0,(scroll.bounds.minY-$0.1.minY)/$0.1.height)) }
    }
    private func restoreReadingAnchor() {
        guard let anchor=pendingAnchor else { return }
        pendingAnchor=nil
        scroll.layoutIfNeeded();content.layoutIfNeeded()
        guard let item=identifiedContent(in:content).first(where:{$0.accessibilityIdentifier == anchor.id}) else { return }
        let rect=item.convert(item.bounds,to:scroll)
        let y=min(max(0,scroll.contentSize.height-scroll.bounds.height),max(0,rect.minY+anchor.fraction*rect.height))
        scroll.setContentOffset(CGPoint(x:0,y:y),animated:false)
    }
    init(session:FPDemoSession,section:FPClubSection) { self.session=session;self.section=section;super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        // 全屏辅助页始终保留返回入口，避免 iOS 27 滚动收栏后难以退出。
        if #available(iOS 27.0, *) { navigationItem.navigationBarMinimization.minimizationBehavior = .never }
        overrideUserInterfaceStyle = .light
        // 收藏页固定使用浅色纸张，导航栏也须采用同一外观，避免深色系统下标题变白。
        navigationController?.overrideUserInterfaceStyle = .light
        title=FPL10n.text("club");view.backgroundColor=FPChibiPalette.paper
        view.accessibilityIdentifier="clubCollection"
        let done=UIButton(type:.system);done.setTitle(FPL10n.text("back_to_course"),for:.normal)
        done.titleLabel?.font=FPTheme.font(.body,weight:.semibold);done.titleLabel?.adjustsFontForContentSizeCategory=true
        done.accessibilityIdentifier="closeClub";done.addAction(UIAction { [weak self] _ in self?.finished?() },for:.touchUpInside)
        done.heightAnchor.constraint(greaterThanOrEqualToConstant:FPTheme.target).isActive=true
        done.widthAnchor.constraint(greaterThanOrEqualToConstant:72).isActive=true
        navigationItem.rightBarButtonItem=UIBarButtonItem(customView:done)
        navigationController?.navigationBar.tintColor=FPChibiPalette.ink
        tabs.selectedSegmentIndex=section.rawValue;tabs.accessibilityIdentifier="clubSections"
        tabs.selectedSegmentTintColor=FPChibiPalette.meadow
        tabs.addAction(UIAction { [weak self] _ in
            guard let self,let section=FPClubSection(rawValue:self.tabs.selectedSegmentIndex) else { return }
            self.section=section;self.rebuild();self.pendingAnchor=nil;self.scroll.setContentOffset(.zero,animated:false)
        },for:.valueChanged)
        view.addSubview(tabs);view.addSubview(scroll)
        scroll.accessibilityIdentifier="clubScroll"
        scroll.contentInsetAdjustmentBehavior = .never
        content.axis = .vertical;content.spacing=16;content.translatesAutoresizingMaskIntoConstraints=false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor,constant:4),
            content.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor,constant:-4),
            content.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor,constant:16),
            content.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor,constant:-24),
            content.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor,constant:-8)
        ])
        NotificationCenter.default.addObserver(self,selector:#selector(progressChanged),name:FPClubProgressStore.didChange,object:nil)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self,UITraitDisplayScale.self]) { (controller:FPClubController,_:UITraitCollection) in
            controller.rebuild();controller.view.setNeedsLayout()
        }
        session.club.reload();rebuild()
    }
    override func viewWillAppear(_ animated:Bool) { super.viewWillAppear(animated);session.club.reload();rebuild() }
    @objc private func progressChanged() { session.club.reload();rebuild() }
    private func text(_ value:String,style:UIFont.TextStyle = .body)->UILabel {
        let label=FPTheme.label(value,style:style);label.textColor=FPChibiPalette.ink;return label
    }
    private func card(title:String,detail:String,id:String,image:UIImage?=nil,action:@escaping ()->Void)->UIButton {
        var config=UIButton.Configuration.filled();config.title=title;config.subtitle=detail
        config.baseForegroundColor=FPChibiPalette.ink;config.baseBackgroundColor=FPChibiPalette.card
        config.cornerStyle = .large;config.contentInsets=NSDirectionalEdgeInsets(top:16,leading:16,bottom:16,trailing:16)
        config.titleAlignment = .leading;config.titlePadding=6;config.image=image;config.imagePadding=14
        config.attributedTitle=AttributedString(NSAttributedString(string:title,attributes:[.font:FPTheme.font(.headline)]))
        config.attributedSubtitle=AttributedString(NSAttributedString(string:detail,attributes:[.font:FPTheme.font(.subheadline)]))
        let button=UIButton(configuration:config,primaryAction:UIAction { _ in action() })
        button.contentHorizontalAlignment = .leading;button.titleLabel?.numberOfLines=0;button.subtitleLabel?.numberOfLines=0
        button.titleLabel?.adjustsFontForContentSizeCategory=true;button.subtitleLabel?.adjustsFontForContentSizeCategory=true
        button.accessibilityIdentifier=id;button.accessibilityLabel=title;button.accessibilityValue=detail
        button.heightAnchor.constraint(greaterThanOrEqualToConstant:FPTheme.target).isActive=true
        return button
    }
    private func heading(_ title:String,_ detail:String) {
        content.addArrangedSubview(text(title,style:.title1))
        let label=text(detail,style:.subheadline);label.textColor=FPChibiPalette.secondary;content.addArrangedSubview(label)
    }
    private func rebuild() {
        guard isViewLoaded else { return }
        if pendingAnchor == nil { pendingAnchor=readingAnchor() }
        content.arrangedSubviews.forEach { content.removeArrangedSubview($0);$0.removeFromSuperview() }
        switch section { case .puzzles:puzzles();case .garden:garden();case .quotes:quotes() }
        view.setNeedsLayout()
    }
    private func puzzles() {
        let state=session.club.state
        let levels=session.levels.enumerated().filter { $0.element.isPuzzle }
        let mastered=levels.filter { state.mastery.contains($0.element.id) }.count
        heading(FPL10n.text("borrow_wall"), FPL10n.format("puzzles_description",FPL10n.number(mastered),FPL10n.number(levels.count)))
        for (index,level) in levels {
            let best=state.best[level.id].map { FPL10n.format("personal_best",FPL10n.number($0)) } ?? FPL10n.text("not_completed")
            let badge=state.mastery.contains(level.id) ? FPL10n.text("mastery_complete"):FPL10n.text("mastery_pending")
            let button=card(title:FPL10n.format("numbered_title",FPL10n.number(level.puzzleNumber ?? 1),level.localizedName),detail:FPL10n.format("puzzle_summary",FPL10n.number(level.par),best,badge,level.mapDescription),id:"puzzle-"+level.id,image:traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? nil:FPClubArt.map(level,scale:traitCollection.displayScale)) { [weak self] in
                guard let self else { return };self.session.loadLevel(index);self.finished?()
            }
            button.accessibilityHint=FPL10n.text("restart_description")
            content.addArrangedSubview(button)
        }
        content.addArrangedSubview(text(FPL10n.text("puzzles_rules"),style:.footnote))
    }
    private func garden() {
        let state=session.club.state
        heading(FPL10n.text("shot_flower"), FPL10n.text("garden_rules"))
        let balance=text(FPL10n.format("garden_balance",FPL10n.number(state.seeds),FPL10n.number(state.plantedCount),FPL10n.number(FPClubRules.gardenSlots)),style:.headline)
        balance.accessibilityIdentifier="gardenBalance";content.addArrangedSubview(balance)
        let points = text(FPL10n.format("points_balance", FPL10n.number(state.points)), style: .headline)
        points.accessibilityIdentifier = "pointsBalance"; content.addArrangedSubview(points)
        content.addArrangedSubview(text(FPL10n.text(session.club.persistenceError == nil ? "points_saved" : "progress_save_error"), style: .footnote))
        let choices=UIStackView();choices.axis=traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical:.horizontal
        choices.distribution = .fillEqually;choices.spacing=8
        for kind in FPFlower.allCases {
            var config=UIButton.Configuration.filled();config.title=kind.title
            config.baseForegroundColor=FPChibiPalette.ink;config.baseBackgroundColor=flower == kind ? FPChibiPalette.meadow:FPChibiPalette.card
            config.image=flower == kind ? UIImage(systemName:"checkmark"):nil;config.imagePadding=4
            let button=UIButton(configuration:config,primaryAction:UIAction { [weak self] _ in self?.flower=kind;self?.rebuild() })
            button.titleLabel?.numberOfLines=0;button.titleLabel?.adjustsFontForContentSizeCategory=true
            button.accessibilityIdentifier="flower-"+kind.rawValue;button.accessibilityTraits=flower == kind ? [.button,.selected]:.button
            button.heightAnchor.constraint(greaterThanOrEqualToConstant:FPTheme.target).isActive=true;choices.addArrangedSubview(button)
        }
        content.addArrangedSubview(choices)
        for row in stride(from:0,to:FPClubRules.gardenSlots,by:columns) {
            let line=UIStackView();line.axis = .horizontal;line.spacing=10;line.distribution = .fillEqually
            for index in row..<min(row+columns,FPClubRules.gardenSlots) {
                let planted=state.garden[index]
                var config=UIButton.Configuration.filled();config.title=planted?.title ?? FPL10n.text("garden_plant")
                config.subtitle=FPL10n.format("garden_slot_number",FPL10n.number(index+1));config.image=FPClubArt.flower(planted,scale:traitCollection.displayScale)
                config.imagePlacement = .top;config.imagePadding=6;config.titleAlignment = .center
                config.baseForegroundColor=FPChibiPalette.ink;config.baseBackgroundColor=planted == nil ? FPChibiPalette.card:FPChibiPalette.meadow
                config.contentInsets=NSDirectionalEdgeInsets(top:12,leading:4,bottom:12,trailing:4);config.cornerStyle = .large
                let button=UIButton(configuration:config,primaryAction:UIAction { [weak self] _ in self?.selectPlot(index) })
                button.titleLabel?.numberOfLines=0;button.subtitleLabel?.numberOfLines=0
                button.titleLabel?.adjustsFontForContentSizeCategory=true;button.subtitleLabel?.adjustsFontForContentSizeCategory=true
                button.accessibilityIdentifier="garden-slot-\(index)"
                button.accessibilityLabel=FPL10n.format("garden_slot_flower",FPL10n.number(index+1),planted?.title ?? FPL10n.text("garden_slot"))
                button.accessibilityHint=planted == nil ? FPL10n.format("garden_plant_hint",flower.title):FPL10n.text("garden_move_hint")
                button.heightAnchor.constraint(greaterThanOrEqualToConstant:124).isActive=true;line.addArrangedSubview(button)
            }
            content.addArrangedSubview(line)
        }
        content.addArrangedSubview(card(title:FPL10n.text("garden_call_to_action"),detail:FPL10n.text("course_progress_hint"),id:"gardenPlay") { [weak self] in
            guard let self else { return };if self.session.phase == .success { self.session.finishReplay();self.session.continueAfterWin() };self.finished?()
        })
    }
    private func selectPlot(_ index:Int) {
        session.club.reload()
        if let planted=session.club.state.garden[index] {
            let alert=UIAlertController(title:FPL10n.format("move_flower",planted.title),message:FPL10n.text("garden_reclaim_description"),preferredStyle:.alert)
            alert.addAction(UIAlertAction(title:FPL10n.text("stay"),style:.cancel))
            alert.addAction(UIAlertAction(title:FPL10n.text("garden_reclaim"),style:.default) { [weak self] _ in
                _=self?.session.club.uproot(at:index)
            });present(alert,animated:!FPMotion.reduced)
        } else if !session.club.plant(flower,at:index) {
            let alert=UIAlertController(title:FPL10n.text("garden_empty"),message:FPL10n.text("garden_seed_hint"),preferredStyle:.alert)
            alert.addAction(UIAlertAction(title:FPL10n.text("keep_browsing"),style:.cancel));alert.addAction(UIAlertAction(title:FPL10n.text("play"),style:.default) { [weak self] _ in self?.finished?() })
            present(alert,animated:!FPMotion.reduced)
        } else { UIAccessibility.post(notification:.announcement,argument:FPL10n.format("garden_planted",FPL10n.number(index+1),flower.title)) }
    }
    private func quotes() {
        let state=session.club.state
        heading(FPL10n.text("progress_silly"), FPL10n.format("quotes_description",FPL10n.number(state.quotes.count),FPL10n.number(FPClubQuote.allCases.count)))
        for voice in FPClubVoice.allCases {
            content.addArrangedSubview(card(title:(state.voice == voice ? "✓ ":"")+voice.title,detail:voice == .quiet ? FPL10n.text("voice_quiet_description"):voice == .silly ? FPL10n.text("mistakes_silly"):FPL10n.text("voice_cozy_description"),id:"voice-"+voice.rawValue) { [weak self] in self?.session.setClubVoice(voice) })
        }
        content.addArrangedSubview(text(FPL10n.text("quotes_collection"),style:.title2))
        for quote in FPClubQuote.allCases {
            let unlocked=state.quotes.contains(quote)
            let title=text((unlocked ? "✓ ":"○ ")+quote.title,style:.headline);title.accessibilityIdentifier="quote-"+quote.rawValue
            let body=text(unlocked ? FPL10n.format("voice_examples",quote.text(.silly),quote.text(.cozy)):FPL10n.text("quote_undiscovered"),style:.body)
            let stack=UIStackView(arrangedSubviews:[title,body]);stack.axis = .vertical;stack.spacing=8
            stack.isLayoutMarginsRelativeArrangement=true;stack.directionalLayoutMargins=NSDirectionalEdgeInsets(top:16,leading:16,bottom:16,trailing:16)
            stack.backgroundColor=FPChibiPalette.card;stack.layer.cornerRadius=18
            content.addArrangedSubview(stack)
        }
        content.addArrangedSubview(text(FPL10n.text("feedback_rules"),style:.footnote))
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange();view.setNeedsLayout()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let regions=FPRegionSnapshot.read(in:view)
        let usable=FPRegionSnapshot.usable(view.safeAreaLayoutGuide.layoutFrame,excluding:regions.exclusions).insetBy(dx:16,dy:8)
        let oldAnchor=readingAnchor()
        let width=max(0,min(720,usable.width)),area=CGRect(x:usable.midX-width/2,y:usable.minY,width:width,height:max(0,usable.height))
        tabs.frame=CGRect(x:area.minX,y:area.minY,width:width,height:FPTheme.target)
        let scrollFrame=CGRect(x:area.minX,y:tabs.frame.maxY+8,width:width,height:max(0,area.height-FPTheme.target-8))
        if scroll.frame.size != scrollFrame.size,pendingAnchor == nil { pendingAnchor=oldAnchor }
        scroll.frame=scrollFrame
        let desiredColumns=traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1:width<330 ? 2:3
        if columns != desiredColumns { columns=desiredColumns;if section == .garden { rebuild() } }
        restoreReadingAnchor()
        #if DEBUG
        let safe=view.safeAreaInsets
        let proof="section=\(section.title);bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(safe.top),\(safe.left),\(safe.bottom),\(safe.right);division=\(regions.divisions);activeDivision=\(regions.activeDivisions);occlusion=\(regions.occlusions);seeds=\(session.club.state.seeds);flowers=\(session.club.state.plantedCount);quotes=\(session.club.state.quotes.count);reduceMotion=\(FPMotion.reduced)"
        view.accessibilityValue=proof
        if let data=proof.data(using:.utf8),let directory=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first { try? data.write(to:directory.appendingPathComponent("club-layout.txt"),options:.atomic) }
        #endif
    }
}

@MainActor private enum FPClubArt {
    static func map(_ level:FPLevel,scale:CGFloat)->UIImage {
        let format=UIGraphicsImageRendererFormat();format.scale=scale
        return UIGraphicsImageRenderer(size:CGSize(width:62,height:86),format:format).image { renderer in
            let c=renderer.cgContext
            FPChibiPalette.meadow.setFill();UIBezierPath(roundedRect:CGRect(x:0,y:0,width:62,height:86),cornerRadius:10).fill()
            func rect(_ r:FPRect)->CGRect { CGRect(x:4+r.x*54,y:4+r.y*54,width:r.width*54,height:r.height*54) }
            FPChibiPalette.sand.setFill();level.sand.forEach { c.fill(rect($0)) }
            FPChibiPalette.water.setFill();level.hazards.forEach { c.fill(rect($0)) }
            FPChibiPalette.edge.setFill();level.obstacles.forEach { c.fill(rect($0)) }
            FPChibiPalette.card.setFill();c.fillEllipse(in:CGRect(x:4+level.start.x*54-3,y:4+level.start.y*54-3,width:6,height:6))
            FPChibiPalette.ink.setFill();c.fillEllipse(in:CGRect(x:4+level.hole.x*54-4,y:4+level.hole.y*54-4,width:8,height:8))
        }
    }
    static func flower(_ flower:FPFlower?,scale:CGFloat)->UIImage {
        let format=UIGraphicsImageRendererFormat();format.scale=scale
        return UIGraphicsImageRenderer(size:CGSize(width:58,height:68),format:format).image { renderer in
            let c=renderer.cgContext
            guard let flower else {
                c.setStrokeColor(FPChibiPalette.edge.cgColor);c.setLineWidth(2)
                c.move(to:CGPoint(x:19,y:34));c.addLine(to:CGPoint(x:39,y:34));c.move(to:CGPoint(x:29,y:24));c.addLine(to:CGPoint(x:29,y:44));c.strokePath();return
            }
            c.setStrokeColor(FPChibiPalette.edge.cgColor);c.setLineWidth(3)
            c.move(to:CGPoint(x:29,y:25));c.addLine(to:CGPoint(x:29,y:64));c.strokePath()
            c.setFillColor(FPChibiPalette.edge.cgColor);c.fillEllipse(in:CGRect(x:15,y:44,width:14,height:7));c.fillEllipse(in:CGRect(x:29,y:50,width:15,height:7))
            let color:UIColor=flower == .daisy ? FPChibiPalette.card:flower == .tulip ? FPChibiPalette.blush:UIColor(red:0.56,green:0.65,blue:0.80,alpha:1)
            c.setFillColor(color.cgColor)
            if flower == .tulip {
                for x in [17,25,33] { c.fillEllipse(in:CGRect(x:x,y:10,width:10,height:24)) }
            } else {
                c.saveGState();c.translateBy(x:29,y:25)
                for _ in 0..<5 { c.fillEllipse(in:CGRect(x:-6,y:-20,width:12,height:21));c.rotate(by:.pi*2/5) };c.restoreGState()
            }
            c.setFillColor(UIColor(red:0.87,green:0.70,blue:0.34,alpha:1).cgColor);c.fillEllipse(in:CGRect(x:24,y:20,width:10,height:10))
        }
    }
}
