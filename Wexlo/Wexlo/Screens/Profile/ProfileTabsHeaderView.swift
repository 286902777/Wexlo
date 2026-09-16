import UIKit

final class ProfileTabsHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "ProfileTabsHeaderView"

    var onSelect: ((Int) -> Void)?
    private let titles = ["My outfits", "My saved"]
    private var buttons: [UIButton] = []
    private let indicator = GradientView()
    private var indicatorCenterConstraints: [NSLayoutConstraint] = []

    var selectedIndex = 0 {
        didSet {
            updateSelection()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = WexloTheme.background

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            buttons.append(button)
        }

        let separator = UIView()
        separator.backgroundColor = WexloTheme.hairline
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        indicator.layer.cornerRadius = 3
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        for (index, button) in buttons.enumerated() {
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
                button.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
            ])
            if index == 0 {
                button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: buttons[index - 1].trailingAnchor).isActive = true
            }
        }

        indicatorCenterConstraints = buttons.map {
            indicator.centerXAnchor.constraint(equalTo: $0.centerXAnchor)
        }
        indicatorCenterConstraints[0].isActive = true
        NSLayoutConstraint.activate([
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            indicator.widthAnchor.constraint(equalToConstant: 58),
            indicator.heightAnchor.constraint(equalToConstant: 4),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        updateSelection()
    }

    private func updateSelection() {
        guard !buttons.isEmpty else { return }
        for (index, button) in buttons.enumerated() {
            let selected = index == selectedIndex
            button.setTitleColor(
                selected ? WexloTheme.primaryText : WexloTheme.secondaryText,
                for: .normal
            )
            button.titleLabel?.font = WexloTheme.font(size: 18, weight: selected ? .bold : .medium)
            indicatorCenterConstraints[index].isActive = selected
        }
    }

    @objc private func didTapButton(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        onSelect?(sender.tag)
    }
}
