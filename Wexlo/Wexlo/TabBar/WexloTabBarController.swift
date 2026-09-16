import UIKit

final class WexloTabBarController: UITabBarController, FloatingTabBarDelegate {
    private let floatingTabBar = FloatingTabBar()
    private let guestInteractionShield = WexloGuestInteractionShieldView()
    private var bottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSystemTabBar()
        configureViewControllers()
        configureFloatingTabBar()
        configureGuestInteractionShield()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hideSystemTabBarWithoutAnimation()
    }

    func floatingTabBar(_ tabBar: FloatingTabBar, didSelect index: Int) {
        guard !isGuestSession else {
            tabBar.selectedIndex = selectedIndex
            presentWexloSignInRequired()
            return
        }
        tabBar.selectedIndex = index
        selectedIndex = index
    }

    func setFloatingTabBarHidden(_ hidden: Bool, animated: Bool) {
        bottomConstraint?.constant = hidden ? 92 : 0
        let updates = {
            self.floatingTabBar.alpha = hidden ? 0 : 1
            self.view.layoutIfNeeded()
        }
        animated ? UIView.animate(withDuration: 0.24, animations: updates) : updates()
    }

    private func configureSystemTabBar() {
        if #available(iOS 18.0, *) {
            setTabBarHidden(true, animated: false)
        } else {
            tabBar.isHidden = true
        }
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior = .never
        }
    }

    private func hideSystemTabBarWithoutAnimation() {
        if #available(iOS 18.0, *) {
            setTabBarHidden(true, animated: false)
        } else {
            tabBar.isHidden = true
        }
    }

    private func configureViewControllers() {
        viewControllers = [
            WexloNavigationController(rootViewController: HomeViewController()),
            WexloNavigationController(rootViewController: ExploreViewController()),
            WexloNavigationController(rootViewController: PublishViewController()),
            WexloNavigationController(rootViewController: MessagesViewController()),
            WexloNavigationController(rootViewController: ProfileViewController())
        ]
    }

    private func configureFloatingTabBar() {
        floatingTabBar.delegate = self
        floatingTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatingTabBar)
        bottomConstraint = floatingTabBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: 0
        )
        guard let bottomConstraint else { return }
        NSLayoutConstraint.activate([
            floatingTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            floatingTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            floatingTabBar.heightAnchor.constraint(equalToConstant: 66),
            bottomConstraint
        ])
    }

    private func configureGuestInteractionShield() {
        guestInteractionShield.presenter = self
        guestInteractionShield.underlyingViews = viewControllers?.compactMap(\.view) ?? []
        guestInteractionShield.translatesAutoresizingMaskIntoConstraints = false
        guestInteractionShield.isHidden = !isGuestSession
        view.insertSubview(guestInteractionShield, belowSubview: floatingTabBar)

        NSLayoutConstraint.activate([
            guestInteractionShield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            guestInteractionShield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            guestInteractionShield.topAnchor.constraint(equalTo: view.topAnchor),
            guestInteractionShield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private var isGuestSession: Bool {
        if case .guest = WexloSessionStore.shared.current {
            return true
        }
        return false
    }
}
