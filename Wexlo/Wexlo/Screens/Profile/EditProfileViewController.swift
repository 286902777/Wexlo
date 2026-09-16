import PhotosUI
import UIKit

final class EditProfileViewController: UIViewController, UITextFieldDelegate, PHPickerViewControllerDelegate {
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let formStack = UIStackView()

    private let photoCard = UIView()
    private let profileImageView = UIImageView()
    private let photoTitleLabel = UILabel()
    private let photoSubtitleLabel = UILabel()
    private let changePhotoButton = UIButton(type: .system)

    private let displayNameLabel = UILabel()
    private let nameTextField = UITextField()
    private let displayNameHintLabel = UILabel()
    private let bioLabel = UILabel()
    private let bioTextView = UITextView()
    private let bioHintLabel = UILabel()

    private let saveBackground = GradientView()
    private let saveButton = UIButton(type: .system)
    private let sessionStore = WexloSessionStore.shared
    private let accountStore = WexloAccountStore.shared
    private let loadingOverlay = WexloLoadingOverlay()
    private var saveBottomConstraint: NSLayoutConstraint?
    private var isSaving = false

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureHeader()
        configureForm()
        configureSaveButton()
        configureKeyboardHandling()
        loadCurrentProfile()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureHeader() {
        backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        titleLabel.text = "Edit Profile"
        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 32, weight: .bold)

        [backButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),

            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 36),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func configureForm() {
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset.bottom = 24
        scrollView.verticalScrollIndicatorInsets.bottom = 24

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(dismissTap)

        contentView.backgroundColor = .clear
        formStack.axis = .vertical
        formStack.alignment = .fill
        formStack.spacing = 0

        configurePhotoCard()
        configureFields()

        formStack.addArrangedSubview(photoCard)
        formStack.setCustomSpacing(36, after: photoCard)
        formStack.addArrangedSubview(displayNameLabel)
        formStack.setCustomSpacing(12, after: displayNameLabel)
        formStack.addArrangedSubview(nameTextField)
        formStack.setCustomSpacing(12, after: nameTextField)
        formStack.addArrangedSubview(displayNameHintLabel)
        formStack.setCustomSpacing(38, after: displayNameHintLabel)
        formStack.addArrangedSubview(bioLabel)
        formStack.setCustomSpacing(12, after: bioLabel)
        formStack.addArrangedSubview(bioTextView)
        formStack.setCustomSpacing(12, after: bioTextView)
        formStack.addArrangedSubview(bioHintLabel)

        [scrollView, contentView, formStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28)
        ])
    }

    private func configurePhotoCard() {
        photoCard.backgroundColor = WexloTheme.surface
        photoCard.layer.cornerRadius = 28
        photoCard.layer.borderWidth = 1
        photoCard.layer.borderColor = WexloTheme.hairline.cgColor
        photoCard.clipsToBounds = true

        profileImageView.image = UIImage(named: "wexlo_profile_avatar")
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 28
        profileImageView.clipsToBounds = true

        photoTitleLabel.text = "Profile photo"
        photoTitleLabel.textColor = WexloTheme.primaryText
        photoTitleLabel.font = WexloTheme.font(size: 21, weight: .bold)

        photoSubtitleLabel.text = "Use a clear photo that feels like you."
        photoSubtitleLabel.textColor = WexloTheme.secondaryText
        photoSubtitleLabel.font = WexloTheme.font(size: 16)
        photoSubtitleLabel.numberOfLines = 2

        changePhotoButton.setTitle("Change photo", for: .normal)
        changePhotoButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        changePhotoButton.titleLabel?.font = WexloTheme.font(size: 16, weight: .bold)
        changePhotoButton.layer.cornerRadius = 24
        changePhotoButton.layer.borderWidth = 1
        changePhotoButton.layer.borderColor = WexloTheme.hairline.cgColor
        changePhotoButton.addTarget(self, action: #selector(didTapChangePhoto), for: .touchUpInside)

        let photoInfoStack = UIStackView(arrangedSubviews: [
            photoTitleLabel,
            photoSubtitleLabel,
            changePhotoButton
        ])
        photoInfoStack.axis = .vertical
        photoInfoStack.alignment = .leading
        photoInfoStack.spacing = 8

        [profileImageView, photoInfoStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            photoCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            photoCard.heightAnchor.constraint(equalToConstant: 152),

            profileImageView.leadingAnchor.constraint(equalTo: photoCard.leadingAnchor, constant: 20),
            profileImageView.centerYAnchor.constraint(equalTo: photoCard.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 112),
            profileImageView.heightAnchor.constraint(equalToConstant: 112),

            photoInfoStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 20),
            photoInfoStack.trailingAnchor.constraint(equalTo: photoCard.trailingAnchor, constant: -20),
            photoInfoStack.centerYAnchor.constraint(equalTo: photoCard.centerYAnchor),

            changePhotoButton.heightAnchor.constraint(equalToConstant: 48),
            changePhotoButton.widthAnchor.constraint(equalToConstant: 144)
        ])
    }

    private func configureFields() {
        displayNameLabel.text = "Display name"
        displayNameLabel.textColor = WexloTheme.primaryText
        displayNameLabel.font = WexloTheme.font(size: 18, weight: .bold)

        nameTextField.text = ""
        nameTextField.textColor = WexloTheme.primaryText
        nameTextField.font = WexloTheme.font(size: 18)
        nameTextField.backgroundColor = WexloTheme.surface
        nameTextField.layer.cornerRadius = 24
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = WexloTheme.hairline.cgColor
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
        nameTextField.leftViewMode = .always
        nameTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
        nameTextField.rightViewMode = .always
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.heightAnchor.constraint(equalToConstant: 72).isActive = true

        displayNameHintLabel.text = "This is the name people see on your outfits."
        displayNameHintLabel.textColor = WexloTheme.secondaryText
        displayNameHintLabel.font = WexloTheme.font(size: 15)
        displayNameHintLabel.numberOfLines = 0

        bioLabel.text = "Bio"
        bioLabel.textColor = WexloTheme.primaryText
        bioLabel.font = WexloTheme.font(size: 18, weight: .bold)

        bioTextView.text = ""
        bioTextView.textColor = WexloTheme.primaryText
        bioTextView.font = WexloTheme.font(size: 18)
        bioTextView.backgroundColor = WexloTheme.surface
        bioTextView.layer.cornerRadius = 24
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.borderColor = WexloTheme.hairline.cgColor
        bioTextView.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        bioTextView.textContainer.lineFragmentPadding = 0
        bioTextView.isScrollEnabled = false
        bioTextView.returnKeyType = .default
        bioTextView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        bioHintLabel.text = "Keep it short and make it yours."
        bioHintLabel.textColor = WexloTheme.secondaryText
        bioHintLabel.font = WexloTheme.font(size: 15)
        bioHintLabel.numberOfLines = 0
    }

    private func loadCurrentProfile() {
        guard case .authenticated(let userID) = sessionStore.current else {
            return
        }
        if let profile = accountStore.profile(for: userID) {
            nameTextField.text = profile.nickname
            bioTextView.text = profile.bio
            if let avatarData = profile.avatarData,
               let avatarImage = UIImage(data: avatarData) {
                profileImageView.image = avatarImage
            } else if let avatarAssetName = profile.avatarAssetName,
                      let avatarImage = UIImage(named: avatarAssetName) {
                profileImageView.image = avatarImage
            }
        }
    }

    private func configureSaveButton() {
        saveBackground.layer.cornerRadius = 28
        saveBackground.layer.masksToBounds = true

        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        saveButton.titleLabel?.font = WexloTheme.font(size: 20, weight: .bold)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        saveBackground.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveBackground)
        saveBackground.addSubview(saveButton)

        saveBottomConstraint = saveBackground.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -14
        )

        NSLayoutConstraint.activate([
            saveBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveBackground.heightAnchor.constraint(equalToConstant: 56),
            saveBottomConstraint!,

            saveButton.topAnchor.constraint(equalTo: saveBackground.topAnchor),
            saveButton.leadingAnchor.constraint(equalTo: saveBackground.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: saveBackground.trailingAnchor),
            saveButton.bottomAnchor.constraint(equalTo: saveBackground.bottomAnchor),

            scrollView.bottomAnchor.constraint(equalTo: saveBackground.topAnchor, constant: -24)
        ])
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func didTapBack() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapSave() {
        guard !isSaving else { return }
        let displayName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !displayName.isEmpty else {
            showToast("Please enter a display name.")
            return
        }

        guard case .authenticated(let userID) = sessionStore.current else {
            showWexloToast("Please sign in to edit your profile.")
            return
        }

        isSaving = true
        saveButton.isEnabled = false
        view.endEditing(true)
        loadingOverlay.show(in: view)

        let existingProfile = accountStore.profile(for: userID)
        let updatedProfile = WexloUserProfile(
            nickname: displayName,
            dateOfBirth: existingProfile?.dateOfBirth ?? "",
            location: existingProfile?.location ?? "",
            gender: existingProfile?.gender ?? "",
            bio: bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarAssetName: existingProfile?.avatarAssetName,
            avatarData: profileImageView.image?.jpegData(compressionQuality: 0.82)
        )

        do {
            try accountStore.saveProfile(updatedProfile, for: userID)
            let destination = navigationController?.viewControllers.dropLast().last
            completeWexloLoading(loadingOverlay) { [weak self] in
                guard let self else { return }
                isSaving = false
                saveButton.isEnabled = true
                navigationController?.popViewController(animated: true)
                DispatchQueue.main.async {
                    destination?.showWexloToast("Profile saved successfully.")
                }
            }
        } catch let error as WexloAccountError {
            loadingOverlay.hide()
            isSaving = false
            saveButton.isEnabled = true
            showWexloToast(error.userMessage)
        } catch {
            loadingOverlay.hide()
            isSaving = false
            saveButton.isEnabled = true
            showWexloToast("Profile could not be saved. Please try again.")
        }
    }

    @objc private func didTapChangePhoto() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
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
                self?.profileImageView.image = image
            }
        }
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
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom)
        saveBottomConstraint?.constant = overlap > 0 ? -(overlap + 10) : -14

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        ) {
            self.view.layoutIfNeeded()
        }
    }

    private func showToast(_ message: String) {
        let label = WexloToastLabel()
        label.text = message
        label.textColor = .white
        label.backgroundColor = WexloTheme.tabBar.withAlphaComponent(0.92)
        label.font = WexloTheme.font(size: 13, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: saveBackground.topAnchor, constant: -14),
            label.heightAnchor.constraint(equalToConstant: 42),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40)
        ])

        UIView.animate(
            withDuration: 0.2,
            delay: 1.5,
            options: []
        ) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}
