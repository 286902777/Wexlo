import UIKit

@MainActor
final class AppRootRouter: NSObject {
    private let window: UIWindow
    private let sessionStore = WexloSessionStore.shared
    private let accountStore = WexloAccountStore.shared

    init(window: UIWindow) {
        self.window = window
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidChange(_:)),
            name: .wexloSessionDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(signInRequested),
            name: .wexloSignInRequested,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        accountStore.seedInitialAccountsIfNeeded()
        WexloRelationshipStore.shared.seedInitialRelationshipsIfNeeded()
        WexloChatStore.shared.seedInitialChatsIfNeeded()
        WexloCommentStore.shared.seedInitialCommentsIfNeeded()
        let splash = SplashViewController()
        splash.onFinished = { [weak self] in self?.routeFromSession() }
        replaceRoot(with: splash, animated: false)
    }

    private func routeFromSession() {
        switch sessionStore.current {
        case .absent:
            showAuthorization(animated: true)
        case .guest, .authenticated:
            showMainInterface(animated: true)
        }
    }

    func showMainInterface(animated: Bool) {
        replaceRoot(with: WexloTabBarController(), animated: animated)
    }

    func showAuthorization(animated: Bool) {
        let authorization = AuthorizationViewController()
        let navigation = WexloNavigationController(rootViewController: authorization)

        authorization.onGuest = { [weak self] in
            self?.sessionStore.enterGuestSession()
        }
        authorization.onSignIn = { [weak self, weak navigation] in
            let controller = SignInViewController()
            controller.onAuthenticated = { userID in
                self?.handleAuthenticatedUser(
                    userID,
                    in: navigation,
                    successMessage: "Signed in successfully."
                )
            }
            controller.onForgotPassword = {
                navigation?.pushViewController(ForgotPasswordViewController(), animated: true)
            }
            navigation?.pushViewController(controller, animated: true)
        }
        authorization.onSignUp = { [weak self, weak navigation] in
            let controller = SignUpViewController()
            controller.onRegistrationReady = { email, password in
                self?.pushProfileCompletion(
                    for: email,
                    password: password,
                    in: navigation,
                    toastMessage: nil
                )
            }
            navigation?.pushViewController(controller, animated: true)
        }

        replaceRoot(with: navigation, animated: animated)
        guard !sessionStore.hasAcceptedEULA else { return }
        DispatchQueue.main.async { [weak self, weak authorization] in
            let eula = EULAViewController()
            eula.onAgree = {
                self?.sessionStore.acceptEULA()
                authorization?.markEULAAccepted()
                authorization?.dismiss(animated: true)
            }
            authorization?.present(eula, animated: true)
        }
    }

    private func handleAuthenticatedUser(
        _ userID: String,
        in navigation: UINavigationController?,
        successMessage: String
    ) {
        guard accountStore.profile(for: userID) != nil else {
            pushProfileCompletion(
                for: userID,
                in: navigation,
                toastMessage: successMessage
            )
            return
        }
        sessionStore.saveAuthenticatedSession(
            userID: userID,
            toastMessage: successMessage
        )
    }

    private func pushProfileCompletion(
        for userID: String,
        in navigation: UINavigationController?,
        toastMessage: String? = nil
    ) {
        let profile = CompleteProfileViewController(userID: userID)
        profile.onProfileSaved = { [weak self] in
            self?.sessionStore.saveAuthenticatedSession(
                userID: userID,
                toastMessage: "Profile saved successfully."
            )
        }
        navigation?.pushViewController(profile, animated: true)
        if let toastMessage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak profile] in
                profile?.showWexloToast(toastMessage)
            }
        }
    }

    private func pushProfileCompletion(
        for email: String,
        password: String,
        in navigation: UINavigationController?,
        toastMessage: String? = nil
    ) {
        let profile = CompleteProfileViewController(email: email, password: password)
        profile.onRegistrationSaved = { [weak self] userID in
            self?.sessionStore.saveAuthenticatedSession(
                userID: userID,
                toastMessage: "Account created successfully."
            )
        }
        navigation?.pushViewController(profile, animated: true)
        if let toastMessage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak profile] in
                profile?.showWexloToast(toastMessage)
            }
        }
    }

    @objc private func sessionDidChange(_ notification: Notification) {
        routeFromSession()
        guard let toastMessage = notification.userInfo?["toastMessage"] as? String else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.window.rootViewController?.showWexloToast(toastMessage)
        }
    }

    @objc private func signInRequested() {
        guard case .guest = sessionStore.current else { return }
        showAuthorization(animated: true)
    }

    private func replaceRoot(with viewController: UIViewController, animated: Bool) {
        let updateRoot = {
            self.window.rootViewController = viewController
            self.window.makeKeyAndVisible()
        }

        guard animated, window.rootViewController != nil else {
            updateRoot()
            return
        }

        UIView.transition(
            with: window,
            duration: 0.28,
            options: [.transitionCrossDissolve, .allowAnimatedContent],
            animations: updateRoot
        )
    }
}
