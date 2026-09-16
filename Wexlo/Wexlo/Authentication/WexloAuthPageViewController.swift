import UIKit

struct WexloAuthField {
    let title: String
    let placeholder: String
    let isSecure: Bool
}

class WexloAuthPageViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UITextFieldDelegate {

    let fields: [WexloAuthField]
    let collectionView: UICollectionView
    var onSubmit: (([String]) -> Void)?
    var onValidate: (([String]) -> String?)?
    var onBack: (() -> Void)?

    private let pageTitle: String
    private let pageSubtitle: String
    private let submitTitle: String
    private let backButton = UIButton(type: .custom)
    private let logoImageView = UIImageView(image: UIImage(named: "wexlo_auth_logo"))
    private let eyebrowView = UIView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let submitBackground = GradientView()
    private let submitButton = UIButton(type: .system)
    private let auxiliaryButton = UIButton(type: .system)
    private var bottomConstraint: NSLayoutConstraint?
    private var auxiliaryHeightConstraint: NSLayoutConstraint?
    private var auxiliaryTopConstraint: NSLayoutConstraint?
    private var formHeaderView: UIView?
    private var formHeaderHeight: CGFloat = 0
    private var formHorizontalInset: CGFloat = 28
    private var showsBackButton = true
    private var showsLogo = true
    private var eyebrowText: String?
    private var values: [Int: String] = [:]
    private var isSubmitting = false
    private let loadingOverlay = WexloLoadingOverlay()

    init(title: String, subtitle: String, submitTitle: String, fields: [WexloAuthField]) {
        pageTitle = title
        pageSubtitle = subtitle
        self.submitTitle = submitTitle
        self.fields = fields
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 28, bottom: 24, right: 28)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureHeader()
        configureCollectionView()
        configureSubmitButton()
        configureKeyboardHandling()
    }

    private func configureHeader() {
        if showsBackButton {
            backButton.setImage(UIImage(named: "wexlo_button_back"), for: .normal)
            backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        }
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.clipsToBounds = true
        logoImageView.layer.cornerRadius = 18
        eyebrowView.backgroundColor = UIColor(red: 1.0, green: 0.91, blue: 0.85, alpha: 1)
        eyebrowView.layer.cornerRadius = 16
        eyebrowLabel.text = eyebrowText
        eyebrowLabel.font = WexloTheme.font(size: 15, weight: .semibold)
        eyebrowLabel.textColor = UIColor(red: 0.58, green: 0.31, blue: 0.17, alpha: 1)
        titleLabel.text = pageTitle
        titleLabel.font = WexloTheme.font(size: 28, weight: .bold)
        titleLabel.textColor = WexloTheme.primaryText
        subtitleLabel.text = pageSubtitle
        subtitleLabel.font = WexloTheme.font(size: 14)
        subtitleLabel.textColor = WexloTheme.secondaryText
        subtitleLabel.numberOfLines = 2

        var headerViews: [UIView] = []
        if showsBackButton { headerViews.append(backButton) }
        if showsLogo { headerViews.append(logoImageView) }
        if eyebrowText != nil {
            eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
            eyebrowView.addSubview(eyebrowLabel)
            headerViews.append(eyebrowView)
        }
        headerViews.append(contentsOf: [titleLabel, subtitleLabel])
        headerViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        var constraints: [NSLayoutConstraint] = [
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: formHorizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -formHorizontalInset),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ]
        if showsBackButton {
            constraints += [
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
                backButton.widthAnchor.constraint(equalToConstant: 36),
                backButton.heightAnchor.constraint(equalToConstant: 36)
            ]
        }
        if showsLogo {
            constraints += [
                logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
                logoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
                logoImageView.widthAnchor.constraint(equalToConstant: 56),
                logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
                titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 14)
            ]
        } else if eyebrowText != nil {
            constraints += [
                eyebrowView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
                eyebrowView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: formHorizontalInset),
                eyebrowView.heightAnchor.constraint(equalToConstant: 32),
                eyebrowLabel.leadingAnchor.constraint(equalTo: eyebrowView.leadingAnchor, constant: 14),
                eyebrowLabel.trailingAnchor.constraint(equalTo: eyebrowView.trailingAnchor, constant: -14),
                eyebrowLabel.topAnchor.constraint(equalTo: eyebrowView.topAnchor),
                eyebrowLabel.bottomAnchor.constraint(equalTo: eyebrowView.bottomAnchor),
                titleLabel.topAnchor.constraint(equalTo: eyebrowView.bottomAnchor, constant: 10)
            ]
        } else {
            constraints.append(titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 0, left: formHorizontalInset, bottom: 24, right: formHorizontalInset)
        }
        collectionView.register(WexloTextFieldCell.self, forCellWithReuseIdentifier: WexloTextFieldCell.reuseIdentifier)
        collectionView.register(WexloGenderCell.self, forCellWithReuseIdentifier: WexloGenderCell.reuseIdentifier)
        collectionView.register(WexloCountryCell.self, forCellWithReuseIdentifier: WexloCountryCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        var constraints: [NSLayoutConstraint] = [
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        if let formHeaderView {
            formHeaderView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(formHeaderView)
            constraints += [
                formHeaderView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
                formHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: formHorizontalInset),
                formHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -formHorizontalInset),
                formHeaderView.heightAnchor.constraint(equalToConstant: formHeaderHeight),
                collectionView.topAnchor.constraint(equalTo: formHeaderView.bottomAnchor, constant: 18)
            ]
        } else {
            constraints.append(collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16))
        }
        NSLayoutConstraint.activate(constraints)

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    private func configureSubmitButton() {
        submitBackground.colors = [
            UIColor(red: 1.0, green: 0.62, blue: 0.39, alpha: 1),
            UIColor(red: 0.88, green: 0.44, blue: 0.69, alpha: 1)
        ]
        submitBackground.layer.cornerRadius = 24
        submitBackground.layer.shadowColor = UIColor(red: 0.83, green: 0.42, blue: 0.27, alpha: 1).cgColor
        submitBackground.layer.shadowOpacity = 0.16
        submitBackground.layer.shadowOffset = CGSize(width: 0, height: 8)
        submitBackground.layer.shadowRadius = 12
        submitButton.setTitle(submitTitle, for: .normal)
        submitButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        submitButton.titleLabel?.font = WexloTheme.font(size: 20, weight: .bold)
        submitButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        auxiliaryButton.setTitleColor(UIColor(red: 0.58, green: 0.31, blue: 0.17, alpha: 1), for: .normal)
        auxiliaryButton.titleLabel?.font = WexloTheme.font(size: 16, weight: .semibold)
        auxiliaryButton.contentHorizontalAlignment = .right
        auxiliaryButton.isHidden = true
        submitBackground.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        auxiliaryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitBackground)
        view.addSubview(auxiliaryButton)
        submitBackground.addSubview(submitButton)
        bottomConstraint = submitBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        auxiliaryHeightConstraint = auxiliaryButton.heightAnchor.constraint(equalToConstant: 0)
        auxiliaryTopConstraint = auxiliaryButton.topAnchor.constraint(equalTo: collectionView.topAnchor)
        NSLayoutConstraint.activate([
            submitBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            submitBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            submitBackground.heightAnchor.constraint(equalToConstant: 58),
            bottomConstraint!,
            auxiliaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            auxiliaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            auxiliaryTopConstraint!,
            auxiliaryHeightConstraint!,
            submitButton.topAnchor.constraint(equalTo: submitBackground.topAnchor),
            submitButton.leadingAnchor.constraint(equalTo: submitBackground.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: submitBackground.trailingAnchor),
            submitButton.bottomAnchor.constraint(equalTo: submitBackground.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: submitBackground.topAnchor, constant: -20)
        ])
    }

    private func configureKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { fields.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if fields[indexPath.item].title == "Country code" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WexloCountryCell.reuseIdentifier, for: indexPath) as! WexloCountryCell
            let value = values[indexPath.item] ?? "US"
            values[indexPath.item] = value
            cell.configure(value: value, tag: indexPath.item) { [weak self] tag, value in
                self?.values[tag] = value
            }
            return cell
        }
        if fields[indexPath.item].title == "Gender" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WexloGenderCell.reuseIdentifier, for: indexPath) as! WexloGenderCell
            let value = values[indexPath.item] ?? "Male"
            values[indexPath.item] = value
            cell.configure(value: value, tag: indexPath.item) { [weak self] tag, value in
                self?.values[tag] = value
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WexloTextFieldCell.reuseIdentifier, for: indexPath) as! WexloTextFieldCell
        cell.configure(
            field: fields[indexPath.item],
            value: values[indexPath.item],
            tag: indexPath.item,
            isLastField: indexPath.item == fields.count - 1,
            delegate: self
        )
        cell.onChange = { [weak self] tag, value in self?.values[tag] = value }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - formHorizontalInset * 2, height: 72)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if nextTag < fields.count,
           let nextCell = collectionView.cellForItem(at: IndexPath(item: nextTag, section: 0)) as? WexloTextFieldCell {
            nextCell.focus()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @objc private func didTapBack() {
        if let onBack { onBack() } else { navigationController?.popViewController(animated: true) }
    }

    @objc private func didTapSubmit() {
        guard !isSubmitting else { return }
        let orderedValues = fields.indices.map { values[$0, default: ""].trimmingCharacters(in: .whitespacesAndNewlines) }
        guard orderedValues.allSatisfy({ !$0.isEmpty }) else {
            showToast("Please complete every field.")
            return
        }
        if let validationMessage = onValidate?(orderedValues) {
            showToast(validationMessage)
            return
        }
        isSubmitting = true
        submitButton.isEnabled = false
        view.endEditing(true)
        loadingOverlay.show(in: view)
        onSubmit?(orderedValues)
        if onSubmit == nil {
            finishSubmission()
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    func finishSubmission(
        successMessage: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        completeWexloLoading(
            loadingOverlay,
            toast: successMessage,
            completion: { [weak self] in
                guard let self else { return }
                isSubmitting = false
                submitButton.isEnabled = true
                completion?()
            }
        )
    }

    func failSubmission(_ message: String) {
        isSubmitting = false
        submitButton.isEnabled = true
        loadingOverlay.hide()
        showToast(message)
    }

    func configureAuxiliaryAction(title: String, action: @escaping () -> Void) {
        auxiliaryButton.setTitle(title, for: .normal)
        auxiliaryButton.isHidden = false
        auxiliaryButton.addAction(
            UIAction { _ in action() },
            for: .touchUpInside
        )
        auxiliaryHeightConstraint?.constant = 28
        auxiliaryTopConstraint?.constant = CGFloat(fields.count * 72 + 8)
        view.layoutIfNeeded()
    }

    func configureHeader(showsBackButton: Bool, showsLogo: Bool, eyebrowText: String?) {
        self.showsBackButton = showsBackButton
        self.showsLogo = showsLogo
        self.eyebrowText = eyebrowText
    }

    func configureFormHeader(_ view: UIView, height: CGFloat) {
        formHeaderView = view
        formHeaderHeight = height
    }

    func configureFormHorizontalInset(_ inset: CGFloat) {
        formHorizontalInset = inset
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY - view.safeAreaInsets.bottom)
        bottomConstraint?.constant = overlap > 0 ? -(overlap + 10) : -14
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
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
            label.bottomAnchor.constraint(equalTo: submitBackground.topAnchor, constant: -14),
            label.heightAnchor.constraint(equalToConstant: 42),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40)
        ])
        UIView.animate(withDuration: 0.2, delay: 1.5, options: []) { label.alpha = 0 } completion: { _ in label.removeFromSuperview() }
    }
}

final class WexloTextFieldCell: UICollectionViewCell {
    static let reuseIdentifier = "WexloTextFieldCell"
    var onChange: ((Int, String) -> Void)?
    private let captionLabel = UILabel()
    private let textField = UITextField()
    private let datePicker = UIDatePicker()

    override init(frame: CGRect) {
        super.init(frame: frame)
        captionLabel.font = WexloTheme.font(size: 16, weight: .semibold)
        captionLabel.textColor = WexloTheme.primaryText
        textField.font = WexloTheme.font(size: 18)
        textField.textColor = WexloTheme.primaryText
        textField.backgroundColor = WexloTheme.surface
        textField.layer.cornerRadius = 16
        textField.layer.borderWidth = 1
        textField.layer.borderColor = WexloTheme.hairline.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 1))
        textField.leftViewMode = .always
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(valueChanged), for: .editingChanged)
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "en_US_POSIX")
        datePicker.calendar = Calendar(identifier: .gregorian)
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 1900, month: 1, day: 1))
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        [captionLabel, textField].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textField.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 7),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(
        field: WexloAuthField,
        value: String?,
        tag: Int,
        isLastField: Bool,
        delegate: UITextFieldDelegate
    ) {
        captionLabel.text = field.title
        textField.placeholder = field.placeholder
        textField.isSecureTextEntry = field.isSecure
        textField.text = value
        textField.tag = tag
        textField.delegate = delegate
        textField.textContentType = field.isSecure
            ? .password
            : (field.title == "Email" ? .emailAddress : .none)
        textField.keyboardType = field.title == "Email" ? .emailAddress : .default
        textField.returnKeyType = isLastField ? .done : .next
        if field.title == "Date of birth" {
            textField.inputView = datePicker
            textField.inputAccessoryView = makeDateToolbar()
        } else {
            textField.inputView = nil
            textField.inputAccessoryView = nil
        }
    }

    func focus() { textField.becomeFirstResponder() }
    @objc private func valueChanged() { onChange?(textField.tag, textField.text ?? "") }

    private func makeDateToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
                self?.textField.resignFirstResponder()
            })
        ]
        return toolbar
    }

    @objc private func dateChanged() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "MM / dd / yyyy"
        textField.text = formatter.string(from: datePicker.date)
        valueChanged()
    }
}

final class WexloGenderCell: UICollectionViewCell {
    static let reuseIdentifier = "WexloGenderCell"

    private let captionLabel = UILabel()
    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private var onChange: ((Int, String) -> Void)?
    private var fieldTag = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        captionLabel.text = "Gender"
        captionLabel.font = WexloTheme.font(size: 16, weight: .semibold)
        captionLabel.textColor = WexloTheme.primaryText
        configureButton(maleButton, title: "Male", tag: 0)
        configureButton(femaleButton, title: "Female", tag: 1)

        [captionLabel, maleButton, femaleButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            maleButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 7),
            maleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            maleButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -6),
            maleButton.heightAnchor.constraint(equalToConstant: 42),
            femaleButton.topAnchor.constraint(equalTo: maleButton.topAnchor),
            femaleButton.leadingAnchor.constraint(equalTo: maleButton.trailingAnchor, constant: 12),
            femaleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            femaleButton.heightAnchor.constraint(equalTo: maleButton.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(value: String?, tag: Int, onChange: @escaping (Int, String) -> Void) {
        fieldTag = tag
        self.onChange = onChange
        updateButton(maleButton, selected: value == "Male")
        updateButton(femaleButton, selected: value == "Female")
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.setTitleColor(WexloTheme.secondaryText, for: .normal)
        button.titleLabel?.font = WexloTheme.font(size: 16, weight: .semibold)
        button.backgroundColor = WexloTheme.surface
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = WexloTheme.hairline.cgColor
        button.addTarget(self, action: #selector(didTapGender(_:)), for: .touchUpInside)
    }

    private func updateButton(_ button: UIButton, selected: Bool) {
        button.backgroundColor = selected ? WexloTheme.primaryText : WexloTheme.surface
        button.setTitleColor(selected ? WexloTheme.surface : WexloTheme.secondaryText, for: .normal)
    }

    @objc private func didTapGender(_ sender: UIButton) {
        let value = sender.tag == 0 ? "Male" : "Female"
        updateButton(maleButton, selected: value == "Male")
        updateButton(femaleButton, selected: value == "Female")
        onChange?(fieldTag, value)
    }
}

final class WexloCountryCell: UICollectionViewCell {
    static let reuseIdentifier = "WexloCountryCell"

    private let captionLabel = UILabel()
    private let selectorButton = UIButton(type: .system)
    private var fieldTag = 0
    private var selectedCode = "US"
    private var onChange: ((Int, String) -> Void)?

    private let countryCodes = ["US", "CN", "JP", "KR", "GB", "CA", "AU", "DE", "FR"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        captionLabel.text = "Country code"
        captionLabel.font = WexloTheme.font(size: 16, weight: .semibold)
        captionLabel.textColor = WexloTheme.primaryText
        selectorButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        selectorButton.titleLabel?.font = WexloTheme.font(size: 18)
        selectorButton.contentHorizontalAlignment = .left
        selectorButton.configuration = .plain()
        selectorButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        selectorButton.configuration?.image = UIImage(systemName: "chevron.down")
        selectorButton.configuration?.imagePlacement = .trailing
        selectorButton.configuration?.imagePadding = 8
        selectorButton.backgroundColor = WexloTheme.surface
        selectorButton.layer.cornerRadius = 16
        selectorButton.layer.borderWidth = 1
        selectorButton.layer.borderColor = WexloTheme.hairline.cgColor
        selectorButton.showsMenuAsPrimaryAction = true

        [captionLabel, selectorButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectorButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 7),
            selectorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectorButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(value: String, tag: Int, onChange: @escaping (Int, String) -> Void) {
        selectedCode = countryCodes.contains(value) ? value : "US"
        fieldTag = tag
        self.onChange = onChange
        selectorButton.setTitle(selectedCode, for: .normal)
        selectorButton.menu = UIMenu(children: countryCodes.map { code in
            let action = UIAction(title: code, state: code == selectedCode ? .on : .off) { [weak self] _ in
                self?.selectedCode = code
                self?.selectorButton.setTitle(code, for: .normal)
                self?.selectorButton.menu = self?.makeMenu()
                self?.onChange?(self?.fieldTag ?? 0, code)
            }
            return action
        })
    }

    private func makeMenu() -> UIMenu {
        UIMenu(children: countryCodes.map { code in
            UIAction(title: code, state: code == selectedCode ? .on : .off) { [weak self] _ in
                self?.selectedCode = code
                self?.selectorButton.setTitle(code, for: .normal)
                self?.selectorButton.menu = self?.makeMenu()
                self?.onChange?(self?.fieldTag ?? 0, code)
            }
        })
    }
}
