import UIKit

final class CompleteProfileViewController: WexloAuthPageViewController {
    private let userID: String?
    private let pendingEmail: String?
    private let pendingPassword: String?
    private let profilePhotoCard = WexloProfilePhotoCard()
    var onProfileSaved: (() -> Void)?
    var onRegistrationSaved: ((String) -> Void)?

    init(userID: String) {
        self.userID = userID
        pendingEmail = nil
        pendingPassword = nil
        super.init(title: "Complete your profile", subtitle: "A few details help people discover your style and make the community feel more personal.", submitTitle: "Save", fields: [
            WexloAuthField(title: "Nickname", placeholder: "How should we call you?", isSecure: false),
            WexloAuthField(title: "Date of birth", placeholder: "MM / DD / YYYY", isSecure: false),
            WexloAuthField(title: "Location", placeholder: "City or region", isSecure: false),
            WexloAuthField(title: "Country code", placeholder: "US", isSecure: false),
            WexloAuthField(title: "Gender", placeholder: "Male or Female", isSecure: false)
        ])
        configureView()
    }

    init(email: String, password: String) {
        userID = nil
        pendingEmail = email
        pendingPassword = password
        super.init(title: "Complete your profile", subtitle: "A few details help people discover your style and make the community feel more personal.", submitTitle: "Save", fields: [
            WexloAuthField(title: "Nickname", placeholder: "How should we call you?", isSecure: false),
            WexloAuthField(title: "Date of birth", placeholder: "MM / DD / YYYY", isSecure: false),
            WexloAuthField(title: "Location", placeholder: "City or region", isSecure: false),
            WexloAuthField(title: "Country code", placeholder: "US", isSecure: false),
            WexloAuthField(title: "Gender", placeholder: "Male or Female", isSecure: false)
        ])
        configureView()
    }

    private func configureView() {
        configureHeader(showsBackButton: false, showsLogo: false, eyebrowText: "Welcome to Wexlo")
        configureFormHorizontalInset(14)
        configureFormHeader(profilePhotoCard, height: 88)
        profilePhotoCard.onAddPhoto = { [weak self] in
            self?.showWexloToast("Photo selection is not available yet.")
        }
        onSubmit = { [weak self] values in
            guard let self else { return }
            let profile = WexloUserProfile(
                nickname: values[0],
                dateOfBirth: values[1],
                location: "\(values[2]) · \(values[3])",
                gender: values[4]
            )
            do {
                if let userID {
                    try WexloAccountStore.shared.saveProfile(profile, for: userID)
                    finishSubmission { [weak self] in
                        self?.onProfileSaved?()
                    }
                } else if let pendingEmail, let pendingPassword {
                    let userID = try WexloAccountStore.shared.register(
                        email: pendingEmail,
                        password: pendingPassword,
                        profile: profile
                    )
                    finishSubmission { [weak self] in
                        self?.onRegistrationSaved?(userID)
                    }
                }
            } catch let error as WexloAccountError {
                failSubmission(error.userMessage)
            } catch {
                failSubmission("Profile could not be saved. Please try again.")
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

final class WexloProfilePhotoCard: UIView {
    private let placeholderView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    var onAddPhoto: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = WexloTheme.surface
        layer.cornerRadius = 28
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 16

        placeholderView.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.68, alpha: 1)
        placeholderView.layer.cornerRadius = 22
        titleLabel.text = "Profile photo"
        titleLabel.font = WexloTheme.font(size: 20, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        subtitleLabel.text = "Choose a photo that feels like you."
        subtitleLabel.font = WexloTheme.font(size: 14)
        subtitleLabel.textColor = WexloTheme.secondaryText
        addButton.setTitle("Add photo", for: .normal)
        addButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        addButton.titleLabel?.font = WexloTheme.font(size: 16, weight: .bold)
        addButton.layer.cornerRadius = 20
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = WexloTheme.hairline.cgColor
        addButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)

        [placeholderView, titleLabel, subtitleLabel, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            placeholderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            placeholderView.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderView.widthAnchor.constraint(equalToConstant: 66),
            placeholderView.heightAnchor.constraint(equalTo: placeholderView.widthAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: placeholderView.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            addButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            addButton.widthAnchor.constraint(equalToConstant: 92),
            addButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    @objc private func didTapAddPhoto() { onAddPhoto?() }
}
