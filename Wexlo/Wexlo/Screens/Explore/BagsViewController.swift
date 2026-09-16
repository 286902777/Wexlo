import UIKit

final class BagsViewController: CategoryViewController {
    init() { super.init(title: "Bags", subtitle: "Thoughtful carry for daily use and weekend life.", symbol: "backpack.fill") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
