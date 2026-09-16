import UIKit

final class ProfileHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "ProfileHeaderView"

    var onRecharge: (() -> Void)?
    var onFollowingTap: (() -> Void)?
    var onFollowersTap: (() -> Void)?

    private let avatarView = UIImageView(image: UIImage(named: "wexlo_profile_avatar"))
    private let statsStack = UIStackView()
    private let outfitsStatView = UIView()
    private let followingStatView = UIView()
    private let followersStatView = UIView()
    private let outfitsValueLabel = UILabel()
    private let outfitsTitleLabel = UILabel()
    private let followingValueLabel = UILabel()
    private let followingTitleLabel = UILabel()
    private let followersValueLabel = UILabel()
    private let followersTitleLabel = UILabel()
    private let followingButton = UIButton(type: .custom)
    private let followersButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let coinsImageView = UIImageView(image: UIImage(named: "wexlo_profile_coins_banner"))
    private let coinsBalanceLabel = UILabel()
    private let coinsValueLabel = UILabel()
    private let rechargeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    static func height(for width: CGFloat) -> CGFloat {
        let contentWidth = max(width - 40, 1)
        let bannerHeight = contentWidth * 363 / 1044
        return 24 + 96 + 28 + 42 + 10 + 52 + 20 + bannerHeight + 22
    }

    private func configure() {
        backgroundColor = WexloTheme.background

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 48
        avatarView.layer.borderWidth = 1
        avatarView.layer.borderColor = WexloTheme.hairline.cgColor

        configureStat(outfitsValueLabel, outfitsTitleLabel, value: "0", title: "Outfits")
        configureStat(followingValueLabel, followingTitleLabel, value: "0", title: "Following")
        configureStat(followersValueLabel, followersTitleLabel, value: "0", title: "Followers")
        configureStatsLayout()

        nameLabel.text = "Guest"
        nameLabel.font = WexloTheme.font(size: 31, weight: .bold)
        nameLabel.textColor = WexloTheme.primaryText

        bioLabel.text = "Sign in to add your profile details."
        bioLabel.font = WexloTheme.font(size: 17, weight: .regular)
        bioLabel.textColor = WexloTheme.secondaryText
        bioLabel.numberOfLines = 2

        coinsImageView.contentMode = .scaleAspectFill
        coinsImageView.clipsToBounds = true
        coinsImageView.layer.cornerRadius = 22
        coinsImageView.isUserInteractionEnabled = true
        coinsImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapRecharge))
        )

        coinsBalanceLabel.text = "Coins balance"
        coinsBalanceLabel.font = WexloTheme.font(size: 14, weight: .bold)
        coinsBalanceLabel.textColor = .white

        coinsValueLabel.text = "0"
        coinsValueLabel.font = WexloTheme.font(size: 33, weight: .black)
        coinsValueLabel.textColor = WexloTheme.pink

        rechargeButton.accessibilityLabel = "Recharge coins"
        rechargeButton.addTarget(self, action: #selector(didTapRecharge), for: .touchUpInside)
        followingButton.accessibilityLabel = "Following"
        followingButton.addTarget(self, action: #selector(didTapFollowing), for: .touchUpInside)
        followersButton.accessibilityLabel = "Followers"
        followersButton.addTarget(self, action: #selector(didTapFollowers), for: .touchUpInside)

        [avatarView, statsStack, nameLabel, bioLabel, coinsImageView, coinsBalanceLabel,
         coinsValueLabel, rechargeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            avatarView.widthAnchor.constraint(equalToConstant: 96),
            avatarView.heightAnchor.constraint(equalToConstant: 96),

            statsStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            statsStack.topAnchor.constraint(equalTo: avatarView.topAnchor),
            statsStack.heightAnchor.constraint(equalTo: avatarView.heightAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 26),

            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),

            coinsImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            coinsImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            coinsImageView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 20),
            coinsImageView.heightAnchor.constraint(equalTo: coinsImageView.widthAnchor, multiplier: 363 / 1044),

            coinsBalanceLabel.leadingAnchor.constraint(equalTo: coinsImageView.leadingAnchor, constant: 22),
            coinsBalanceLabel.topAnchor.constraint(equalTo: coinsImageView.topAnchor, constant: 22),
            coinsValueLabel.leadingAnchor.constraint(equalTo: coinsImageView.leadingAnchor, constant: 48),
            coinsValueLabel.topAnchor.constraint(equalTo: coinsBalanceLabel.bottomAnchor, constant: 7),

            rechargeButton.trailingAnchor.constraint(equalTo: coinsImageView.trailingAnchor, constant: -44),
            rechargeButton.centerYAnchor.constraint(equalTo: coinsImageView.centerYAnchor, constant: 2),
            rechargeButton.widthAnchor.constraint(equalToConstant: 138),
            rechargeButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func configureStatsLayout() {
        statsStack.axis = .horizontal
        statsStack.alignment = .fill
        statsStack.distribution = .fillEqually
        statsStack.spacing = 0

        [outfitsStatView, followingStatView, followersStatView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            statsStack.addArrangedSubview($0)
        }

        configureStatView(
            outfitsStatView,
            valueLabel: outfitsValueLabel,
            titleLabel: outfitsTitleLabel
        )
        configureStatView(
            followingStatView,
            valueLabel: followingValueLabel,
            titleLabel: followingTitleLabel
        )
        configureStatView(
            followersStatView,
            valueLabel: followersValueLabel,
            titleLabel: followersTitleLabel
        )

        followingButton.translatesAutoresizingMaskIntoConstraints = false
        followingStatView.addSubview(followingButton)
        followersButton.translatesAutoresizingMaskIntoConstraints = false
        followersStatView.addSubview(followersButton)

        NSLayoutConstraint.activate([
            followingButton.leadingAnchor.constraint(equalTo: followingStatView.leadingAnchor),
            followingButton.trailingAnchor.constraint(equalTo: followingStatView.trailingAnchor),
            followingButton.topAnchor.constraint(equalTo: followingStatView.topAnchor),
            followingButton.bottomAnchor.constraint(equalTo: followingStatView.bottomAnchor),
            followersButton.leadingAnchor.constraint(equalTo: followersStatView.leadingAnchor),
            followersButton.trailingAnchor.constraint(equalTo: followersStatView.trailingAnchor),
            followersButton.topAnchor.constraint(equalTo: followersStatView.topAnchor),
            followersButton.bottomAnchor.constraint(equalTo: followersStatView.bottomAnchor)
        ])
    }

    private func configureStatView(
        _ container: UIView,
        valueLabel: UILabel,
        titleLabel: UILabel
    ) {
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 32),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 7),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
    }

    private func configureStat(
        _ valueLabel: UILabel,
        _ titleLabel: UILabel,
        value: String,
        title: String
    ) {
        valueLabel.text = value
        valueLabel.font = WexloTheme.font(size: 26, weight: .bold)
        valueLabel.textColor = WexloTheme.primaryText
        valueLabel.textAlignment = .center

        titleLabel.text = title
        titleLabel.font = WexloTheme.font(size: 15, weight: .regular)
        titleLabel.textColor = WexloTheme.secondaryText
        titleLabel.textAlignment = .center
    }

    func configure(
        balance: Int,
        profile: WexloUserProfile?,
        outfitCount: Int,
        followingCount: Int,
        followerCount: Int
    ) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        coinsValueLabel.text = formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"
        nameLabel.text = profile?.nickname ?? "Guest"
        let bio = profile?.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        bioLabel.text = bio.isEmpty ? "Sign in to add your profile details." : bio
        let fallbackAvatar = UIImage(named: "wexlo_profile_avatar")
        if let avatarData = profile?.avatarData,
           let avatarImage = UIImage(data: avatarData) {
            avatarView.image = avatarImage
        } else if let avatarAssetName = profile?.avatarAssetName,
                  let avatarImage = UIImage(named: avatarAssetName) {
            avatarView.image = avatarImage
        } else {
            avatarView.image = fallbackAvatar
        }
        outfitsValueLabel.text = "\(outfitCount)"
        followingValueLabel.text = "\(followingCount)"
        followersValueLabel.text = "\(followerCount)"
    }

    @objc private func didTapRecharge() {
        onRecharge?()
    }

    @objc private func didTapFollowing() {
        onFollowingTap?()
    }

    @objc private func didTapFollowers() {
        onFollowersTap?()
    }
}
