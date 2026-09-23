import UIKit

final class OutfitDetailViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    private static let breakdownUnlockCost = 300

    private let post: WexloLocalPost
    private let shouldScrollToBreakdown: Bool
    private var isBreakdownUnlocked: Bool
    private let headerView = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let composerView = UIView()
    private let commentTextField = UITextField()
    private let loadingOverlay = WexloLoadingOverlay()
    private let likeButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private var composerBottomConstraint: NSLayoutConstraint?
    private var breakdownSectionView: UIView?
    private var commentsSectionView: UIView?
    private var isLiked = false
    private var likeCount = 0
    private var isSaved = false
    private var isSendingComment = false
    private var isSaving = false
    private var isUnlockingBreakdown = false
    private var hasScrolledToBreakdown = false

    init(
        post: WexloLocalPost,
        isBreakdownUnlocked: Bool = false,
        scrollToBreakdown: Bool = false
    ) {
        self.post = post
        self.shouldScrollToBreakdown = scrollToBreakdown
        self.isBreakdownUnlocked = isBreakdownUnlocked || WexloBreakdownUnlockStore.shared.isUnlocked(
            postID: post.id,
            userID: Self.activeBreakdownUserID
        )
        super.init(nibName: nil, bundle: nil)
    }

    convenience init?(
        postID: String,
        isBreakdownUnlocked: Bool = false,
        scrollToBreakdown: Bool = false
    ) {
        guard let post = WexloLocalContentStore.shared.post(for: postID) else {
            return nil
        }
        self.init(
            post: post,
            isBreakdownUnlocked: isBreakdownUnlocked,
            scrollToBreakdown: scrollToBreakdown
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureNavigation()
        configureContent()
        configureKeyboardHandling()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBreakdownIfNeeded(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        composerView.layer.shadowPath = UIBezierPath(
            roundedRect: composerView.bounds,
            cornerRadius: composerView.layer.cornerRadius
        ).cgPath
        scrollToBreakdownIfNeeded(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNavigation() {
        headerView.backgroundColor = WexloTheme.background
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Outfit detail"
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 20, weight: .bold)
        titleLabel.textAlignment = .center

        [backButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }

        var constraints = [
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ]

        if !isCurrentUserAuthor {
            let moreButton = UIButton(type: .custom)
            moreButton.setImage(UIImage(named: "wexlo_outfit_more"), for: .normal)
            moreButton.imageView?.contentMode = .scaleAspectFit
            moreButton.backgroundColor = WexloTheme.surface
            moreButton.layer.cornerRadius = 17.5
            moreButton.layer.borderWidth = 1
            moreButton.layer.borderColor = WexloTheme.hairline.cgColor
            moreButton.accessibilityLabel = "More actions"
            moreButton.menu = nil
            moreButton.showsMenuAsPrimaryAction = false
            moreButton.addTarget(self, action: #selector(didTapMore(_:)), for: .touchUpInside)
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(moreButton)
            constraints += [
                moreButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
                moreButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                moreButton.widthAnchor.constraint(equalToConstant: 35),
                moreButton.heightAnchor.constraint(equalToConstant: 35)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func configureContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)

        configureCommentComposer()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composerView.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 15),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -15),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])

        appendArranged(makeHeroSection(), spacing: 18)
        appendArranged(makeAuthorSection(), spacing: 18)
        appendArranged(makeTitleSection(), spacing: 16)
        appendArranged(makeTags(), spacing: 18)
        appendArranged(makeDivider(), spacing: 8)
        appendArranged(makeActionRow(), spacing: 14)
        appendArranged(makeDivider(), spacing: 20)
        let breakdownSection = makeBreakdownSection()
        breakdownSectionView = breakdownSection
        appendArranged(breakdownSection, spacing: 20)
        appendArranged(makeAISection(), spacing: 28)
        let commentsSection = makeCommentsSection()
        commentsSectionView = commentsSection
        appendArranged(commentsSection, spacing: 16)
    }

    private func appendArranged(_ view: UIView, spacing: CGFloat) {
        contentStack.addArrangedSubview(view)
        contentStack.setCustomSpacing(spacing, after: view)
    }

    private func scrollToBreakdownIfNeeded(animated: Bool) {
        guard shouldScrollToBreakdown, !hasScrolledToBreakdown else { return }
        guard let breakdownSectionView else { return }

        view.layoutIfNeeded()
        scrollView.layoutIfNeeded()
        contentStack.layoutIfNeeded()

        guard scrollView.bounds.height > 0,
              scrollView.contentSize.height > 0,
              breakdownSectionView.bounds.height > 0 else {
            return
        }

        let targetRect = breakdownSectionView.convert(
            breakdownSectionView.bounds,
            to: contentStack
        )
        let targetY = contentStack.frame.minY + targetRect.minY - 12
        let maximumOffsetY = max(
            -scrollView.adjustedContentInset.top,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        let offsetY = min(
            max(targetY, -scrollView.adjustedContentInset.top),
            maximumOffsetY
        )

        hasScrolledToBreakdown = true
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: offsetY),
            animated: animated
        )
    }

    private func makeHeroSection() -> UIView {
        let container = UIView()
        container.backgroundColor = WexloTheme.surface
        container.layer.cornerRadius = 24
        container.clipsToBounds = true

        let imageView = UIImageView()
        if let imageName = post.mediaAssetName {
            imageView.image = UIImage(named: imageName)
        } else if post.mediaKind == .image,
                  let mediaURL = WexloLocalContentStore.shared.mediaURL(for: post.mediaFileName) {
            imageView.image = UIImage(contentsOfFile: mediaURL.path)
        } else {
            imageView.image = UIImage(named: "wexlo_outfit_detail_cover")
            WexloVideoMedia.loadFirstFrame(
                for: post.mediaFileName,
                storage: post.mediaStorage
            ) { [weak imageView] image in
                imageView?.image = image ?? imageView?.image
            }
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let shade = OutfitBottomShadeView()

        let titleLabel = makeLabel(
            post.title,
            size: 23,
            weight: .bold,
            color: .white
        )
        titleLabel.numberOfLines = 2

        var heroSubviews: [UIView] = [imageView, shade, titleLabel]
        if post.mediaKind == .video {
            let playButton = UIButton(type: .custom)
            playButton.setImage(
                UIImage(
                    systemName: "play.fill",
                    withConfiguration: UIImage.SymbolConfiguration(
                        pointSize: 24,
                        weight: .bold
                    )
                ),
                for: .normal
            )
            playButton.tintColor = WexloTheme.primaryText
            playButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            playButton.layer.cornerRadius = 32
            playButton.accessibilityLabel = "Play video"
            playButton.addTarget(self, action: #selector(didTapPlayVideo), for: .touchUpInside)
            heroSubviews.append(playButton)
        }

        heroSubviews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 380.0 / 345.0),

            shade.topAnchor.constraint(equalTo: imageView.topAnchor),
            shade.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -17)
        ])
        if let playButton = heroSubviews.last as? UIButton {
            NSLayoutConstraint.activate([
                playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                playButton.widthAnchor.constraint(equalToConstant: 64),
                playButton.heightAnchor.constraint(equalToConstant: 64)
            ])
        }
        return container
    }

    private func makeAuthorSection() -> UIView {
        let row = UIView()
        let author = WexloLocalContentStore.shared.user(for: post.authorID)
        let avatar = UIImageView(image: UIImage(named: author?.avatarAssetName ?? "wexlo_profile_avatar"))
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 13
        if isOtherUser(post.authorID) {
            avatar.isUserInteractionEnabled = true
            avatar.accessibilityIdentifier = post.authorID
            avatar.accessibilityLabel = "Open \(author?.name ?? "author")'s profile"
            avatar.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapProfileAvatar(_:)))
            )
        }

        let authorName = author?.name ?? "Wexlo member"
        let nameLabel = makeLabel(authorName, size: 16, weight: .bold, color: WexloTheme.primaryText)
        let handle = "@\(authorName.lowercased().replacingOccurrences(of: " ", with: "."))"
        let metaLabel = makeLabel("\(handle) · Today", size: 13, color: WexloTheme.secondaryText)
        let followButton = makeOutlineButton(
            title: isCurrentUserFollowingAuthor ? "Following" : "Follow"
        )
        followButton.addTarget(self, action: #selector(didTapFollow), for: .touchUpInside)
        followButton.isHidden = isCurrentUserAuthor

        [avatar, nameLabel, metaLabel, followButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            avatar.topAnchor.constraint(equalTo: row.topAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 43),
            avatar.heightAnchor.constraint(equalToConstant: 43),
            avatar.bottomAnchor.constraint(equalTo: row.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 1),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -8),
            metaLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -8),

            followButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            followButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 84),
            followButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        return row
    }

    private func makeTitleSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 7

        let title = makeLabel(
            post.title,
            size: 20,
            weight: .bold,
            color: WexloTheme.primaryText
        )
        title.numberOfLines = 0
        let description = makeLabel(
            post.detail,
            size: 15,
            color: WexloTheme.primaryText
        )
        description.numberOfLines = 0

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(description)
        return stack
    }

    private func makeTags() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        let tags: [String]
        tags = [post.category, post.styleTag, post.setting]
        tags.forEach {
            stack.addArrangedSubview(makeTag($0))
        }
        stack.addArrangedSubview(UIView())
        return stack
    }

    private func makeActionRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fillEqually
        row.spacing = 24
        let likeState = WexloLikeStore.shared.state(for: post, userID: likeUserID)
        isLiked = likeState.isLiked
        likeCount = likeState.count
        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        configureLikeButton()
        row.addArrangedSubview(likeButton)
        isSaved = WexloSavedOutfitStore.shared.isSaved(
            postID: post.id,
            userID: saveUserID
        )
        configureSaveButton()
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        row.addArrangedSubview(saveButton)
        configureActionButton(
            commentButton,
            systemName: "bubble.right",
            title: "Comment \(WexloCommentStore.shared.count(for: post))",
            tintColor: WexloTheme.secondaryText
        )
        row.addArrangedSubview(commentButton)
        return row
    }

    private func makeBreakdownSection() -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 10

        let heading = UIStackView()
        heading.axis = .horizontal
        heading.alignment = .center
        let title = makeLabel("Five-layer breakdown", size: 17, weight: .bold, color: WexloTheme.primaryText)
        let detail = makeBreakdownStatusLabel(isBreakdownUnlocked ? "Full details unlocked" : "Unlock for full details")
        heading.addArrangedSubview(title)
        heading.addArrangedSubview(UIView())
        heading.addArrangedSubview(detail)
        section.addArrangedSubview(heading)

        if isBreakdownUnlocked {
            section.addArrangedSubview(makeUnlockedBreakdownCard(for: latestPost))
        } else {
            section.addArrangedSubview(makeUnlockCard())
        }
        return section
    }

    private func makeUnlockedBreakdownCard(for post: WexloLocalPost) -> UIView {
        let card = UIView()
        card.backgroundColor = WexloTheme.surface
        card.layer.cornerRadius = 17
        card.layer.borderWidth = 1
        card.layer.borderColor = WexloTheme.hairline.cgColor
        card.clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let layers = post.layers
        if layers.isEmpty {
            let emptyLabel = makeLabel(
                "No layer details are available for this outfit.",
                size: 13,
                color: WexloTheme.secondaryText
            )
            emptyLabel.numberOfLines = 0
            stack.addArrangedSubview(emptyLabel)
        } else {
            for (index, layer) in layers.enumerated() {
                stack.addArrangedSubview(makeLayerRow(layer))
                if index < layers.count - 1 {
                    stack.addArrangedSubview(makeBreakdownDivider())
                }
            }
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func makeUnlockCard() -> UIView {
        let card = DashedBorderView()
        card.backgroundColor = WexloTheme.surface
        card.layer.cornerRadius = 20
        card.isUserInteractionEnabled = true

        let title = makeLabel("See the complete breakdown", size: 16, weight: .bold, color: WexloTheme.primaryText)
        let subtitle = makeLabel("Brand, model, and styling logic are inside.", size: 13, color: WexloTheme.secondaryText)
        let gradient = GradientView()
        gradient.layer.cornerRadius = 18
        gradient.clipsToBounds = true
        let button = UIButton(type: .system)
        button.setTitle("Unlock · \(Self.breakdownUnlockCost) Coins", for: .normal)
        button.setTitleColor(WexloTheme.primaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 13, weight: .bold)
        button.addTarget(self, action: #selector(didTapUnlock), for: .touchUpInside)

        [title, subtitle, gradient].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        gradient.addSubview(button)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 128),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            title.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 16),
            subtitle.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            subtitle.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 16),
            gradient.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            gradient.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 16),
            gradient.widthAnchor.constraint(equalToConstant: 142),
            gradient.heightAnchor.constraint(equalToConstant: 36),
            button.topAnchor.constraint(equalTo: gradient.topAnchor),
            button.leadingAnchor.constraint(equalTo: gradient.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: gradient.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: gradient.bottomAnchor)
        ])
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUnlock)))
        return card
    }

    private func makeLayerRow(_ layer: WexloLayerItem) -> UIView {
        let row = UIView()

        let titleLabel = makeLabel(layer.name, size: 13, weight: .bold, color: WexloTheme.primaryText)
        titleLabel.numberOfLines = 1
        let detailLabel = makeLabel(layer.detail, size: 12, color: WexloTheme.secondaryText)
        detailLabel.numberOfLines = 2

        [titleLabel, detailLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -15),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -12)
        ])
        return row
    }

    private func makeAISection() -> UIView {
        let card = UIView()
        card.backgroundColor = WexloTheme.tabBar
        card.layer.cornerRadius = 18

        let title = makeLabel("Make this fit yours?", size: 16, weight: .bold, color: .white)
        let subtitle = makeLabel("Ask AI Stylist for a layering remix.", size: 12, color: UIColor.white.withAlphaComponent(0.66))
        let gradient = GradientView()
        gradient.layer.cornerRadius = 17
        gradient.clipsToBounds = true
        let button = UIButton(type: .system)
        button.setTitle("Ask AI", for: .normal)
        button.setTitleColor(WexloTheme.primaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 13, weight: .bold)
        button.addTarget(self, action: #selector(didTapAI), for: .touchUpInside)

        [title, subtitle, gradient].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        gradient.addSubview(button)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 68),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            title.trailingAnchor.constraint(lessThanOrEqualTo: gradient.leadingAnchor, constant: -12),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitle.trailingAnchor.constraint(lessThanOrEqualTo: gradient.leadingAnchor, constant: -12),
            gradient.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            gradient.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            gradient.widthAnchor.constraint(equalToConstant: 58),
            gradient.heightAnchor.constraint(equalToConstant: 34),
            button.topAnchor.constraint(equalTo: gradient.topAnchor),
            button.leadingAnchor.constraint(equalTo: gradient.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: gradient.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: gradient.bottomAnchor)
        ])
        return card
    }

    private func makeCommentsSection() -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 0

        let heading = UIStackView()
        heading.axis = .horizontal
        heading.alignment = .center
        heading.addArrangedSubview(makeLabel("Comments", size: 20, weight: .bold, color: WexloTheme.primaryText))
        heading.addArrangedSubview(UIView())
        let comments = WexloCommentStore.shared.comments(for: post)
        let commentCount = comments.count
        heading.addArrangedSubview(
            makeLabel("\(commentCount) comments", size: 12, color: WexloTheme.secondaryText)
        )
        section.addArrangedSubview(heading)
        section.setCustomSpacing(24, after: heading)

        for (index, comment) in comments.enumerated() {
            let author = WexloLocalContentStore.shared.user(for: comment.authorID)
            let commentRow = makeCommentRow(
                authorID: comment.authorID,
                username: author?.name ?? "Wexlo member",
                text: comment.text,
                time: comment.timeLabel,
                avatarName: author?.avatarAssetName ?? "wexlo_profile_avatar"
            )
            section.addArrangedSubview(commentRow)
            if index < comments.count - 1 {
                section.setCustomSpacing(15, after: commentRow)
                section.addArrangedSubview(makeDivider())
                section.setCustomSpacing(14, after: section.arrangedSubviews.last!)
            }
        }
        if comments.isEmpty {
            section.addArrangedSubview(
                makeLabel("No comments yet.", size: 14, color: WexloTheme.secondaryText)
            )
        }
        return section
    }

    private func makeCommentRow(
        authorID: String?,
        username: String,
        text: String,
        time: String,
        avatarName: String
    ) -> UIView {
        let row = UIView()
        let avatar = UIImageView(image: UIImage(named: avatarName))
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 11
        if let authorID,
           isOtherUser(authorID) {
            avatar.isUserInteractionEnabled = true
            avatar.accessibilityIdentifier = authorID
            avatar.accessibilityLabel = "Open \(username)'s profile"
            avatar.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapProfileAvatar(_:)))
            )
        }
        let name = makeLabel(username, size: 14, weight: .bold, color: WexloTheme.primaryText)
        let body = makeLabel(text, size: 14, color: WexloTheme.primaryText)
        body.numberOfLines = 0
        let timeLabel = makeLabel(time, size: 12, color: WexloTheme.secondaryText)
        var moreButton: UIButton?
        if let authorID, isOtherUser(authorID) {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "wexlo_outfit_more"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = "More comment actions"
            button.accessibilityIdentifier = authorID
            button.addTarget(
                self,
                action: #selector(didTapCommentMore(_:)),
                for: .touchUpInside
            )
            moreButton = button
        }

        [avatar, name, body, timeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        if let moreButton {
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(moreButton)
        }

        let textTrailingAnchor = moreButton?.leadingAnchor ?? row.trailingAnchor
        let textTrailingConstant: CGFloat = moreButton == nil ? 0 : -8
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            avatar.topAnchor.constraint(equalTo: row.topAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            avatar.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor),
            name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 9),
            name.topAnchor.constraint(equalTo: row.topAnchor),
            name.trailingAnchor.constraint(
                lessThanOrEqualTo: textTrailingAnchor,
                constant: textTrailingConstant
            ),
            body.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            body.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2),
            body.trailingAnchor.constraint(
                lessThanOrEqualTo: textTrailingAnchor,
                constant: textTrailingConstant
            ),
            timeLabel.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        if let moreButton {
            NSLayoutConstraint.activate([
                moreButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                moreButton.topAnchor.constraint(equalTo: row.topAnchor, constant: -7),
                moreButton.widthAnchor.constraint(equalToConstant: 24),
                moreButton.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        return row
    }

    private func configureCommentComposer() {
        composerView.backgroundColor = WexloTheme.tabBar
        composerView.layer.cornerRadius = 24
        composerView.layer.borderWidth = 1
        composerView.layer.borderColor = WexloTheme.tabBarBorder.cgColor
        composerView.layer.shadowColor = UIColor.black.cgColor
        composerView.layer.shadowOpacity = 0.13
        composerView.layer.shadowRadius = 12
        composerView.layer.shadowOffset = CGSize(width: 0, height: 7)

        commentTextField.textColor = .white
        commentTextField.font = WexloTheme.font(size: 15)
        commentTextField.returnKeyType = .send
        commentTextField.delegate = self
        commentTextField.borderStyle = .none
        commentTextField.attributedPlaceholder = NSAttributedString(
            string: "Add a comment...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        commentTextField.backgroundColor = UIColor(red: 0.28, green: 0.27, blue: 0.27, alpha: 1)
        commentTextField.layer.cornerRadius = 18
        commentTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        commentTextField.leftViewMode = .always

        let sendButton = UIButton(type: .custom)
        sendButton.setImage(UIImage(named: "wexlo_chat_send_message"), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.accessibilityLabel = "Send comment"
        sendButton.addTarget(self, action: #selector(didTapSendComment), for: .touchUpInside)

        [commentTextField, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            composerView.addSubview($0)
        }
        composerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composerView)
        composerBottomConstraint = composerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -12
        )
        NSLayoutConstraint.activate([
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            composerView.heightAnchor.constraint(equalToConstant: 62),
            composerBottomConstraint!,
            commentTextField.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 8),
            commentTextField.topAnchor.constraint(equalTo: composerView.topAnchor, constant: 8),
            commentTextField.bottomAnchor.constraint(equalTo: composerView.bottomAnchor, constant: -8),
            sendButton.leadingAnchor.constraint(equalTo: commentTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 42),
            sendButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func makeLabel(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = WexloTheme.font(size: size, weight: weight)
        label.textColor = color
        return label
    }

    private func makeTag(_ text: String) -> UIView {
        let label = PaddedLabel(horizontalInset: 8, verticalInset: 6)
        label.text = text
        label.textAlignment = .center
        label.font = WexloTheme.font(size: 12)
        label.textColor = WexloTheme.secondaryText
        label.backgroundColor = WexloTheme.surface
        label.layer.cornerRadius = 13
        label.layer.borderWidth = 1
        label.layer.borderColor = WexloTheme.hairline.cgColor
        label.clipsToBounds = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func makeBreakdownStatusLabel(_ text: String) -> UILabel {
        let label = makeLabel(text, size: 11, color: WexloTheme.secondaryText)
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = WexloTheme.hairline
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func makeBreakdownDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = WexloTheme.hairline
        divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        return divider
    }

    private func makeOutlineButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 14, weight: .semibold)
        button.layer.cornerRadius = 17
        button.backgroundColor = WexloTheme.primaryText
        return button
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
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
    }

    private func configureLikeButton() {
        configureActionButton(
            likeButton,
            systemName: "heart",
            title: "\(likeCount)",
            tintColor: isLiked ? .red : WexloTheme.secondaryText
        )
        likeButton.accessibilityLabel = isLiked ? "Unlike outfit" : "Like outfit"
        likeButton.accessibilityValue = "\(likeCount) likes"
        likeButton.accessibilityTraits = isLiked ? [.button, .selected] : [.button]
    }

    private func configureSaveButton() {
        configureActionButton(
            saveButton,
            systemName: "bookmark",
            title: isSaved ? "Saved" : "Save",
            tintColor: isSaved ? .red : WexloTheme.secondaryText
        )
        saveButton.accessibilityLabel = isSaved
            ? "Remove from saved outfits"
            : "Save outfit"
        saveButton.accessibilityTraits = isSaved ? [.button, .selected] : [.button]
    }

    @objc private func didTapBack() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapMore(_ sender: UIButton) {
        guard !isCurrentUserAuthor else { return }

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            guard let self else { return }
            navigationController?.pushViewController(ReportViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            self?.blockAuthor()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
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

    @objc private func didTapCommentMore(_ sender: UIButton) {
        guard let authorID = sender.accessibilityIdentifier,
              isOtherUser(authorID) else {
            return
        }

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(
                ReportViewController(),
                animated: true
            )
        })
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            self?.blockCommentAuthor(authorID)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
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

    private func blockAuthor() {
        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to block users.")
            return
        }
        guard !isCurrentUserAuthor else { return }
        guard WexloBlockStore.shared.blockUser(post.authorID, for: accountID) else {
            showWexloToast("Unable to block this user.")
            return
        }

        let previousViewController = navigationController?.viewControllers.dropLast().last
        navigationController?.popViewController(animated: true)
        previousViewController?.showWexloToast("User blocked.")
    }

    private func blockCommentAuthor(_ authorID: String) {
        guard isOtherUser(authorID) else { return }
        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to block users.")
            return
        }
        guard WexloBlockStore.shared.blockUser(authorID, for: accountID) else {
            showWexloToast("Unable to block this user.")
            return
        }

        let previousViewController = navigationController?.viewControllers.dropLast().last
        navigationController?.popViewController(animated: true)
        previousViewController?.showWexloToast("User blocked.")
    }

    @objc private func didTapFollow(_ sender: UIButton) {
        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to follow users.")
            return
        }
        guard !isCurrentUserAuthor else { return }

        let nextIsFollowing = !WexloRelationshipStore.shared.isFollowing(
            post.authorID,
            from: accountID
        )
        guard WexloRelationshipStore.shared.setFollowing(
            nextIsFollowing,
            from: accountID,
            to: post.authorID
        ) else {
            showWexloToast("Following could not be updated.")
            return
        }

        sender.setTitle(nextIsFollowing ? "Following" : "Follow", for: .normal)
        showWexloToast(nextIsFollowing ? "Following." : "Unfollowed.")
    }

    @objc private func didTapLike() {
        guard let nextState = WexloLikeStore.shared.toggleLike(for: post, userID: likeUserID) else {
            showWexloToast("Like could not be saved.")
            return
        }

        isLiked = nextState.isLiked
        likeCount = nextState.count
        configureLikeButton()
        showWexloToast(isLiked ? "Liked." : "Like removed.")
    }

    @objc private func didTapSave() {
        guard !isSaving else { return }
        isSaving = true
        saveButton.isEnabled = false
        loadingOverlay.show(in: view)

        let nextSavedState = !isSaved
        guard WexloSavedOutfitStore.shared.setSaved(
            nextSavedState,
            postID: post.id,
            userID: saveUserID
        ) else {
            loadingOverlay.hide()
            isSaving = false
            saveButton.isEnabled = true
            showWexloToast("Outfit could not be saved.")
            return
        }

        completeWexloLoading(loadingOverlay) { [weak self] in
            guard let self else { return }
            isSaved = nextSavedState
            configureSaveButton()
            saveButton.isEnabled = true
            isSaving = false
            showWexloToast(isSaved ? "Saved to your looks." : "Removed from your saved looks.")
        }
    }

    @objc private func didTapUnlock() {
        guard !isUnlockingBreakdown, !isBreakdownUnlocked else { return }
        guard case .authenticated(let userID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to unlock breakdowns.")
            return
        }
        guard WexloCoinStore.shared.balance(for: userID) >= Self.breakdownUnlockCost else {
            showWexloToast("You need 300 coins to unlock this breakdown.")
            return
        }

        let dialog = UnlockOutfitViewController()
        dialog.onConfirm = { [weak self] in
            self?.unlockBreakdown(for: userID)
        }
        present(dialog, animated: true)
    }

    private func unlockBreakdown(for userID: String) {
        guard !isUnlockingBreakdown, !isBreakdownUnlocked else { return }
        isUnlockingBreakdown = true
        loadingOverlay.show(in: view)

        do {
            try WexloCoinStore.shared.spendCoins(Self.breakdownUnlockCost, for: userID)
            WexloBreakdownUnlockStore.shared.setUnlocked(true, postID: post.id, userID: userID)
        } catch WexloCoinStoreError.insufficientBalance {
            loadingOverlay.hide()
            isUnlockingBreakdown = false
            showWexloToast("You need 300 coins to unlock this breakdown.")
            return
        } catch {
            loadingOverlay.hide()
            isUnlockingBreakdown = false
            showWexloToast("Breakdown could not be unlocked.")
            return
        }

        completeWexloLoading(loadingOverlay) { [weak self] in
            guard let self else { return }
            isBreakdownUnlocked = true
            refreshBreakdownSection()
            isUnlockingBreakdown = false
            showWexloToast("Breakdown unlocked.")
        }
    }

    @objc private func didTapAI() {
        navigationController?.pushViewController(AIStylistViewController(), animated: true)
    }

    @objc private func didTapPlayVideo() {
        guard post.mediaKind == .video,
              let controller = WexloVideoPlayerViewController(
                videoFileName: post.mediaFileName,
                storage: post.mediaStorage
              ) else {
            showWexloToast("Video unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func didTapSendComment() {
        guard !isSendingComment else { return }
        let text = commentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            showWexloToast("Enter a comment first.")
            return
        }
        guard case .authenticated(let userID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to comment.")
            return
        }
        guard WexloCommentStore.shared.appendComment(
            text,
            to: post,
            authorID: userID
        ) != nil else {
            showWexloToast("Comment could not be saved.")
            return
        }
        isSendingComment = true
        commentTextField.text = nil
        view.endEditing(true)
        refreshCommentsSection()
        showWexloToast("Comment posted.")
        isSendingComment = false
    }

    @objc private func didTapProfileAvatar(_ gesture: UITapGestureRecognizer) {
        guard let userID = gesture.view?.accessibilityIdentifier,
              isOtherUser(userID) else {
            return
        }
        navigationController?.pushViewController(
            UserProfileViewController(userID: userID),
            animated: true
        )
    }

    private func refreshCommentsSection() {
        guard let currentSection = commentsSectionView,
              let index = contentStack.arrangedSubviews.firstIndex(of: currentSection) else {
            return
        }
        contentStack.removeArrangedSubview(currentSection)
        currentSection.removeFromSuperview()

        let updatedSection = makeCommentsSection()
        commentsSectionView = updatedSection
        contentStack.insertArrangedSubview(updatedSection, at: index)
        contentStack.setCustomSpacing(16, after: updatedSection)
        commentButton.setTitle(
            "Comment \(WexloCommentStore.shared.count(for: post))",
            for: .normal
        )
        view.layoutIfNeeded()
    }

    private func refreshBreakdownSection() {
        guard let currentSection = breakdownSectionView,
              let index = contentStack.arrangedSubviews.firstIndex(of: currentSection) else {
            return
        }
        contentStack.removeArrangedSubview(currentSection)
        currentSection.removeFromSuperview()

        let updatedSection = makeBreakdownSection()
        breakdownSectionView = updatedSection
        contentStack.insertArrangedSubview(updatedSection, at: index)
        contentStack.setCustomSpacing(20, after: updatedSection)
        view.layoutIfNeeded()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSendComment()
        return true
    }

    private func configureKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let convertedFrame = view.convert(frame, from: nil)
        let overlap = max(
            0,
            view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom
        )
        updateComposerPosition(
            keyboardOverlap: overlap,
            duration: duration,
            userInfo: userInfo
        )
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        updateComposerPosition(
            keyboardOverlap: 0,
            duration: duration,
            userInfo: notification.userInfo ?? [:]
        )
    }

    private func updateComposerPosition(
        keyboardOverlap: CGFloat,
        duration: TimeInterval,
        userInfo: [AnyHashable: Any]
    ) {
        let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        let options = UIView.AnimationOptions(rawValue: curveValue << 16).union(.beginFromCurrentState)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options
        ) {
            self.composerBottomConstraint?.constant = -12 - keyboardOverlap
            self.view.layoutIfNeeded()
        }
    }

    private var likeUserID: String {
        switch WexloSessionStore.shared.current {
        case .authenticated(let userID):
            return userID
        case .guest:
            return "guest"
        case .absent:
            return "anonymous"
        }
    }

    private var saveUserID: String {
        switch WexloSessionStore.shared.current {
        case .authenticated(let userID):
            return userID
        case .guest:
            return "guest"
        case .absent:
            return "anonymous"
        }
    }

    private var latestPost: WexloLocalPost {
        WexloLocalContentStore.shared.post(for: post.id) ?? post
    }

    private static var activeBreakdownUserID: String? {
        guard case .authenticated(let userID) = WexloSessionStore.shared.current else {
            return nil
        }
        return userID
    }

    private var isCurrentUserAuthor: Bool {
        guard case .authenticated(let currentUserID) = WexloSessionStore.shared.current else {
            return false
        }
        return currentUserID == post.authorID
    }

    private var isCurrentUserFollowingAuthor: Bool {
        guard case .authenticated(let currentUserID) = WexloSessionStore.shared.current else {
            return false
        }
        return WexloRelationshipStore.shared.isFollowing(
            post.authorID,
            from: currentUserID
        )
    }

    private func isOtherUser(_ userID: String) -> Bool {
        guard case .authenticated(let currentUserID) = WexloSessionStore.shared.current else {
            return true
        }
        return currentUserID != userID
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: composerView)
    }
}

private final class OutfitBottomShadeView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let gradient = layer as! CAGradientLayer
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.04).cgColor,
            UIColor.black.withAlphaComponent(0.58).cgColor
        ]
        gradient.locations = [0.0, 0.58, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }
}

private final class DashedBorderView: UIView {
    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = WexloTheme.hairline.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineDashPattern = [NSNumber(value: 5), NSNumber(value: 4)]
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}

private final class WexloBreakdownUnlockStore {
    static let shared = WexloBreakdownUnlockStore()

    private struct StoredState: Codable {
        var unlockedPostIDsByUser: [String: [String]] = [:]
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.breakdown.unlocks"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isUnlocked(postID: String, userID: String?) -> Bool {
        guard let userID else { return false }
        return loadState().unlockedPostIDsByUser[userID]?.contains(postID) == true
    }

    func setUnlocked(_ unlocked: Bool, postID: String, userID: String) {
        var state = loadState()
        var postIDs = state.unlockedPostIDsByUser[userID] ?? []

        if unlocked {
            if !postIDs.contains(postID) {
                postIDs.append(postID)
            }
        } else {
            postIDs.removeAll { $0 == postID }
        }

        if postIDs.isEmpty {
            state.unlockedPostIDsByUser.removeValue(forKey: userID)
        } else {
            state.unlockedPostIDsByUser[userID] = postIDs
        }
        saveState(state)
    }

    private func loadState() -> StoredState {
        guard let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return StoredState()
        }
        return state
    }

    private func saveState(_ state: StoredState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
    }
}

private final class PaddedLabel: UILabel {
    private let horizontalInset: CGFloat
    private let verticalInset: CGFloat

    init(horizontalInset: CGFloat, verticalInset: CGFloat) {
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + horizontalInset * 2,
            height: size.height + verticalInset * 2
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: horizontalInset, dy: verticalInset))
    }
}
