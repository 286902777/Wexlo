import UIKit

final class RechargeCoinsViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let collectionView: UICollectionView
    private let confirmButton = RechargeConfirmButton(type: .custom)
    private let sessionStore = WexloSessionStore.shared
    private let coinStore = WexloCoinStore.shared
    private let purchaseService = WexloPurchaseService.shared
    private let loadingOverlay = WexloLoadingOverlay()
    private var packages: [WexloRechargePackage] = []
    private var selectedPackageID: String?
    private var currentBalance = 0
    private var isPurchasing = false

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 20, right: 15)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(coinsDidChange(_:)),
            name: .wexloCoinsDidChange,
            object: nil
        )
        loadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        loadData()
    }

    private func configureView() {
        view.backgroundColor = WexloTheme.background

        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        titleLabel.text = "Recharge Coins"
        titleLabel.font = WexloTheme.font(size: 34, weight: .black)
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        subtitleLabel.text = "Choose a bundle for outfit breakdowns and AI Stylist prompts."
        subtitleLabel.font = WexloTheme.font(size: 14, weight: .regular)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.8

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            RechargeCollectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: RechargeCollectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            RechargePackageCell.self,
            forCellWithReuseIdentifier: RechargePackageCell.reuseIdentifier
        )

        confirmButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        confirmButton.titleLabel?.font = WexloTheme.font(size: 20, weight: .bold)
        confirmButton.accessibilityIdentifier = "recharge.confirmButton"
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)

        [backButton, titleLabel, subtitleLabel, collectionView, confirmButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),

            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 17),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -8),

            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            confirmButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func loadData() {
        packages = WexloRechargeCatalog.packages
        if selectedPackageID == nil ||
            !packages.contains(where: { $0.productID == selectedPackageID }) {
            selectedPackageID = packages.first?.productID
        }
        currentBalance = coinStore.balance(for: currentAccountID)
        collectionView.reloadData()
        updateConfirmButton()
    }

    private var currentAccountID: String {
        if case .authenticated(let userID) = sessionStore.current {
            return userID
        }
        return "guest"
    }

    private func updateConfirmButton() {
        guard let selectedPackage = packages.first(where: { $0.productID == selectedPackageID }) else {
            confirmButton.setTitle("Confirm recharge", for: .normal)
            return
        }
        confirmButton.setTitle(
            "Confirm recharge · \(selectedPackage.price)",
            for: .normal
        )
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapConfirm() {
        guard !isPurchasing else { return }
        guard case .authenticated(let userID) = sessionStore.current else {
            let dialog = SignInRequiredViewController()
            dialog.onConfirm = { [weak self] in
                self?.pushSignIn()
            }
            present(dialog, animated: true)
            return
        }
        guard let selectedPackage = packages.first(where: { $0.productID == selectedPackageID }) else {
            showWexloToast("Choose a recharge package first.")
            return
        }

        isPurchasing = true
        confirmButton.isEnabled = false
        loadingOverlay.show(in: view)
        Task { [weak self] in
            guard let self else { return }
            let result = await purchaseService.purchase(package: selectedPackage, for: userID)
            handlePurchaseResult(result)
        }
    }

    private func handlePurchaseResult(_ result: WexloPurchaseResult) {
        isPurchasing = false
        confirmButton.isEnabled = true
        loadingOverlay.hide()

        switch result {
        case .success:
            loadData()
            showWexloToast("Coins added successfully.")
        case .pending:
            showWexloToast("Purchase is pending approval.")
        case .cancelled:
            break
        case .failed:
            showWexloToast("Purchase is unavailable right now.")
        }
    }

    private func pushSignIn() {
        let controller = SignInViewController()
        controller.onAuthenticated = { [weak self] userID in
            guard let self else { return }
            if WexloAccountStore.shared.profile(for: userID) == nil {
                let profile = CompleteProfileViewController(userID: userID)
                profile.onProfileSaved = {
                    self.sessionStore.saveAuthenticatedSession(
                        userID: userID,
                        toastMessage: "Profile saved successfully."
                    )
                }
                self.navigationController?.pushViewController(profile, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak profile] in
                    profile?.showWexloToast("Signed in successfully.")
                }
            } else {
                self.sessionStore.saveAuthenticatedSession(
                    userID: userID,
                    toastMessage: "Signed in successfully."
                )
            }
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func coinsDidChange(_ notification: Notification) {
        guard let userID = notification.userInfo?["userID"] as? String,
              userID == currentAccountID else { return }
        loadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        packages.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RechargePackageCell.reuseIdentifier,
            for: indexPath
        ) as! RechargePackageCell
        let package = packages[indexPath.item]
        cell.configure(
            amount: package.amount,
            price: package.price,
            isSelected: package.productID == selectedPackageID
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: RechargeCollectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (header as? RechargeCollectionHeaderView)?.configure(balance: currentBalance)
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 202)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = (collectionView.bounds.width - 30 - 10) / 2
        return CGSize(width: max(width, 0), height: 104)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPackageID = packages[indexPath.item].productID
        collectionView.reloadData()
        updateConfirmButton()
    }
}

private final class RechargeCollectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "RechargeCollectionHeaderView"

    private let bannerImageView = UIImageView(
        image: UIImage(named: "wexlo_recharge_balance_banner")
    )
    private let balanceValueLabel = UILabel()
    private let sectionTitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = .clear

        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.layer.cornerRadius = 24
        bannerImageView.layer.masksToBounds = true

        balanceValueLabel.text = ""
        balanceValueLabel.font = WexloTheme.font(size: 32, weight: .black)
        balanceValueLabel.textColor = .white
        balanceValueLabel.adjustsFontSizeToFitWidth = true
        balanceValueLabel.minimumScaleFactor = 0.8

        sectionTitleLabel.text = "Choose a bundle"
        sectionTitleLabel.font = WexloTheme.font(size: 24, weight: .black)
        sectionTitleLabel.textColor = WexloTheme.primaryText

        [
            bannerImageView,
            balanceValueLabel,
            sectionTitleLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            bannerImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            bannerImageView.heightAnchor.constraint(equalToConstant: 145),

            balanceValueLabel.leadingAnchor.constraint(equalTo: bannerImageView.leadingAnchor, constant: 19),
            balanceValueLabel.centerYAnchor.constraint(equalTo: bannerImageView.centerYAnchor, constant: -4),
            balanceValueLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: bannerImageView.centerXAnchor,
                constant: 35
            ),

            sectionTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            sectionTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    func configure(balance: Int) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let value = formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"
        balanceValueLabel.text = "\(value) Coins"
    }
}

private final class RechargePackageCell: UICollectionViewCell {
    static let reuseIdentifier = "RechargePackageCell"

    private let amountLabel = UILabel()
    private let coinsLabel = UILabel()
    private let priceLabel = UILabel()
    private let coinImageView = UIImageView(image: UIImage(named: "wexlo_recharge_coin"))
    private let selectedBadge = GradientView()
    private let selectedLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = .clear
        contentView.layer.cornerRadius = 22
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = WexloTheme.hairline.cgColor
        contentView.clipsToBounds = true

        amountLabel.font = WexloTheme.font(size: 26, weight: .black)
        amountLabel.textColor = WexloTheme.primaryText

        coinsLabel.font = WexloTheme.font(size: 15, weight: .regular)
        coinsLabel.textColor = WexloTheme.secondaryText

        priceLabel.font = WexloTheme.font(size: 18, weight: .bold)
        priceLabel.textColor = WexloTheme.primaryText

        coinImageView.contentMode = .scaleAspectFit
        coinImageView.isUserInteractionEnabled = false

        selectedBadge.layer.cornerRadius = 18
        selectedBadge.colors = [WexloTheme.coral, WexloTheme.pink]

        selectedLabel.text = "Selected"
        selectedLabel.font = WexloTheme.font(size: 14, weight: .bold)
        selectedLabel.textColor = WexloTheme.primaryText
        selectedLabel.textAlignment = .center

        [amountLabel, coinsLabel, priceLabel, coinImageView, selectedBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        selectedLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedBadge.addSubview(selectedLabel)

        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

            coinsLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            coinsLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 2),

            priceLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),

            coinImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 6),
            coinImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            coinImageView.widthAnchor.constraint(equalToConstant: 82),
            coinImageView.heightAnchor.constraint(equalToConstant: 82),

            selectedBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            selectedBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            selectedBadge.widthAnchor.constraint(equalToConstant: 82),
            selectedBadge.heightAnchor.constraint(equalToConstant: 30),

            selectedLabel.leadingAnchor.constraint(equalTo: selectedBadge.leadingAnchor),
            selectedLabel.trailingAnchor.constraint(equalTo: selectedBadge.trailingAnchor),
            selectedLabel.topAnchor.constraint(equalTo: selectedBadge.topAnchor),
            selectedLabel.bottomAnchor.constraint(equalTo: selectedBadge.bottomAnchor)
        ])
    }

    func configure(amount: String, price: String, isSelected: Bool) {
        amountLabel.text = amount
        coinsLabel.text = "Coins"
        priceLabel.text = price
        selectedBadge.isHidden = !isSelected
        contentView.backgroundColor = isSelected
            ? UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1)
            : WexloTheme.surface
        contentView.layer.borderWidth = isSelected ? 2.5 : 1
        contentView.layer.borderColor = isSelected
            ? WexloTheme.primaryText.cgColor
            : WexloTheme.hairline.cgColor
    }
}

private final class RechargeConfirmButton: UIButton {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            WexloTheme.coral.cgColor,
            WexloTheme.pink.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 7)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.cornerRadius = bounds.height / 2
    }
}
