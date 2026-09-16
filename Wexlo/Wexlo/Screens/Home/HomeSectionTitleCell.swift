import UIKit

final class HomeSectionTitleCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeSectionTitleCell"

    private let titleLabel = UILabel()
    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.background

        titleLabel.font = WexloTheme.font(size: 25, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        countLabel.font = WexloTheme.font(size: 15, weight: .regular)
        countLabel.textColor = WexloTheme.secondaryText

        [titleLabel, countLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(title: String, count: String) {
        titleLabel.text = title
        countLabel.text = count
    }
}
