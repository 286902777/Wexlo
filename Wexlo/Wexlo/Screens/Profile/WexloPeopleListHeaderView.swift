import UIKit

final class WexloPeopleListHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "WexloPeopleListHeaderView"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var subtitleHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = WexloTheme.background

        titleLabel.font = WexloTheme.font(size: 24, weight: .black)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        subtitleLabel.font = WexloTheme.font(size: 12, weight: .regular)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping

        [titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        subtitleHeightConstraint = subtitleLabel.heightAnchor.constraint(equalToConstant: 20)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            titleLabel.heightAnchor.constraint(equalToConstant: 34),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 45),
            subtitleHeightConstraint,
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    static func height(for width: CGFloat, subtitle: String) -> CGFloat {
        subtitle.contains("\n") ? 93 : 79
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleHeightConstraint.constant = subtitle.contains("\n") ? 38 : 20
    }
}
