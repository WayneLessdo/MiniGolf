import UIKit

/// 政策随 App 打包，离线可读；布局只依赖当前容器与实际保留区域。
final class FPPrivacyController: UIViewController {
    var finished: (() -> Void)?
    private let text = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // 全屏辅助页始终保留返回入口，避免 iOS 27 滚动收栏后难以退出。
        if #available(iOS 27.0, *) { navigationItem.navigationBarMinimization.minimizationBehavior = .never }

        title = FPL10n.text("privacy")
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "privacyPolicy"
        let done = UIButton(type: .system)
        done.setTitle(FPL10n.text("done"), for: .normal)
        done.titleLabel?.font = FPTheme.font(.body, weight: .semibold)
        done.titleLabel?.adjustsFontForContentSizeCategory = true
        done.accessibilityIdentifier = "closePrivacy"
        done.heightAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        done.widthAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        done.addAction(UIAction { [weak self] _ in self?.finished?() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: done)
        text.accessibilityIdentifier = "privacyText"
        text.isEditable = false
        text.isSelectable = true
        text.dataDetectorTypes = [.link]
        text.adjustsFontForContentSizeCategory = true
        text.font = FPTheme.font(.body)
        text.textAlignment = .natural
        text.textColor = .label
        text.backgroundColor = .systemBackground
        text.contentInsetAdjustmentBehavior = .never
        text.textContainerInset = UIEdgeInsets(top: FPTheme.spacing, left: FPTheme.spacing, bottom: FPTheme.spacing * 2, right: FPTheme.spacing)
        let localizedPolicy = FPL10n.text("privacy_policy_body")
        if localizedPolicy != "privacy_policy_body" {
            text.text = localizedPolicy
        } else if let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "txt"),
           let policy = try? String(contentsOf: url, encoding: .utf8) {
            text.text = policy
        } else {
            text.text = FPL10n.text("privacy_unavailable")
        }
        // 保留离线正文，并提供可直接打开的公开政策链接。
        let policyPath = FPL10n.language == "zh-Hans" ? "privacy-zh-Hans" : "privacy"
        text.text += "\n\n\(FPL10n.text("privacy")):\nhttps://foldputt-help-wayne.humble-mite-6617.chatgpt.site/\(policyPath)"
        view.addSubview(text)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: FPPrivacyController, _: UITraitCollection) in
            controller.text.font = FPTheme.font(.body)
            controller.view.setNeedsLayout()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let regions = FPRegionSnapshot.read(in: view)
        let safe = FPRegionSnapshot.usable(view.safeAreaLayoutGuide.layoutFrame, excluding: regions.exclusions)
        let width = min(720, safe.width)
        text.frame = CGRect(x: safe.midX - width / 2, y: safe.minY, width: width, height: safe.height)
        #if DEBUG
        view.accessibilityValue = "language=\(FPL10n.language);direction=\(view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? "rtl":"ltr");bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(view.safeAreaInsets);division=\(regions.divisions);occlusion=\(regions.occlusions)"
        #endif
    }
}
