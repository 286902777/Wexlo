import UIKit

final class ProfileViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private var outfitItems: [ProfileOutfitItem] = []

    private func makeOutfitItems() -> [ProfileOutfitItem] {
        let colors: [UIColor] = [
            UIColor(red: 0.35, green: 0.82, blue: 0.84, alpha: 1),
            UIColor(red: 0.05, green: 0.42, blue: 0.60, alpha: 1),
            UIColor(red: 0.78, green: 0.75, blue: 0.70, alpha: 1),
            UIColor(red: 0.62, green: 0.65, blue: 0.67, alpha: 1),
            UIColor(red: 0.92, green: 0.55, blue: 0.23, alpha: 1),
            UIColor(red: 0.37, green: 0.44, blue: 0.50, alpha: 1)
        ]
        let symbols = ["wind", "cloud.rain.fill", "tent.fill", "figure.hiking", "mountain.2.fill", "building.2.fill"]
        let posts: [WexloLocalPost]
        if selectedTabIndex == 1 {
            guard isAuthenticated else {
                posts = []
                return []
            }
            let savedIDs = WexloSavedOutfitStore.shared.savedPostIDs(for: currentAccountID)
            posts = savedIDs.compactMap { WexloLocalContentStore.shared.post(for: $0) }
        } else {
            posts = WexloLocalContentStore.shared.posts.filter {
                $0.authorID == currentAccountID
            }
        }

        return posts.enumerated().map { index, post in
            ProfileOutfitItem(
                postID: post.id,
                title: post.title,
                mediaAssetName: post.mediaAssetName,
                mediaFileName: post.mediaFileName,
                mediaKind: post.mediaKind,
                mediaStorage: post.mediaStorage,
                backgroundColor: colors[index % colors.count],
                symbol: symbols[index % symbols.count]
            )
        }
    }

    private var selectedTabIndex = 0
    private let sessionStore = WexloSessionStore.shared
    private let coinStore = WexloCoinStore.shared
    private let accountStore = WexloAccountStore.shared
    private let relationshipStore = WexloRelationshipStore.shared

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 12
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
            ProfileOutfitCell.self,
            forCellWithReuseIdentifier: ProfileOutfitCell.reuseIdentifier
        )
        collectionView.register(
            ProfileSpacerCell.self,
            forCellWithReuseIdentifier: ProfileSpacerCell.reuseIdentifier
        )
        collectionView.register(
            ProfileHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileHeaderView.reuseIdentifier
        )
        collectionView.register(
            ProfileTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileTabsHeaderView.reuseIdentifier
        )
        reloadProfileContent()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(coinsDidChange(_:)),
            name: .wexloCoinsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savedPostDidChange(_:)),
            name: .wexloSavedPostDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(profileDidChange(_:)),
            name: .wexloProfileDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(relationshipDidChange(_:)),
            name: .wexloRelationshipDidChange,
            object: nil
        )

        navigationHeader.setTrailingImageNames(
            ["wexlo_profile_edit_button", "gearshape.fill"],
            actions: [
                { [weak self] in
                    self?.navigationController?.pushViewController(
                        EditProfileViewController(),
                        animated: true
                    )
                },
                { [weak self] in
                    self?.navigationController?.pushViewController(
                        SettingsViewController(),
                        animated: true
                    )
                }
            ]
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        reloadProfileContent()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? 1 : outfitItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProfileSpacerCell.reuseIdentifier,
                for: indexPath
            )
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProfileOutfitCell.reuseIdentifier,
            for: indexPath
        ) as! ProfileOutfitCell
        cell.configure(with: outfitItems[indexPath.item])
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
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ProfileHeaderView.reuseIdentifier,
                for: indexPath
            ) as! ProfileHeaderView
            header.onRecharge = { [weak self] in
                self?.navigationController?.pushViewController(
                    RechargeCoinsViewController(),
                    animated: true
                )
            }
            header.onFollowingTap = { [weak self] in
                self?.navigationController?.pushViewController(
                    FollowingViewController(),
                    animated: true
                )
            }
            header.onFollowersTap = { [weak self] in
                self?.navigationController?.pushViewController(
                    FollowersViewController(),
                    animated: true
                )
            }
            header.configure(
                balance: coinStore.balance(for: currentAccountID),
                profile: currentProfile,
                outfitCount: currentOutfitCount,
                followingCount: currentFollowingCount,
                followerCount: currentFollowerCount
            )
            return header
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ProfileTabsHeaderView.reuseIdentifier,
            for: indexPath
        ) as! ProfileTabsHeaderView
        header.selectedIndex = selectedTabIndex
        header.onSelect = { [weak self] index in
            self?.selectTab(index)
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
                height: ProfileHeaderView.height(for: collectionView.bounds.width)
            )
        }
        return CGSize(width: collectionView.bounds.width, height: 68)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        section == 0
            ? .zero
            : UIEdgeInsets(top: 18, left: 20, bottom: 20, right: 20)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: collectionView.bounds.width, height: 1)
        }

        let availableWidth = collectionView.bounds.width - 52
        return CGSize(width: availableWidth / 2, height: 190)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        guard let controller = OutfitDetailViewController(
            postID: outfitItems[indexPath.item].postID
        ) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func selectTab(_ index: Int) {
        guard (0...1).contains(index), index != selectedTabIndex else { return }
        selectedTabIndex = index
        reloadProfileContent()
    }

    private var currentAccountID: String {
        if case .authenticated(let userID) = sessionStore.current {
            return userID
        }
        return "guest"
    }

    private var currentProfile: WexloUserProfile? {
        if case .authenticated(let userID) = sessionStore.current {
            return accountStore.profile(for: userID)
        }
        return nil
    }

    private var isAuthenticated: Bool {
        if case .authenticated = sessionStore.current {
            return true
        }
        return false
    }

    private var currentOutfitCount: Int {
        guard isAuthenticated else { return 0 }
        return WexloLocalContentStore.shared.posts.filter {
            $0.authorID == currentAccountID
        }.count
    }

    private var currentFollowingCount: Int {
        guard isAuthenticated else { return 0 }
        return relationshipStore.followingUserIDs(for: currentAccountID).count
    }

    private var currentFollowerCount: Int {
        guard isAuthenticated else { return 0 }
        return relationshipStore.followerUserIDs(for: currentAccountID).count
    }

    private func refreshProfileHeader() {
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    private func reloadProfileContent() {
        outfitItems = makeOutfitItems()
        guard isViewLoaded else { return }
        collectionView.reloadData()
    }

    @objc private func coinsDidChange(_ notification: Notification) {
        guard let userID = notification.userInfo?["userID"] as? String,
              userID == currentAccountID else { return }
        refreshProfileHeader()
    }

    @objc private func savedPostDidChange(_ notification: Notification) {
        guard selectedTabIndex == 1,
              let userID = notification.userInfo?["userID"] as? String,
              userID == currentAccountID else { return }
        reloadProfileContent()
    }

    @objc private func profileDidChange(_ notification: Notification) {
        guard let userID = notification.object as? String,
              userID == currentAccountID else { return }
        refreshProfileHeader()
    }

    @objc private func relationshipDidChange(_ notification: Notification) {
        guard isAuthenticated else { return }
        refreshProfileHeader()
    }
}

private final class ProfileSpacerCell: UICollectionViewCell {
    static let reuseIdentifier = "ProfileSpacerCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }
}
