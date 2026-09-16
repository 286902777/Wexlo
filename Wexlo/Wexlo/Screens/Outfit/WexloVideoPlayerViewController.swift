import AVKit
import UIKit

final class WexloVideoPlayerViewController: UIViewController {
    private let videoFileName: String
    private let storage: WexloMediaStorage
    private let navigationHeader = WexloNavigationHeader(style: .titled("Video"))
    private let playerViewController = AVPlayerViewController()
    private var player: AVPlayer?

    init?(
        videoFileName: String,
        storage: WexloMediaStorage = .bundled
    ) {
        guard WexloVideoMedia.url(for: videoFileName, storage: storage) != nil else {
            return nil
        }
        self.videoFileName = videoFileName
        self.storage = storage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureNavigation()
        configurePlayer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        playerViewController.player = nil
        player = nil
    }

    private func configureNavigation() {
        navigationHeader.backgroundColor = .white
        navigationHeader.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationHeader)

        NSLayoutConstraint.activate([
            navigationHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configurePlayer() {
        guard let fileURL = WexloVideoMedia.url(for: videoFileName, storage: storage) else {
            showWexloToast("Video unavailable.")
            return
        }

        let player = AVPlayer(url: fileURL)
        self.player = player
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
        playerViewController.view.backgroundColor = .black

        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: navigationHeader.bottomAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        playerViewController.didMove(toParent: self)
        player.play()
    }
}
