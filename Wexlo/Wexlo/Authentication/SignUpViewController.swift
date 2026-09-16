import UIKit

final class SignUpViewController: WexloAuthPageViewController {
    var onRegistrationReady: ((String, String) -> Void)?

    init() {
        super.init(title: "Join Wexlo", subtitle: "Create your account and start sharing the way you move through the world.", submitTitle: "Sign up", fields: [
            WexloAuthField(title: "Email", placeholder: "you@example.com", isSecure: false),
            WexloAuthField(title: "Password", placeholder: "Create a password", isSecure: true),
            WexloAuthField(title: "Confirm password", placeholder: "Repeat your password", isSecure: true)
        ])
        onValidate = { values in
            guard values[0].contains("@") else { return "Enter a valid email address." }
            guard values[1].count >= 6 else { return "Password must contain at least 6 characters." }
            guard values[1] == values[2] else { return "Passwords do not match." }
            return nil
        }
        onSubmit = { [weak self] values in
            guard let self else { return }
            finishSubmission { [weak self] in
                self?.onRegistrationReady?(values[0], values[1])
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
