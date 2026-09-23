import UIKit

private struct ExploreTile {
    let title: String
    let subtitle: String
    let imageName: String
    let route: String
}

private struct ExploreRecommendation {
    let postID: String?
    let authorID: String
    let title: String
    let author: String
    let styleTag: String
    let context: String
    let imageName: String
    let mediaFileName: String
    let mediaKind: WexloMediaKind
    let mediaStorage: WexloMediaStorage
}

final class ExploreViewController: WexloCollectionPageViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let categories = [
        ExploreTile(title: "Jackets", subtitle: "Shells and light layers", imageName: "wexlo_explore_jackets", route: "jackets"),
        ExploreTile(title: "Pants", subtitle: "Utility and trail fits", imageName: "wexlo_explore_pants", route: "pants"),
        ExploreTile(title: "Shoes", subtitle: "Outdoor and trail shoes", imageName: "wexlo_explore_shoes", route: "shoes"),
        ExploreTile(title: "Bags", subtitle: "Daily and travel carry", imageName: "wexlo_explore_bags", route: "bags"),
        ExploreTile(title: "Fleece", subtitle: "Soft mid-layers", imageName: "wexlo_explore_fleece", route: "fleece"),
        ExploreTile(title: "Accessories", subtitle: "Caps, eyewear, extras", imageName: "wexlo_explore_accessories", route: "accessories")
    ]

    private let themes = [
        ExploreTile(title: "Rainy Day", subtitle: "128 layered looks", imageName: "wexlo_explore_rainy_day", route: "rainy-day"),
        ExploreTile(title: "Weekend Camp", subtitle: "86 looks outside", imageName: "wexlo_explore_weekend_camp", route: "camping")
    ]

    private var allRecommendations: [ExploreRecommendation] {
        let store = WexloLocalContentStore.shared
        return store.posts.compactMap { post in
            guard let author = store.user(for: post.authorID) else { return nil }
            return ExploreRecommendation(
                postID: post.id,
                authorID: post.authorID,
                title: post.title,
                author: author.name,
                styleTag: post.styleTag,
                context: post.setting,
                imageName: post.mediaAssetName ?? "wexlo_outfit_detail_cover",
                mediaFileName: post.mediaFileName,
                mediaKind: post.mediaKind,
                mediaStorage: post.mediaStorage
            )
        }
    }

    private let filters = ["Gorpcore", "City Outdoor", "Techwear", "Minimal Outdoor"]
    private var selectedFilter = 0
    private let loadingOverlay = WexloLoadingOverlay()
    private var isSaving = false

    private var filteredRecommendations: [ExploreRecommendation] {
        guard filters.indices.contains(selectedFilter) else { return [] }
        let blockedAuthorIDs: Set<String>
        if case .authenticated(let accountID) = WexloSessionStore.shared.current {
            blockedAuthorIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
        } else {
            blockedAuthorIDs = []
        }
        return allRecommendations.filter {
            $0.styleTag == filters[selectedFilter] &&
            !blockedAuthorIDs.contains($0.authorID)
        }
    }

    init() {
        super.init(headerStyle: .brand, layout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ExploreHeroCell.self, forCellWithReuseIdentifier: ExploreHeroCell.reuseIdentifier)
        collectionView.register(ExploreCategoryCell.self, forCellWithReuseIdentifier: ExploreCategoryCell.reuseIdentifier)
        collectionView.register(ExploreRecommendationCell.self, forCellWithReuseIdentifier: ExploreRecommendationCell.reuseIdentifier)
        collectionView.register(ExploreSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ExploreSectionHeaderView.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.showsVerticalScrollIndicator = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadSections(IndexSet(integer: 3))
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 4 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return categories.count
        case 2: return themes.count
        default: return filteredRecommendations.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreHeroCell.reuseIdentifier, for: indexPath) as! ExploreHeroCell
            cell.onSearch = { [weak self] in self?.showSearch() }
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreCategoryCell.reuseIdentifier, for: indexPath) as! ExploreCategoryCell
            cell.configure(with: categories[indexPath.item])
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreCategoryCell.reuseIdentifier, for: indexPath) as! ExploreCategoryCell
            cell.configure(with: themes[indexPath.item])
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreRecommendationCell.reuseIdentifier, for: indexPath) as! ExploreRecommendationCell
            let recommendations = filteredRecommendations
            guard recommendations.indices.contains(indexPath.item) else { return cell }
            let recommendation = recommendations[indexPath.item]
            cell.configure(with: recommendation)
            cell.onBreakdown = { [weak self] in
                self?.showRecommendationDetails(recommendation, scrollToBreakdown: true)
            }
            cell.onSave = { [weak self] in self?.saveRecommendation() }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            let recommendations = filteredRecommendations
            guard recommendations.indices.contains(indexPath.item) else { return }
            showRecommendationDetails(recommendations[indexPath.item])
            return
        }
        guard indexPath.section == 1 || indexPath.section == 2 else { return }
        let tile = indexPath.section == 1 ? categories[indexPath.item] : themes[indexPath.item]
        navigationController?.pushViewController(Self.destination(for: tile.route), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ExploreSectionHeaderView.reuseIdentifier, for: indexPath) as! ExploreSectionHeaderView
        switch indexPath.section {
        case 1:
            header.configure(title: "Browse categories", trailing: "")
        case 2:
            header.configure(title: "Trending themes", trailing: "Updated this week")
        default:
            header.configure(
                title: "Recommended looks",
                trailing: "",
                filters: filters,
                selectedIndex: selectedFilter
            ) { [weak self] index in
                self?.selectedFilter = index
                self?.collectionView.reloadSections(IndexSet(integer: 3))
            }
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        section == 3 ? CGSize(width: collectionView.bounds.width, height: 106) : (section == 0 ? .zero : CGSize(width: collectionView.bounds.width, height: 58))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return UIEdgeInsets(top: 18, left: 20, bottom: 22, right: 20)
        case 1: return UIEdgeInsets(top: 0, left: 20, bottom: 22, right: 20)
        case 2: return UIEdgeInsets(top: 0, left: 20, bottom: 22, right: 20)
        default: return UIEdgeInsets(top: 0, left: 20, bottom: 28, right: 20)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        section == 1 ? 8 : 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        section == 1 ? 8 : 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentWidth = collectionView.bounds.width - 40
        switch indexPath.section {
        case 0: return CGSize(width: contentWidth, height: 188)
        case 1:
            let width = (contentWidth - 16) / 3
            return CGSize(width: width, height: width * 199 / 220)
        case 2:
            let width = (contentWidth - 12) / 2
            return CGSize(width: width, height: width * 208 / 335)
        default: return CGSize(width: contentWidth, height: 166)
        }
    }

    private func showSearch() {
        navigationController?.pushViewController(ExploreSearchViewController(), animated: true)
    }

    private func showRecommendationDetails(
        _ recommendation: ExploreRecommendation,
        scrollToBreakdown: Bool = false
    ) {
        guard let postID = recommendation.postID,
              let controller = OutfitDetailViewController(
                postID: postID,
                scrollToBreakdown: scrollToBreakdown
              ) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func saveRecommendation() {
        guard !isSaving else { return }
        isSaving = true
        loadingOverlay.show(in: view)
        completeWexloLoading(loadingOverlay) { [weak self] in
            guard let self else { return }
            isSaving = false
            showWexloToast("Saved to your looks.")
        }
    }

    static func destination(for route: String) -> UIViewController {
        switch route {
        case "jackets", "pants", "shoes", "bags", "fleece", "accessories":
            return JacketsViewController(route: route)
        case "camping": return CampingViewController()
        default: return RainyDayViewController()
        }
    }
}

private final class ExploreHeroCell: UICollectionViewCell {
    static let reuseIdentifier = "ExploreHeroCell"
    var onSearch: (() -> Void)?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let searchButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = WexloTheme.font(size: 34, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.text = "Explore"
        subtitleLabel.font = WexloTheme.font(size: 15)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 2
        subtitleLabel.text = "Discover outdoor inspiration by style, piece, and setting."

        searchButton.backgroundColor = WexloTheme.surface
        searchButton.layer.cornerRadius = 20
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = WexloTheme.hairline.cgColor
        searchButton.contentHorizontalAlignment = .left
        searchButton.titleLabel?.font = WexloTheme.font(size: 14)
        searchButton.setTitle("Search styles, pieces, people, or brands", for: .normal)
        searchButton.setTitleColor(WexloTheme.secondaryText, for: .normal)
        searchButton.setImage(UIImage(named: "wexlo_explore_search"), for: .normal)
        searchButton.tintColor = WexloTheme.secondaryText
        searchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 10)
        searchButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 8)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, searchButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func searchTapped() { onSearch?() }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private class ExploreCategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "ExploreCategoryCell"
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlay)
        titleLabel.font = WexloTheme.font(size: 15, weight: .bold)
        titleLabel.textColor = .white
        subtitleLabel.font = WexloTheme.font(size: 10)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labels)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), overlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), overlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor), overlay.heightAnchor.constraint(equalToConstant: 50),
            labels.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10), labels.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6), labels.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9)
        ])
    }

    func configure(with tile: ExploreTile) {
        imageView.image = UIImage(named: tile.imageName)
        titleLabel.text = tile.title
        subtitleLabel.text = tile.subtitle
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private final class ExploreRecommendationCell: UICollectionViewCell {
    static let reuseIdentifier = "ExploreRecommendationCell"
    var onBreakdown: (() -> Void)?
    var onSave: (() -> Void)?
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let contextLabel = UILabel()
    private let breakdownButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var representedMediaKey: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        representedMediaKey = nil
        imageView.image = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.surface
        contentView.layer.cornerRadius = 22
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        titleLabel.font = WexloTheme.font(size: 14, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.numberOfLines = 2
        authorLabel.font = WexloTheme.font(size: 11)
        authorLabel.textColor = WexloTheme.secondaryText
        contextLabel.font = WexloTheme.font(size: 11)
        contextLabel.textColor = WexloTheme.secondaryText
        let details = UIStackView(arrangedSubviews: [titleLabel, authorLabel, contextLabel])
        details.axis = .vertical
        details.spacing = 3
        details.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(details)

        styleButton(breakdownButton, title: "Breakdown", filled: true)
        breakdownButton.addTarget(self, action: #selector(breakdownTapped), for: .touchUpInside)
        styleButton(saveButton, title: "Save", filled: false)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [breakdownButton, saveButton])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actions)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12), imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12), imageView.widthAnchor.constraint(equalToConstant: 106),
            details.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12), details.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12), details.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            actions.leadingAnchor.constraint(equalTo: details.leadingAnchor), actions.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12), actions.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
            breakdownButton.heightAnchor.constraint(equalToConstant: 34), saveButton.heightAnchor.constraint(equalToConstant: 34), breakdownButton.widthAnchor.constraint(equalToConstant: 124), saveButton.widthAnchor.constraint(equalToConstant: 64)
        ])
    }

    private func styleButton(_ button: UIButton, title: String, filled: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 12, weight: .semibold)
        button.layer.cornerRadius = 17
        if filled {
            let gradient = GradientView(frame: .zero)
            gradient.isUserInteractionEnabled = false
            gradient.layer.cornerRadius = 17
            gradient.clipsToBounds = true
            button.insertSubview(gradient, at: 0)
            gradient.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                gradient.leadingAnchor.constraint(equalTo: button.leadingAnchor), gradient.trailingAnchor.constraint(equalTo: button.trailingAnchor), gradient.topAnchor.constraint(equalTo: button.topAnchor), gradient.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
            button.clipsToBounds = true
            button.setTitleColor(WexloTheme.primaryText, for: .normal)
        } else {
            button.backgroundColor = WexloTheme.surface
            button.layer.borderWidth = 1
            button.layer.borderColor = WexloTheme.hairline.cgColor
            button.setTitleColor(WexloTheme.primaryText, for: .normal)
        }
    }

    func configure(with recommendation: ExploreRecommendation) {
        titleLabel.text = recommendation.title
        authorLabel.text = "\(recommendation.author) · \(recommendation.styleTag)"
        contextLabel.text = recommendation.context

        let mediaKey = recommendation.mediaFileName
        representedMediaKey = mediaKey

        if recommendation.mediaKind == .image,
           recommendation.mediaStorage == .local,
           let mediaURL = WexloLocalContentStore.shared.mediaURL(for: recommendation.mediaFileName),
           let image = UIImage(contentsOfFile: mediaURL.path) {
            // User-published photo post: show the actual cover from local storage.
            imageView.image = image
        } else if recommendation.mediaKind == .video {
            // Video post: show the first frame as the cover.
            imageView.image = croppedImage(named: recommendation.imageName)
            let mediaKey = recommendation.mediaFileName
            WexloVideoMedia.loadFirstFrame(
                for: recommendation.mediaFileName,
                storage: recommendation.mediaStorage
            ) { [weak self] frame in
                guard let self,
                      representedMediaKey == mediaKey,
                      let frame else { return }
                imageView.image = frame
            }
        } else {
            imageView.image = croppedImage(named: recommendation.imageName)
        }
    }

    private func croppedImage(named name: String) -> UIImage? {
        guard let image = UIImage(named: name),
              name == "wexlo_home_feed_commute",
              let source = image.cgImage else {
            return UIImage(named: name)
        }
        let cropHeight = Int(CGFloat(source.height) * 0.78)
        let cropRect = CGRect(x: 0, y: 0, width: source.width, height: cropHeight)
        guard let croppedSource = source.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: croppedSource, scale: image.scale, orientation: image.imageOrientation)
    }

    @objc private func breakdownTapped() { onBreakdown?() }
    @objc private func saveTapped() { onSave?() }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private final class ExploreSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "ExploreSectionHeaderView"
    private let titleLabel = UILabel()
    private let trailingLabel = UILabel()
    private let filterScrollView = UIScrollView()
    private let filterStack = UIStackView()
    private var filterLayoutConstraints: [NSLayoutConstraint] = []
    private var onFilterSelected: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = WexloTheme.font(size: 23, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        trailingLabel.font = WexloTheme.font(size: 12, weight: .semibold)
        trailingLabel.textColor = WexloTheme.secondaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        addSubview(trailingLabel)
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.addSubview(filterStack)
        addSubview(filterScrollView)
        filterLayoutConstraints = [
            filterScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            filterScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            filterScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            filterScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 50)
        ]
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -8),
            trailingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            trailingLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.leadingAnchor), filterStack.trailingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.trailingAnchor), filterStack.topAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.topAnchor), filterStack.bottomAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.bottomAnchor, constant: -16), filterStack.heightAnchor.constraint(equalToConstant: 34)
        ])
        NSLayoutConstraint.activate(filterLayoutConstraints)
    }

    func configure(title: String, trailing: String, filters: [String] = [], selectedIndex: Int = 0, onFilterSelected: ((Int) -> Void)? = nil) {
        titleLabel.text = title
        trailingLabel.text = trailing
        self.onFilterSelected = onFilterSelected
        filterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filterScrollView.isHidden = filters.isEmpty
        if filters.isEmpty {
            NSLayoutConstraint.deactivate(filterLayoutConstraints)
        } else {
            NSLayoutConstraint.activate(filterLayoutConstraints)
        }
        for (index, filter) in filters.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(filter, for: .normal)
            button.titleLabel?.font = WexloTheme.font(size: 12, weight: .semibold)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            button.backgroundColor = index == selectedIndex ? WexloTheme.primaryText : WexloTheme.surface
            button.setTitleColor(index == selectedIndex ? .white : WexloTheme.primaryText, for: .normal)
            button.layer.borderWidth = index == selectedIndex ? 0 : 1
            button.layer.borderColor = WexloTheme.hairline.cgColor
            button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            filterStack.addArrangedSubview(button)
        }
    }

    @objc private func filterTapped(_ sender: UIButton) { onFilterSelected?(sender.tag) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

private final class ExploreSearchViewController: WexloCollectionPageViewController,
    UISearchBarDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    private let searchBar = UISearchBar()
    private let resultsCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let emptyStateLabel = UILabel()
    private var searchResults: [HomeFeedItem] = []
    private var hasSearched = false
    private var isTogglingSave = false

    init() {
        super.init(headerStyle: .titled("Search"), layout: UICollectionViewFlowLayout())
        if let layout = resultsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 16
        }
        searchBar.delegate = self
        searchBar.placeholder = "Search posts"
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isHidden = true
        resultsCollectionView.dataSource = self
        resultsCollectionView.delegate = self
        resultsCollectionView.register(
            HomeFeedCell.self,
            forCellWithReuseIdentifier: HomeFeedCell.reuseIdentifier
        )
        resultsCollectionView.backgroundColor = WexloTheme.background
        resultsCollectionView.showsVerticalScrollIndicator = false
        resultsCollectionView.alwaysBounceVertical = true
        resultsCollectionView.keyboardDismissMode = .interactive

        emptyStateLabel.textColor = WexloTheme.secondaryText
        emptyStateLabel.font = WexloTheme.font(size: 16, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        resultsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(resultsCollectionView)
        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: navigationHeader.bottomAnchor, constant: 6),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            searchBar.heightAnchor.constraint(equalToConstant: 48),
            resultsCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            resultsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emptyStateLabel.centerYAnchor.constraint(equalTo: resultsCollectionView.centerYAnchor)
        ])
        let dismissGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard hasSearched else { return }
        hasSearched = false
        searchResults = []
        resultsCollectionView.isHidden = true
        emptyStateLabel.isHidden = true
        resultsCollectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch()
    }

    private func performSearch() {
        hasSearched = true
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchResults = WexloLocalContentStore.shared.searchPosts(matching: query)
        resultsCollectionView.isHidden = false
        emptyStateLabel.text = query.isEmpty ? "Enter a search term." : "No posts found."
        emptyStateLabel.isHidden = !searchResults.isEmpty
        resultsCollectionView.reloadData()
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        searchResults.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeFeedCell.reuseIdentifier,
            for: indexPath
        ) as! HomeFeedCell
        guard searchResults.indices.contains(indexPath.item) else { return cell }
        let item = searchResults[indexPath.item]
        cell.configure(with: item)
        cell.onSave = { [weak self] in
            self?.toggleSave(for: item)
        }
        return cell
    }

    private func toggleSave(for item: HomeFeedItem) {
        guard !isTogglingSave, let postID = item.postID else { return }
        isTogglingSave = true
        let nextSavedState = !item.isSaved
        guard WexloSavedOutfitStore.shared.setSaved(
            nextSavedState,
            postID: postID,
            userID: Self.saveUserID
        ) else {
            isTogglingSave = false
            showWexloToast("Outfit could not be saved.")
            return
        }
        isTogglingSave = false
        performSearch()
        showWexloToast(
            nextSavedState ? "Saved to your looks." : "Removed from your saved looks."
        )
    }

    private static var saveUserID: String {
        switch WexloSessionStore.shared.current {
        case .authenticated(let userID):
            return userID
        case .guest:
            return "guest"
        case .absent:
            return "anonymous"
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 16, left: 16, bottom: 28, right: 16)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width - 32,
            height: HomeFeedCell.preferredHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard searchResults.indices.contains(indexPath.item),
              let postID = searchResults[indexPath.item].postID,
              let controller = OutfitDetailViewController(postID: postID) else {
            showWexloToast("This outfit is unavailable.")
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}
