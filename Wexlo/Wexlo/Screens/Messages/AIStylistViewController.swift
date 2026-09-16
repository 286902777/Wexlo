import UIKit

final class AIStylistViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UITextFieldDelegate {

    private enum ChatItem {
        case incoming(String)
        case outgoing(String)
    }

    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let avatarView = UIImageView(image: UIImage(named: "wexlo_ai_stylist_avatar"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let fixedIntroView = UIView()
    private let fixedIntroMessageView = AIIncomingMessageView(frame: .zero)
    private let fixedPromptView = AIQuickPromptView(frame: .zero)
    private let collectionView: UICollectionView
    private let composerView = UIView()
    private let inputBackground = UIView()
    private let messageTextField = UITextField()
    private let sendButton = AIGradientButton(type: .custom)
    private var composerBottomConstraint: NSLayoutConstraint?
    private var fixedIntroMessageHeightConstraint: NSLayoutConstraint?
    private var isSending = false

    private var items: [ChatItem] = []

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 18, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        items = WexloSessionStore.shared.aiMessages(for: currentAccountID).map {
            $0.isAI ? .incoming($0.text) : .outgoing($0.text)
        }
        configureHeader()
        configureFixedIntro()
        configureMessages()
        configureComposer()
        configureKeyboardHandling()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let messageWidth = max(collectionView.bounds.width - 32, 1)
        let targetHeight = AIIncomingMessageView.height(
            for: "Hey Alex! I can help you build outfits, find the right layers, or plan a look for any scene.",
            width: messageWidth
        )
        if fixedIntroMessageHeightConstraint?.constant != targetHeight {
            fixedIntroMessageHeightConstraint?.constant = targetHeight
            view.layoutIfNeeded()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToLatest(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureHeader() {
        headerView.backgroundColor = WexloTheme.background

        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.backgroundColor = WexloTheme.surface
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = WexloTheme.hairline.cgColor
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true

        titleLabel.text = "AI Stylist"
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 21, weight: .bold)

        subtitleLabel.text = "Your personal outfit guide"
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.font = WexloTheme.font(size: 15)

        [backButton, avatarView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 62),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            avatarView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            avatarView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: avatarView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    private func configureFixedIntro() {
        fixedIntroView.backgroundColor = .clear
        fixedIntroMessageView.configure(
            text: "Hey Alex! I can help you build outfits, find the right layers, or plan a look for any scene."
        )
        fixedPromptView.onPromptSelected = { [weak self] prompt in
            self?.appendPrompt(prompt)
        }

        [fixedIntroMessageView, fixedPromptView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            fixedIntroView.addSubview($0)
        }
        fixedIntroView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fixedIntroView)

        fixedIntroMessageHeightConstraint = fixedIntroMessageView.heightAnchor.constraint(equalToConstant: 112)
        NSLayoutConstraint.activate([
            fixedIntroView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            fixedIntroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fixedIntroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            fixedIntroMessageView.topAnchor.constraint(equalTo: fixedIntroView.topAnchor),
            fixedIntroMessageView.leadingAnchor.constraint(equalTo: fixedIntroView.leadingAnchor, constant: 16),
            fixedIntroMessageView.trailingAnchor.constraint(equalTo: fixedIntroView.trailingAnchor, constant: -16),
            fixedIntroMessageHeightConstraint!,

            fixedPromptView.topAnchor.constraint(equalTo: fixedIntroMessageView.bottomAnchor, constant: 12),
            fixedPromptView.leadingAnchor.constraint(equalTo: fixedIntroView.leadingAnchor, constant: 44),
            fixedPromptView.trailingAnchor.constraint(equalTo: fixedIntroView.trailingAnchor, constant: -44),
            fixedPromptView.heightAnchor.constraint(equalToConstant: 72),
            fixedPromptView.bottomAnchor.constraint(equalTo: fixedIntroView.bottomAnchor, constant: -10)
        ])
    }

    private func configureMessages() {
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .interactive
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            AIIncomingMessageCell.self,
            forCellWithReuseIdentifier: AIIncomingMessageCell.reuseIdentifier
        )
        collectionView.register(
            AIOutgoingMessageCell.self,
            forCellWithReuseIdentifier: AIOutgoingMessageCell.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: fixedIntroView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    private func configureComposer() {
        composerView.backgroundColor = WexloTheme.tabBar
        composerView.layer.cornerRadius = 28
        composerView.layer.borderWidth = 1
        composerView.layer.borderColor = WexloTheme.tabBarBorder.cgColor
        composerView.layer.masksToBounds = true

        inputBackground.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        inputBackground.layer.cornerRadius = 22

        messageTextField.textColor = .white
        messageTextField.font = WexloTheme.font(size: 17)
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Ask your AI Stylist...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.62)]
        )
        messageTextField.borderStyle = .none
        messageTextField.addTarget(self, action: #selector(messageTextDidChange), for: .editingChanged)

        sendButton.setImage(UIImage(named: "wexlo_chat_send_message"), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.accessibilityLabel = "Send message"
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        [inputBackground, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            composerView.addSubview($0)
        }
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        inputBackground.addSubview(messageTextField)
        composerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composerView)

        composerBottomConstraint = composerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            composerView.heightAnchor.constraint(equalToConstant: 58),
            composerBottomConstraint!,

            inputBackground.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 16),
            inputBackground.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            inputBackground.heightAnchor.constraint(equalToConstant: 44),

            messageTextField.leadingAnchor.constraint(equalTo: inputBackground.leadingAnchor, constant: 16),
            messageTextField.trailingAnchor.constraint(equalTo: inputBackground.trailingAnchor, constant: -12),
            messageTextField.topAnchor.constraint(equalTo: inputBackground.topAnchor),
            messageTextField.bottomAnchor.constraint(equalTo: inputBackground.bottomAnchor),

            sendButton.leadingAnchor.constraint(equalTo: inputBackground.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            collectionView.bottomAnchor.constraint(equalTo: composerView.topAnchor, constant: -12)
        ])
        sendButton.alpha = 0.72
    }

    private func configureKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .incoming(let text):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AIIncomingMessageCell.reuseIdentifier,
                for: indexPath
            ) as! AIIncomingMessageCell
            cell.configure(text: text)
            return cell
        case .outgoing(let text):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AIOutgoingMessageCell.reuseIdentifier,
                for: indexPath
            ) as! AIOutgoingMessageCell
            cell.configure(text: text)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width - 32
        let height: CGFloat
        switch items[indexPath.item] {
        case .incoming(let text):
            height = AIIncomingMessageCell.height(for: text, width: width)
        case .outgoing(let text):
            height = AIOutgoingMessageCell.height(for: text, width: width)
        }
        return CGSize(width: width, height: height)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }

    @objc private func didTapBack() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapSend() {
        sendMessage(messageTextField.text ?? "")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func messageTextDidChange() {
        sendButton.alpha = messageTextField.text?.isEmpty == false ? 1 : 0.72
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let convertedFrame = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom)
        composerBottomConstraint?.constant = overlap > 0 ? -(overlap + 10) : 0

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        ) {
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.scrollToLatest(animated: false)
        }
    }

    private func appendPrompt(_ prompt: String) {
        sendMessage(prompt)
    }

    private func sendMessage(_ rawText: String) {
        guard !isSending else { return }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let accountID = currentAccountID else {
            showWexloToast("Please sign in to chat with AI Stylist.")
            return
        }
        guard WexloCoinStore.shared.balance(for: accountID) >= Self.messageCost else {
            showWexloToast("You need \(Self.messageCost) coins to continue chatting.")
            return
        }

        isSending = true
        view.endEditing(true)
        messageTextField.text = nil

        do {
            try WexloCoinStore.shared.spendCoins(Self.messageCost, for: accountID)
            let userMessage = WexloAIMessage(
                text: text,
                isAI: false,
                createdAt: Date()
            )
            guard WexloSessionStore.shared.appendAIMessage(userMessage, for: accountID) else {
                throw WexloAIChatError.storageFailure
            }
        } catch WexloCoinStoreError.insufficientBalance {
            isSending = false
            showWexloToast("You need \(Self.messageCost) coins to continue chatting.")
            return
        } catch {
            try? WexloCoinStore.shared.addCoins(Self.messageCost, for: accountID)
            isSending = false
            showWexloToast("Your message could not be sent right now.")
            return
        }

        items.append(.outgoing(text))
        collectionView.reloadData()
        scrollToLatest(animated: true)

        let reply = response(for: text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            let aiMessage = WexloAIMessage(
                text: reply,
                isAI: true,
                createdAt: Date()
            )
            guard WexloSessionStore.shared.appendAIMessage(aiMessage, for: accountID) else {
                self?.isSending = false
                self?.showWexloToast("The AI reply could not be saved.")
                return
            }
            guard let self else { return }
            self.items.append(.incoming(reply))
            self.collectionView.reloadData()
            self.scrollToLatest(animated: true)
            self.isSending = false
        }
    }

    private var currentAccountID: String? {
        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            return nil
        }
        return accountID
    }

    private func response(for text: String) -> String {
        if text.localizedCaseInsensitiveContains("rain") {
            return "Start with a breathable base, add a soft fleece, and finish with a light shell that can handle a passing shower."
        }
        if text.localizedCaseInsensitiveContains("weekend") || text.localizedCaseInsensitiveContains("camp") {
            return "Try a warm mid-layer, durable utility pants, and trail shoes. Keep one weatherproof layer close for the walk home."
        }
        return "I would keep the layers light and flexible: a breathable base, one warm mid-layer, and comfortable trail sneakers."
    }

    private func scrollToLatest(animated: Bool) {
        guard !items.isEmpty else { return }
        collectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: items.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    private static let messageCost = 5
}

private enum WexloAIChatError: Error {
    case storageFailure
}

private final class AIIncomingMessageView: UIView {
    private let avatarView = UIImageView(image: UIImage(named: "wexlo_ai_stylist_avatar"))
    private let bubbleView = UIView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 16
        avatarView.clipsToBounds = true

        bubbleView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        bubbleView.layer.cornerRadius = 23
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.15
        bubbleView.layer.shadowRadius = 14
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 6)

        textLabel.textColor = WexloTheme.primaryText
        textLabel.font = WexloTheme.font(size: 17)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping

        [avatarView, bubbleView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(textLabel)
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarView.bottomAnchor.constraint(equalTo: bottomAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),

            bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),

            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14)
        ])
    }

    func configure(text: String) {
        textLabel.text = text
    }

    static func height(for text: String, width: CGFloat) -> CGFloat {
        let bubbleWidth = max(160, width - 56)
        let contentWidth = bubbleWidth - 32
        let textHeight = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: WexloTheme.font(size: 17)],
            context: nil
        ).height
        return max(64, ceil(textHeight) + 28)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleView.layer.shadowPath = UIBezierPath(
            roundedRect: bubbleView.bounds,
            cornerRadius: 23
        ).cgPath
    }
}

private final class AIIncomingMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "AIIncomingMessageCell"

    private let avatarView = UIImageView(image: UIImage(named: "wexlo_ai_stylist_avatar"))
    private let bubbleView = UIView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 16
        avatarView.clipsToBounds = true

        bubbleView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        bubbleView.layer.cornerRadius = 23
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.15
        bubbleView.layer.shadowRadius = 14
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 6)

        textLabel.textColor = WexloTheme.primaryText
        textLabel.font = WexloTheme.font(size: 17)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping

        [avatarView, bubbleView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(textLabel)
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),

            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14)
        ])
    }

    func configure(text: String) {
        textLabel.text = text
    }

    static func height(for text: String, width: CGFloat) -> CGFloat {
        let bubbleWidth = max(160, width - 56)
        let contentWidth = bubbleWidth - 32
        let textHeight = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: WexloTheme.font(size: 17)],
            context: nil
        ).height
        return max(64, ceil(textHeight) + 28)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleView.layer.shadowPath = UIBezierPath(
            roundedRect: bubbleView.bounds,
            cornerRadius: 23
        ).cgPath
    }
}

private final class AIOutgoingMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "AIOutgoingMessageCell"

    private let bubbleView = UIView()
    private let textLabel = UILabel()
    private var bubbleWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.backgroundColor = WexloTheme.tabBar
        bubbleView.layer.cornerRadius = 23
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.13
        bubbleView.layer.shadowRadius = 14
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 6)

        textLabel.textColor = .white
        textLabel.font = WexloTheme.font(size: 17)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(textLabel)
        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: 260)

        NSLayoutConstraint.activate([
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bubbleWidthConstraint!,

            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 16),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -16)
        ])
    }

    func configure(text: String) {
        textLabel.text = text
    }

    static func height(for text: String, width: CGFloat) -> CGFloat {
        let bubbleWidth = min(260, max(180, width - 28))
        let contentWidth = bubbleWidth - 32
        let textHeight = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: WexloTheme.font(size: 17)],
            context: nil
        ).height
        return max(64, ceil(textHeight) + 32)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleWidthConstraint?.constant = min(260, max(180, contentView.bounds.width - 28))
        bubbleView.layer.shadowPath = UIBezierPath(
            roundedRect: bubbleView.bounds,
            cornerRadius: 23
        ).cgPath
    }
}

private final class AIQuickPromptView: UIView {
    private let prompts = [
        "Style a rainy-day commute",
        "Build a weekend outfit",
        "Find my best layers"
    ]
    private var buttons: [UIButton] = []
    var onPromptSelected: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        prompts.enumerated().forEach { index, prompt in
            let button = UIButton(type: .custom)
            button.tag = index
            button.setTitle(prompt, for: .normal)
            button.setTitleColor(WexloTheme.secondaryText, for: .normal)
            button.titleLabel?.font = WexloTheme.font(size: 14)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.65
            button.titleLabel?.lineBreakMode = .byClipping
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            button.backgroundColor = WexloTheme.surface
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 1
            button.layer.borderColor = WexloTheme.hairline.cgColor
            button.addTarget(self, action: #selector(didTapPrompt(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard buttons.count == 3 else { return }
        let buttonHeight: CGFloat = 32
        let rowGap: CGFloat = 8
        buttons[0].frame = CGRect(x: 0, y: 0, width: bounds.width, height: buttonHeight)

        let availableWidth = max(0, bounds.width - rowGap)
        let secondIntrinsicWidth = buttons[1].sizeThatFits(
            CGSize(width: .greatestFiniteMagnitude, height: buttonHeight)
        ).width
        let thirdIntrinsicWidth = buttons[2].sizeThatFits(
            CGSize(width: .greatestFiniteMagnitude, height: buttonHeight)
        ).width
        let intrinsicTotal = secondIntrinsicWidth + thirdIntrinsicWidth
        let secondWidth: CGFloat
        let thirdWidth: CGFloat
        if intrinsicTotal <= availableWidth {
            secondWidth = secondIntrinsicWidth
            thirdWidth = availableWidth - secondWidth
        } else {
            secondWidth = availableWidth * 0.56
            thirdWidth = availableWidth - secondWidth
        }

        buttons[1].frame = CGRect(
            x: 0,
            y: buttonHeight + rowGap,
            width: secondWidth,
            height: buttonHeight
        )
        buttons[2].frame = CGRect(
            x: secondWidth + rowGap,
            y: buttonHeight + rowGap,
            width: thirdWidth,
            height: buttonHeight
        )
    }

    @objc private func didTapPrompt(_ sender: UIButton) {
        guard prompts.indices.contains(sender.tag) else { return }
        onPromptSelected?(prompts[sender.tag])
    }
}

private final class AIGradientButton: UIButton {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [WexloTheme.coral.cgColor, WexloTheme.pink.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.cornerRadius = 22
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }
}
