import UIKit

final class WexloNavigationHeader: UIView {
    enum Style {
        case brand
        case titled(String)
    }

    var onBack: (() -> Void)?
    var onLeadingAction: (() -> Void)?
    var onTrailingAction: (() -> Void)?

    private let logoView = UIImageView(image: UIImage(named: "wexlo_profile_avatar"))
    private let titleLabel = UILabel()
    private let leadingButton = UIButton(type: .custom)
    private let trailingButton = UIButton(type: .system)
    private let separatorView = UIView()
    private var customTrailingButtons: [UIButton] = []

    init(style: Style, leadingSymbol: String? = nil, trailingSymbol: String? = nil) {
        super.init(frame: .zero)
        configure(style: style, leadingSymbol: leadingSymbol, trailingSymbol: trailingSymbol)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure(style: Style, leadingSymbol: String?, trailingSymbol: String?) {
        backgroundColor = WexloTheme.background

        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 19, weight: .bold)

        logoView.layer.cornerRadius = 10
        logoView.layer.masksToBounds = true
        logoView.contentMode = .scaleAspectFill

        [leadingButton, trailingButton].forEach {
            $0.tintColor = WexloTheme.primaryText
            $0.backgroundColor = WexloTheme.surface
            $0.layer.cornerRadius = 16
            $0.layer.borderWidth = 1
            $0.layer.borderColor = WexloTheme.hairline.cgColor
        }

        leadingButton.addTarget(self, action: #selector(didTapLeading), for: .touchUpInside)
        trailingButton.addTarget(self, action: #selector(didTapTrailing), for: .touchUpInside)
        separatorView.backgroundColor = WexloTheme.hairline.withAlphaComponent(0.7)

        switch style {
        case .brand:
            titleLabel.text = "Wexlo"
            leadingButton.isHidden = leadingSymbol == nil
        case .titled(let title):
            titleLabel.text = title
            if let leadingSymbol {
                leadingButton.setImage(UIImage(systemName: leadingSymbol), for: .normal)
            } else {
                leadingButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
                leadingButton.backgroundColor = .clear
                leadingButton.layer.borderWidth = 0
            }
        }

        if let leadingSymbol {
            leadingButton.setImage(UIImage(systemName: leadingSymbol), for: .normal)
        }
        if let trailingSymbol {
            trailingButton.setImage(UIImage(systemName: trailingSymbol), for: .normal)
        }
        trailingButton.isHidden = trailingSymbol == nil

        [logoView, titleLabel, leadingButton, trailingButton, separatorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let showsBrand = {
            if case .brand = style { return true }
            return false
        }()
        logoView.isHidden = !showsBrand

        let leadingButtonVerticalConstraint: NSLayoutConstraint
        if case .titled = style {
            leadingButtonVerticalConstraint = leadingButton.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 18
            )
        } else {
            leadingButtonVerticalConstraint = leadingButton.centerYAnchor.constraint(
                equalTo: centerYAnchor
            )
        }
        let leadingButtonInset: CGFloat = {
            if case .titled = style { return 15 }
            return 20
        }()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 24),
            logoView.heightAnchor.constraint(equalToConstant: 24),

            leadingButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingButtonInset),
            leadingButtonVerticalConstraint,
            leadingButton.widthAnchor.constraint(equalToConstant: 35),
            leadingButton.heightAnchor.constraint(equalToConstant: 35),

            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            showsBrand
                ? titleLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 7)
                : titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            trailingButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            trailingButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingButton.widthAnchor.constraint(equalToConstant: 32),
            trailingButton.heightAnchor.constraint(equalToConstant: 32),

            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    @objc private func didTapLeading() {
        if onLeadingAction != nil {
            onLeadingAction?()
        } else {
            onBack?()
        }
    }

    @objc private func didTapTrailing() {
        onTrailingAction?()
    }

    func setTrailingImageNames(_ imageNames: [String], actions: [() -> Void]) {
        customTrailingButtons.forEach { $0.removeFromSuperview() }
        customTrailingButtons.removeAll()
        trailingButton.isHidden = true

        for (index, imageName) in imageNames.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.adjustsImageWhenHighlighted = false
            let isAssetImage = UIImage(named: imageName) != nil
            let image = UIImage(named: imageName)
                ?? UIImage(
                    systemName: imageName,
                    withConfiguration: UIImage.SymbolConfiguration(
                        pointSize: 16,
                        weight: .medium
                    )
                )
            button.setImage(image, for: .normal)
            button.tintColor = WexloTheme.primaryText
            button.backgroundColor = WexloTheme.surface
            button.layer.cornerRadius = 17.5
            button.layer.borderWidth = isAssetImage ? 0 : 1
            button.layer.borderColor = WexloTheme.hairline.cgColor
            button.imageView?.contentMode = .scaleAspectFit
            button.addAction(
                UIAction { [weak self] _ in
                    guard actions.indices.contains(index) else { return }
                    actions[index]()
                    self?.customTrailingButtons[index].isSelected = false
                },
                for: .touchUpInside
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            customTrailingButtons.append(button)

            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 35),
                button.heightAnchor.constraint(equalToConstant: 35)
            ])
        }

        for index in customTrailingButtons.indices {
            if index == customTrailingButtons.count - 1 {
                customTrailingButtons[index].trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -18
                ).isActive = true
            } else {
                customTrailingButtons[index].trailingAnchor.constraint(
                    equalTo: customTrailingButtons[index + 1].leadingAnchor,
                    constant: -10
                ).isActive = true
            }
        }
    }
}
