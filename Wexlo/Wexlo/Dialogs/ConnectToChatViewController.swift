import UIKit

final class ConnectToChatViewController: WexloDialogViewController {
    init() { super.init(title: "Connect to Chat", message: "Follow each other to unlock messages.", confirmTitle: "OK", showsCancel: false) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
