import UIKit

final class UnlockOutfitViewController: WexloDialogViewController {
    init() { super.init(title: "Unlock Outfit Breakdown", message: "Use 300 Coins to unlock this outfit breakdown.", confirmTitle: "Confirm") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
