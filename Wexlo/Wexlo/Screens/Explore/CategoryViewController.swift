import UIKit

class CategoryViewController: WexloBlueprintPageViewController {
    init(title: String, subtitle: String, symbol: String) {
        super.init(title: title, items: [
            WexloBlueprintItem(title, subtitle, symbol: symbol, style: .hero),
            WexloBlueprintItem("Light Shell / Fleece / Trail Shoes", "Henry · Gorpcore · Commute", symbol: "figure.walk", style: .card, route: "outfit:henry-rainy-day-city-layers"),
            WexloBlueprintItem("Soft Fleece for Weekend Camp", "Samuel · Techwear · Camping", symbol: "tent.fill", style: .card, route: "outfit:samuel-weekend-camping-functional-layering")
        ], trailingSymbol: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        onRoute = { [weak self] route in
            guard let self,
                  let postID = route.split(separator: ":", maxSplits: 1).last,
                  let controller = OutfitDetailViewController(postID: String(postID)) else {
                self?.showWexloToast("This outfit is unavailable.")
                return
            }
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}
