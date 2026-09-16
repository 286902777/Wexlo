import UIKit

final class MessagesViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    fileprivate struct MessagePreview {
        let name: String
        let preview: String
        let timestamp: String
        let avatarAssetName: String
        let hasUnreadIndicator: Bool
        let route: String
    }

    private var directMessages: [MessagePreview] {
        guard case .authenticated(let userID) = WexloSessionStore.shared.current else {
            return []
        }
        return WexloChatStore.shared.conversationPreviews(for: userID).compactMap { conversation in
            guard let user = WexloLocalContentStore.shared.user(for: conversation.contactID) else {
                return nil
            }
            return MessagePreview(
                name: user.name,
                preview: WexloChatStore.shared.previewText(for: conversation.latestMessage),
                timestamp: WexloChatStore.shared.relativeTimestamp(for: conversation.latestMessage.timestamp),
                avatarAssetName: user.avatarAssetName,
                hasUnreadIndicator: conversation.isUnread,
                route: user.id
            )
        }
    }
    private var notifications: [MessagePreview] = []

    private var selectedTabIndex = 0

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.sectionHeadersPinToVisibleBounds = false
        super.init(headerStyle: .brand, layout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MessagesCell.self,
            forCellWithReuseIdentifier: MessagesCell.reuseIdentifier
        )
        collectionView.register(
            MessagesOverviewHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MessagesOverviewHeaderView.reuseIdentifier
        )
        collectionView.register(
            MessagesTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MessagesTabsHeaderView.reuseIdentifier
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadMessages),
            name: .wexloChatDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadMessages),
            name: .wexloRelationshipDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        collectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 1 ? currentMessages.count : 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessagesCell.reuseIdentifier,
            for: indexPath
        ) as? MessagesCell,
        currentMessages.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }
        cell.configure(with: currentMessages[indexPath.item])
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

        if indexPath.section == 0,
           let header = collectionView.dequeueReusableSupplementaryView(
               ofKind: kind,
               withReuseIdentifier: MessagesOverviewHeaderView.reuseIdentifier,
               for: indexPath
           ) as? MessagesOverviewHeaderView {
            header.onStartChatting = { [weak self] in
                self?.openAIStylist()
            }
            return header
        }

        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MessagesTabsHeaderView.reuseIdentifier,
            for: indexPath
        ) as? MessagesTabsHeaderView else {
            return UICollectionReusableView()
        }
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
                height: MessagesOverviewHeaderView.height(for: collectionView.bounds.width)
            )
        }
        return CGSize(width: collectionView.bounds.width, height: 76)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        section == 0
            ? .zero
            : UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width - 32, height: 92)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentMessages.indices.contains(indexPath.item) else { return }
        ChatViewController.openIfAllowed(
            contactUserID: currentMessages[indexPath.item].route,
            from: self
        )
    }

    private var currentMessages: [MessagePreview] {
        selectedTabIndex == 0 ? directMessages : notifications
    }

    private func selectTab(_ index: Int) {
        guard index != selectedTabIndex, (0...1).contains(index) else { return }
        selectedTabIndex = index
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    private func openAIStylist() {
        navigationController?.pushViewController(AIStylistViewController(), animated: true)
    }

    @objc private func reloadMessages() {
        guard isViewLoaded else { return }
        collectionView.reloadData()
    }
}

final class MessagesOverviewHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "MessagesOverviewHeaderView"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let heroImageView = UIImageView(image: UIImage(named: "wexlo_home_ai_stylist"))

    var onStartChatting: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    static func height(for width: CGFloat) -> CGFloat {
        let heroWidth = max(width - 32, 1)
        let heroHeight = heroWidth * 755 / 1124
        return 16 + 50 + 4 + 24 + 20 + heroHeight + 16
    }

    private func configure() {
        backgroundColor = WexloTheme.background

        titleLabel.text = "Messages"
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 42, weight: .bold)

        subtitleLabel.text = "Stay close to people who share your way outside."
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.font = WexloTheme.font(size: 18, weight: .regular)
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.78
        subtitleLabel.numberOfLines = 1

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = 28
        heroImageView.isUserInteractionEnabled = true
        heroImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapHero))
        )

        [titleLabel, subtitleLabel, heroImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 24),

            heroImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 755 / 1124),
            heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    @objc private func didTapHero() {
        onStartChatting?()
    }
}

final class MessagesTabsHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "MessagesTabsHeaderView"

    private let directMessagesButton = UIButton(type: .custom)
    private let notificationsButton = UIButton(type: .custom)
    private let underlineView = GradientView()
    private let separatorView = UIView()
    private var underlineLeadingConstraint: NSLayoutConstraint?
    private var underlineWidthConstraint: NSLayoutConstraint?

    var onSelect: ((Int) -> Void)?
    var selectedIndex = 0 {
        didSet {
            updateSelection()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = WexloTheme.background
        separatorView.backgroundColor = WexloTheme.hairline
        underlineView.layer.cornerRadius = 3
        underlineView.layer.masksToBounds = true

        configureButton(directMessagesButton, title: "Direct messages", tag: 0)
        configureButton(notificationsButton, title: "Notifications", tag: 1)

        [directMessagesButton, notificationsButton, underlineView, separatorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            directMessagesButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            directMessagesButton.topAnchor.constraint(equalTo: topAnchor),
            directMessagesButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            directMessagesButton.widthAnchor.constraint(equalToConstant: 172),

            notificationsButton.leadingAnchor.constraint(equalTo: directMessagesButton.trailingAnchor, constant: 6),
            notificationsButton.topAnchor.constraint(equalTo: topAnchor),
            notificationsButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            notificationsButton.widthAnchor.constraint(equalToConstant: 170),

            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        underlineWidthConstraint = underlineView.widthAnchor.constraint(equalToConstant: 96)
        guard let underlineLeadingConstraint, let underlineWidthConstraint else { return }
        NSLayoutConstraint.activate([
            underlineLeadingConstraint,
            underlineWidthConstraint,
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 6)
        ])
        updateSelection()
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 20, weight: .semibold)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
    }

    private func updateSelection() {
        directMessagesButton.setTitleColor(
            selectedIndex == 0 ? WexloTheme.primaryText : WexloTheme.secondaryText,
            for: .normal
        )
        notificationsButton.setTitleColor(
            selectedIndex == 1 ? WexloTheme.primaryText : WexloTheme.secondaryText,
            for: .normal
        )
        underlineLeadingConstraint?.constant = selectedIndex == 0 ? 16 : 196
        underlineWidthConstraint?.constant = selectedIndex == 0 ? 124 : 120
    }

    @objc private func didTapButton(_ sender: UIButton) {
        onSelect?(sender.tag)
    }
}

final class MessagesCell: UICollectionViewCell {
    static let reuseIdentifier = "MessagesCell"

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timestampLabel = UILabel()
    private let separatorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
    }

    fileprivate func configure(with message: MessagesViewController.MessagePreview) {
        avatarView.image = UIImage(named: message.avatarAssetName)
        nameLabel.text = message.name
        previewLabel.text = message.preview
        timestampLabel.text = message.timestamp
    }

    private func configure() {
        backgroundColor = WexloTheme.background
        contentView.backgroundColor = WexloTheme.background

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 30
        avatarView.layer.masksToBounds = true
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = UIColor.white.cgColor

        nameLabel.textColor = WexloTheme.primaryText
        nameLabel.font = WexloTheme.font(size: 20, weight: .bold)
        nameLabel.numberOfLines = 1

        previewLabel.textColor = WexloTheme.secondaryText
        previewLabel.font = WexloTheme.font(size: 17, weight: .regular)
        previewLabel.numberOfLines = 1
        previewLabel.adjustsFontSizeToFitWidth = true
        previewLabel.minimumScaleFactor = 0.75

        timestampLabel.textColor = WexloTheme.secondaryText
        timestampLabel.font = WexloTheme.font(size: 14, weight: .regular)
        timestampLabel.textAlignment = .right

        separatorView.backgroundColor = WexloTheme.hairline

        [avatarView, nameLabel, previewLabel, timestampLabel, separatorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -1),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),

            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            timestampLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestampLabel.leadingAnchor, constant: -10),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),

            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
