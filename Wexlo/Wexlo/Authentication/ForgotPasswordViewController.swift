import UIKit

final class ForgotPasswordViewController: WexloAuthPageViewController {
    init() {
        super.init(title: "Forgot your password?", subtitle: "Set a new password to get back to your Wexlo account.", submitTitle: "Save", fields: [
            WexloAuthField(title: "Email", placeholder: "you@example.com", isSecure: false),
            WexloAuthField(title: "Password", placeholder: "Create a new password", isSecure: true),
            WexloAuthField(title: "Confirm new password", placeholder: "Repeat your new password", isSecure: true)
        ])
        onValidate = { values in
            guard values[0].contains("@") else { return "Enter a valid email address." }
            guard values[1].count >= 6 else { return "Password must contain at least 6 characters." }
            guard values[1] == values[2] else { return "Passwords do not match." }
            return nil
        }
        onSubmit = { [weak self] values in
            guard let self else { return }
            do {
                try WexloAccountStore.shared.resetPassword(
                    email: values[0],
                    password: values[1]
                )
                finishSubmission { [weak self] in
                    guard let self else { return }
                    let destination = navigationController?.viewControllers.dropLast().last
                    navigationController?.popViewController(animated: true)
                    DispatchQueue.main.async {
                        destination?.showWexloToast("Password updated successfully.")
                    }
                }
            } catch let error as WexloAccountError {
                failSubmission(error.userMessage)
            } catch {
                failSubmission("Password reset failed. Please try again.")
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
