import UIKit

final class HomeViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private static let fallbackCellReuseIdentifier = "HomeFallbackCell"
    private static let feedHorizontalInset: CGFloat = 16

    private var feedItemsByTab: [[HomeFeedItem]]

    private var selectedTabIndex = 0
    private let feedTabTitles = ["For you", "Trending", "Following"]
    private let loadingOverlay = WexloLoadingOverlay()
    private var isSaving = false

    init() {
        feedItemsByTab = Self.makeFeedItems()
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.sectionHeadersPinToVisibleBounds = true
        super.init(headerStyle: .brand, layout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            HomeFeedCell.self,
            forCellWithReuseIdentifier: HomeFeedCell.reuseIdentifier
        )
        collectionView.register(
            HomeSectionTitleCell.self,
            forCellWithReuseIdentifier: HomeSectionTitleCell.reuseIdentifier
        )
        collectionView.register(
            HomeDiscoveryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeDiscoveryHeaderView.reuseIdentifier
        )
        collectionView.register(
            HomeTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeTabsHeaderView.reuseIdentifier
        )
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: Self.fallbackCellReuseIdentifier
        )

        guard WexloStartupState.shared.claimInitialHomeLoad() else { return }
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            collectionView.reloadData()
            loadingOverlay.hide()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        feedItemsByTab = Self.makeFeedItems()
        collectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 1 else { return 0 }
        guard feedItemsByTab.indices.contains(selectedTabIndex) else { return 1 }
        return 1 + feedItemsByTab[selectedTabIndex].count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard indexPath.section == 1 else {
            return fallbackCell(in: collectionView, at: indexPath)
        }

        if indexPath.item == 0 {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeSectionTitleCell.reuseIdentifier,
                for: indexPath
            ) as? HomeSectionTitleCell else {
                return fallbackCell(in: collectionView, at: indexPath)
            }
            let title = feedTabTitles.indices.contains(selectedTabIndex)
                ? feedTabTitles[selectedTabIndex]
                : feedTabTitles[0]
            let count = feedItemsByTab.indices.contains(selectedTabIndex)
                ? "\(feedItemsByTab[selectedTabIndex].count) looks"
                : "0 looks"
            cell.configure(title: title, count: count)
            return cell
        }

        guard feedItemsByTab.indices.contains(selectedTabIndex) else {
            return fallbackCell(in: collectionView, at: indexPath)
        }
        let itemIndex = indexPath.item - 1
        guard feedItemsByTab[selectedTabIndex].indices.contains(itemIndex) else {
            return fallbackCell(in: collectionView, at: indexPath)
        }
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeFeedCell.reuseIdentifier,
            for: indexPath
        ) as? HomeFeedCell else {
            return fallbackCell(in: collectionView, at: indexPath)
        }
        let item = feedItemsByTab[selectedTabIndex][itemIndex]
        cell.configure(with: item)
        cell.onSave = { [weak self] in
            self?.saveFeedItem()
        }
        cell.onBreakdown = { [weak self] in
            guard let self else { return }
            guard let postID = item.postID,
                  let controller = OutfitDetailViewController(
                    postID: postID,
                    scrollToBreakdown: true
                  ) else {
                showWexloToast("This outfit is unavailable.")
                return
            }
            navigationController?.pushViewController(controller, animated: true)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if indexPath.section == 0 {
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HomeDiscoveryHeaderView.reuseIdentifier,
                for: indexPath
            ) as? HomeDiscoveryHeaderView else {
                return UICollectionReusableView()
            }
            header.onSceneSelected = { [weak self] route in
                self?.routeToHomeDestination(route)
            }
            return header
        }

        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: HomeTabsHeaderView.reuseIdentifier,
            for: indexPath
        ) as? HomeTabsHeaderView else {
            return UICollectionReusableView()
        }
        header.selectedIndex = selectedTabIndex
        header.onSelect = { [weak self] index in
            self?.selectFeedTab(index)
        }
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if section == 0 {
            return CGSize(
                width: collectionView.bounds.width,
                height: HomeDiscoveryHeaderView.height(for: collectionView.bounds.width)
            )
        }
        return CGSize(width: collectionView.bounds.width, height: 72)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        section == 0
            ? .zero
            : UIEdgeInsets(
                top: 0,
                left: Self.feedHorizontalInset,
                bottom: 20,
                right: Self.feedHorizontalInset
            )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: collectionView.bounds.width, height: 1)
        }
        let width = collectionView.bounds.width - Self.feedHorizontalInset * 2
        return CGSize(
            width: width,
            height: indexPath.item == 0 ? 62 : HomeFeedCell.preferredHeight
        )
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 1,
              indexPath.item > 0,
              feedItemsByTab.indices.contains(selectedTabIndex),
              feedItemsByTab[selectedTabIndex].indices.contains(indexPath.item - 1) else {
            return
        }
        guard let postID = feedItemsByTab[selectedTabIndex][indexPath.item - 1].postID,
              let controller = OutfitDetailViewController(postID: postID) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func fallbackCell(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.fallbackCellReuseIdentifier,
            for: indexPath
        )
    }

    private func selectFeedTab(_ index: Int) {
        guard index != selectedTabIndex, feedItemsByTab.indices.contains(index) else { return }
        selectedTabIndex = index
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    private func saveFeedItem() {
        guard !isSaving else { return }
        isSaving = true
        loadingOverlay.show(in: view)
        completeWexloLoading(loadingOverlay) { [weak self] in
            guard let self else { return }
            isSaving = false
            showWexloToast("Saved to your looks.")
        }
    }

    private func routeToHomeDestination(_ route: String) {
        let controller: UIViewController
        switch route {
        case "ai":
            controller = AIStylistViewController()
        case "rainy":
            controller = RainyDayViewController()
        case "camping":
            controller = CampingViewController()
        case "travel":
            controller = TravelViewController()
        default:
            controller = CommuteViewController()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private static func makeFeedItems() -> [[HomeFeedItem]] {
        let blockedAuthorIDs: Set<String>
        if case .authenticated(let accountID) = WexloSessionStore.shared.current {
            blockedAuthorIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
        } else {
            blockedAuthorIDs = []
        }
        return (0..<3).map {
            WexloLocalContentStore.shared.homeFeedItems(
                for: $0,
                excludingAuthorIDs: blockedAuthorIDs
            )
        }
    }
}
