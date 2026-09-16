import UIKit

final class ThemeDetailViewController: WexloBlueprintPageViewController {
    init() {
        super.init(title: "Rainy Day", items: [
            WexloBlueprintItem("Rainy Day", "A field guide to staying light, dry, and ready for the next turn.", symbol: "cloud.rain.fill", style: .hero),
            WexloBlueprintItem("128 layered looks", "2.4k saves · 18 creators", symbol: "chart.bar.fill", style: .compact),
            WexloBlueprintItem("Light shell, warm core", "Henry · Gorpcore", symbol: "figure.walk", style: .card, route: "outfit:henry-rainy-day-city-layers"),
            WexloBlueprintItem("Rain-ready city layer", "Mia · City Outdoor", symbol: "umbrella.fill", style: .card, route: "outfit:mia-daily-city-cycling-outfit"),
            WexloBlueprintItem("Soft fleece commute", "Samuel · Techwear", symbol: "cloud.fill", style: .card, route: "outfit:samuel-weekend-camping-functional-layering")
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
