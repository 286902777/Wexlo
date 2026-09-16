import UIKit

protocol FloatingTabBarDelegate: AnyObject {
    func floatingTabBar(_ tabBar: FloatingTabBar, didSelect index: Int)
}

final class FloatingTabBar: UIView {
    weak var delegate: FloatingTabBarDelegate?

    private let unselectedAssets = [
        "wexlo_tab_home",
        "wexlo_tab_explore",
        "wexlo_tab_post",
        "wexlo_tab_messages",
        "wexlo_tab_profile"
    ]
    private let selectedAssets = [
        "wexlo_tab_home_selected",
        "wexlo_tab_explore_selected",
        "wexlo_tab_post_selected",
        "wexlo_tab_messages_selected",
        "wexlo_tab_profile_selected"
    ]
    private var buttons: [UIButton] = []

    var selectedIndex = 0 {
        didSet {
            guard oldValue != selectedIndex else { return }
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
        backgroundColor = WexloTheme.tabBarSurface
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = WexloTheme.tabBarBorder.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)

        for index in unselectedAssets.indices {
            let button = UIButton(type: .custom)
            button.tag = index
            button.adjustsImageWhenHighlighted = false
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            buttons.append(button)
        }

        for (index, button) in buttons.enumerated() {
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
                button.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2)
            ])
            if index == 0 {
                button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: buttons[index - 1].trailingAnchor).isActive = true
            }
        }
        buttons.last?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        updateSelection()
    }

    private func updateSelection() {
        guard !buttons.isEmpty else { return }
        let safeIndex = min(max(selectedIndex, 0), buttons.count - 1)
        if safeIndex != selectedIndex {
            selectedIndex = safeIndex
            return
        }

        for index in buttons.indices {
            let assetName = index == selectedIndex ? selectedAssets[index] : unselectedAssets[index]
            buttons[index].setImage(UIImage(named: assetName), for: .normal)
            buttons[index].accessibilityLabel = index == selectedIndex ? "Selected tab" : "Tab"
        }
    }

    @objc private func didTapButton(_ sender: UIButton) {
        delegate?.floatingTabBar(self, didSelect: sender.tag)
    }
}
