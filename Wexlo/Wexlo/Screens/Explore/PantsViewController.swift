import UIKit

final class PantsViewController: CategoryViewController {
    init() { super.init(title: "Pants", subtitle: "All-weather pants for trails and city movement.", symbol: "figure.walk") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
