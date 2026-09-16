import UIKit

final class NotEnoughCoinsViewController: WexloDialogViewController {
    init() { super.init(title: "Not Enough Coins", message: "You do not have enough Coins to continue. Would you like to recharge now?", confirmTitle: "Confirm") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
