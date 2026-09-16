import UIKit

final class HomeTabsHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "HomeTabsHeaderView"

    var onSelect: ((Int) -> Void)?

    private let titles = ["For You", "Trending", "Following"]
    private var buttons: [UIButton] = []
    private let indicator = GradientView()
    private var indicatorLeadingConstraint: NSLayoutConstraint?

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

    override func layoutSubviews() {
        super.layoutSubviews()
        updateIndicatorPosition()
    }

    private func configure() {
        backgroundColor = WexloTheme.background

        let separator = UIView()
        separator.backgroundColor = WexloTheme.hairline
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            buttons.append(button)
        }

        indicator.layer.cornerRadius = 3
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        for (index, button) in buttons.enumerated() {
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
                button.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / 3)
            ])
            if index == 0 {
                button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: buttons[index - 1].trailingAnchor).isActive = true
            }
        }

        indicatorLeadingConstraint = indicator.leadingAnchor.constraint(equalTo: leadingAnchor)
        guard let indicatorLeadingConstraint else { return }
        NSLayoutConstraint.activate([
            indicatorLeadingConstraint,
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            indicator.widthAnchor.constraint(equalToConstant: 48),
            indicator.heightAnchor.constraint(equalToConstant: 4),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        updateSelection()
    }

    private func updateIndicatorPosition() {
        let segmentWidth = bounds.width / CGFloat(max(buttons.count, 1))
        let indicatorWidth: CGFloat = 48
        indicatorLeadingConstraint?.constant =
            CGFloat(selectedIndex) * segmentWidth + (segmentWidth - indicatorWidth) / 2
    }

    private func updateSelection() {
        guard !buttons.isEmpty else { return }
        let safeIndex = min(max(selectedIndex, 0), buttons.count - 1)
        if safeIndex != selectedIndex {
            selectedIndex = safeIndex
            return
        }

        for (index, button) in buttons.enumerated() {
            let selected = index == selectedIndex
            button.setTitleColor(
                selected ? WexloTheme.primaryText : WexloTheme.secondaryText,
                for: .normal
            )
            button.titleLabel?.font = WexloTheme.font(size: 20, weight: selected ? .bold : .medium)
        }
        updateIndicatorPosition()
    }

    @objc private func didTapButton(_ sender: UIButton) {
        guard selectedIndex != sender.tag else { return }
        selectedIndex = sender.tag
        onSelect?(sender.tag)
    }
}
