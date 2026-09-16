import UIKit

final class SignInRequiredViewController: WexloDialogViewController {
    init() { super.init(title: "Sign In Required", message: "To ensure the normal operation of this function, please sign in to your account first.", confirmTitle: "Sign in") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
