import UIKit

class WexloCollectionPageViewController: UIViewController {
    let navigationHeader: WexloNavigationHeader
    let collectionView: UICollectionView

    init(
        headerStyle: WexloNavigationHeader.Style = .brand,
        leadingSymbol: String? = nil,
        trailingSymbol: String? = nil,
        layout: UICollectionViewLayout = UICollectionViewFlowLayout()
    ) {
        navigationHeader = WexloNavigationHeader(
            style: headerStyle,
            leadingSymbol: leadingSymbol,
            trailingSymbol: trailingSymbol
        )
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        collectionView.backgroundColor = WexloTheme.background
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInset.bottom = 96
        collectionView.verticalScrollIndicatorInsets.bottom = 96

        navigationHeader.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationHeader)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            navigationHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: navigationHeader.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationHeader.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
