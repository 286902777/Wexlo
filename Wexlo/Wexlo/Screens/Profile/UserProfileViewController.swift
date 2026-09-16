import UIKit

final class UserProfileViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let userID: String
    private let sessionStore = WexloSessionStore.shared
    private let accountStore = WexloAccountStore.shared
    private let relationshipStore = WexloRelationshipStore.shared
    private var selectedTabIndex = 0
    private var isUpdatingRelationship = false

    private var seedUser: WexloSeedUser? {
        WexloLocalContentStore.shared.user(for: userID)
    }

    private var accountProfile: WexloUserProfile? {
        accountStore.profile(for: userID)
    }

    private var displayName: String {
        seedUser?.name ?? accountProfile?.nickname ?? "Wexlo member"
    }

    private var displayBio: String {
        let bio = accountProfile?.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return bio.isEmpty
            ? (seedUser?.bio ?? "Outdoor style community member.")
            : bio
    }

    private var handle: String {
        let value = displayName
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: ".")
        return "@\(value)"
    }

    private var currentAccountID: String? {
        guard case .authenticated(let accountID) = sessionStore.current else {
            return nil
        }
        return accountID
    }

    private var isCurrentUserProfile: Bool {
        currentAccountID == userID
    }

    private var visiblePosts: [WexloLocalPost] {
        let contentStore = WexloLocalContentStore.shared
        let posts: [WexloLocalPost]
        if selectedTabIndex == 0 {
            posts = contentStore.posts.filter { $0.authorID == userID }
        } else {
            let savedIDs = WexloSavedOutfitStore.shared.savedPostIDs(for: userID)
            posts = savedIDs.compactMap { contentStore.post(for: $0) }
        }

        guard let accountID = currentAccountID else { return posts }
        let blockedIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
        return posts.filter { !blockedIDs.contains($0.authorID) }
    }

    private var outfitItems: [ProfileOutfitItem] {
        let colors: [UIColor] = [
            UIColor(red: 0.35, green: 0.82, blue: 0.84, alpha: 1),
            UIColor(red: 0.05, green: 0.42, blue: 0.60, alpha: 1),
            UIColor(red: 0.78, green: 0.75, blue: 0.70, alpha: 1),
            UIColor(red: 0.62, green: 0.65, blue: 0.67, alpha: 1),
            UIColor(red: 0.92, green: 0.55, blue: 0.23, alpha: 1),
            UIColor(red: 0.37, green: 0.44, blue: 0.50, alpha: 1)
        ]
        let symbols = ["wind", "cloud.rain.fill", "tent.fill", "figure.hiking", "mountain.2.fill", "building.2.fill"]

        return visiblePosts.enumerated().map { index, post in
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

    init(userID: String = "henry") {
        self.userID = userID
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 12
        layout.sectionHeadersPinToVisibleBounds = false
        super.init(
            headerStyle: .titled(""),
            layout: layout
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            ProfileOutfitCell.self,
            forCellWithReuseIdentifier: ProfileOutfitCell.reuseIdentifier
        )
        collectionView.register(
            UserProfileSpacerCell.self,
            forCellWithReuseIdentifier: UserProfileSpacerCell.reuseIdentifier
        )
        collectionView.register(
            UserProfileEmptyCell.self,
            forCellWithReuseIdentifier: UserProfileEmptyCell.reuseIdentifier
        )
        collectionView.register(
            UserProfileHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: UserProfileHeaderView.reuseIdentifier
        )
        collectionView.register(
            UserProfileContentHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: UserProfileContentHeaderView.reuseIdentifier
        )

        configureNavigationHeader()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadProfile),
            name: .wexloRelationshipDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadProfile),
            name: .wexloProfileDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadProfile),
            name: .wexloSavedPostDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadProfile),
            name: .wexloPublishedPostDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidChange),
            name: .wexloSessionDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        reloadProfile()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if section == 0 { return 1 }
        return max(outfitItems.count, 1)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.section == 0 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: UserProfileSpacerCell.reuseIdentifier,
                for: indexPath
            )
        }

        guard !outfitItems.isEmpty else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserProfileEmptyCell.reuseIdentifier,
                for: indexPath
            ) as! UserProfileEmptyCell
            cell.configure(isSavedTab: selectedTabIndex == 1)
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
                withReuseIdentifier: UserProfileHeaderView.reuseIdentifier,
                for: indexPath
            ) as! UserProfileHeaderView
            header.configure(
                name: displayName,
                handle: handle,
                bio: displayBio,
                profile: accountProfile,
                seedUser: seedUser,
                outfitCount: WexloLocalContentStore.shared.posts.filter { $0.authorID == userID }.count,
                followingCount: relationshipStore.followingUserIDs(for: userID).count,
                followerCount: relationshipStore.followerUserIDs(for: userID).count,
                isFollowing: currentAccountID.map {
                    relationshipStore.isFollowing(userID, from: $0)
                } ?? false,
                showsActions: !isCurrentUserProfile,
                onFollow: { [weak self] in self?.toggleFollowing() },
                onMessage: { [weak self] in self?.openMessage() }
            )
            return header
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: UserProfileContentHeaderView.reuseIdentifier,
            for: indexPath
        ) as! UserProfileContentHeaderView
        header.configure(
            selectedIndex: selectedTabIndex,
            count: outfitItems.count,
            onSelect: { [weak self] index in self?.selectTab(index) }
        )
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
                height: UserProfileHeaderView.height(
                    for: collectionView.bounds.width,
                    bio: displayBio
                )
            )
        }
        return CGSize(width: collectionView.bounds.width, height: 134)
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
        if outfitItems.isEmpty {
            return CGSize(width: collectionView.bounds.width - 40, height: 136)
        }
        let availableWidth = collectionView.bounds.width - 52
        return CGSize(width: availableWidth / 2, height: 190)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 1, outfitItems.indices.contains(indexPath.item) else { return }
        guard let controller = OutfitDetailViewController(
            postID: outfitItems[indexPath.item].postID
        ) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func configureNavigationHeader() {
        guard !isCurrentUserProfile else {
            navigationHeader.setTrailingImageNames([], actions: [])
            return
        }
        navigationHeader.setTrailingImageNames(
            ["ellipsis"],
            actions: [{ [weak self] in self?.presentMoreMenu() }]
        )
    }

    private func selectTab(_ index: Int) {
        guard index != selectedTabIndex, (0...1).contains(index) else { return }
        selectedTabIndex = index
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    private func toggleFollowing() {
        guard !isCurrentUserProfile, !isUpdatingRelationship else { return }
        guard case .authenticated(let accountID) = sessionStore.current else {
            showWexloToast("Please sign in to follow users.")
            return
        }

        isUpdatingRelationship = true
        let nextValue = !relationshipStore.isFollowing(userID, from: accountID)
        let didUpdate = relationshipStore.setFollowing(
            nextValue,
            from: accountID,
            to: userID
        )
        isUpdatingRelationship = false
        guard didUpdate else {
            showWexloToast("Following could not be updated.")
            return
        }
        reloadProfile()
    }

    private func openMessage() {
        guard !isCurrentUserProfile else { return }
        ChatViewController.openIfAllowed(contactUserID: userID, from: self)
    }

    private func presentMoreMenu() {
        guard !isCurrentUserProfile,
              let targetUser = seedUser else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(ReportViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            self?.blockUser(targetUser)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover.sourceView = navigationHeader
                popover.sourceRect = navigationHeader.bounds
            } else if #available(iOS 26.0, *) {
                let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame
                popover.sourceView = view
                popover.sourceRect = CGRect(
                    x: safeAreaFrame.midX,
                    y: safeAreaFrame.maxY - 1,
                    width: 1,
                    height: 1
                )
                popover.permittedArrowDirections = []
            }
        }
        present(alert, animated: true)
    }

    private func blockUser(_ targetUser: WexloSeedUser) {
        guard !isCurrentUserProfile else { return }
        guard case .authenticated(let accountID) = sessionStore.current else {
            showWexloToast("Please sign in to block users.")
            return
        }
        guard WexloBlockStore.shared.blockUser(targetUser.id, for: accountID) else {
            showWexloToast("Unable to block this user.")
            return
        }

        let previousViewController = navigationController?.viewControllers.dropLast().last
        navigationController?.popViewController(animated: true)
        previousViewController?.showWexloToast("User blocked.")
    }

    @objc private func reloadProfile() {
        guard isViewLoaded else { return }
        configureNavigationHeader()
        collectionView.reloadData()
    }

    @objc private func sessionDidChange() {
        reloadProfile()
    }
}

private final class UserProfileHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "UserProfileHeaderView"

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let bioLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let messageButton = UIButton(type: .system)
    private let followBackground = GradientView()
    private let divider = UIView()
    private let statsStack = UIStackView()
    private var followAction: (() -> Void)?
    private var messageAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    static func height(for width: CGFloat, bio: String) -> CGFloat {
        let textWidth = max(width - 40, 1)
        let bioFont = WexloTheme.font(size: 18)
        let bioHeight = ceil(
            bio.boundingRect(
                with: CGSize(width: textWidth, height: 180),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: bioFont],
                context: nil
            ).height
        )
        return 24 + 92 + 20 + max(bioHeight, 22) + 22 + 52 + 34 + 1 + 88 + 20
    }

    func configure(
        name: String,
        handle: String,
        bio: String,
        profile: WexloUserProfile?,
        seedUser: WexloSeedUser?,
        outfitCount: Int,
        followingCount: Int,
        followerCount: Int,
        isFollowing: Bool,
        showsActions: Bool,
        onFollow: @escaping () -> Void,
        onMessage: @escaping () -> Void
    ) {
        nameLabel.text = name
        handleLabel.text = handle
        bioLabel.text = bio
        followAction = onFollow
        messageAction = onMessage
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.isHidden = !showsActions
        messageButton.isHidden = !showsActions
        followBackground.isHidden = !showsActions

        let avatarData = profile?.avatarData
        let avatarAssetName = profile?.avatarAssetName ?? seedUser?.avatarAssetName
        if let avatarData, let image = UIImage(data: avatarData) {
            avatarView.image = image
        } else {
            avatarView.image = avatarAssetName.flatMap { UIImage(named: $0) }
                ?? UIImage(named: "wexlo_profile_avatar")
        }

        statsStack.arrangedSubviews.forEach {
            statsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        [
            ("\(outfitCount)", "Outfits"),
            (formattedCount(followingCount), "Following"),
            (formattedCount(followerCount), "Followers")
        ].forEach { value, title in
            statsStack.addArrangedSubview(makeStat(value: value, title: title))
        }
    }

    private func configureView() {
        backgroundColor = WexloTheme.background

        avatarView.backgroundColor = WexloTheme.hairline
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 22

        nameLabel.textColor = WexloTheme.primaryText
        nameLabel.font = WexloTheme.font(size: 30, weight: .bold)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75

        handleLabel.textColor = WexloTheme.secondaryText
        handleLabel.font = WexloTheme.font(size: 18)

        bioLabel.textColor = WexloTheme.secondaryText
        bioLabel.font = WexloTheme.font(size: 18)
        bioLabel.numberOfLines = 0

        followButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        followButton.titleLabel?.font = WexloTheme.font(size: 18, weight: .bold)
        followButton.backgroundColor = .clear
        followButton.layer.cornerRadius = 26
        followButton.addTarget(self, action: #selector(didTapFollow), for: .touchUpInside)

        followBackground.colors = [WexloTheme.coral, WexloTheme.pink]
        followBackground.layer.cornerRadius = 26
        followBackground.clipsToBounds = true
        followBackground.isUserInteractionEnabled = false

        messageButton.setTitle("Message", for: .normal)
        messageButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        messageButton.titleLabel?.font = WexloTheme.font(size: 18, weight: .bold)
        messageButton.backgroundColor = WexloTheme.surface
        messageButton.layer.cornerRadius = 26
        messageButton.layer.borderWidth = 1.5
        messageButton.layer.borderColor = WexloTheme.hairline.cgColor
        messageButton.addTarget(self, action: #selector(didTapMessage), for: .touchUpInside)

        divider.backgroundColor = WexloTheme.hairline
        statsStack.axis = .horizontal
        statsStack.alignment = .fill
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8

        [avatarView, nameLabel, handleLabel, bioLabel, followBackground, followButton, messageButton, divider, statsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            avatarView.widthAnchor.constraint(equalToConstant: 92),
            avatarView.heightAnchor.constraint(equalToConstant: 92),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 12),
            nameLabel.heightAnchor.constraint(equalToConstant: 38),
            handleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            handleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            handleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            handleLabel.heightAnchor.constraint(equalToConstant: 26),

            bioLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 20),
            bioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            followBackground.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 22),
            followBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            followBackground.heightAnchor.constraint(equalToConstant: 52),
            followBackground.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.46),
            followButton.leadingAnchor.constraint(equalTo: followBackground.leadingAnchor),
            followButton.trailingAnchor.constraint(equalTo: followBackground.trailingAnchor),
            followButton.topAnchor.constraint(equalTo: followBackground.topAnchor),
            followButton.bottomAnchor.constraint(equalTo: followBackground.bottomAnchor),

            messageButton.leadingAnchor.constraint(equalTo: followBackground.trailingAnchor, constant: 12),
            messageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            messageButton.topAnchor.constraint(equalTo: followBackground.topAnchor),
            messageButton.bottomAnchor.constraint(equalTo: followBackground.bottomAnchor),

            divider.topAnchor.constraint(equalTo: followBackground.bottomAnchor, constant: 34),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1),
            statsStack.topAnchor.constraint(equalTo: divider.bottomAnchor),
            statsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statsStack.heightAnchor.constraint(equalToConstant: 88),
            statsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    private func makeStat(value: String, title: String) -> UIView {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = WexloTheme.primaryText
        valueLabel.font = WexloTheme.font(size: 25, weight: .bold)
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = WexloTheme.secondaryText
        titleLabel.font = WexloTheme.font(size: 16)
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 3
        return stack
    }

    private func formattedCount(_ count: Int) -> String {
        guard count >= 1_000 else { return "\(count)" }
        return String(format: "%.1fk", Double(count) / 1_000)
    }

    @objc private func didTapFollow() {
        followAction?()
    }

    @objc private func didTapMessage() {
        messageAction?()
    }
}

private final class UserProfileContentHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "UserProfileContentHeaderView"

    private let tabsStack = UIStackView()
    private let indicator = GradientView()
    private let sectionTitleLabel = UILabel()
    private let countLabel = UILabel()
    private var buttons: [UIButton] = []
    private var indicatorConstraints: [NSLayoutConstraint] = []
    private var onSelect: ((Int) -> Void)?
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(selectedIndex: Int, count: Int, onSelect: @escaping (Int) -> Void) {
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        countLabel.text = "\(count) looks"
        updateSelection()
    }

    private func configureView() {
        backgroundColor = WexloTheme.background
        tabsStack.axis = .horizontal
        tabsStack.alignment = .fill
        tabsStack.distribution = .fillEqually
        tabsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabsStack)

        ["Outfits", "Saved"].enumerated().forEach { index, title in
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: #selector(didTapTab(_:)), for: .touchUpInside)
            tabsStack.addArrangedSubview(button)
            buttons.append(button)
        }

        let tabDivider = UIView()
        tabDivider.backgroundColor = WexloTheme.hairline
        tabDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabDivider)

        indicator.colors = [WexloTheme.coral, WexloTheme.pink]
        indicator.layer.cornerRadius = 3
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        sectionTitleLabel.text = "Outfits"
        sectionTitleLabel.textColor = WexloTheme.primaryText
        sectionTitleLabel.font = WexloTheme.font(size: 27, weight: .bold)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sectionTitleLabel)

        countLabel.textColor = WexloTheme.secondaryText
        countLabel.font = WexloTheme.font(size: 16)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        indicatorConstraints = buttons.map {
            indicator.centerXAnchor.constraint(equalTo: $0.centerXAnchor)
        }
        NSLayoutConstraint.activate([
            tabsStack.topAnchor.constraint(equalTo: topAnchor),
            tabsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabsStack.heightAnchor.constraint(equalToConstant: 66),
            tabDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabDivider.topAnchor.constraint(equalTo: tabsStack.bottomAnchor),
            tabDivider.heightAnchor.constraint(equalToConstant: 1),
            indicator.bottomAnchor.constraint(equalTo: tabDivider.topAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 58),
            indicator.heightAnchor.constraint(equalToConstant: 4),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            sectionTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            countLabel.centerYAnchor.constraint(equalTo: sectionTitleLabel.centerYAnchor)
        ])
        updateSelection()
    }

    private func updateSelection() {
        guard buttons.count == indicatorConstraints.count else { return }
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(
                isSelected ? WexloTheme.primaryText : WexloTheme.secondaryText,
                for: .normal
            )
            button.titleLabel?.font = WexloTheme.font(
                size: 18,
                weight: isSelected ? .bold : .medium
            )
            indicatorConstraints[index].isActive = isSelected
        }
    }

    @objc private func didTapTab(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        updateSelection()
        onSelect?(sender.tag)
    }
}

private final class UserProfileSpacerCell: UICollectionViewCell {
    static let reuseIdentifier = "UserProfileSpacerCell"

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

private final class UserProfileEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = "UserProfileEmptyCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.surface
        contentView.layer.cornerRadius = 22
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        titleLabel.textColor = WexloTheme.secondaryText
        titleLabel.font = WexloTheme.font(size: 16)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(isSavedTab: Bool) {
        titleLabel.text = isSavedTab ? "No saved outfits yet." : "No outfits yet."
    }
}
