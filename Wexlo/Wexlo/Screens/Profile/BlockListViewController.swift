import UIKit

final class BlockListViewController: WexloPeopleListViewController {
    init() {
        super.init(kind: .blockList)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
