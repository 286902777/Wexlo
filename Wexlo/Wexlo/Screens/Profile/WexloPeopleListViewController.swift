import UIKit

struct WexloPeopleListItem {
    let userID: String
    let name: String
    let handle: String
    let detail: String
    let avatarAssetName: String
    var actionTitle: String
}

enum WexloPeopleListKind: Equatable {
    case following
    case blockList
    case followers

    var title: String {
        switch self {
        case .following:
            return "Following"
        case .followers:
            return "Followers"
        case .blockList:
            return "Block list"
        }
    }

    var subtitle: String {
        switch self {
        case .following, .followers:
            return "People whose style you want to keep close."
        case .blockList:
            return "Accounts you have blocked will not interact with\nyou."
        }
    }

}

class WexloPeopleListViewController: WexloCollectionPageViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private let kind: WexloPeopleListKind
    private var people: [WexloPeopleListItem]
    private let relationshipStore = WexloRelationshipStore.shared
    private var isUpdatingRelationship = false

    init(kind: WexloPeopleListKind) {
        self.kind = kind
        self.people = Self.makePeople(for: kind)

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        super.init(
            headerStyle: .titled(""),
            trailingSymbol: nil,
            layout: layout
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.contentInset.bottom = 96
        collectionView.register(
            WexloPeopleListCell.self,
            forCellWithReuseIdentifier: WexloPeopleListCell.reuseIdentifier
        )
        collectionView.register(
            WexloPeopleListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: WexloPeopleListHeaderView.reuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadPeople),
            name: .wexloBlockedUserDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadPeople),
            name: .wexloSessionDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadPeople),
            name: .wexloRelationshipDidChange,
            object: nil
        )
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        people.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WexloPeopleListCell.reuseIdentifier,
            for: indexPath
        ) as! WexloPeopleListCell

        let position: WexloPeopleListCell.Position
        if people.count == 1 {
            position = .single
        } else if indexPath.item == 0 {
            position = .first
        } else if indexPath.item == people.count - 1 {
            position = .last
        } else {
            position = .middle
        }

        cell.configure(with: people[indexPath.item], position: position)
        cell.onAction = { [weak self, weak collectionView, weak cell] in
            guard let cell, let currentIndexPath = collectionView?.indexPath(for: cell) else {
                return
            }
            self?.performAction(at: currentIndexPath.item, collectionView: collectionView)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: WexloPeopleListHeaderView.reuseIdentifier,
            for: indexPath
        ) as! WexloPeopleListHeaderView
        header.configure(title: self.kind.title, subtitle: self.kind.subtitle)
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: WexloPeopleListHeaderView.height(
                for: collectionView.bounds.width,
                subtitle: kind.subtitle
            )
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width - 30, height: 79)
    }

    private func performAction(
        at index: Int,
        collectionView: UICollectionView?
    ) {
        guard people.indices.contains(index) else { return }

        if kind == .blockList {
            guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
                showWexloToast("Please sign in to manage blocked users.")
                return
            }
            isUpdatingRelationship = true
            defer { isUpdatingRelationship = false }
            guard WexloBlockStore.shared.unblockUser(
                people[index].userID,
                for: accountID
            ) else {
                showWexloToast("Unable to unblock this user.")
                return
            }
            people.remove(at: index)
            collectionView?.performBatchUpdates {
                collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
            return
        }

        guard case .authenticated(let accountID) = WexloSessionStore.shared.current else {
            showWexloToast("Please sign in to manage following.")
            return
        }

        isUpdatingRelationship = true
        defer { isUpdatingRelationship = false }

        let targetUserID = people[index].userID
        let nextIsFollowing = kind == .followers
            ? !relationshipStore.isFollowing(targetUserID, from: accountID)
            : false
        guard relationshipStore.setFollowing(
            nextIsFollowing,
            from: accountID,
            to: targetUserID
        ) else {
            showWexloToast("Following could not be updated.")
            return
        }

        if kind == .following {
            people.remove(at: index)
            collectionView?.performBatchUpdates {
                collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        } else {
            people[index].actionTitle = nextIsFollowing ? "Following" : "Follow back"
            collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }

    @objc private func reloadPeople() {
        guard !isUpdatingRelationship else { return }
        people = Self.makePeople(for: kind)
        collectionView.reloadData()
    }

    private static func makePeople(for kind: WexloPeopleListKind) -> [WexloPeopleListItem] {
        let common = WexloLocalContentStore.shared.users.map {
            (
                $0.id,
                $0.name,
                "@\($0.name.lowercased())",
                $0.bio,
                $0.avatarAssetName
            )
        }
        let relationshipStore = WexloRelationshipStore.shared
        let accountID: String?
        if case .authenticated(let userID) = WexloSessionStore.shared.current {
            accountID = userID
        } else {
            accountID = nil
        }

        let visibleUsers: [(String, String, String, String, String)]
        switch kind {
        case .following:
            guard let accountID else { return [] }
            let followingIDs = relationshipStore.followingUserIDs(for: accountID)
            visibleUsers = common.filter { followingIDs.contains($0.0) }
        case .followers:
            guard let accountID else { return [] }
            let followerIDs = relationshipStore.followerUserIDs(for: accountID)
            visibleUsers = common.filter { followerIDs.contains($0.0) }
        case .blockList:
            guard let accountID else { return [] }
            let blockedIDs = WexloBlockStore.shared.blockedUserIDs(for: accountID)
            visibleUsers = common.filter { blockedIDs.contains($0.0) }
        }

        return visibleUsers.enumerated().map { index, user in
            let listDetail: String
            switch kind {
            case .following, .followers:
                listDetail = user.3
            case .blockList:
                let dates = ["Aug 18", "Aug 12", "Aug 04", "Jul 29", "Jul 21", "Jul 14", "Jul 08", "Jun 30"]
                listDetail = "Blocked on \(dates[index]) · \(user.3)"
            }
            let actionTitle: String
            switch kind {
            case .following:
                actionTitle = "Following"
            case .followers:
                actionTitle = accountID.map {
                    relationshipStore.isFollowing(user.0, from: $0)
                        ? "Following"
                        : "Follow back"
                } ?? "Follow back"
            case .blockList:
                actionTitle = "Unblock"
            }
            return WexloPeopleListItem(
                userID: user.0,
                name: user.1,
                handle: user.2,
                detail: listDetail,
                avatarAssetName: user.4,
                actionTitle: actionTitle
            )
        }
    }
}
