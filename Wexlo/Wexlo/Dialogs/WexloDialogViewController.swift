import UIKit

class WexloDialogViewController: UIViewController {
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    private let dialogTitle: String
    private let message: String
    private let confirmTitle: String
    private let showsCancel: Bool
    private let dimView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let confirmBackground = GradientView()
    private let confirmButton = UIButton(type: .system)

    init(title: String, message: String, confirmTitle: String, showsCancel: Bool = true) {
        dialogTitle = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.showsCancel = showsCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 24
        titleLabel.text = dialogTitle
        titleLabel.font = WexloTheme.font(size: 22, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        messageLabel.text = message
        messageLabel.font = WexloTheme.font(size: 13)
        messageLabel.textColor = WexloTheme.secondaryText
        messageLabel.numberOfLines = 0
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        cancelButton.layer.cornerRadius = 13
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = WexloTheme.hairline.cgColor
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        confirmBackground.layer.cornerRadius = 13
        confirmBackground.clipsToBounds = true
        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        confirmButton.titleLabel?.font = WexloTheme.font(size: 13, weight: .semibold)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)

        [dimView, cardView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        [titleLabel, messageLabel, cancelButton, confirmBackground].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; cardView.addSubview($0) }
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmBackground.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor), dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor), dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 22),
            cancelButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 46),
            confirmBackground.topAnchor.constraint(equalTo: cancelButton.topAnchor),
            confirmBackground.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            confirmBackground.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),
            confirmBackground.leadingAnchor.constraint(equalTo: showsCancel ? cancelButton.trailingAnchor : cardView.leadingAnchor, constant: showsCancel ? 10 : 22),
            showsCancel ? cancelButton.widthAnchor.constraint(equalTo: confirmBackground.widthAnchor) : cancelButton.widthAnchor.constraint(equalToConstant: 0),
            confirmButton.topAnchor.constraint(equalTo: confirmBackground.topAnchor),
            confirmButton.leadingAnchor.constraint(equalTo: confirmBackground.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: confirmBackground.trailingAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: confirmBackground.bottomAnchor)
        ])
        cancelButton.isHidden = !showsCancel
    }

    @objc private func didTapCancel() { dismiss(animated: true); onCancel?() }
    @objc private func didTapConfirm() { dismiss(animated: true); onConfirm?() }
}
