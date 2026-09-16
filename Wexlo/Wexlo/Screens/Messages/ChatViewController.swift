import AVFoundation
import PhotosUI
import UIKit

final class ChatViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UITextFieldDelegate,
    PHPickerViewControllerDelegate,
    AVAudioPlayerDelegate {

    fileprivate enum MessageKind {
        case text(String)
        case voice(URL?, TimeInterval)
        case image(UIImage?)
    }

    fileprivate struct ChatMessage {
        let id: String
        let kind: MessageKind
        let isIncoming: Bool
        let timestamp: String

        init(
            id: String = UUID().uuidString,
            kind: MessageKind,
            isIncoming: Bool,
            timestamp: String
        ) {
            self.id = id
            self.kind = kind
            self.isIncoming = isIncoming
            self.timestamp = timestamp
        }
    }

    private let headerView = UIView()
    private let contactUser: WexloSeedUser?
    private let backButton = UIButton(type: .custom)
    private let contactAvatarView = UIImageView()
    private let contactNameLabel = UILabel()
    private let contactStatusDot = UIView()
    private let contactStatusLabel = UILabel()
    private let moreButton = UIButton(type: .custom)

    private let collectionView: UICollectionView
    private let composerView = UIView()
    private let imageButton = UIButton(type: .custom)
    private let voiceButton = UIButton(type: .custom)
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .custom)
    private var composerBottomConstraint: NSLayoutConstraint?
    private var isSending = false
    private var messages: [ChatMessage] = []
    private let currentUserID: String?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingStartedAt: Date?
    private var recordingTimer: Timer?
    private var isRecording = false
    private var isRequestingRecordingPermission = false
    private var isVoicePressActive = false
    private var audioPlayer: AVAudioPlayer?
    private var playingMessageID: String?
    private let recordingOverlay = VoiceRecordingOverlayView()

    init(userID: String = "mia") {
        contactUser = WexloLocalContentStore.shared.user(for: userID)
        if case .authenticated(let currentUserID) = WexloSessionStore.shared.current {
            self.currentUserID = currentUserID
        } else {
            currentUserID = nil
        }
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
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
        guard let currentUserID,
              let contactUser,
              WexloChatStore.shared.canChat(between: currentUserID, and: contactUser.id) else {
            presentChatRestriction()
            return
        }
        messages = WexloChatStore.shared.messages(
            between: currentUserID,
            and: contactUser.id
        ).map { makeChatMessage(from: $0, currentUserID: currentUserID) }
        WexloChatStore.shared.markConversationRead(for: currentUserID, with: contactUser.id)
        configureHeader()
        configureMessages()
        configureComposer()
        configureKeyboardHandling()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToLatest(animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isRecording {
            finishVoiceRecording(send: false)
        }
        stopVoicePlayback()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureHeader() {
        headerView.backgroundColor = WexloTheme.background

        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        contactAvatarView.image = UIImage(named: contactUser?.avatarAssetName ?? "wexlo_profile_avatar")
        contactAvatarView.contentMode = .scaleAspectFill
        contactAvatarView.layer.cornerRadius = 20
        contactAvatarView.clipsToBounds = true

        contactNameLabel.text = contactUser?.name ?? "Wexlo member"
        contactNameLabel.textColor = WexloTheme.primaryText
        contactNameLabel.font = WexloTheme.font(size: 20, weight: .bold)

        contactStatusDot.backgroundColor = UIColor(red: 0.26, green: 0.75, blue: 0.48, alpha: 1)
        contactStatusDot.layer.cornerRadius = 5

        let handle = contactUser.map {
            "@\($0.name.lowercased().replacingOccurrences(of: " ", with: "."))"
        } ?? "@wexlo.member"
        contactStatusLabel.text = "Online · \(handle)"
        contactStatusLabel.textColor = WexloTheme.secondaryText
        contactStatusLabel.font = WexloTheme.font(size: 15)

        moreButton.setImage(UIImage(named: "wexlo_chat_more"), for: .normal)
        moreButton.imageView?.contentMode = .scaleAspectFit
        moreButton.accessibilityLabel = "More actions"
        moreButton.menu = nil
        moreButton.showsMenuAsPrimaryAction = false
        moreButton.addTarget(self, action: #selector(didTapMore(_:)), for: .touchUpInside)
        moreButton.isHidden = isCurrentUserContact

        [backButton, contactAvatarView, contactNameLabel, contactStatusDot,
         contactStatusLabel, moreButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 88),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 26),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),

            contactAvatarView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 18),
            contactAvatarView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 22),
            contactAvatarView.widthAnchor.constraint(equalToConstant: 40),
            contactAvatarView.heightAnchor.constraint(equalToConstant: 40),

            contactNameLabel.leadingAnchor.constraint(equalTo: contactAvatarView.trailingAnchor, constant: 14),
            contactNameLabel.topAnchor.constraint(equalTo: contactAvatarView.topAnchor, constant: 0),
            contactNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -12),

            contactStatusDot.leadingAnchor.constraint(equalTo: contactNameLabel.leadingAnchor),
            contactStatusDot.topAnchor.constraint(equalTo: contactNameLabel.bottomAnchor, constant: 9),
            contactStatusDot.widthAnchor.constraint(equalToConstant: 10),
            contactStatusDot.heightAnchor.constraint(equalToConstant: 10),

            contactStatusLabel.leadingAnchor.constraint(equalTo: contactStatusDot.trailingAnchor, constant: 10),
            contactStatusLabel.centerYAnchor.constraint(equalTo: contactStatusDot.centerYAnchor),
            contactStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),

            moreButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            moreButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 26),
            moreButton.widthAnchor.constraint(equalToConstant: 35),
            moreButton.heightAnchor.constraint(equalToConstant: 35)
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
            ChatMessageCell.self,
            forCellWithReuseIdentifier: ChatMessageCell.reuseIdentifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
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

        configureComposerButton(
            imageButton,
            imageName: "wexlo_chat_send_image",
            accessibilityLabel: "Send image",
            action: #selector(didTapImage)
        )
        configureComposerButton(
            voiceButton,
            imageName: "wexlo_chat_send_voice",
            accessibilityLabel: "Send voice message",
            action: nil
        )
        let voiceLongPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleVoiceLongPress(_:))
        )
        voiceLongPress.minimumPressDuration = 0.25
        voiceButton.addGestureRecognizer(voiceLongPress)
        configureComposerButton(
            sendButton,
            imageName: "wexlo_chat_send_message",
            accessibilityLabel: "Send message",
            action: #selector(didTapSend)
        )

        messageTextField.textColor = .white
        messageTextField.font = WexloTheme.font(size: 17)
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Write a message...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.62)]
        )
        messageTextField.borderStyle = .none
        messageTextField.clearButtonMode = .whileEditing
        messageTextField.addTarget(self, action: #selector(messageTextDidChange), for: .editingChanged)

        [imageButton, voiceButton, messageTextField, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            composerView.addSubview($0)
        }
        composerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composerView)

        composerBottomConstraint = composerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -18
        )

        NSLayoutConstraint.activate([
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composerView.heightAnchor.constraint(equalToConstant: 72),
            composerBottomConstraint!,

            imageButton.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 16),
            imageButton.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            imageButton.widthAnchor.constraint(equalToConstant: 34),
            imageButton.heightAnchor.constraint(equalToConstant: 34),

            voiceButton.leadingAnchor.constraint(equalTo: imageButton.trailingAnchor, constant: 10),
            voiceButton.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 34),
            voiceButton.heightAnchor.constraint(equalToConstant: 34),

            messageTextField.leadingAnchor.constraint(equalTo: voiceButton.trailingAnchor, constant: 10),
            messageTextField.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            messageTextField.heightAnchor.constraint(equalToConstant: 42),

            sendButton.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: composerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 42),
            sendButton.heightAnchor.constraint(equalToConstant: 42),

            collectionView.bottomAnchor.constraint(equalTo: composerView.topAnchor, constant: -12)
        ])
    }

    private func configureComposerButton(
        _ button: UIButton,
        imageName: String,
        accessibilityLabel: String,
        action: Selector?
    ) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = accessibilityLabel
        if let action {
            button.addTarget(self, action: action, for: .touchUpInside)
        }
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
        messages.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as! ChatMessageCell
        cell.configure(
            message: messages[indexPath.item],
            avatarAssetName: contactUser?.avatarAssetName,
            onVoiceTap: { [weak self] messageID, audioURL in
                self?.toggleVoicePlayback(messageID: messageID, audioURL: audioURL)
            }
        )
        cell.setVoicePlaying(messages[indexPath.item].id == playingMessageID)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let message = messages[indexPath.item]
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: ChatMessageCell.height(for: message, width: width))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }

    static func openIfAllowed(contactUserID: String, from presenter: UIViewController) {
        guard case .authenticated(let currentUserID) = WexloSessionStore.shared.current else {
            presenter.showWexloToast("Please sign in to send messages.")
            return
        }
        guard currentUserID != contactUserID else {
            presenter.showWexloToast("You cannot message yourself.")
            return
        }
        guard WexloLocalContentStore.shared.user(for: contactUserID) != nil else {
            presenter.showWexloToast("This user is unavailable.")
            return
        }
        guard WexloChatStore.shared.canChat(between: currentUserID, and: contactUserID) else {
            presenter.present(ConnectToChatViewController(), animated: true)
            return
        }
        presenter.navigationController?.pushViewController(
            ChatViewController(userID: contactUserID),
            animated: true
        )
    }

    @objc private func didTapBack() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapMore(_ sender: UIButton) {
        guard let contactUser, !isCurrentUserContact else { return }

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(
                ReportViewController(),
                animated: true
            )
        })
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            self?.blockContact(contactUser)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
            } else if #available(iOS 26.0, *) {
                let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame
                popover.sourceView = view
                popover.sourceRect = CGRect(
                    x: safeAreaFrame.midX,
                    y: safeAreaFrame.maxY - 1,
                    width: 1,
                    height: 1
                )
                popover.permittedArrowDirections = []
            }
        }
        present(alert, animated: true)
    }

    private func blockContact(_ contactUser: WexloSeedUser) {
        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to block users.")
            return
        }
        guard !isCurrentUserContact else { return }
        guard WexloBlockStore.shared.blockUser(contactUser.id, for: accountID) else {
            showWexloToast("Unable to block this user.")
            return
        }

        let previousViewController = navigationController?.viewControllers.dropLast().last
        navigationController?.popViewController(animated: true)
        previousViewController?.showWexloToast("User blocked.")
    }

    @objc private func didTapSend() {
        guard !isSending,
              let currentUserID,
              let contactUser else { return }
        let text = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        isSending = true
        defer { isSending = false }
        guard let storedMessage = WexloChatStore.shared.appendTextMessage(
            text,
            from: currentUserID,
            to: contactUser.id
        ) else {
            showWexloToast("Message could not be sent.")
            return
        }

        view.endEditing(true)
        messageTextField.text = nil
        messages.append(makeChatMessage(from: storedMessage, currentUserID: currentUserID))
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        collectionView.layoutIfNeeded()
        scrollToLatest(animated: true)
        isSending = false
    }

    @objc private func didTapImage() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func handleVoiceLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard !isRecording, !isRequestingRecordingPermission else { return }
            isVoicePressActive = true
            requestMicrophoneAccessIfNeeded()
        case .ended:
            isVoicePressActive = false
            if isRecording {
                finishVoiceRecording(send: true)
            }
        case .cancelled, .failed:
            isVoicePressActive = false
            if isRecording {
                finishVoiceRecording(send: false)
            }
        default:
            break
        }
    }

    private func requestMicrophoneAccessIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startVoiceRecording()
        case .denied:
            showToast("Microphone access is unavailable.")
        case .undetermined:
            isRequestingRecordingPermission = true
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isRequestingRecordingPermission = false
                    guard granted else {
                        self.isVoicePressActive = false
                        self.showToast("Microphone access is unavailable.")
                        return
                    }
                    guard self.isVoicePressActive else { return }
                    self.startVoiceRecording()
                }
            }
        @unknown default:
            showToast("Microphone access is unavailable.")
        }
    }

    private func startVoiceRecording() {
        guard !isRecording,
              currentUserID != nil,
              contactUser != nil else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setActive(true, options: [])

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("wexlo-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                throw NSError(domain: "WexloVoiceRecording", code: 1)
            }

            view.endEditing(true)
            audioRecorder = recorder
            recordingURL = url
            recordingStartedAt = Date()
            isRecording = true
            voiceButton.alpha = 0.58
            recordingOverlay.show(in: view)
            recordingTimer?.invalidate()
            let timer = Timer(
                timeInterval: 0.05,
                repeats: true
            ) { [weak self] _ in
                self?.updateRecordingOverlay()
            }
            recordingTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        } catch {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            showToast("Voice recording could not start.")
        }
    }

    private func updateRecordingOverlay() {
        guard let recordingStartedAt,
              let audioRecorder else {
            return
        }
        audioRecorder.updateMeters()
        let power = audioRecorder.averagePower(forChannel: 0)
        let level = CGFloat(max(0, min(1, (power + 50) / 50)))
        recordingOverlay.update(
            elapsed: Date().timeIntervalSince(recordingStartedAt),
            level: level
        )
    }

    private func finishVoiceRecording(send: Bool) {
        guard isRecording else { return }

        let recorder = audioRecorder
        let url = recordingURL
        let duration = max(
            recorder?.currentTime ?? 0,
            recordingStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        )
        recorder?.stop()
        audioRecorder = nil
        recordingURL = nil
        recordingStartedAt = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        voiceButton.alpha = 1
        recordingOverlay.hide()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )

        guard send, let url else {
            if let url {
                try? FileManager.default.removeItem(at: url)
            }
            return
        }

        guard duration >= 0.35 else {
            try? FileManager.default.removeItem(at: url)
            showToast("Hold to record a longer voice message.")
            return
        }
        guard let currentUserID,
              let contactUser,
              let storedMessage = WexloChatStore.shared.appendVoiceMessage(
                from: url,
                duration: duration,
                senderID: currentUserID,
                to: contactUser.id
              ) else {
            try? FileManager.default.removeItem(at: url)
            showToast("Voice message could not be sent.")
            return
        }

        try? FileManager.default.removeItem(at: url)
        messages.append(makeChatMessage(from: storedMessage, currentUserID: currentUserID))
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        collectionView.layoutIfNeeded()
        scrollToLatest(animated: true)
    }

    private func toggleVoicePlayback(messageID: String, audioURL: URL?) {
        guard let audioURL else {
            showToast("Voice message audio is unavailable.")
            return
        }
        if playingMessageID == messageID {
            stopVoicePlayback()
            return
        }

        audioPlayer?.stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try session.setActive(true, options: [])
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            player.volume = 1
            player.prepareToPlay()
            guard player.play() else {
                throw NSError(domain: "WexloVoicePlayback", code: 1)
            }
            audioPlayer = player
            playingMessageID = messageID
            updateVoicePlaybackState()
        } catch {
            stopVoicePlayback()
            showToast("Voice message could not be played.")
        }
    }

    private func stopVoicePlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingMessageID = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        updateVoicePlaybackState()
    }

    private func updateVoicePlaybackState() {
        for cell in collectionView.visibleCells {
            guard let cell = cell as? ChatMessageCell else { continue }
            cell.setVoicePlaying(cell.messageID == playingMessageID)
        }
    }

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        stopVoicePlayback()
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.appendSelectedImage(image)
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func messageTextDidChange() {
        sendButton.alpha = (messageTextField.text?.isEmpty == false) ? 1 : 0.72
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let convertedFrame = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom)
        composerBottomConstraint?.constant = overlap > 0 ? -(overlap + 10) : -18

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

    private func appendSelectedImage(_ image: UIImage) {
        guard !isSending,
              let currentUserID,
              let contactUser else {
            return
        }

        isSending = true
        defer { isSending = false }
        guard let storedMessage = WexloChatStore.shared.appendImageMessage(
            image,
            senderID: currentUserID,
            to: contactUser.id
        ) else {
            showToast("Photo could not be sent.")
            return
        }

        messages.append(makeChatMessage(from: storedMessage, currentUserID: currentUserID))
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        scrollToLatest(animated: true)
    }

    private func scrollToLatest(animated: Bool) {
        guard !messages.isEmpty else { return }
        collectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func makeChatMessage(
        from message: WexloChatMessage,
        currentUserID: String
    ) -> ChatMessage {
        let kind: MessageKind
        switch message.kind {
        case .text:
            kind = .text(message.text ?? "")
        case .voice:
            kind = .voice(
                WexloChatStore.shared.audioURL(for: message),
                message.duration ?? 12
            )
        case .image:
            let image = WexloChatStore.shared.imageURL(for: message)
                .flatMap { UIImage(contentsOfFile: $0.path) }
            kind = .image(image)
        }
        return ChatMessage(
            id: message.id,
            kind: kind,
            isIncoming: message.senderID != currentUserID,
            timestamp: WexloChatStore.shared.timestampLabel(for: message.timestamp)
        )
    }

    private func presentChatRestriction() {
        let dialog = ConnectToChatViewController()
        dialog.onConfirm = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        DispatchQueue.main.async { [weak self] in
            self?.present(dialog, animated: true)
        }
    }

    private var isCurrentUserContact: Bool {
        guard let contactUser,
              case .authenticated(let currentUserID) = WexloSessionStore.shared.current else {
            return false
        }
        return contactUser.id == currentUserID
    }

    private func showToast(_ message: String) {
        let toast = WexloToastLabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = WexloTheme.tabBar.withAlphaComponent(0.94)
        toast.font = WexloTheme.font(size: 13, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 12
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: composerView.topAnchor, constant: -12),
            toast.heightAnchor.constraint(equalToConstant: 42),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -24)
        ])

        UIView.animate(
            withDuration: 0.2,
            delay: 1.5,
            options: []
        ) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }
}

private final class ChatMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "ChatMessageCell"
    private(set) var messageID = ""
    private var onVoiceTap: ((String, URL?) -> Void)?

    private let avatarView = UIImageView()
    private let bubbleView = UIView()
    private let contentStack = UIStackView()
    private let textLabel = UILabel()
    private let imageMessageView = UIImageView()
    private let voiceMessageView = ChatVoiceMessageView()
    private let timestampLabel = UILabel()

    private var incomingBubbleLeading: NSLayoutConstraint?
    private var incomingBubbleTrailing: NSLayoutConstraint?
    private var outgoingBubbleLeading: NSLayoutConstraint?
    private var outgoingBubbleTrailing: NSLayoutConstraint?
    private var bubbleWidth: NSLayoutConstraint?
    private var isIncomingMessage = true
    private var preferredBubbleWidth: CGFloat = 253
    private var timestampLeading: NSLayoutConstraint?
    private var timestampTrailing: NSLayoutConstraint?
    private var contentTopPadding: NSLayoutConstraint?
    private var contentLeadingPadding: NSLayoutConstraint?
    private var contentTrailingPadding: NSLayoutConstraint?
    private var contentBottomPadding: NSLayoutConstraint?

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
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(named: "15d058e5b1d372de38f21d8055f89223")

        bubbleView.layer.cornerRadius = 22
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.15
        bubbleView.layer.shadowRadius = 14
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bubbleView.layer.masksToBounds = false

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0

        textLabel.font = WexloTheme.font(size: 17)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping

        imageMessageView.contentMode = .scaleAspectFill
        imageMessageView.clipsToBounds = true
        imageMessageView.layer.cornerRadius = 18
        imageMessageView.widthAnchor.constraint(equalToConstant: 108).isActive = true
        imageMessageView.heightAnchor.constraint(equalToConstant: 148).isActive = true
        voiceMessageView.widthAnchor.constraint(equalToConstant: 176).isActive = true
        voiceMessageView.heightAnchor.constraint(equalToConstant: 52).isActive = true

        timestampLabel.font = WexloTheme.font(size: 14)
        timestampLabel.textColor = WexloTheme.secondaryText
        timestampLabel.setContentHuggingPriority(.required, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        [textLabel, imageMessageView, voiceMessageView].forEach {
            contentStack.addArrangedSubview($0)
        }
        [avatarView, bubbleView, timestampLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(contentStack)

        incomingBubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48)
        incomingBubbleTrailing = bubbleView.trailingAnchor.constraint(
            lessThanOrEqualTo: contentView.trailingAnchor,
            constant: -42
        )
        outgoingBubbleLeading = bubbleView.leadingAnchor.constraint(
            greaterThanOrEqualTo: contentView.leadingAnchor,
            constant: 42
        )
        outgoingBubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        bubbleWidth = bubbleView.widthAnchor.constraint(equalToConstant: preferredBubbleWidth)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bubbleWidth!,

            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4),
            timestampLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        contentTopPadding = contentStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10)
        contentLeadingPadding = contentStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16)
        contentTrailingPadding = contentStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16)
        contentBottomPadding = contentStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        NSLayoutConstraint.activate([
            contentTopPadding!,
            contentLeadingPadding!,
            contentTrailingPadding!,
            contentBottomPadding!
        ])
    }

    func configure(
        message: ChatViewController.ChatMessage,
        avatarAssetName: String? = nil,
        onVoiceTap: ((String, URL?) -> Void)? = nil
    ) {
        messageID = message.id
        self.onVoiceTap = onVoiceTap
        voiceMessageView.onTap = nil
        voiceMessageView.setPlaying(false)
        let isIncoming = message.isIncoming
        isIncomingMessage = isIncoming
        avatarView.isHidden = !isIncoming
        avatarView.image = UIImage(named: avatarAssetName ?? "15d058e5b1d372de38f21d8055f89223")
        textLabel.isHidden = true
        imageMessageView.isHidden = true
        voiceMessageView.isHidden = true
        preferredBubbleWidth = 253
        bubbleWidth?.isActive = true

        incomingBubbleLeading?.isActive = isIncoming
        incomingBubbleTrailing?.isActive = isIncoming
        outgoingBubbleLeading?.isActive = !isIncoming
        outgoingBubbleTrailing?.isActive = !isIncoming

        timestampLeading?.isActive = false
        timestampTrailing?.isActive = false
        if isIncoming {
            timestampLeading = timestampLabel.leadingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: 10
            )
        } else {
            timestampTrailing = timestampLabel.trailingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: -10
            )
        }
        timestampLeading?.isActive = true
        timestampTrailing?.isActive = true

        if isIncoming {
            bubbleView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            textLabel.textColor = WexloTheme.primaryText
            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            bubbleView.backgroundColor = WexloTheme.tabBar
            textLabel.textColor = .white
            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]
        }
        bubbleView.layer.shadowOpacity = isIncoming ? 0.15 : 0.18

        timestampLabel.text = message.timestamp

        switch message.kind {
        case .text(let text):
            preferredBubbleWidth = isIncoming ? 253 : 278
            contentTopPadding?.constant = 10
            contentLeadingPadding?.constant = 16
            contentTrailingPadding?.constant = -16
            contentBottomPadding?.constant = -10
            textLabel.text = text
            textLabel.isHidden = false
        case .voice(let audioURL, let duration):
            bubbleView.backgroundColor = .clear
            preferredBubbleWidth = 176
            bubbleView.layer.shadowOpacity = 0.16
            contentTopPadding?.constant = 0
            contentLeadingPadding?.constant = 0
            contentTrailingPadding?.constant = 0
            contentBottomPadding?.constant = 0
            voiceMessageView.configure(duration: duration)
            voiceMessageView.onTap = { [weak self] in
                self?.onVoiceTap?(message.id, audioURL)
            }
            voiceMessageView.isHidden = false
        case .image(let image):
            preferredBubbleWidth = 140
            bubbleView.layer.shadowOpacity = 0.11
            contentTopPadding?.constant = 10
            contentLeadingPadding?.constant = 16
            contentTrailingPadding?.constant = -16
            contentBottomPadding?.constant = -10
            imageMessageView.image = image
            imageMessageView.isHidden = false
        }
    }

    static func height(
        for message: ChatViewController.ChatMessage,
        width: CGFloat
    ) -> CGFloat {
        let maxBubbleWidth = message.isIncoming
            ? min(253, width - 90)
            : min(278, width - 42)
        let contentWidth = maxBubbleWidth - 32
        let contentHeight: CGFloat

        switch message.kind {
        case .text(let text):
            let boundingRect = (text as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: WexloTheme.font(size: 17)],
                context: nil
            )
            contentHeight = ceil(boundingRect.height)
        case .voice(_, _):
            contentHeight = 52
        case .image:
            contentHeight = 148
        }

        let verticalPadding: CGFloat = {
            switch message.kind {
            case .voice(_, _):
                return 0
            default:
                return 20
            }
        }()
        return max(44, contentHeight + verticalPadding)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let availableWidth = contentView.bounds.width - (isIncomingMessage ? 90 : 42)
        let maximumWidth: CGFloat = isIncomingMessage ? 253 : 278
        bubbleWidth?.constant = min(preferredBubbleWidth, max(120, min(maximumWidth, availableWidth)))
        let corners: UIRectCorner = isIncomingMessage
            ? [.topLeft, .topRight, .bottomRight]
            : [.topLeft, .topRight, .bottomLeft]
        bubbleView.layer.shadowPath = UIBezierPath(
            roundedRect: bubbleView.bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 22, height: 22)
        ).cgPath
    }

    func setVoicePlaying(_ isPlaying: Bool) {
        voiceMessageView.setPlaying(isPlaying)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageID = ""
        onVoiceTap = nil
        voiceMessageView.onTap = nil
        voiceMessageView.setPlaying(false)
    }
}

private final class ChatVoiceMessageView: UIView {
    private let playImageView = UIImageView()
    private let waveformImageView = UIImageView(image: UIImage(systemName: "waveform"))
    private let durationLabel = UILabel()
    var onTap: (() -> Void)?

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
        layer.cornerRadius = 22
        clipsToBounds = true

        playImageView.contentMode = .scaleAspectFit
        waveformImageView.tintColor = WexloTheme.primaryText
        waveformImageView.contentMode = .scaleAspectFit
        durationLabel.text = "0:12"
        durationLabel.textColor = WexloTheme.primaryText
        durationLabel.font = WexloTheme.font(size: 17)
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTap))
        )

        [playImageView, waveformImageView, durationLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            playImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            playImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 26),
            playImageView.heightAnchor.constraint(equalToConstant: 26),

            waveformImageView.leadingAnchor.constraint(equalTo: playImageView.trailingAnchor, constant: 12),
            waveformImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            waveformImageView.widthAnchor.constraint(equalToConstant: 64),
            waveformImageView.heightAnchor.constraint(equalToConstant: 28),

            durationLabel.leadingAnchor.constraint(equalTo: waveformImageView.trailingAnchor, constant: 8),
            durationLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(duration: TimeInterval) {
        durationLabel.text = Self.durationText(duration)
        setPlaying(false)
    }

    func setPlaying(_ isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playImageView.image = UIImage(
            systemName: imageName,
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: 15,
                weight: .bold
            )
        )
        playImageView.tintColor = WexloTheme.primaryText
    }

    @objc private func didTap() {
        onTap?()
    }

    private static func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(duration)))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}

private final class VoiceRecordingOverlayView: UIView {
    private let panelView = UIView()
    private let indicatorView = UIView()
    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    private let hintLabel = UILabel()
    private let waveformStack = UIStackView()
    private var waveformBars: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        alpha = 0
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false

        panelView.backgroundColor = UIColor.black.withAlphaComponent(0.82)
        panelView.layer.cornerRadius = 22
        panelView.layer.borderWidth = 1
        panelView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        indicatorView.backgroundColor = WexloTheme.coral
        indicatorView.layer.cornerRadius = 5

        titleLabel.text = "Recording"
        titleLabel.textColor = .white
        titleLabel.font = WexloTheme.font(size: 16, weight: .semibold)
        titleLabel.textAlignment = .center

        durationLabel.text = "0:00"
        durationLabel.textColor = .white
        durationLabel.font = WexloTheme.font(size: 30, weight: .bold)
        durationLabel.textAlignment = .center
        durationLabel.accessibilityLabel = "Recording duration"

        hintLabel.text = "Release to send"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        hintLabel.font = WexloTheme.font(size: 13)
        hintLabel.textAlignment = .center

        waveformStack.axis = .horizontal
        waveformStack.alignment = .center
        waveformStack.distribution = .equalSpacing
        waveformStack.spacing = 5

        let barHeights: [CGFloat] = [12, 24, 34, 20, 42, 26, 36, 18, 30]
        for height in barHeights {
            let bar = UIView()
            bar.backgroundColor = WexloTheme.pink
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
            bar.heightAnchor.constraint(equalToConstant: height).isActive = true
            waveformStack.addArrangedSubview(bar)
            waveformBars.append(bar)
        }

        [panelView, indicatorView, titleLabel, durationLabel, hintLabel, waveformStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(panelView)
        panelView.addSubview(indicatorView)
        panelView.addSubview(titleLabel)
        panelView.addSubview(durationLabel)
        panelView.addSubview(waveformStack)
        panelView.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            panelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            panelView.topAnchor.constraint(equalTo: topAnchor),
            panelView.bottomAnchor.constraint(equalTo: bottomAnchor),

            indicatorView.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 18),
            indicatorView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 18),
            indicatorView.widthAnchor.constraint(equalToConstant: 10),
            indicatorView.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -18),

            durationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            durationLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            durationLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),

            waveformStack.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 12),
            waveformStack.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 24),
            waveformStack.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -24),
            waveformStack.heightAnchor.constraint(equalToConstant: 44),

            hintLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            hintLabel.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func show(in hostView: UIView) {
        if superview == nil {
            hostView.addSubview(self)
            NSLayoutConstraint.activate([
                centerXAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.centerXAnchor),
                centerYAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.centerYAnchor),
                widthAnchor.constraint(equalToConstant: 196),
                heightAnchor.constraint(equalToConstant: 188)
            ])
        }

        durationLabel.text = "0:00"
        update(elapsed: 0, level: 0.5)
        isHidden = false
        layer.removeAllAnimations()
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.72
        pulse.toValue = 1
        pulse.duration = 0.75
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        indicatorView.layer.add(pulse, forKey: "recordingPulse")

        panelView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut]
        ) {
            self.alpha = 1
            self.panelView.transform = .identity
        }
    }

    func update(elapsed: TimeInterval, level: CGFloat) {
        durationLabel.text = Self.durationText(elapsed)
        let normalizedLevel = min(1, max(0, level))
        UIView.animate(
            withDuration: 0.08,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveLinear]
        ) {
            for (index, bar) in self.waveformBars.enumerated() {
                let phase = CGFloat(index % 4) * 0.18
                let scale = 0.48 + normalizedLevel * (0.45 + phase)
                bar.transform = CGAffineTransform(scaleX: 1, y: scale)
            }
        }
    }

    func hide() {
        guard !isHidden else { return }
        indicatorView.layer.removeAnimation(forKey: "recordingPulse")
        UIView.animate(
            withDuration: 0.16,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn]
        ) {
            self.alpha = 0
            self.panelView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        } completion: { _ in
            self.isHidden = true
            self.panelView.transform = .identity
        }
    }

    private static func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(floor(duration)))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}
