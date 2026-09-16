import UIKit

struct HomeScene {
    let title: String
    let subtitle: String
    let assetName: String
    let route: String
}

final class HomeDiscoveryHeaderView: UICollectionReusableView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    static let reuseIdentifier = "HomeDiscoveryHeaderView"
    private static let fallbackCellReuseIdentifier = "HomeSceneFallbackCell"
    static let scenes = [
        HomeScene(
            title: "Commute",
            subtitle: "City Outdoor",
            assetName: "wexlo_home_scene_commute",
            route: "commute"
        ),
        HomeScene(
            title: "Rainy Day",
            subtitle: "Weather Ready",
            assetName: "wexlo_home_scene_rain",
            route: "rainy"
        ),
        HomeScene(
            title: "Camping",
            subtitle: "Weekend Outside",
            assetName: "wexlo_home_scene_camping",
            route: "camping"
        ),
        HomeScene(
            title: "Travel",
            subtitle: "On the Move",
            assetName: "wexlo_scene_travel",
            route: "travel"
        )
    ]

    var onSceneSelected: ((String) -> Void)?

    private let heroImageView = UIImageView(image: UIImage(named: "wexlo_home_ai_stylist"))
    private let sceneTitleLabel = UILabel()
    private let sceneCollectionView: UICollectionView

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = .zero
        sceneCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    static func height(for width: CGFloat) -> CGFloat {
        let contentWidth = max(width - 40, 1)
        let heroHeight = contentWidth * 755 / 1124
        return 20 + heroHeight + 26 + 34 + 12 + 74 + 20
    }

    private func configure() {
        backgroundColor = WexloTheme.background

        heroImageView.contentMode = .scaleAspectFit
        heroImageView.clipsToBounds = true
        heroImageView.isUserInteractionEnabled = true
        let heroTap = UITapGestureRecognizer(target: self, action: #selector(didTapHero))
        heroImageView.addGestureRecognizer(heroTap)

        sceneTitleLabel.text = "Find inspiration by scene"
        sceneTitleLabel.font = WexloTheme.font(size: 23, weight: .bold)
        sceneTitleLabel.textColor = WexloTheme.primaryText

        sceneCollectionView.backgroundColor = .clear
        sceneCollectionView.showsHorizontalScrollIndicator = false
        sceneCollectionView.alwaysBounceHorizontal = true
        sceneCollectionView.dataSource = self
        sceneCollectionView.delegate = self
        sceneCollectionView.register(
            HomeSceneCell.self,
            forCellWithReuseIdentifier: HomeSceneCell.reuseIdentifier
        )
        sceneCollectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: Self.fallbackCellReuseIdentifier
        )

        [heroImageView, sceneTitleLabel, sceneCollectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 755 / 1124),

            sceneTitleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 26),
            sceneTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            sceneTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            sceneCollectionView.topAnchor.constraint(equalTo: sceneTitleLabel.bottomAnchor, constant: 12),
            sceneCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            sceneCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sceneCollectionView.heightAnchor.constraint(equalToConstant: 74),
            sceneCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    @objc private func didTapHero() {
        onSceneSelected?("ai")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Self.scenes.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard Self.scenes.indices.contains(indexPath.item) else {
            return fallbackCell(in: collectionView, at: indexPath)
        }
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeSceneCell.reuseIdentifier,
            for: indexPath
        ) as? HomeSceneCell else {
            return fallbackCell(in: collectionView, at: indexPath)
        }
        cell.configure(with: Self.scenes[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 186, height: 72)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard Self.scenes.indices.contains(indexPath.item) else { return }
        onSceneSelected?(Self.scenes[indexPath.item].route)
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
}

final class HomeSceneCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeSceneCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.surface
        contentView.layer.cornerRadius = 20
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.06
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)

        iconView.contentMode = .scaleAspectFit
        titleLabel.font = WexloTheme.font(size: 16, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        subtitleLabel.font = WexloTheme.font(size: 12, weight: .regular)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.8

        [iconView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 47),
            iconView.heightAnchor.constraint(equalToConstant: 47),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(with scene: HomeScene) {
        iconView.image = UIImage(named: scene.assetName)
        titleLabel.text = scene.title
        subtitleLabel.text = scene.subtitle
    }
}
