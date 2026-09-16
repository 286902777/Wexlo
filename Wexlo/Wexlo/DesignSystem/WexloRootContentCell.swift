import UIKit

struct WexloRootContentItem {
    let title: String
    let subtitle: String
    let symbol: String
    let emphasized: Bool
    let route: String?

    init(title: String, subtitle: String, symbol: String, emphasized: Bool, route: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.emphasized = emphasized
        self.route = route
    }
}

final class WexloRootContentCell: UICollectionViewCell {
    static let reuseIdentifier = "WexloRootContentCell"

    private let symbolContainer = GradientView()
    private let symbolImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.surface
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.035
        contentView.layer.shadowRadius = 10
        contentView.layer.shadowOffset = CGSize(width: 0, height: 5)

        symbolContainer.layer.cornerRadius = 16
        symbolContainer.layer.masksToBounds = true
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.tintColor = WexloTheme.primaryText

        titleLabel.font = WexloTheme.font(size: 18, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.numberOfLines = 2
        subtitleLabel.font = WexloTheme.font(size: 12, weight: .regular)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 3

        [symbolContainer, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolContainer.addSubview(symbolImageView)

        NSLayoutConstraint.activate([
            symbolContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            symbolContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            symbolContainer.widthAnchor.constraint(equalToConstant: 48),
            symbolContainer.heightAnchor.constraint(equalToConstant: 48),
            symbolImageView.centerXAnchor.constraint(equalTo: symbolContainer.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: symbolContainer.centerYAnchor),
            symbolImageView.widthAnchor.constraint(equalToConstant: 21),
            symbolImageView.heightAnchor.constraint(equalToConstant: 21),

            titleLabel.leadingAnchor.constraint(equalTo: symbolContainer.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(with item: WexloRootContentItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        symbolImageView.image = UIImage(systemName: item.symbol)
        if item.emphasized {
            contentView.backgroundColor = UIColor(red: 0.10, green: 0.09, blue: 0.10, alpha: 1)
            titleLabel.textColor = .white
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.64)
        } else {
            contentView.backgroundColor = WexloTheme.surface
            titleLabel.textColor = WexloTheme.primaryText
            subtitleLabel.textColor = WexloTheme.secondaryText
        }
    }
}
