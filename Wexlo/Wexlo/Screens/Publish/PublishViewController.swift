import AVFoundation
import PhotosUI
import UniformTypeIdentifiers
import UIKit

final class PublishViewController: UIViewController,
    UIScrollViewDelegate,
    UITextFieldDelegate,
    UITextViewDelegate,
    PHPickerViewControllerDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    private struct LayerDefinition {
        let name: String
        let requirement: String
        let placeholder: String
        let symbol: String
    }

    private let navigationHeader = WexloNavigationHeader(style: .brand)
    private let publishButton = UIButton(type: .custom)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleField = UITextField()
    private let notesTextView = PublishPlaceholderTextView()
    private let mediaPreview = PublishMediaPreviewView()
    private let loadingOverlay = WexloLoadingOverlay()
    private let sessionStore = WexloSessionStore.shared
    private let accountStore = WexloAccountStore.shared
    private let contentStore = WexloLocalContentStore.shared

    private var styleButtons: [UIButton] = []
    private var settingButtons: [UIButton] = []
    private var layerFields: [UITextField] = []
    private var selectedStyleIndex = 0
    private var selectedSettingIndex = 0
    private var selectedMedia: UIImage?
    private var selectedMediaKind: WexloMediaKind = .image
    private var selectedVideoURL: URL?
    private var isPublishing = false
    private var keyboardBottomInset: CGFloat = 0

    private let styles = ["Gorpcore", "City Outdoor", "Techwear", "Minimal Outdoor"]
    private let settings = ["Commute", "Rainy Day", "Camping", "Travel"]
    private let layerDefinitions = [
        LayerDefinition(
            name: "Shell · Outer layer",
            requirement: "Required",
            placeholder: "Piece name / brand / model",
            symbol: "wind"
        ),
        LayerDefinition(
            name: "Mid-layer",
            requirement: "Optional",
            placeholder: "Fleece, vest, or soft shell",
            symbol: "cloud"
        ),
        LayerDefinition(
            name: "Base layer",
            requirement: "Optional",
            placeholder: "T-shirt or performance base",
            symbol: "tshirt"
        ),
        LayerDefinition(
            name: "Footwear",
            requirement: "Required",
            placeholder: "Shoe name / brand",
            symbol: "shoe"
        ),
        LayerDefinition(
            name: "Accessories",
            requirement: "Optional",
            placeholder: "Cap, bag, eyewear, and more",
            symbol: "backpack"
        )
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureNavigationHeader()
        configureScrollView()
        configureKeyboardHandling()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeStagedVideo()
    }

    private func configureNavigationHeader() {
        publishButton.setTitle("Publish look", for: .normal)
        publishButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        publishButton.titleLabel?.font = WexloTheme.font(size: 16, weight: .bold)
        publishButton.backgroundColor = WexloTheme.surface
        publishButton.layer.cornerRadius = 23
        publishButton.layer.borderWidth = 1
        publishButton.layer.borderColor = WexloTheme.hairline.cgColor
        publishButton.addTarget(self, action: #selector(didTapPublish), for: .touchUpInside)
        publishButton.accessibilityLabel = "Publish look"

        navigationHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationHeader)
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(publishButton)
        NSLayoutConstraint.activate([
            navigationHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            publishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            publishButton.centerYAnchor.constraint(equalTo: navigationHeader.centerYAnchor),
            publishButton.widthAnchor.constraint(equalToConstant: 112),
            publishButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func configureScrollView() {
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.delegate = self
        scrollView.contentInset.bottom = 112
        scrollView.verticalScrollIndicatorInsets.bottom = 112

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        configureTitleField()
        configureNotesTextView()

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStack)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navigationHeader.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28)
        ])

        buildContent()

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    private func buildContent() {
        let pageTitle = UILabel()
        pageTitle.text = "Publish a look"
        pageTitle.textColor = WexloTheme.primaryText
        pageTitle.font = WexloTheme.font(size: 32, weight: .bold)

        let pageTitleRow = UIView()
        pageTitleRow.translatesAutoresizingMaskIntoConstraints = false
        pageTitle.translatesAutoresizingMaskIntoConstraints = false
        pageTitleRow.addSubview(pageTitle)
        NSLayoutConstraint.activate([
            pageTitleRow.heightAnchor.constraint(equalToConstant: 46),
            pageTitle.leadingAnchor.constraint(equalTo: pageTitleRow.leadingAnchor),
            pageTitle.centerYAnchor.constraint(equalTo: pageTitleRow.centerYAnchor),
            pageTitle.trailingAnchor.constraint(equalTo: pageTitleRow.trailingAnchor)
        ])

        let pageSubtitle = UILabel()
        pageSubtitle.text = "Share your outdoor style and the thinking behind it."
        pageSubtitle.textColor = WexloTheme.secondaryText
        pageSubtitle.font = WexloTheme.font(size: 18)
        pageSubtitle.numberOfLines = 0

        contentStack.addArrangedSubview(pageTitleRow)
        contentStack.addArrangedSubview(pageSubtitle)
        contentStack.setCustomSpacing(26, after: pageSubtitle)

        let mediaHeader = makeSectionHeader(title: "Add a photo or video", trailing: "At least 1")
        contentStack.addArrangedSubview(mediaHeader)
        contentStack.setCustomSpacing(8, after: mediaHeader)

        mediaPreview.translatesAutoresizingMaskIntoConstraints = false
        mediaPreview.heightAnchor.constraint(equalToConstant: 178).isActive = true
        mediaPreview.onTap = { [weak self] in
            self?.presentMediaSourceSheet()
        }
        mediaPreview.configure(image: selectedMedia)
        contentStack.addArrangedSubview(mediaPreview)
        contentStack.setCustomSpacing(30, after: mediaPreview)

        contentStack.addArrangedSubview(
            makeSectionHeader(title: "Outfit information", trailing: "Can add later")
        )
        contentStack.setCustomSpacing(2, after: contentStack.arrangedSubviews.last!)

        contentStack.addArrangedSubview(makeFieldLabel("Title"))
        contentStack.setCustomSpacing(8, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(titleField)
        contentStack.setCustomSpacing(16, after: titleField)

        contentStack.addArrangedSubview(makeFieldLabel("Style tags"))
        contentStack.setCustomSpacing(8, after: contentStack.arrangedSubviews.last!)
        styleButtons = makePillButtons(titles: styles, selectedIndex: selectedStyleIndex)
        contentStack.addArrangedSubview(makePillRow(styleButtons))
        contentStack.setCustomSpacing(16, after: contentStack.arrangedSubviews.last!)

        contentStack.addArrangedSubview(makeFieldLabel("Setting"))
        contentStack.setCustomSpacing(8, after: contentStack.arrangedSubviews.last!)
        settingButtons = makePillButtons(titles: settings, selectedIndex: selectedSettingIndex)
        contentStack.addArrangedSubview(makePillRow(settingButtons))
        contentStack.setCustomSpacing(16, after: contentStack.arrangedSubviews.last!)

        contentStack.addArrangedSubview(makeFieldLabel("Outfit notes"))
        contentStack.setCustomSpacing(8, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(notesTextView)
        contentStack.setCustomSpacing(30, after: notesTextView)

        contentStack.addArrangedSubview(
            makeSectionHeader(title: "Outfit breakdown", trailing: "Structured details")
        )
        contentStack.setCustomSpacing(8, after: contentStack.arrangedSubviews.last!)

        let breakdownHint = PublishDashedHintView()
        breakdownHint.translatesAutoresizingMaskIntoConstraints = false
        breakdownHint.heightAnchor.constraint(equalToConstant: 72).isActive = true
        contentStack.addArrangedSubview(breakdownHint)
        contentStack.setCustomSpacing(10, after: breakdownHint)

        for (index, layer) in layerDefinitions.enumerated() {
            contentStack.addArrangedSubview(
                makeLayerCard(
                    title: layer.name,
                    requirement: layer.requirement,
                    placeholder: layer.placeholder
                )
            )
            if index < layerDefinitions.count - 1 {
                contentStack.setCustomSpacing(10, after: contentStack.arrangedSubviews.last!)
            }
        }
    }

    private func configureTitleField() {
        titleField.placeholder = "e.g. Rainy day city layers"
        titleField.font = WexloTheme.font(size: 20)
        titleField.textColor = WexloTheme.primaryText
        titleField.attributedPlaceholder = NSAttributedString(
            string: "e.g. Rainy day city layers",
            attributes: [.foregroundColor: WexloTheme.secondaryText.withAlphaComponent(0.72)]
        )
        titleField.backgroundColor = WexloTheme.surface
        titleField.layer.cornerRadius = 22
        titleField.layer.borderWidth = 1
        titleField.layer.borderColor = WexloTheme.hairline.cgColor
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        titleField.leftViewMode = .always
        titleField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        titleField.rightViewMode = .always
        titleField.returnKeyType = .done
        titleField.delegate = self
        titleField.heightAnchor.constraint(equalToConstant: 72).isActive = true
    }

    private func configureNotesTextView() {
        notesTextView.placeholder = "Share the weather, your layering logic, and\nhow it felt to wear."
        notesTextView.font = WexloTheme.font(size: 20)
        notesTextView.textColor = WexloTheme.primaryText
        notesTextView.backgroundColor = WexloTheme.surface
        notesTextView.layer.cornerRadius = 22
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = WexloTheme.hairline.cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 17, left: 16, bottom: 14, right: 16)
        notesTextView.textContainer.lineFragmentPadding = 0
        notesTextView.textContainer.widthTracksTextView = true
        notesTextView.alwaysBounceVertical = true
        notesTextView.alwaysBounceHorizontal = false
        notesTextView.showsHorizontalScrollIndicator = false
        notesTextView.isDirectionalLockEnabled = true
        notesTextView.delegate = self
        notesTextView.returnKeyType = .default
        notesTextView.heightAnchor.constraint(equalToConstant: 112).isActive = true
    }

    private func makeSectionHeader(title: String, trailing: String) -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 24, weight: .bold)

        let trailingLabel = UILabel()
        trailingLabel.text = trailing
        trailingLabel.textColor = WexloTheme.secondaryText
        trailingLabel.font = WexloTheme.font(size: 16)
        trailingLabel.textAlignment = .right
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        [titleLabel, trailingLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -10),
            trailingLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            trailingLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func makeFieldLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.textColor = WexloTheme.primaryText
        label.font = WexloTheme.font(size: 17, weight: .bold)
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return label
    }

    private func makeOutlineButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(WexloTheme.primaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 17, weight: .bold)
        button.backgroundColor = WexloTheme.surface
        button.layer.cornerRadius = 24
        button.layer.borderWidth = 1
        button.layer.borderColor = WexloTheme.hairline.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makePillButtons(titles: [String], selectedIndex: Int) -> [UIButton] {
        titles.enumerated().map { index, title in
            let button = UIButton(type: .custom)
            button.tag = index
            button.accessibilityIdentifier = titles == styles ? "style-pill" : "setting-pill"
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = WexloTheme.font(size: 16, weight: .bold)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 17)
            button.layer.cornerRadius = 21
            button.layer.borderWidth = 1
            button.heightAnchor.constraint(equalToConstant: 42).isActive = true
            button.addTarget(self, action: #selector(didTapPill(_:)), for: .touchUpInside)
            setPill(button, selected: index == selectedIndex)
            return button
        }
    }

    private func makePillRow(_ buttons: [UIButton]) -> UIView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false

        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = 7
        row.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(row)

        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalToConstant: 42),
            row.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        return scrollView
    }

    private func setPill(_ button: UIButton, selected: Bool) {
        button.backgroundColor = selected ? WexloTheme.tabBar : WexloTheme.surface
        button.setTitleColor(selected ? .white : WexloTheme.primaryText, for: .normal)
        button.layer.borderColor = selected
            ? WexloTheme.tabBar.cgColor
            : WexloTheme.hairline.cgColor
    }

    private func makeLayerCard(title: String, requirement: String, placeholder: String) -> UIView {
        let card = UIView()
        card.backgroundColor = WexloTheme.surface
        card.layer.cornerRadius = 22
        card.layer.borderWidth = 1
        card.layer.borderColor = WexloTheme.hairline.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 172).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 18, weight: .bold)

        let requirementLabel = UILabel()
        requirementLabel.text = requirement
        requirementLabel.textColor = WexloTheme.secondaryText
        requirementLabel.font = WexloTheme.font(size: 14)
        requirementLabel.textAlignment = .right

        let field = UITextField()
        field.placeholder = placeholder
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: WexloTheme.secondaryText.withAlphaComponent(0.68)]
        )
        field.textColor = WexloTheme.primaryText
        field.font = WexloTheme.font(size: 17)
        field.backgroundColor = WexloTheme.surface
        field.layer.cornerRadius = 18
        field.layer.borderWidth = 1
        field.layer.borderColor = WexloTheme.hairline.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.rightViewMode = .always
        field.returnKeyType = .done
        field.delegate = self
        layerFields.append(field)

        [titleLabel, requirementLabel, field].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: requirementLabel.leadingAnchor, constant: -8),

            requirementLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            requirementLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            field.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            field.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            field.heightAnchor.constraint(equalToConstant: 62)
        ])
        return card
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

    @objc private func didTapPill(_ sender: UIButton) {
        let isStyle = sender.accessibilityIdentifier == "style-pill"
        if isStyle {
            selectedStyleIndex = sender.tag
            styleButtons.forEach { setPill($0, selected: $0 === sender) }
        } else {
            selectedSettingIndex = sender.tag
            settingButtons.forEach { setPill($0, selected: $0 === sender) }
        }
    }

    private func presentMediaSourceSheet() {
        let alert = UIAlertController(title: "Add media", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Choose a photo", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        alert.addAction(UIAlertAction(title: "Take a photo", style: .default) { [weak self] _ in
            self?.presentPhotoCamera()
        })
        alert.addAction(UIAlertAction(title: "Choose a video", style: .default) { [weak self] _ in
            self?.presentVideoPicker()
        })
        alert.addAction(UIAlertAction(title: "Record a video", style: .default) { [weak self] _ in
            self?.presentVideoCamera()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = mediaPreview
            popover.sourceRect = mediaPreview.bounds
        }
        present(alert, animated: true)
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentVideoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentPhotoCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showWexloToast("Camera is not available on this device.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentVideoCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showWexloToast("Camera is not available on this device.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.delegate = self
        present(picker, animated: true)
    }

    private func validateRequiredFields() -> Bool {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else {
            showWexloToast("Please enter a title.")
            return false
        }

        let notes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !notes.isEmpty else {
            showWexloToast("Please enter outfit notes.")
            return false
        }

        guard styles.indices.contains(selectedStyleIndex) else {
            showWexloToast("Please choose a style.")
            return false
        }

        guard settings.indices.contains(selectedSettingIndex) else {
            showWexloToast("Please choose a setting.")
            return false
        }

        for (definition, field) in zip(layerDefinitions, layerFields)
            where definition.requirement == "Required" {
            let value = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else {
                showWexloToast("Please complete \(definition.name).")
                return false
            }
        }

        return true
    }

    @objc private func didTapPublish() {
        guard !isPublishing else { return }
        guard let selectedMedia else {
            showWexloToast("Add at least one photo or video.")
            return
        }
        guard case .authenticated(let userID) = sessionStore.current else {
            showWexloToast("Please sign in to publish a look.")
            return
        }
        guard selectedMediaKind == .image || selectedVideoURL != nil else {
            showWexloToast("The selected video is unavailable.")
            return
        }
        guard validateRequiredFields() else { return }

        isPublishing = true
        publishButton.isEnabled = false
        loadingOverlay.show(in: view)

        let trimmedTitle = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = trimmedTitle
        let trimmedDetail = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = trimmedDetail
        let profile = accountStore.profile(for: userID)
        let layers = zip(layerDefinitions, layerFields).map { definition, field in
            let trimmedDetail = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return WexloLayerItem(
                name: definition.name,
                detail: trimmedDetail.isEmpty ? "Not specified" : trimmedDetail,
                symbol: definition.symbol
            )
        }

        do {
            try contentStore.publishPost(
                authorID: userID,
                authorName: profile?.nickname,
                authorAvatarAssetName: profile?.avatarAssetName ?? "",
                title: title,
                detail: detail,
                styleTag: styles[selectedStyleIndex],
                setting: settings[selectedSettingIndex],
                layers: layers,
                image: selectedMediaKind == .image ? selectedMedia : nil,
                videoURL: selectedMediaKind == .video ? selectedVideoURL : nil
            )
            completeWexloLoading(loadingOverlay) { [weak self] in
                guard let self else { return }
                resetPublishForm()
                isPublishing = false
                publishButton.isEnabled = true
                showWexloToast("Look published.")
            }
        } catch let error as WexloContentStoreError {
            loadingOverlay.hide()
            isPublishing = false
            publishButton.isEnabled = true
            showWexloToast(error.userMessage)
        } catch {
            loadingOverlay.hide()
            isPublishing = false
            publishButton.isEnabled = true
            showWexloToast("The outfit could not be saved. Please try again.")
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let url else {
                    DispatchQueue.main.async {
                        self?.showWexloToast("The selected video could not be loaded.")
                    }
                    return
                }
                self?.loadFirstFrame(from: url, retainForPublish: true)
            }
            return
        }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else {
                    DispatchQueue.main.async {
                        self?.showWexloToast("The selected photo could not be loaded.")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self?.setSelectedMedia(image)
                }
            }
            return
        }

        showWexloToast("The selected media is unavailable.")
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            setSelectedMedia(image)
            return
        }

        guard let url = info[.mediaURL] as? URL else {
            showWexloToast("The selected media is unavailable.")
            return
        }
        loadFirstFrame(from: url, retainForPublish: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    private func setSelectedMedia(_ image: UIImage) {
        removeStagedVideo()
        selectedMediaKind = .image
        selectedMedia = image
        mediaPreview.configure(image: image)
    }

    private func loadFirstFrame(from url: URL, retainForPublish: Bool = false) {
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
        let hasCopiedMedia = (try? FileManager.default.copyItem(at: url, to: previewURL)) != nil
        guard !retainForPublish || hasCopiedMedia else {
            showWexloToast("The selected video could not be prepared.")
            return
        }
        let sourceURL = hasCopiedMedia ? previewURL : url

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                if hasCopiedMedia && !retainForPublish {
                    try? FileManager.default.removeItem(at: previewURL)
                }
            }

            let asset = AVAsset(url: sourceURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let image = try? UIImage(
                cgImage: generator.copyCGImage(at: .zero, actualTime: nil)
            )

            DispatchQueue.main.async {
                guard let self, let image else {
                    if retainForPublish {
                        try? FileManager.default.removeItem(at: previewURL)
                    }
                    self?.showWexloToast("The selected video could not be previewed.")
                    return
                }
                if retainForPublish {
                    self.selectedMediaKind = .video
                    self.selectedVideoURL = previewURL
                }
                self.selectedMedia = image
                self.mediaPreview.configure(image: image)
            }
        }
    }

    private func resetPublishForm() {
        removeStagedVideo()
        selectedMedia = nil
        selectedMediaKind = .image
        titleField.text = nil
        notesTextView.text = nil
        notesTextView.updatePlaceholderVisibility()
        layerFields.forEach { $0.text = nil }
        mediaPreview.configure(image: nil)
    }

    private func removeStagedVideo() {
        if let selectedVideoURL {
            try? FileManager.default.removeItem(at: selectedVideoURL)
        }
        selectedVideoURL = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        notesTextView.updatePlaceholderVisibility()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let convertedFrame = view.convert(frame, from: nil)
        keyboardBottomInset = max(
            0,
            view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom
        )
        let bottomInset = 112 + keyboardBottomInset + 16
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        ) {
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }

        guard let activeView = view.findFirstResponder() else { return }
        DispatchQueue.main.async { [weak self, weak activeView] in
            guard let self, let activeView else { return }
            let rect = activeView.convert(activeView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -24), animated: true)
        }
    }
}

private final class PublishMediaPreviewView: UIView {
    private let imageView = UIImageView()
    private let shadeView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tapButton = UIButton(type: .custom)
    private let addButton = UIButton(type: .system)
    private let shadeGradientLayer = CAGradientLayer()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = WexloTheme.surface
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = WexloTheme.hairline.cgColor
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        shadeGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.48).cgColor
        ]
        shadeGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        shadeGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        shadeView.layer.addSublayer(shadeGradientLayer)
        titleLabel.text = "Your next outside fit"
        titleLabel.textColor = .white
        titleLabel.font = WexloTheme.font(size: 23, weight: .bold)
        subtitleLabel.text = "Upload a photo or video to get started."
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = WexloTheme.font(size: 16)

        tapButton.accessibilityLabel = "Add a photo or video"
        tapButton.addTarget(self, action: #selector(didTapPreview), for: .touchUpInside)

        addButton.setImage(
            UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            ),
            for: .normal
        )
        addButton.tintColor = WexloTheme.primaryText
        addButton.backgroundColor = WexloTheme.background
        addButton.layer.cornerRadius = 30
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = WexloTheme.hairline.cgColor
        addButton.accessibilityLabel = "Add a photo or video"
        addButton.addTarget(self, action: #selector(didTapPreview), for: .touchUpInside)

        [imageView, shadeView, titleLabel, subtitleLabel, tapButton, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            shadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadeView.topAnchor.constraint(equalTo: topAnchor),
            shadeView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -10),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            tapButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapButton.topAnchor.constraint(equalTo: topAnchor),
            tapButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            addButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(image: UIImage?) {
        let hasMedia = image != nil
        imageView.image = image
        imageView.isHidden = !hasMedia
        shadeView.isHidden = !hasMedia
        titleLabel.isHidden = !hasMedia
        subtitleLabel.isHidden = !hasMedia
        addButton.isHidden = hasMedia
        tapButton.accessibilityLabel = hasMedia ? "Change photo or video" : "Add a photo or video"
        addButton.accessibilityLabel = "Add a photo or video"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadeGradientLayer.frame = shadeView.bounds
    }

    @objc private func didTapPreview() {
        onTap?()
    }
}

private final class PublishDashedHintView: UIView {
    private let hintLabel = UILabel()
    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = WexloTheme.secondaryText.withAlphaComponent(0.42).cgColor
        borderLayer.lineWidth = 1.2
        borderLayer.lineDashPattern = [4, 3]
        layer.addSublayer(borderLayer)

        hintLabel.text = "The more complete this is, the easier it is for people to\nunderstand your outfit logic."
        hintLabel.textColor = WexloTheme.secondaryText
        hintLabel.font = WexloTheme.font(size: 16)
        hintLabel.numberOfLines = 0
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 1, dy: 1),
            cornerRadius: 18
        ).cgPath
    }
}

private final class PublishPlaceholderTextView: UITextView {
    private let placeholderLabel = UILabel()

    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        placeholderLabel.textColor = WexloTheme.secondaryText.withAlphaComponent(0.72)
        placeholderLabel.font = WexloTheme.font(size: 20)
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 21),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 17)
        ])
        updatePlaceholderVisibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}

private extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let responder = subview.findFirstResponder() {
                return responder
            }
        }
        return nil
    }
}
