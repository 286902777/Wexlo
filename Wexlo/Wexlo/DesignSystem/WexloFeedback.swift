import UIKit

final class WexloLoadingOverlay: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.12)
        isUserInteractionEnabled = true
        activityIndicator.color = WexloTheme.primaryText
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func show(in parent: UIView) {
        guard superview == nil else { return }
        translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            topAnchor.constraint(equalTo: parent.topAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
        activityIndicator.startAnimating()
    }

    func hide() {
        activityIndicator.stopAnimating()
        removeFromSuperview()
    }
}

enum WexloOperationFeedback {
    static let loadingDuration: TimeInterval = 1.5
}

final class WexloToastLabel: UILabel {
    static let horizontalTextInset: CGFloat = 12

    override func textRect(
        forBounds bounds: CGRect,
        limitedToNumberOfLines numberOfLines: Int
    ) -> CGRect {
        let insetBounds = bounds.insetBy(dx: Self.horizontalTextInset, dy: 0)
        let textRect = super.textRect(
            forBounds: insetBounds,
            limitedToNumberOfLines: numberOfLines
        )
        return CGRect(
            x: textRect.minX - Self.horizontalTextInset,
            y: textRect.minY,
            width: textRect.width + Self.horizontalTextInset * 2,
            height: textRect.height
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(
            in: rect.insetBy(dx: Self.horizontalTextInset, dy: 0)
        )
    }
}

extension UIViewController {
    func showWexloToast(_ message: String) {
        let label = WexloToastLabel()
        label.text = message
        label.textColor = .white
        label.backgroundColor = WexloTheme.tabBar.withAlphaComponent(0.92)
        label.font = WexloTheme.font(size: 13, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -12),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -24),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])
        UIView.animate(withDuration: 0.2, delay: 1.5, options: []) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }

    func completeWexloLoading(
        _ overlay: WexloLoadingOverlay,
        toast message: String? = nil,
        after delay: TimeInterval = WexloOperationFeedback.loadingDuration,
        completion: (() -> Void)? = nil
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak overlay] in
            overlay?.hide()
            if let message, let self {
                self.showWexloToast(message)
            }
            completion?()
        }
    }

    func presentWexloSignInRequired() {
        guard case .guest = WexloSessionStore.shared.current else { return }
        guard presentedViewController == nil ||
            !(presentedViewController is SignInRequiredViewController) else {
            return
        }

        let dialog = SignInRequiredViewController()
        dialog.onConfirm = {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .wexloSignInRequested,
                    object: nil
                )
            }
        }
        present(dialog, animated: true)
    }
}

final class WexloGuestInteractionShieldView: UIView {
    weak var presenter: UIViewController?
    var underlyingViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else {
            return nil
        }

        for underlyingView in underlyingViews.reversed() {
            let pointInUnderlyingView = convert(point, to: underlyingView)
            guard let target = underlyingView.hitTest(pointInUnderlyingView, with: event) else {
                continue
            }
            return isProtectedInteraction(target) ? self : nil
        }
        return nil
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        presenter?.presentWexloSignInRequired()
    }

    private func isProtectedInteraction(_ view: UIView) -> Bool {
        var current: UIView? = view
        while let candidate = current {
            if candidate is UIControl ||
                candidate is UICollectionViewCell ||
                candidate is UITableViewCell ||
                !(candidate.gestureRecognizers?.isEmpty ?? true) {
                return true
            }
            current = candidate.superview
        }
        return false
    }
}
