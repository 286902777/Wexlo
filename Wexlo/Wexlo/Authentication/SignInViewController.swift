import UIKit

final class SignInViewController: WexloAuthPageViewController {
    var onAuthenticated: ((String) -> Void)?
    var onForgotPassword: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAuxiliaryAction(title: "Forgot password?") { [weak self] in
            self?.onForgotPassword?()
        }
    }

    init() {
        super.init(title: "Welcome back", subtitle: "Log in to keep exploring outdoor style on Wexlo.", submitTitle: "Sign in", fields: [
            WexloAuthField(title: "Email", placeholder: "you@example.com", isSecure: false),
            WexloAuthField(title: "Password", placeholder: "Enter your password", isSecure: true)
        ])
        onValidate = { values in
            guard values[0].contains("@") else { return "Enter a valid email address." }
            return nil
        }
        onSubmit = { [weak self] values in
            guard let self else { return }
            do {
                let userID = try WexloAccountStore.shared.authenticate(
                    email: values[0],
                    password: values[1]
                )
                finishSubmission { [weak self] in
                    self?.onAuthenticated?(userID)
                }
            } catch let error as WexloAccountError {
                failSubmission(error.userMessage)
            } catch {
                failSubmission("Sign in failed. Please try again.")
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
