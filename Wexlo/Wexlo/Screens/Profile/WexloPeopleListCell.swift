import UIKit

final class WexloPeopleListCell: UICollectionViewCell {
    enum Position {
        case first
        case middle
        case last
        case single
    }

    static let reuseIdentifier = "WexloPeopleListCell"

    var onAction: (() -> Void)?

    private let cardView = UIView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionGradientView = GradientView()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        cardView.backgroundColor = UIColor(red: 1, green: 1, blue: 253.0 / 255.0, alpha: 1)
        cardView.layer.borderWidth = 0.67
        cardView.layer.borderColor = UIColor(
            red: 231.0 / 255.0,
            green: 231.0 / 255.0,
            blue: 230.0 / 255.0,
            alpha: 1
        ).cgColor
        cardView.clipsToBounds = true

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 17

        nameLabel.font = WexloTheme.font(size: 13, weight: .bold)
        nameLabel.textColor = WexloTheme.primaryText
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8

        handleLabel.font = WexloTheme.font(size: 10, weight: .regular)
        handleLabel.textColor = WexloTheme.secondaryText

        detailLabel.font = WexloTheme.font(size: 9, weight: .bold)
        detailLabel.textColor = UIColor(red: 0.62, green: 0.36, blue: 0.21, alpha: 1)
        detailLabel.adjustsFontSizeToFitWidth = true
        detailLabel.minimumScaleFactor = 0.72
        detailLabel.lineBreakMode = .byTruncatingTail

        actionGradientView.colors = [
            UIColor(red: 252.0 / 255.0, green: 171.0 / 255.0, blue: 116.0 / 255.0, alpha: 1),
            UIColor(red: 234.0 / 255.0, green: 164.0 / 255.0, blue: 184.0 / 255.0, alpha: 1)
        ]
        actionGradientView.layer.cornerRadius = 16
        actionGradientView.isUserInteractionEnabled = true

        actionButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        actionButton.titleLabel?.font = WexloTheme.font(size: 10, weight: .bold)
        actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)

        [cardView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        [avatarView, nameLabel, handleLabel, detailLabel, actionGradientView, actionButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 13),
            avatarView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 9),
            nameLabel.trailingAnchor.constraint(equalTo: actionGradientView.leadingAnchor, constant: -10),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            nameLabel.heightAnchor.constraint(equalToConstant: 22),

            handleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            handleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            handleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 0),
            handleLabel.heightAnchor.constraint(equalToConstant: 18),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: handleLabel.bottomAnchor, constant: 0),
            detailLabel.heightAnchor.constraint(equalToConstant: 18),

            actionGradientView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            actionGradientView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            actionGradientView.widthAnchor.constraint(equalToConstant: 78),
            actionGradientView.heightAnchor.constraint(equalToConstant: 32),

            actionButton.leadingAnchor.constraint(equalTo: actionGradientView.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: actionGradientView.trailingAnchor),
            actionButton.topAnchor.constraint(equalTo: actionGradientView.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: actionGradientView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(with item: WexloPeopleListItem, position: Position) {
        avatarView.image = UIImage(named: item.avatarAssetName)
        nameLabel.text = item.name
        handleLabel.text = item.handle
        detailLabel.text = item.detail
        actionButton.setTitle(item.actionTitle, for: .normal)

        switch position {
        case .first:
            cardView.layer.cornerRadius = 26
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .last:
            cardView.layer.cornerRadius = 26
            cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .single:
            cardView.layer.cornerRadius = 26
            cardView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        case .middle:
            cardView.layer.cornerRadius = 0
            cardView.layer.maskedCorners = []
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAction = nil
        avatarView.image = nil
        nameLabel.text = nil
        handleLabel.text = nil
        detailLabel.text = nil
        actionButton.setTitle(nil, for: .normal)
    }

    @objc private func didTapAction() {
        onAction?()
    }
}
