import UIKit

final class SplashViewController: UIViewController {
    var onFinished: (() -> Void)?
    private let splashImageView = UIImageView(image: UIImage(named: "sb"))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        splashImageView.contentMode = .scaleAspectFill
        splashImageView.clipsToBounds = true
        splashImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splashImageView)

        NSLayoutConstraint.activate([
            splashImageView.topAnchor.constraint(equalTo: view.topAnchor),
            splashImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splashImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in self?.onFinished?() }
    }
}
