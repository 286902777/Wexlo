import UIKit

final class FollowingViewController: WexloPeopleListViewController {
    init() {
        super.init(kind: .following)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
