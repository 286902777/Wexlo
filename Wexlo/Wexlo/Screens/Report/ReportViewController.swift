import UIKit

final class ReportViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let backButton = UIButton(type: .custom)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let pageTitleLabel = UILabel()
    private let pageSubtitleLabel = UILabel()
    private let reportCardView = UIView()
    private let questionLabel = UILabel()
    private let questionSubtitleLabel = UILabel()
    private let reasonsTableView = UITableView(frame: .zero, style: .plain)
    private let submitButton = ReportSubmitButton(type: .custom)
    private let loadingOverlay = WexloLoadingOverlay()

    private let reasons = [
        "Spam or scam",
        "Harassment or bullying",
        "Hate speech",
        "Nudity or sexual content",
        "Dangerous activity",
        "False water or safety information",
        "Other"
    ]
    private var selectedReasonIndex = 0
    private var isSubmitting = false

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WexloTheme.background
        configureBackButton()
        configureSubmitButton()
        configureScrollView()
        configureReportCard()
    }

    private func configureBackButton() {
        let backImage = UIImage(named: "wexlo_button_back")
            ?? UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = WexloTheme.primaryText
        backButton.backgroundColor = WexloTheme.surface
        backButton.layer.cornerRadius = 17.5
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = WexloTheme.hairline.cgColor
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }

    private func configureScrollView() {
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        pageTitleLabel.text = "Report"
        pageTitleLabel.textColor = WexloTheme.primaryText
        pageTitleLabel.font = WexloTheme.font(size: 32, weight: .black)

        pageSubtitleLabel.text = "Help keep Wexlo welcoming. Choose the reason that best describes the issue."
        pageSubtitleLabel.textColor = WexloTheme.secondaryText
        pageSubtitleLabel.font = WexloTheme.font(size: 17)
        pageSubtitleLabel.numberOfLines = 0

        [pageTitleLabel, pageSubtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -16),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            pageTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 78),
            pageTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pageTitleLabel.heightAnchor.constraint(equalToConstant: 40),

            pageSubtitleLabel.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 15),
            pageSubtitleLabel.leadingAnchor.constraint(equalTo: pageTitleLabel.leadingAnchor),
            pageSubtitleLabel.trailingAnchor.constraint(equalTo: pageTitleLabel.trailingAnchor),
            pageSubtitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }

    private func configureReportCard() {
        reportCardView.backgroundColor = WexloTheme.surface
        reportCardView.layer.cornerRadius = 25
        reportCardView.layer.borderWidth = 1
        reportCardView.layer.borderColor = WexloTheme.hairline.cgColor
        reportCardView.layer.shadowColor = UIColor.black.cgColor
        reportCardView.layer.shadowOpacity = 0.035
        reportCardView.layer.shadowRadius = 14
        reportCardView.layer.shadowOffset = CGSize(width: 0, height: 5)
        reportCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reportCardView)

        questionLabel.text = "Why are you reporting this?"
        questionLabel.textColor = WexloTheme.primaryText
        questionLabel.font = WexloTheme.font(size: 22, weight: .bold)
        questionLabel.numberOfLines = 1

        questionSubtitleLabel.text = "Select one reason to continue."
        questionSubtitleLabel.textColor = WexloTheme.secondaryText
        questionSubtitleLabel.font = WexloTheme.font(size: 16)

        [questionLabel, questionSubtitleLabel, reasonsTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            reportCardView.addSubview($0)
        }

        reasonsTableView.backgroundColor = .clear
        reasonsTableView.separatorStyle = .none
        reasonsTableView.isScrollEnabled = false
        reasonsTableView.allowsMultipleSelection = false
        reasonsTableView.rowHeight = 64
        reasonsTableView.dataSource = self
        reasonsTableView.delegate = self
        reasonsTableView.register(
            ReportReasonCell.self,
            forCellReuseIdentifier: ReportReasonCell.reuseIdentifier
        )

        NSLayoutConstraint.activate([
            reportCardView.topAnchor.constraint(equalTo: pageSubtitleLabel.bottomAnchor, constant: 40),
            reportCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            reportCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            reportCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            questionLabel.topAnchor.constraint(equalTo: reportCardView.topAnchor, constant: 29),
            questionLabel.leadingAnchor.constraint(equalTo: reportCardView.leadingAnchor, constant: 24),
            questionLabel.trailingAnchor.constraint(equalTo: reportCardView.trailingAnchor, constant: -24),
            questionLabel.heightAnchor.constraint(equalToConstant: 28),

            questionSubtitleLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 7),
            questionSubtitleLabel.leadingAnchor.constraint(equalTo: questionLabel.leadingAnchor),
            questionSubtitleLabel.trailingAnchor.constraint(equalTo: questionLabel.trailingAnchor),
            questionSubtitleLabel.heightAnchor.constraint(equalToConstant: 22),

            reasonsTableView.topAnchor.constraint(equalTo: questionSubtitleLabel.bottomAnchor, constant: 20),
            reasonsTableView.leadingAnchor.constraint(equalTo: reportCardView.leadingAnchor, constant: 24),
            reasonsTableView.trailingAnchor.constraint(equalTo: reportCardView.trailingAnchor, constant: -24),
            reasonsTableView.heightAnchor.constraint(equalToConstant: CGFloat(reasons.count) * 64),
            reasonsTableView.bottomAnchor.constraint(equalTo: reportCardView.bottomAnchor, constant: -19)
        ])
    }

    private func configureSubmitButton() {
        submitButton.setTitle("Report", for: .normal)
        submitButton.setTitleColor(WexloTheme.primaryText, for: .normal)
        submitButton.titleLabel?.font = WexloTheme.font(size: 20, weight: .bold)
        submitButton.accessibilityLabel = "Report"
        submitButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            submitButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reasons.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReportReasonCell.reuseIdentifier,
            for: indexPath
        ) as! ReportReasonCell
        cell.configure(title: reasons[indexPath.row], isSelected: indexPath.row == selectedReasonIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard reasons.indices.contains(indexPath.row),
              indexPath.row != selectedReasonIndex else {
            return
        }

        let previousIndexPath = IndexPath(row: selectedReasonIndex, section: 0)
        selectedReasonIndex = indexPath.row
        tableView.reloadRows(
            at: [previousIndexPath, indexPath],
            with: .none
        )
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapSubmit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        submitButton.isUserInteractionEnabled = false
        loadingOverlay.show(in: view)
        completeWexloLoading(
            loadingOverlay,
            toast: "Report submitted.",
            after: WexloOperationFeedback.loadingDuration
        ) { [weak self] in
            self?.isSubmitting = false
            self?.submitButton.isUserInteractionEnabled = true
        }
    }
}

private final class ReportReasonCell: UITableViewCell {
    static let reuseIdentifier = "ReportReasonCell"

    private let cardView = UIView()
    private let radioView = UIView()
    private let radioDotView = UIView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = WexloTheme.surface
        cardView.layer.cornerRadius = 26
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = WexloTheme.hairline.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        radioView.backgroundColor = WexloTheme.surface
        radioView.layer.cornerRadius = 11
        radioView.layer.borderWidth = 2
        radioView.layer.borderColor = WexloTheme.secondaryText.withAlphaComponent(0.55).cgColor
        radioView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(radioView)

        radioDotView.backgroundColor = WexloTheme.primaryText
        radioDotView.layer.cornerRadius = 5
        radioDotView.translatesAutoresizingMaskIntoConstraints = false
        radioView.addSubview(radioDotView)

        titleLabel.textColor = WexloTheme.primaryText
        titleLabel.font = WexloTheme.font(size: 17, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),

            radioView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            radioView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            radioView.widthAnchor.constraint(equalToConstant: 22),
            radioView.heightAnchor.constraint(equalToConstant: 22),

            radioDotView.centerXAnchor.constraint(equalTo: radioView.centerXAnchor),
            radioDotView.centerYAnchor.constraint(equalTo: radioView.centerYAnchor),
            radioDotView.widthAnchor.constraint(equalToConstant: 10),
            radioDotView.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: radioView.trailingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        radioDotView.isHidden = !isSelected
        radioView.layer.borderColor = (
            isSelected
                ? WexloTheme.primaryText
                : WexloTheme.secondaryText.withAlphaComponent(0.55)
        ).cgColor
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
    }
}

private final class ReportSubmitButton: UIButton {
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
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 7)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.cornerRadius = bounds.height / 2
    }
}
