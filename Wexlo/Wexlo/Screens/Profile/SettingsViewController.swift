import UIKit
import WebKit

final class SettingsViewController: UIViewController {
    struct Item {
        let title: String
        let subtitle: String
        let iconName: String
        let route: String?
        let isDestructive: Bool
    }

    private let pageTitle = "Settings"
    private let pageSubtitle = "Manage your Wexlo account and preferences."
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let sessionStore = WexloSessionStore.shared
    private let accountStore = WexloAccountStore.shared
    private let coinStore = WexloCoinStore.shared
    private let loadingOverlay = WexloLoadingOverlay()
    private var isProcessingAccountAction = false

    private let primaryItems = [
        Item(
            title: "Block List",
            subtitle: "Manage accounts you have blocked",
            iconName: "wexlo_settings_block",
            route: "blockList",
            isDestructive: false
        ),
        Item(
            title: "Privacy Policy",
            subtitle: "How Wexlo handles your information",
            iconName: "wexlo_settings_privacy",
            route: "privacy",
            isDestructive: false
        ),
        Item(
            title: "Terms Of Service",
            subtitle: "The rules for using Wexlo",
            iconName: "wexlo_settings_terms",
            route: "terms",
            isDestructive: false
        )
    ]

    private let accountItems = [
        Item(
            title: "Sign Out",
            subtitle: "Sign out of this device",
            iconName: "wexlo_settings_logout",
            route: "logout",
            isDestructive: false
        ),
        Item(
            title: "Delete Account",
            subtitle: "Permanently remove your Wexlo account",
            iconName: "wexlo_settings_delete",
            route: "delete",
            isDestructive: true
        )
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureHeader()
        configureContent()
    }

    private func configureHeader() {
        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        titleLabel.text = pageTitle
        titleLabel.font = WexloTheme.font(size: 30, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText

        subtitleLabel.text = pageSubtitle
        subtitleLabel.font = WexloTheme.font(size: 16)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 2

        [backButton, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 36),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    private func configureContent() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.distribution = .fill

        addCard(items: primaryItems)
        addCard(items: accountItems)

        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset.bottom = 28
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func addCard(items: [Item]) {
        let card = UIView()
        card.backgroundColor = WexloTheme.surface
        card.layer.cornerRadius = 25
        card.layer.borderWidth = 1
        card.layer.borderColor = WexloTheme.hairline.cgColor
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let rows = UIStackView()
        rows.axis = .vertical
        rows.alignment = .fill
        rows.distribution = .fill
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)

        for (index, item) in items.enumerated() {
            let row = SettingsRowView(item: item)
            row.onTap = { [weak self] in
                self?.handleRoute(item.route)
            }
            rows.addArrangedSubview(row)

            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = WexloTheme.hairline
                separator.translatesAutoresizingMaskIntoConstraints = false
                rows.addArrangedSubview(separator)
                separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
            }
        }

        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func handleRoute(_ route: String?) {
        switch route {
        case "blockList":
            navigationController?.pushViewController(BlockListViewController(), animated: true)
        case "privacy":
            navigationController?.pushViewController(
                LegalWebViewController(
                    title: "Privacy Policy",
                    urlString: "https://sites.google.com/view/wexlo/privacy"
                ),
                animated: true
            )
        case "terms":
            navigationController?.pushViewController(
                LegalWebViewController(
                    title: "Terms of Service",
                    urlString: "https://sites.google.com/view/wexlo/users"
                ),
                animated: true
            )
        case "logout":
            let dialog = SignOutViewController()
            dialog.onConfirm = { [weak self] in
                self?.performLogout()
            }
            present(dialog, animated: true)
        case "delete":
            let dialog = DeleteAccountViewController()
            dialog.onConfirm = { [weak self] in
                self?.performDeleteAccount()
            }
            present(dialog, animated: true)
        default:
            break
        }
    }

    private func performLogout() {
        guard !isProcessingAccountAction else { return }
        isProcessingAccountAction = true
        setAccountActionEnabled(false)
        loadingOverlay.show(in: view)
        completeWexloLoading(loadingOverlay) { [weak self] in
            guard let self else { return }
            isProcessingAccountAction = false
            setAccountActionEnabled(true)
            sessionStore.clearSession(toastMessage: "Signed out successfully.")
        }
    }

    private func performDeleteAccount() {
        guard !isProcessingAccountAction else { return }
        guard case .authenticated(let userID) = sessionStore.current else {
            showWexloToast("Please sign in to delete your account.")
            return
        }

        isProcessingAccountAction = true
        setAccountActionEnabled(false)
        loadingOverlay.show(in: view)
        do {
            try accountStore.deleteAccount(userID: userID)
            completeWexloLoading(loadingOverlay) { [weak self] in
                guard let self else { return }
                coinStore.deleteBalance(for: userID)
                isProcessingAccountAction = false
                setAccountActionEnabled(true)
                sessionStore.clearSession(toastMessage: "Account deleted successfully.")
            }
        } catch let error as WexloAccountError {
            loadingOverlay.hide()
            isProcessingAccountAction = false
            setAccountActionEnabled(true)
            showWexloToast(error.userMessage)
        } catch {
            loadingOverlay.hide()
            isProcessingAccountAction = false
            setAccountActionEnabled(true)
            showWexloToast("Account deletion failed. Please try again.")
        }
    }

    private func setAccountActionEnabled(_ enabled: Bool) {
        view.isUserInteractionEnabled = enabled
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
}

final class LegalWebViewController: UIViewController, WKNavigationDelegate {
    private let urlString: String
    private let navigationHeader: WexloNavigationHeader
    private let webView = WKWebView(frame: .zero)

    init(title: String, urlString: String) {
        self.urlString = urlString
        navigationHeader = WexloNavigationHeader(style: .titled(title))
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        navigationHeader.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        webView.navigationDelegate = self
        webView.backgroundColor = WexloTheme.background
        webView.isOpaque = false
        webView.allowsBackForwardNavigationGestures = true

        navigationHeader.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationHeader)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            navigationHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            webView.topAnchor.constraint(equalTo: navigationHeader.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        guard let url = URL(string: urlString) else {
            showWexloToast("This page is unavailable.")
            return
        }
        webView.load(URLRequest(url: url))
    }
}

private final class SettingsRowView: UIControl {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let disclosureView = UIImageView(image: UIImage(named: "wexlo_settings_chevron"))

    init(item: SettingsViewController.Item) {
        super.init(frame: .zero)
        configure(with: item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure(with item: SettingsViewController.Item) {
        iconView.image = UIImage(named: item.iconName)
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        titleLabel.text = item.title
        titleLabel.font = WexloTheme.font(size: 17, weight: .bold)
        titleLabel.textColor = item.isDestructive
            ? UIColor(red: 0.70, green: 0.22, blue: 0.24, alpha: 1)
            : WexloTheme.primaryText
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.text = item.subtitle
        subtitleLabel.font = WexloTheme.font(size: 14)
        subtitleLabel.textColor = item.isDestructive
            ? UIColor(red: 0.70, green: 0.22, blue: 0.24, alpha: 0.78)
            : WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 1
        subtitleLabel.isUserInteractionEnabled = false

        disclosureView.contentMode = .scaleAspectFit
        disclosureView.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.distribution = .fill
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        [iconView, disclosureView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        addSubview(textStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 37),
            iconView.heightAnchor.constraint(equalToConstant: 37),

            disclosureView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            disclosureView.centerYAnchor.constraint(equalTo: centerYAnchor),
            disclosureView.widthAnchor.constraint(equalToConstant: 17),
            disclosureView.heightAnchor.constraint(equalToConstant: 17),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: disclosureView.leadingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addTarget(self, action: #selector(didPressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(didPressUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        accessibilityLabel = item.title
        accessibilityValue = item.subtitle
        accessibilityTraits = .button
    }

    @objc private func didTap() {
        onTap?()
    }

    @objc private func didPressDown() {
        UIView.animate(withDuration: 0.12) { self.alpha = 0.65 }
    }

    @objc private func didPressUp() {
        UIView.animate(withDuration: 0.12) { self.alpha = 1 }
    }
}
