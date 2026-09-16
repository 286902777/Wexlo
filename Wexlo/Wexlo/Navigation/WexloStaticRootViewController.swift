import UIKit

class WexloStaticRootViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let items: [WexloRootContentItem]
    var onRoute: ((String) -> Void)?

    init(items: [WexloRootContentItem], trailingSymbol: String? = nil) {
        self.items = items
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 18, left: 20, bottom: 20, right: 20)
        super.init(headerStyle: .brand, trailingSymbol: trailingSymbol, layout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            WexloRootContentCell.self,
            forCellWithReuseIdentifier: WexloRootContentCell.reuseIdentifier
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WexloRootContentCell.reuseIdentifier,
            for: indexPath
        ) as! WexloRootContentCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width - 40
        return CGSize(width: width, height: indexPath.item == 0 ? 130 : 84)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let route = items[indexPath.item].route else { return }
        onRoute?(route)
    }
}
