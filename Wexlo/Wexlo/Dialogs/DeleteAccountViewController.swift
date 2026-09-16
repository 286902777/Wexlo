import UIKit

final class DeleteAccountViewController: WexloDialogViewController {
    init() { super.init(title: "Delete Account", message: "This permanently deletes your account and all associated data. This action cannot be recovered.", confirmTitle: "Delete") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
