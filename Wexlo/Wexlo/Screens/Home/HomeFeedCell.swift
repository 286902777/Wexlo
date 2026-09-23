import UIKit

struct HomeFeedItem {
    let postID: String?
    let authorID: String
    let title: String
    let author: String
    let ageAndWeather: String
    let description: String
    let tags: [String]
    let likes: String
    let mediaAssetName: String?
    let mediaFileName: String?
    let mediaKind: WexloMediaKind
    let mediaStorage: WexloMediaStorage
    let mediaColor: UIColor
    let mediaSymbol: String?
    let avatarAssetName: String?
    let mediaContainsTitleOverlay: Bool
    let isLiked: Bool
    let isSaved: Bool

    init(
        postID: String? = nil,
        authorID: String,
        title: String,
        author: String,
        ageAndWeather: String,
        description: String,
        tags: [String],
        likes: String,
        mediaAssetName: String?,
        mediaFileName: String? = nil,
        mediaKind: WexloMediaKind = .image,
        mediaStorage: WexloMediaStorage = .bundled,
        mediaColor: UIColor,
        mediaSymbol: String?,
        avatarAssetName: String?,
        mediaContainsTitleOverlay: Bool,
        isLiked: Bool = false,
        isSaved: Bool = false
    ) {
        self.postID = postID
        self.authorID = authorID
        self.title = title
        self.author = author
        self.ageAndWeather = ageAndWeather
        self.description = description
        self.tags = tags
        self.likes = likes
        self.mediaAssetName = mediaAssetName
        self.mediaFileName = mediaFileName
        self.mediaKind = mediaKind
        self.mediaStorage = mediaStorage
        self.mediaColor = mediaColor
        self.mediaSymbol = mediaSymbol
        self.avatarAssetName = avatarAssetName
        self.mediaContainsTitleOverlay = mediaContainsTitleOverlay
        self.isLiked = isLiked
        self.isSaved = isSaved
    }
}

final class HomeFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeFeedCell"
    static let preferredHeight: CGFloat = 502
    var onSave: (() -> Void)?
    var onBreakdown: (() -> Void)?

    private let cardView = UIView()
    private let mediaView = UIImageView()
    private let mediaShade = UIView()
    private let mediaTitleLabel = UILabel()
    private let avatarView = UIView()
    private let avatarImageView = UIImageView()
    private let avatarLabel = UILabel()
    private let authorLabel = UILabel()
    private let ageWeatherLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let descriptionLabel = UILabel()
    private var tagViews: [UILabel] = []
    private let separatorView = UIView()
    private let likesButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let breakdownBackground = GradientView()
    private let breakdownCoinView = UIImageView()
    private let breakdownTextLabel = UILabel()
    private let breakdownArrowView = UIImageView(image: UIImage(systemName: "arrow.up.right"))
    private let breakdownButton = UIButton(type: .custom)
    private let mediaSymbolView = UIImageView()
    private let mediaPlayButton = UIButton(type: .custom)
    private var representedMediaKey: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedMediaKey = nil
        mediaView.image = nil
        mediaPlayButton.isHidden = true
        onSave = nil
        onBreakdown = nil
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = WexloTheme.surface
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = WexloTheme.hairline.cgColor
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 5)
        cardView.clipsToBounds = true

        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 24
        mediaView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        mediaShade.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        mediaShade.layer.cornerRadius = 24
        mediaShade.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        mediaShade.clipsToBounds = true
        mediaSymbolView.contentMode = .scaleAspectFit
        mediaSymbolView.tintColor = .white.withAlphaComponent(0.9)
        mediaPlayButton.setImage(
            UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: 24,
                    weight: .bold
                )
            ),
            for: .normal
        )
        mediaPlayButton.tintColor = WexloTheme.primaryText
        mediaPlayButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        mediaPlayButton.layer.cornerRadius = 32
        mediaPlayButton.clipsToBounds = true
        mediaPlayButton.accessibilityLabel = "Play video"
        mediaPlayButton.isUserInteractionEnabled = false
        mediaPlayButton.isHidden = true

        mediaTitleLabel.font = WexloTheme.font(size: 25, weight: .bold)
        mediaTitleLabel.textColor = .white
        mediaTitleLabel.numberOfLines = 2

        avatarView.layer.cornerRadius = 22
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.white.cgColor
        avatarView.backgroundColor = WexloTheme.tabBarSurface
        avatarView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarLabel.text = "A"
        avatarLabel.textColor = .white
        avatarLabel.font = WexloTheme.font(size: 18, weight: .bold)
        avatarLabel.textAlignment = .center

        authorLabel.font = WexloTheme.font(size: 17, weight: .bold)
        authorLabel.textColor = WexloTheme.primaryText
        ageWeatherLabel.font = WexloTheme.font(size: 14, weight: .regular)
        ageWeatherLabel.textColor = WexloTheme.secondaryText

        configureOutlineButton(followButton, title: "Follow")
        descriptionLabel.font = WexloTheme.font(size: 17, weight: .bold)
        descriptionLabel.textColor = WexloTheme.primaryText
        descriptionLabel.numberOfLines = 2

        separatorView.backgroundColor = WexloTheme.hairline
        likesButton.tintColor = WexloTheme.secondaryText
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        breakdownBackground.layer.cornerRadius = 16
        breakdownBackground.clipsToBounds = true
        breakdownCoinView.image = UIImage(named: "wexlo_coin")?.withRenderingMode(.alwaysOriginal)
        breakdownCoinView.contentMode = .scaleAspectFit
        breakdownTextLabel.text = "300 · View breakdown"
        breakdownTextLabel.textColor = WexloTheme.primaryText
        breakdownTextLabel.font = WexloTheme.font(size: 10, weight: .bold)
        breakdownArrowView.tintColor = WexloTheme.primaryText.withAlphaComponent(0.78)
        breakdownArrowView.contentMode = .scaleAspectFit
        breakdownButton.addTarget(self, action: #selector(didTapBreakdown), for: .touchUpInside)

        [cardView, mediaView, mediaShade, mediaTitleLabel, mediaSymbolView, mediaPlayButton, avatarView, avatarImageView,
         avatarLabel,
         authorLabel, ageWeatherLabel, followButton, descriptionLabel, separatorView, likesButton,
         saveButton, breakdownBackground, breakdownCoinView, breakdownTextLabel,
         breakdownArrowView, breakdownButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(cardView)
        cardView.addSubview(mediaView)
        cardView.addSubview(mediaShade)
        cardView.addSubview(mediaSymbolView)
        cardView.addSubview(mediaPlayButton)
        cardView.addSubview(mediaTitleLabel)
        cardView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarLabel)
        cardView.addSubview(authorLabel)
        cardView.addSubview(ageWeatherLabel)
        cardView.addSubview(followButton)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(separatorView)
        cardView.addSubview(likesButton)
        cardView.addSubview(saveButton)
        cardView.addSubview(breakdownBackground)
        breakdownBackground.addSubview(breakdownCoinView)
        breakdownBackground.addSubview(breakdownTextLabel)
        breakdownBackground.addSubview(breakdownArrowView)
        breakdownBackground.addSubview(breakdownButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            mediaView.topAnchor.constraint(equalTo: cardView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            mediaView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.74),
            mediaShade.topAnchor.constraint(equalTo: mediaView.topAnchor),
            mediaShade.leadingAnchor.constraint(equalTo: mediaView.leadingAnchor),
            mediaShade.trailingAnchor.constraint(equalTo: mediaView.trailingAnchor),
            mediaShade.bottomAnchor.constraint(equalTo: mediaView.bottomAnchor),
            mediaSymbolView.centerXAnchor.constraint(equalTo: mediaView.centerXAnchor),
            mediaSymbolView.centerYAnchor.constraint(equalTo: mediaView.centerYAnchor),
            mediaSymbolView.widthAnchor.constraint(equalToConstant: 72),
            mediaSymbolView.heightAnchor.constraint(equalToConstant: 72),
            mediaPlayButton.centerXAnchor.constraint(equalTo: mediaView.centerXAnchor),
            mediaPlayButton.centerYAnchor.constraint(equalTo: mediaView.centerYAnchor),
            mediaPlayButton.widthAnchor.constraint(equalToConstant: 64),
            mediaPlayButton.heightAnchor.constraint(equalToConstant: 64),
            mediaTitleLabel.leadingAnchor.constraint(equalTo: mediaView.leadingAnchor, constant: 16),
            mediaTitleLabel.trailingAnchor.constraint(equalTo: mediaView.trailingAnchor, constant: -16),
            mediaTitleLabel.bottomAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: -16),

            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            authorLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            authorLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 1),
            ageWeatherLabel.leadingAnchor.constraint(equalTo: authorLabel.leadingAnchor),
            ageWeatherLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 3),
            followButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            followButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 84),
            followButton.heightAnchor.constraint(equalToConstant: 38),

            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),

            separatorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            likesButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            likesButton.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 12),
            likesButton.heightAnchor.constraint(equalToConstant: 34),
            saveButton.leadingAnchor.constraint(equalTo: likesButton.trailingAnchor, constant: 10),
            saveButton.centerYAnchor.constraint(equalTo: likesButton.centerYAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 34),

            breakdownBackground.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            breakdownBackground.centerYAnchor.constraint(equalTo: likesButton.centerYAnchor),
            breakdownBackground.widthAnchor.constraint(equalToConstant: 172),
            breakdownBackground.heightAnchor.constraint(equalToConstant: 32),
            breakdownCoinView.leadingAnchor.constraint(equalTo: breakdownBackground.leadingAnchor, constant: 10),
            breakdownCoinView.centerYAnchor.constraint(equalTo: breakdownBackground.centerYAnchor),
            breakdownCoinView.widthAnchor.constraint(equalToConstant: 14),
            breakdownCoinView.heightAnchor.constraint(equalToConstant: 14),
            breakdownTextLabel.leadingAnchor.constraint(equalTo: breakdownCoinView.trailingAnchor, constant: 4),
            breakdownTextLabel.centerYAnchor.constraint(equalTo: breakdownBackground.centerYAnchor),
            breakdownArrowView.leadingAnchor.constraint(equalTo: breakdownTextLabel.trailingAnchor, constant: 3),
            breakdownArrowView.trailingAnchor.constraint(equalTo: breakdownBackground.trailingAnchor, constant: -9),
            breakdownArrowView.centerYAnchor.constraint(equalTo: breakdownBackground.centerYAnchor),
            breakdownArrowView.widthAnchor.constraint(equalToConstant: 11),
            breakdownArrowView.heightAnchor.constraint(equalToConstant: 11),
            breakdownButton.leadingAnchor.constraint(equalTo: breakdownBackground.leadingAnchor),
            breakdownButton.trailingAnchor.constraint(equalTo: breakdownBackground.trailingAnchor),
            breakdownButton.topAnchor.constraint(equalTo: breakdownBackground.topAnchor),
            breakdownButton.bottomAnchor.constraint(equalTo: breakdownBackground.bottomAnchor)
        ])

        for _ in 0..<3 {
            let tagLabel = UILabel()
            tagLabel.font = WexloTheme.font(size: 13, weight: .regular)
            tagLabel.textColor = WexloTheme.secondaryText
            tagLabel.textAlignment = .center
            tagLabel.layer.cornerRadius = 15
            tagLabel.layer.borderWidth = 1
            tagLabel.layer.borderColor = WexloTheme.hairline.cgColor
            tagLabel.clipsToBounds = true
            tagLabel.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(tagLabel)
            tagViews.append(tagLabel)
        }

        NSLayoutConstraint.activate([
            tagViews[0].leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            tagViews[0].topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            tagViews[0].widthAnchor.constraint(equalToConstant: 92),
            tagViews[0].heightAnchor.constraint(equalToConstant: 30),
            tagViews[1].leadingAnchor.constraint(equalTo: tagViews[0].trailingAnchor, constant: 10),
            tagViews[1].topAnchor.constraint(equalTo: tagViews[0].topAnchor),
            tagViews[1].widthAnchor.constraint(equalToConstant: 116),
            tagViews[1].heightAnchor.constraint(equalToConstant: 30),
            tagViews[2].leadingAnchor.constraint(equalTo: tagViews[1].trailingAnchor, constant: 10),
            tagViews[2].topAnchor.constraint(equalTo: tagViews[0].topAnchor),
            tagViews[2].widthAnchor.constraint(equalToConstant: 70),
            tagViews[2].heightAnchor.constraint(equalToConstant: 30),
            separatorView.topAnchor.constraint(equalTo: tagViews[0].bottomAnchor, constant: 16)
        ])
    }

    func configure(with item: HomeFeedItem) {
        representedMediaKey = item.mediaKind == .video
            ? item.mediaFileName
            : item.mediaAssetName
        mediaView.image = item.mediaAssetName.flatMap { UIImage(named: $0) }

        if item.mediaKind == .image,
           item.mediaStorage == .local,
           let mediaFileName = item.mediaFileName,
           let mediaURL = WexloLocalContentStore.shared.mediaURL(for: mediaFileName) {
            mediaView.image = UIImage(contentsOfFile: mediaURL.path)
        }

        if item.mediaKind == .video,
           let mediaFileName = item.mediaFileName {
            let mediaKey = mediaFileName
            mediaView.image = UIImage(named: "wexlo_outfit_detail_cover")
            WexloVideoMedia.loadFirstFrame(
                for: mediaFileName,
                storage: item.mediaStorage
            ) { [weak self] image in
                guard let self, representedMediaKey == mediaKey else { return }
                mediaView.image = image ?? mediaView.image
            }
        }
        mediaView.backgroundColor = item.mediaColor
        if item.mediaKind == .video {
            mediaSymbolView.isHidden = true
            mediaPlayButton.isHidden = false
        } else {
            mediaSymbolView.image = item.mediaSymbol.flatMap { UIImage(systemName: $0) }
            mediaSymbolView.isHidden = item.mediaAssetName != nil || item.mediaStorage == .local
            mediaPlayButton.isHidden = true
        }
        mediaTitleLabel.text = item.mediaContainsTitleOverlay ? nil : item.title
        mediaTitleLabel.isHidden = item.mediaContainsTitleOverlay
        mediaShade.isHidden = item.mediaContainsTitleOverlay ||
            (item.mediaAssetName == nil && item.mediaKind == .image && item.mediaStorage == .bundled)
        avatarView.backgroundColor = WexloTheme.tabBarSurface
        avatarImageView.image = item.avatarAssetName.flatMap { UIImage(named: $0) }
        avatarImageView.isHidden = item.avatarAssetName == nil
        avatarLabel.isHidden = item.avatarAssetName != nil
        avatarLabel.text = item.author.first.map(String.init) ?? "A"
        authorLabel.text = item.author
        ageWeatherLabel.text = item.ageAndWeather
        followButton.isHidden = currentAccountID == item.authorID
        descriptionLabel.text = item.description
        let likeTintColor: UIColor = item.isLiked ? .red : WexloTheme.secondaryText
        configureActionButton(
            likesButton,
            systemName: "heart",
            title: item.likes,
            tintColor: likeTintColor
        )

        let saveTintColor: UIColor = item.isSaved ? .red : WexloTheme.secondaryText
        configureActionButton(
            saveButton,
            systemName: "bookmark",
            title: item.isSaved ? "Saved" : "Save",
            tintColor: saveTintColor
        )

        for index in tagViews.indices {
            tagViews[index].text = index < item.tags.count ? item.tags[index] : nil
        }
    }

    private func configureOutlineButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(WexloTheme.primaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 15, weight: .bold)
        button.layer.cornerRadius = 19
        button.layer.borderWidth = 1
        button.layer.borderColor = WexloTheme.hairline.cgColor
    }

    private func configureActionButton(
        _ button: UIButton,
        systemName: String,
        title: String,
        tintColor: UIColor
    ) {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12)
        button.setImage(
            UIImage(systemName: systemName, withConfiguration: symbolConfiguration),
            for: .normal
        )
        button.setTitle(title, for: .normal)
        button.setTitleColor(tintColor, for: .normal)
        button.tintColor = tintColor
        button.titleLabel?.font = WexloTheme.font(size: 12)
        button.titleLabel?.lineBreakMode = .byClipping
        button.imageEdgeInsets = .zero
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private var currentAccountID: String? {
        if case .authenticated(let userID) = WexloSessionStore.shared.current {
            return userID
        }
        return nil
    }

    @objc private func didTapSave() {
        onSave?()
    }

    @objc private func didTapBreakdown() {
        onBreakdown?()
    }
}
