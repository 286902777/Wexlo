import UIKit

private struct SceneConfiguration {
    let setting: String
    let title: String
    let subtitle: String
    let badge: String
    let categoryLabel: String
    let displayCount: String
    let heroAssetName: String
    let heroIncludesCopy: Bool

    static func forSetting(_ setting: String) -> SceneConfiguration {
        switch setting.lowercased() {
        case "rainy day", "rainy":
            return SceneConfiguration(
                setting: "Rainy Day",
                title: "Rainy Day",
                subtitle: "Layer up for wet streets, changing skies, and everything in between.",
                badge: "Find inspiration by scene",
                categoryLabel: "Weather Ready",
                displayCount: "128 looks",
                heroAssetName: "wexlo_scene_rainy_day",
                heroIncludesCopy: false
            )
        case "camping":
            return SceneConfiguration(
                setting: "Camping",
                title: "Camping",
                subtitle: "Pack light, layer comfortably, and settle into the weekend outside.",
                badge: "Find inspiration by scene",
                categoryLabel: "Weekend Outside",
                displayCount: "86 looks",
                heroAssetName: "wexlo_scene_camping",
                heroIncludesCopy: true
            )
        case "travel":
            return SceneConfiguration(
                setting: "Travel",
                title: "Travel",
                subtitle: "Easy layers and thoughtful carry-ons for wherever the route takes you.",
                badge: "Find inspiration by scene",
                categoryLabel: "On the Move",
                displayCount: "104 looks",
                heroAssetName: "wexlo_scene_travel",
                heroIncludesCopy: false
            )
        default:
            return SceneConfiguration(
                setting: "Commute",
                title: "Commute",
                subtitle: "City-ready layers that move from the train platform to the last block home.",
                badge: "Find inspiration by scene",
                categoryLabel: "City Outdoor",
                displayCount: "24 looks",
                heroAssetName: "wexlo_scene_commute",
                heroIncludesCopy: false
            )
        }
    }
}

class SceneDetailViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let configuration: SceneConfiguration
    private var posts: [WexloLocalPost] = []

    init(setting: String) {
        configuration = .forSetting(setting)
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 14
        super.init(headerStyle: .titled(""), layout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationHeader.backgroundColor = WexloTheme.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SceneHeroCell.self, forCellWithReuseIdentifier: SceneHeroCell.reuseIdentifier)
        collectionView.register(SceneSectionHeaderCell.self, forCellWithReuseIdentifier: SceneSectionHeaderCell.reuseIdentifier)
        collectionView.register(SceneKitCell.self, forCellWithReuseIdentifier: SceneKitCell.reuseIdentifier)
        collectionView.register(SceneLookCell.self, forCellWithReuseIdentifier: SceneLookCell.reuseIdentifier)
        collectionView.register(SceneEmptyCell.self, forCellWithReuseIdentifier: SceneEmptyCell.reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChange), name: .wexloPublishedPostDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChange), name: .wexloBlockedUserDidChange, object: nil)
        reloadPosts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isViewLoaded { reloadPosts() }
    }

    @objc private func contentDidChange() {
        reloadPosts()
    }

    private func reloadPosts() {
        let blockedAuthorIDs: Set<String>
        if case .authenticated(let accountID) = WexloSessionStore.shared.current {
            blockedAuthorIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
        } else {
            blockedAuthorIDs = []
        }
        posts = WexloLocalContentStore.shared.posts.filter {
            $0.setting.compare(configuration.setting, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame &&
            !blockedAuthorIDs.contains($0.authorID)
        }
        collectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0, 1: return 1
        default: return max(posts.count, 1)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SceneHeroCell.reuseIdentifier, for: indexPath) as! SceneHeroCell
            cell.configure(with: configuration)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SceneSectionHeaderCell.reuseIdentifier, for: indexPath) as! SceneSectionHeaderCell
            cell.configure(title: "Looks for the route", trailing: "Community picks")
            return cell
        default:
            if posts.isEmpty {
                return collectionView.dequeueReusableCell(withReuseIdentifier: SceneEmptyCell.reuseIdentifier, for: indexPath)
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SceneLookCell.reuseIdentifier, for: indexPath) as! SceneLookCell
            cell.configure(with: posts[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 4,
              posts.indices.contains(indexPath.item),
              let controller = OutfitDetailViewController(postID: posts[indexPath.item].id) else { return }
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return UIEdgeInsets(top: 26, left: 20, bottom: 24, right: 20)
        case 1: return UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)
        default: return UIEdgeInsets(top: 0, left: 20, bottom: 28, right: 20)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentWidth = collectionView.bounds.width - 40
        switch indexPath.section {
        case 0: return CGSize(width: contentWidth, height: contentWidth * 606 / 1033)
        case 1: return CGSize(width: contentWidth, height: 48)
        default:
            if posts.isEmpty { return CGSize(width: contentWidth, height: 84) }
            let cardWidth = (contentWidth - 12) / 2
            return CGSize(width: cardWidth, height: cardWidth * 1.32)
        }
    }
}

private final class SceneHeroCell: UICollectionViewCell {
    static let reuseIdentifier = "SceneHeroCell"
    private let imageView = UIImageView()
    private let shadeView = UIView()
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let countLabel = UILabel()

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
        for label in [categoryLabel, countLabel] {
            label.font = WexloTheme.font(size: 14)
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.28)
            label.layer.cornerRadius = 16
            label.clipsToBounds = true
            label.textAlignment = .center
        }
        [imageView, shadeView, badgeLabel, titleLabel, subtitleLabel, categoryLabel, countLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shadeView.topAnchor.constraint(equalTo: contentView.topAnchor), shadeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), shadeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), shadeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), badgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40), badgeLabel.heightAnchor.constraint(equalToConstant: 40), badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16), titleLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor), subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), categoryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16), categoryLabel.heightAnchor.constraint(equalToConstant: 32), categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 116),
            countLabel.leadingAnchor.constraint(equalTo: categoryLabel.trailingAnchor, constant: 10), countLabel.bottomAnchor.constraint(equalTo: categoryLabel.bottomAnchor), countLabel.heightAnchor.constraint(equalTo: categoryLabel.heightAnchor), countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 84)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(with configuration: SceneConfiguration) {
        imageView.image = UIImage(named: configuration.heroAssetName)
        badgeLabel.text = configuration.badge
        titleLabel.text = configuration.title
        subtitleLabel.text = configuration.subtitle
        categoryLabel.text = configuration.categoryLabel
        countLabel.text = configuration.displayCount
        let baked = configuration.heroIncludesCopy
        [shadeView, badgeLabel, titleLabel, subtitleLabel, categoryLabel, countLabel].forEach { $0.isHidden = baked }
    }
}

private final class SceneSectionHeaderCell: UICollectionViewCell {
    static let reuseIdentifier = "SceneSectionHeaderCell"
    private let titleLabel = UILabel()
    private let trailingLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = WexloTheme.font(size: 23, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        trailingLabel.font = WexloTheme.font(size: 14)
        trailingLabel.textColor = WexloTheme.secondaryText
        trailingLabel.textAlignment = .right
        [titleLabel, trailingLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -8),
            trailingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), trailingLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(title: String, trailing: String?) {
        titleLabel.text = title
        trailingLabel.text = trailing
    }
}

private final class SceneKitCell: UICollectionViewCell {
    static let reuseIdentifier = "SceneKitCell"
    private let imageView = UIImageView()
    private let shadeView = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        shadeView.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        titleLabel.font = WexloTheme.font(size: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        [imageView, shadeView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shadeView.topAnchor.constraint(equalTo: contentView.topAnchor), shadeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), shadeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), shadeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10), titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10), titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(title: String, imageName: String) {
        imageView.image = UIImage(named: imageName)
        titleLabel.text = title
    }
}

private final class SceneLookCell: UICollectionViewCell {
    static let reuseIdentifier = "SceneLookCell"
    private let imageView = UIImageView()
    private let shadeView = UIView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private var representedPostID: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 22
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        shadeView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        titleLabel.font = WexloTheme.font(size: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        authorLabel.font = WexloTheme.font(size: 12)
        authorLabel.textColor = UIColor.white.withAlphaComponent(0.84)
        [imageView, shadeView, titleLabel, authorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shadeView.topAnchor.constraint(equalTo: contentView.topAnchor), shadeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), shadeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), shadeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12), titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12), titleLabel.bottomAnchor.constraint(equalTo: authorLabel.topAnchor, constant: -5),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor), authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedPostID = nil
        imageView.image = nil
    }

    func configure(with post: WexloLocalPost) {
        representedPostID = post.id
        imageView.backgroundColor = WexloTheme.surface
        imageView.image = post.mediaAssetName.flatMap { UIImage(named: $0) }
        if post.mediaStorage == .local, post.mediaKind == .image,
           let url = WexloLocalContentStore.shared.mediaURL(for: post.mediaFileName) {
            imageView.image = UIImage(contentsOfFile: url.path)
        }
        if post.mediaKind == .video {
            WexloVideoMedia.loadFirstFrame(for: post.mediaFileName, storage: post.mediaStorage) { [weak self] image in
                guard let self, representedPostID == post.id else { return }
                imageView.image = image ?? imageView.image
            }
        }
        titleLabel.text = post.title
        let author = post.authorName ?? WexloLocalContentStore.shared.user(for: post.authorID)?.name ?? "Wexlo creator"
        authorLabel.text = "\(author) · \(post.styleTag)"
    }
}

private final class SceneEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = "SceneEmptyCell"
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        messageLabel.text = "No looks for this scene yet."
        messageLabel.font = WexloTheme.font(size: 15)
        messageLabel.textColor = WexloTheme.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16), messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16), messageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
