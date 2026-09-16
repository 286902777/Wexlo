import UIKit

struct WexloBlueprintItem {
    enum Style {
        case hero
        case card
        case compact
        case person
        case incoming
        case outgoing
        case field
        case destructive
        case sectionHeader
    }

    let title: String
    let subtitle: String
    let symbol: String
    let style: Style
    let route: String?

    init(
        _ title: String,
        _ subtitle: String = "",
        symbol: String = "circle.fill",
        style: Style = .card,
        route: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.style = style
        self.route = route
    }
}

class WexloBlueprintPageViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let items: [WexloBlueprintItem]
    var onRoute: ((String) -> Void)?

    init(
        title: String,
        items: [WexloBlueprintItem],
        trailingSymbol: String? = "ellipsis"
    ) {
        self.items = items
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 28, right: 20)
        super.init(
            headerStyle: .titled(title),
            trailingSymbol: trailingSymbol,
            layout: layout
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.contentInset.bottom = 28
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            WexloBlueprintCell.self,
            forCellWithReuseIdentifier: WexloBlueprintCell.reuseIdentifier
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WexloBlueprintCell.reuseIdentifier,
            for: indexPath
        ) as! WexloBlueprintCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let item = items[indexPath.item]
        let height: CGFloat
        switch item.style {
        case .hero: height = 188
        case .field: height = 76
        case .incoming, .outgoing: height = 92
        case .person: height = 72
        case .compact: height = 58
        case .card, .destructive: height = 104
        case .sectionHeader: height = 58
        }
        return CGSize(width: collectionView.bounds.width - 40, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let route = items[indexPath.item].route else { return }
        onRoute?(route)
    }
}

final class WexloBlueprintCell: UICollectionViewCell {
    static let reuseIdentifier = "WexloBlueprintCell"

    private let iconBackground = GradientView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sectionTitleLabel = UILabel()
    private let sectionIndicator = GradientView()
    private let disclosureView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        contentView.clipsToBounds = true

        iconBackground.layer.cornerRadius = 15
        iconView.tintColor = WexloTheme.primaryText
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = WexloTheme.font(size: 16, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.numberOfLines = 2
        subtitleLabel.font = WexloTheme.font(size: 11, weight: .regular)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 3
        sectionTitleLabel.font = WexloTheme.font(size: 18, weight: .bold)
        sectionTitleLabel.textColor = WexloTheme.primaryText
        sectionTitleLabel.textAlignment = .center
        sectionIndicator.colors = [
            WexloTheme.pink,
            WexloTheme.coral
        ]
        sectionIndicator.layer.cornerRadius = 3
        sectionIndicator.clipsToBounds = true
        sectionTitleLabel.isHidden = true
        sectionIndicator.isHidden = true
        disclosureView.tintColor = WexloTheme.secondaryText.withAlphaComponent(0.45)

        [iconBackground, titleLabel, subtitleLabel, sectionTitleLabel,
         sectionIndicator, disclosureView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 19),
            iconView.heightAnchor.constraint(equalToConstant: 19),

            titleLabel.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: disclosureView.leadingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            subtitleLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 3),
            disclosureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            disclosureView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disclosureView.widthAnchor.constraint(equalToConstant: 8),

            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sectionTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -5),
            sectionIndicator.centerXAnchor.constraint(equalTo: sectionTitleLabel.centerXAnchor),
            sectionIndicator.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 5),
            sectionIndicator.widthAnchor.constraint(equalToConstant: 58),
            sectionIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(with item: WexloBlueprintItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        iconView.image = UIImage(systemName: item.symbol)
        disclosureView.isHidden = item.route == nil
        iconBackground.isHidden = false
        sectionTitleLabel.isHidden = true
        sectionIndicator.isHidden = true
        contentView.layer.borderWidth = 1
        titleLabel.textAlignment = .left

        switch item.style {
        case .hero:
            contentView.backgroundColor = WexloTheme.tabBar
            titleLabel.textColor = .white
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.64)
        case .outgoing:
            contentView.backgroundColor = WexloTheme.tabBar
            titleLabel.textColor = .white
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        case .incoming:
            contentView.backgroundColor = .white
            titleLabel.textColor = WexloTheme.primaryText
            subtitleLabel.textColor = WexloTheme.secondaryText
        case .field:
            contentView.backgroundColor = .white
            titleLabel.textColor = WexloTheme.secondaryText
            subtitleLabel.textColor = WexloTheme.primaryText
            iconBackground.isHidden = true
            titleLabel.transform = CGAffineTransform(translationX: -54, y: 0)
            subtitleLabel.transform = CGAffineTransform(translationX: -54, y: 0)
        case .destructive:
            contentView.backgroundColor = .white
            titleLabel.textColor = UIColor(red: 0.80, green: 0.22, blue: 0.30, alpha: 1)
            subtitleLabel.textColor = WexloTheme.secondaryText
        case .card, .compact, .person:
            contentView.backgroundColor = .white
            titleLabel.textColor = WexloTheme.primaryText
            subtitleLabel.textColor = WexloTheme.secondaryText
        case .sectionHeader:
            contentView.backgroundColor = WexloTheme.background
            contentView.layer.borderWidth = 0
            iconBackground.isHidden = true
            titleLabel.isHidden = true
            subtitleLabel.isHidden = true
            disclosureView.isHidden = true
            sectionTitleLabel.isHidden = false
            sectionIndicator.isHidden = false
            sectionTitleLabel.text = item.title
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.transform = .identity
        subtitleLabel.transform = .identity
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        sectionTitleLabel.isHidden = true
        sectionIndicator.isHidden = true
        iconBackground.isHidden = false
        disclosureView.isHidden = false
        contentView.layer.borderWidth = 1
    }
}
