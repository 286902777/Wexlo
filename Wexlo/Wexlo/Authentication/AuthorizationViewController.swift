import UIKit

final class AuthorizationViewController: UIViewController, UITextViewDelegate {
    var onGuest: (() -> Void)?
    var onSignIn: (() -> Void)?
    var onSignUp: (() -> Void)?

    private let backgroundImageView = UIImageView(image: UIImage(named: "cs"))

    private let guestBackground = GradientView()
    private let signInBackground = GradientView()
    private let guestButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)

    private let consentButton = UIButton(type: .custom)
    private let consentIconView = UIImageView()
    private let consentLabel = UITextView()
    private var consentGranted = false
    private let sessionStore = WexloSessionStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureButtons()
        configureConsent()
        configureLayout()
    }

    private func configureBackground() {
        view.backgroundColor = WexloTheme.background
        view.clipsToBounds = true

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
    }

    private func configureButtons() {
        guestBackground.colors = [
            UIColor(red: 1.0, green: 0.62, blue: 0.39, alpha: 1),
            UIColor(red: 0.88, green: 0.44, blue: 0.69, alpha: 1)
        ]
        signInBackground.colors = guestBackground.colors

        [guestBackground, signInBackground].forEach {
            $0.layer.cornerRadius = 24
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.16
            $0.layer.shadowOffset = CGSize(width: 0, height: 8)
            $0.layer.shadowRadius = 12
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        configureButton(guestButton, title: "I'm New", action: #selector(didTapGuest))
        configureButton(signInButton, title: "Sign In By Email", action: #selector(didTapSignIn))

        let signUpText = NSMutableAttributedString(
            string: "Don't have an account? ",
            attributes: [
                .font: WexloTheme.font(size: 16, weight: .semibold),
                .foregroundColor: WexloTheme.primaryText
            ]
        )
        signUpText.append(
            NSAttributedString(
                string: "Sign up",
                attributes: [
                    .font: WexloTheme.font(size: 16, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.83, green: 0.02, blue: 0.50, alpha: 1),
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
        )
        signUpButton.setAttributedTitle(signUpText, for: .normal)
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
        signUpButton.accessibilityLabel = "Sign up"

        [guestButton, signInButton, signUpButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(WexloTheme.primaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 20, weight: .bold)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureConsent() {
        consentGranted = sessionStore.hasAcceptedEULA
        consentButton.backgroundColor = .clear
        consentButton.addTarget(self, action: #selector(didTapConsent), for: .touchUpInside)
        consentButton.accessibilityLabel = "Consent checkbox"
        consentButton.accessibilityTraits = .button

        consentIconView.contentMode = .scaleAspectFit
        consentIconView.isUserInteractionEnabled = false
        consentLabel.delegate = self
        consentLabel.backgroundColor = .clear
        consentLabel.isEditable = false
        consentLabel.isSelectable = true
        consentLabel.isScrollEnabled = false
        consentLabel.textContainerInset = .zero
        consentLabel.textContainer.lineFragmentPadding = 0
        consentLabel.linkTextAttributes = [
            .foregroundColor: UIColor(red: 0.83, green: 0.02, blue: 0.50, alpha: 1),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let consentText = NSMutableAttributedString(
            string: "By continuing you agree to our ",
            attributes: [
                .font: WexloTheme.font(size: 13, weight: .medium),
                .foregroundColor: WexloTheme.primaryText
            ]
        )
        consentText.append(
            NSAttributedString(
                string: "Terms of Service",
                attributes: [
                    .font: WexloTheme.font(size: 13, weight: .medium),
                    .foregroundColor: UIColor(red: 0.83, green: 0.02, blue: 0.50, alpha: 1),
                    .link: URL(string: "wexlo://terms")!
                ]
            )
        )
        consentText.append(
            NSAttributedString(
                string: " and ",
                attributes: [
                    .font: WexloTheme.font(size: 13, weight: .medium),
                    .foregroundColor: WexloTheme.primaryText
                ]
            )
        )
        consentText.append(
            NSAttributedString(
                string: "Privacy Policy",
                attributes: [
                    .font: WexloTheme.font(size: 13, weight: .medium),
                    .foregroundColor: UIColor(red: 0.83, green: 0.02, blue: 0.50, alpha: 1),
                    .link: URL(string: "wexlo://privacy")!
                ]
            )
        )
        consentLabel.attributedText = consentText
        consentLabel.textAlignment = .center

        [consentButton, consentIconView, consentLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        updateConsentPresentation()
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            guestBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            guestBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            guestBackground.heightAnchor.constraint(equalToConstant: 44),
            guestBackground.bottomAnchor.constraint(equalTo: signInBackground.topAnchor, constant: -20),
            signInBackground.leadingAnchor.constraint(equalTo: guestBackground.leadingAnchor),
            signInBackground.trailingAnchor.constraint(equalTo: guestBackground.trailingAnchor),
            signInBackground.heightAnchor.constraint(equalTo: guestBackground.heightAnchor),
            signInBackground.bottomAnchor.constraint(equalTo: signUpButton.topAnchor, constant: -11),

            guestButton.leadingAnchor.constraint(equalTo: guestBackground.leadingAnchor),
            guestButton.trailingAnchor.constraint(equalTo: guestBackground.trailingAnchor),
            guestButton.topAnchor.constraint(equalTo: guestBackground.topAnchor),
            guestButton.bottomAnchor.constraint(equalTo: guestBackground.bottomAnchor),
            signInButton.leadingAnchor.constraint(equalTo: signInBackground.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: signInBackground.trailingAnchor),
            signInButton.topAnchor.constraint(equalTo: signInBackground.topAnchor),
            signInButton.bottomAnchor.constraint(equalTo: signInBackground.bottomAnchor),

            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            signUpButton.heightAnchor.constraint(equalToConstant: 32),
            signUpButton.bottomAnchor.constraint(equalTo: consentButton.topAnchor),

            consentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            consentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            consentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            consentButton.heightAnchor.constraint(equalToConstant: 36),
            consentIconView.leadingAnchor.constraint(equalTo: consentButton.leadingAnchor, constant: 16),
            consentIconView.centerYAnchor.constraint(equalTo: consentButton.centerYAnchor),
            consentIconView.widthAnchor.constraint(equalToConstant: 10),
            consentIconView.heightAnchor.constraint(equalToConstant: 10),
            consentLabel.leadingAnchor.constraint(equalTo: consentIconView.trailingAnchor, constant: 8),
            consentLabel.trailingAnchor.constraint(equalTo: consentButton.trailingAnchor),
            consentLabel.topAnchor.constraint(equalTo: consentButton.topAnchor),
            consentLabel.bottomAnchor.constraint(equalTo: consentButton.bottomAnchor)
        ])
    }

    private func updateConsentPresentation() {
        let imageName = consentGranted
            ? "wexlo_authorization_consent_selected"
            : "wexlo_authorization_consent_unselected"
        consentIconView.image = UIImage(named: imageName)
        consentButton.accessibilityValue = consentGranted ? "Accepted" : "Not accepted"
    }

    private func canContinue() -> Bool {
        guard consentGranted else {
            showToast("Please accept the terms to continue.")
            return false
        }
        return true
    }

    private func showToast(_ message: String) {
        showWexloToast(message)
    }

    @objc private func didTapConsent() {
        consentGranted.toggle()
        updateConsentPresentation()
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        switch URL.absoluteString {
        case "wexlo://terms":
            navigationController?.pushViewController(
                LegalWebViewController(
                    title: "Terms of Service",
                    urlString: "https://sites.google.com/view/wexlo/users"
                ),
                animated: true
            )
        case "wexlo://privacy":
            navigationController?.pushViewController(
                LegalWebViewController(
                    title: "Privacy Policy",
                    urlString: "https://sites.google.com/view/wexlo/privacy"
                ),
                animated: true
            )
        default:
            break
        }
        return false
    }

    func markEULAAccepted() {
        consentGranted = true
        updateConsentPresentation()
    }

    @objc private func didTapGuest() {
        if canContinue() {
            onGuest?()
        }
    }

    @objc private func didTapSignIn() {
        if canContinue() {
            onSignIn?()
        }
    }

    @objc private func didTapSignUp() {
        if canContinue() {
            onSignUp?()
        }
    }
}
