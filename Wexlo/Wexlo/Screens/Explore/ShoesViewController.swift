import UIKit

final class ShoesViewController: CategoryViewController {
    init() { super.init(title: "Shoes", subtitle: "Outdoor-ready shoes for city streets, trails, and weekends.", symbol: "shoe.fill") }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
