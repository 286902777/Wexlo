import UIKit

final class SignOutViewController: WexloDialogViewController {
    init() { super.init(title: "Sign Out", message: "Are you sure you want to sign out of your account?", confirmTitle: "Sure") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
