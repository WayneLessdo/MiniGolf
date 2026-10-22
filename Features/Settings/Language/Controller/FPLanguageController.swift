import UIKit

/// 原生列表提供即时切换，所有操作都能滚动至安全区域内。
final class FPLanguageController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var finished: (() -> Void)?
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let done = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "languageSelection"
        table.dataSource = self; table.delegate = self
        table.rowHeight = UITableView.automaticDimension; table.estimatedRowHeight = 56
        table.contentInsetAdjustmentBehavior = .never
        view.addSubview(table)
        done.setTitleColor(.label, for: .normal)
        done.titleLabel?.font = FPTheme.font(.body, weight: .semibold)
        done.titleLabel?.adjustsFontForContentSizeCategory = true
        done.accessibilityIdentifier = "closeLanguage"
        done.heightAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        done.widthAnchor.constraint(greaterThanOrEqualToConstant: FPTheme.target).isActive = true
        done.addAction(UIAction { [weak self] _ in self?.finished?() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: done)
        refreshLanguage()
    }
    func refreshLanguage() {
        guard isViewLoaded else { return }
        title = FPL10n.text("settings_language")
        done.setTitle(FPL10n.text("done"), for: .normal)
        let direction: UISemanticContentAttribute = FPLanguageManager.shared.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
        navigationController?.view.semanticContentAttribute = direction
        navigationController?.navigationBar.semanticContentAttribute = direction
        view.semanticContentAttribute = direction
        table.semanticContentAttribute = direction
        table.reloadData(); view.setNeedsLayout()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { FPLanguage.allCases.count + 1 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let language = indexPath.row == 0 ? nil : FPLanguage.allCases[indexPath.row - 1]
        cell.textLabel?.text = language?.nativeName ?? FPL10n.text("settings_language_system")
        cell.textLabel?.textAlignment = FPLanguageManager.shared.isRightToLeft ? .right : .left
        cell.textLabel?.font = FPTheme.font(.body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true; cell.textLabel?.numberOfLines = 0
        cell.accessoryType = FPLanguageManager.shared.selection == language ? .checkmark : .none
        cell.accessibilityTraits = FPLanguageManager.shared.selection == language ? [.button, .selected] : .button
        cell.accessibilityIdentifier = "language-" + (language?.rawValue ?? "system")
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        FPLanguageManager.shared.select(indexPath.row == 0 ? nil : FPLanguage.allCases[indexPath.row - 1])
    }
    override func viewSafeAreaInsetsDidChange() { super.viewSafeAreaInsetsDidChange(); view.setNeedsLayout() }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let regions = FPRegionSnapshot.read(in: view)
        let safe = FPRegionSnapshot.usable(view.safeAreaLayoutGuide.layoutFrame, excluding: regions.exclusions)
        let width = min(640, safe.width)
        table.frame = CGRect(x: safe.midX - width / 2, y: safe.minY, width: width, height: safe.height)
        #if DEBUG
        view.accessibilityValue = "language=\(FPL10n.language);direction=\(view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? "rtl" : "ltr");bounds=\(view.bounds);traits=\(traitCollection.horizontalSizeClass.rawValue),\(traitCollection.verticalSizeClass.rawValue);safeArea=\(view.safeAreaInsets);division=\(regions.divisions);occlusion=\(regions.occlusions)"
        #endif
    }
}
