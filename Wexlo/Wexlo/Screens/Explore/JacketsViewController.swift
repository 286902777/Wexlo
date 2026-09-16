import UIKit

private struct JacketsLook {
    let postID: String
    let title: String
    let author: String
    let styleTag: String
    let context: String
    let imageName: String
    let mediaFileName: String
    let mediaKind: WexloMediaKind
    let mediaStorage: WexloMediaStorage
}

private struct JacketsCategoryConfiguration {
    let title: String
    let subtitle: String
    let badge: String
    let imageName: String
    let databaseCategory: String

    init(route: String) {
        switch route {
        case "pants":
            self.init(title: "Pants", subtitle: "Utility and trail fits", badge: "Shop the mood", imageName: "wexlo_explore_pants", databaseCategory: "Bottoms")
        case "shoes":
            self.init(title: "Shoes", subtitle: "Outdoor and trail shoes", badge: "Shop the mood", imageName: "wexlo_explore_shoes", databaseCategory: "Footwear")
        case "bags":
            self.init(title: "Bags", subtitle: "Daily and travel carry", badge: "Shop the mood", imageName: "wexlo_explore_bags", databaseCategory: "Equipment")
        case "fleece":
            self.init(title: "Fleece", subtitle: "Soft mid-layers", badge: "Shop the mood", imageName: "wexlo_explore_fleece", databaseCategory: "Tops")
        case "accessories":
            self.init(title: "Accessories", subtitle: "Caps, eyewear, extras", badge: "Shop the mood", imageName: "wexlo_explore_accessories", databaseCategory: "Accessories")
        default:
            self.init(title: "Jackets", subtitle: "Shells and light layers for changing weather.", badge: "Shop the mood", imageName: "wexlo_explore_jackets", databaseCategory: "Outerwear")
        }
    }

    init(title: String, subtitle: String, badge: String, imageName: String, databaseCategory: String) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.imageName = imageName
        self.databaseCategory = databaseCategory
    }
}

final class JacketsViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let configuration: JacketsCategoryConfiguration
    private var looks: [JacketsLook] = []

    init(route: String = "jackets") {
        configuration = JacketsCategoryConfiguration(route: route)
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        super.init(headerStyle: .titled(""), layout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(JacketsHeroCell.self, forCellWithReuseIdentifier: JacketsHeroCell.reuseIdentifier)
        collectionView.register(JacketsSectionHeaderCell.self, forCellWithReuseIdentifier: JacketsSectionHeaderCell.reuseIdentifier)
        collectionView.register(JacketsLookCell.self, forCellWithReuseIdentifier: JacketsLookCell.reuseIdentifier)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationHeader.backgroundColor = WexloTheme.background
        loadLooks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLooks()
    }

    private func loadLooks() {
        let store = WexloLocalContentStore.shared
        let blockedAuthorIDs: Set<String>
        if case .authenticated(let accountID) = WexloSessionStore.shared.current {
            blockedAuthorIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
        } else {
            blockedAuthorIDs = []
        }

        looks = store.posts.compactMap { post in
            guard post.category == configuration.databaseCategory,
                  !blockedAuthorIDs.contains(post.authorID) else { return nil }
            let author = store.user(for: post.authorID)?.name
                ?? post.authorName
                ?? "Creator"
            return JacketsLook(
                postID: post.id,
                title: post.title,
                author: author,
                styleTag: post.styleTag,
                context: post.setting,
                imageName: post.mediaAssetName ?? "wexlo_outfit_detail_cover",
                mediaFileName: post.mediaFileName,
                mediaKind: post.mediaKind,
                mediaStorage: post.mediaStorage
            )
        }
        collectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 2 ? looks.count : 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JacketsHeroCell.reuseIdentifier, for: indexPath) as! JacketsHeroCell
            cell.configure(with: configuration)
            return cell
        case 1:
            return collectionView.dequeueReusableCell(withReuseIdentifier: JacketsSectionHeaderCell.reuseIdentifier, for: indexPath)
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JacketsLookCell.reuseIdentifier, for: indexPath) as! JacketsLookCell
            let look = looks[indexPath.item]
            cell.configure(with: look)
            cell.onBreakdown = { [weak self] in self?.openDetails(for: look, scrollToBreakdown: true) }
            cell.onSave = { [weak self] in self?.showWexloToast("Saved to your looks.") }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 2, looks.indices.contains(indexPath.item) else { return }
        openDetails(for: looks[indexPath.item])
    }

    private func openDetails(for look: JacketsLook, scrollToBreakdown: Bool = false) {
        guard let controller = OutfitDetailViewController(
            postID: look.postID,
            scrollToBreakdown: scrollToBreakdown
        ) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return UIEdgeInsets(top: 26, left: 20, bottom: 26, right: 20)
        case 1: return UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)
        default: return UIEdgeInsets(top: 0, left: 20, bottom: 28, right: 20)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentWidth = collectionView.bounds.width - 40
        switch indexPath.section {
        case 0: return CGSize(width: contentWidth, height: 238)
        case 1: return CGSize(width: contentWidth, height: 40)
        default: return CGSize(width: contentWidth, height: 166)
        }
    }
}

private final class JacketsHeroCell: UICollectionViewCell {
    static let reuseIdentifier = "JacketsHeroCell"
    private let imageView = UIImageView()
    private let shadeView = UIView()
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 24
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        shadeView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        badgeLabel.font = WexloTheme.font(size: 14, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        badgeLabel.layer.cornerRadius = 20
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        titleLabel.font = WexloTheme.font(size: 34, weight: .bold)
        titleLabel.textColor = .white
        subtitleLabel.font = WexloTheme.font(size: 15)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 2
        [imageView, shadeView, badgeLabel, titleLabel, subtitleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shadeView.topAnchor.constraint(equalTo: contentView.topAnchor), shadeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), shadeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), shadeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), badgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40), badgeLabel.widthAnchor.constraint(equalToConstant: 134), badgeLabel.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), titleLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 16), titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor), subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -23)
        ])
    }

    func configure(with category: JacketsCategoryConfiguration) {
        imageView.image = UIImage(named: category.imageName)
        badgeLabel.text = category.badge
        titleLabel.text = category.title
        subtitleLabel.text = category.subtitle
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private final class JacketsSectionHeaderCell: UICollectionViewCell {
    static let reuseIdentifier = "JacketsSectionHeaderCell"
    private let titleLabel = UILabel()
    private let trailingLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Recommended looks"
        titleLabel.font = WexloTheme.font(size: 24, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        trailingLabel.text = "For you"
        trailingLabel.font = WexloTheme.font(size: 14)
        trailingLabel.textColor = WexloTheme.secondaryText
        trailingLabel.textAlignment = .right
        [titleLabel, trailingLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -8),
            trailingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), trailingLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private final class JacketsLookCell: UICollectionViewCell {
    static let reuseIdentifier = "JacketsLookCell"
    var onBreakdown: (() -> Void)?
    var onSave: (() -> Void)?
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let contextLabel = UILabel()
    private let breakdownBackground = GradientView()
    private let breakdownButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .custom)
    private var representedPostID: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        cardView.backgroundColor = WexloTheme.surface
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = WexloTheme.hairline.cgColor
        cardView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18
        titleLabel.font = WexloTheme.font(size: 16, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.numberOfLines = 2
        authorLabel.font = WexloTheme.font(size: 13)
        authorLabel.textColor = WexloTheme.secondaryText
        contextLabel.font = WexloTheme.font(size: 13)
        contextLabel.textColor = WexloTheme.secondaryText
        breakdownBackground.layer.cornerRadius = 18
        breakdownBackground.clipsToBounds = true
        breakdownButton.setTitle("Breakdown", for: .normal)
        breakdownButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        breakdownButton.titleLabel?.font = WexloTheme.font(size: 14, weight: .bold)
        breakdownButton.addTarget(self, action: #selector(didTapBreakdown), for: .touchUpInside)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        saveButton.titleLabel?.font = WexloTheme.font(size: 14, weight: .bold)
        saveButton.layer.cornerRadius = 18
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = WexloTheme.hairline.cgColor
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        [cardView, imageView, titleLabel, authorLabel, contextLabel, breakdownBackground, saveButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        breakdownButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(authorLabel)
        cardView.addSubview(contextLabel)
        cardView.addSubview(breakdownBackground)
        cardView.addSubview(saveButton)
        breakdownBackground.addSubview(breakdownButton)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor), cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12), imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12), imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12), imageView.widthAnchor.constraint(equalToConstant: 112),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12), titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 17), titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8), authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            contextLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), contextLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 5), contextLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            breakdownBackground.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), breakdownBackground.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18), breakdownBackground.widthAnchor.constraint(equalToConstant: 112), breakdownBackground.heightAnchor.constraint(equalToConstant: 42),
            breakdownButton.topAnchor.constraint(equalTo: breakdownBackground.topAnchor), breakdownButton.leadingAnchor.constraint(equalTo: breakdownBackground.leadingAnchor), breakdownButton.trailingAnchor.constraint(equalTo: breakdownBackground.trailingAnchor), breakdownButton.bottomAnchor.constraint(equalTo: breakdownBackground.bottomAnchor),
            saveButton.leadingAnchor.constraint(equalTo: breakdownBackground.trailingAnchor, constant: 10), saveButton.centerYAnchor.constraint(equalTo: breakdownBackground.centerYAnchor), saveButton.widthAnchor.constraint(equalToConstant: 76), saveButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBreakdown = nil
        onSave = nil
        representedPostID = nil
        imageView.image = nil
    }

    func configure(with look: JacketsLook) {
        representedPostID = look.postID
        imageView.image = UIImage(named: look.imageName)
        titleLabel.text = look.title
        authorLabel.text = "\(look.author) · \(look.styleTag)"
        contextLabel.text = look.context

        if look.mediaStorage == .local,
           look.mediaKind == .image,
           let mediaURL = WexloLocalContentStore.shared.mediaURL(for: look.mediaFileName) {
            imageView.image = UIImage(contentsOfFile: mediaURL.path)
        }
        if look.mediaKind == .video {
            WexloVideoMedia.loadFirstFrame(for: look.mediaFileName, storage: look.mediaStorage) { [weak self] image in
                guard let self, representedPostID == look.postID else { return }
                imageView.image = image ?? imageView.image
            }
        }
    }

    @objc private func didTapBreakdown() { onBreakdown?() }
    @objc private func didTapSave() { onSave?() }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
