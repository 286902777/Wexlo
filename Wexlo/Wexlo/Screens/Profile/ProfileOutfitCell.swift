import UIKit

struct ProfileOutfitItem {
    let postID: String
    let title: String
    let mediaAssetName: String?
    let mediaFileName: String
    let mediaKind: WexloMediaKind
    let mediaStorage: WexloMediaStorage
    let backgroundColor: UIColor
    let symbol: String
}

final class ProfileOutfitCell: UICollectionViewCell {
    static let reuseIdentifier = "ProfileOutfitCell"

    private let mediaView = UIImageView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let gradientView = GradientView()
    private var representedMediaKey: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 22
        contentView.clipsToBounds = true

        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = UIColor.white.withAlphaComponent(0.9)
        titleLabel.font = WexloTheme.font(size: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        gradientView.colors = [
            UIColor.black.withAlphaComponent(0.02),
            UIColor.black.withAlphaComponent(0.65)
        ]
        gradientView.isUserInteractionEnabled = false

        [mediaView, gradientView, symbolView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.55),
            symbolView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            symbolView.widthAnchor.constraint(equalToConstant: 58),
            symbolView.heightAnchor.constraint(equalToConstant: 58),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedMediaKey = nil
        mediaView.image = nil
    }

    func configure(with item: ProfileOutfitItem) {
        representedMediaKey = item.postID
        mediaView.backgroundColor = item.backgroundColor
        mediaView.image = item.mediaAssetName.flatMap { UIImage(named: $0) }
        if item.mediaStorage == .local,
           item.mediaKind == .image,
           let mediaURL = WexloLocalContentStore.shared.mediaURL(for: item.mediaFileName) {
            mediaView.image = UIImage(contentsOfFile: mediaURL.path)
        }
        if item.mediaKind == .video {
            WexloVideoMedia.loadFirstFrame(
                for: item.mediaFileName,
                storage: item.mediaStorage
            ) { [weak self] image in
                guard let self, representedMediaKey == item.postID else { return }
                mediaView.image = image ?? mediaView.image
            }
        }
        symbolView.image = UIImage(systemName: item.symbol)
        symbolView.isHidden = item.mediaAssetName != nil || item.mediaStorage == .local
        titleLabel.text = item.title
    }
}
