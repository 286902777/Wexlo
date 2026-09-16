import UIKit

enum WexloTheme {
    static let background = UIColor(
        red: 255.0 / 255.0,
        green: 254.0 / 255.0,
        blue: 250.0 / 255.0,
        alpha: 1
    )
    static let surface = UIColor.white
    static let primaryText = UIColor(red: 0.075, green: 0.071, blue: 0.067, alpha: 1)
    static let secondaryText = UIColor(red: 0.46, green: 0.44, blue: 0.41, alpha: 1)
    static let hairline = UIColor(red: 0.91, green: 0.89, blue: 0.86, alpha: 1)
    static let tabBar = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    static let coral = UIColor(red: 1.0, green: 0.62, blue: 0.39, alpha: 1)
    static let pink = UIColor(red: 0.92, green: 0.49, blue: 0.70, alpha: 1)
    static let tabBarSurface = UIColor(red: 0.165, green: 0.161, blue: 0.161, alpha: 1)
    static let tabBarBorder = UIColor(red: 0.298, green: 0.294, blue: 0.294, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    var colors: [UIColor] = [WexloTheme.coral, WexloTheme.pink] {
        didSet { updateColors() }
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func updateColors() {
        gradientLayer.colors = colors.map(\.cgColor)
    }
}
