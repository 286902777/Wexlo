import UIKit

final class HomeSectionTitleCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeSectionTitleCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = WexloTheme.background

        titleLabel.font = WexloTheme.font(size: 25, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText


        [titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(title: String, count: String) {
        titleLabel.text = title
    }
}
