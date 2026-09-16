import UIKit

final class FollowersViewController: WexloPeopleListViewController {
    init() {
        super.init(kind: .followers)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
