import Foundation

@MainActor
final class WexloCommentStore {
    static let shared = WexloCommentStore()

    private struct StoredComment: Codable {
        let id: String
        let postID: String
        let authorID: String
        let text: String
        let createdAt: Date
    }

    private struct StoredState: Codable {
        var comments: [StoredComment] = []
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.post.comments"
    private let seedVersionKey = "wexlo.post.comments.seed.version"
    private let currentSeedVersion = "comments-2026-09-15"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func seedInitialCommentsIfNeeded() {
        guard defaults.string(forKey: seedVersionKey) != currentSeedVersion else {
            return
        }

        var state = loadState()
        let existingIDs = Set(state.comments.map(\.id))
        for post in WexloLocalContentStore.shared.posts {
            for (index, comment) in post.comments.enumerated() {
                let id = "seed-\(post.id)-comment-\(index)"
                guard !existingIDs.contains(id) else { continue }
                state.comments.append(
                    StoredComment(
                        id: id,
                        postID: post.id,
                        authorID: comment.authorID,
                        text: comment.text,
                        createdAt: Date()
                    )
                )
            }
        }

        guard saveState(state) else { return }
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
        NotificationCenter.default.post(name: .wexloCommentDidChange, object: nil)
    }

    func comments(for post: WexloLocalPost) -> [WexloLocalComment] {
        loadState().comments
            .filter { $0.postID == post.id }
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                WexloLocalComment(
                    authorID: $0.authorID,
                    text: $0.text,
                    timeLabel: relativeTimestamp(for: $0.createdAt)
                )
            }
    }

    @discardableResult
    func appendComment(
        _ text: String,
        to post: WexloLocalPost,
        authorID: String
    ) -> WexloLocalComment? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty, !authorID.isEmpty else {
            return nil
        }

        let createdAt = Date()
        let storedComment = StoredComment(
            id: UUID().uuidString,
            postID: post.id,
            authorID: authorID,
            text: normalizedText,
            createdAt: createdAt
        )
        var state = loadState()
        state.comments.append(storedComment)
        guard saveState(state) else { return nil }

        NotificationCenter.default.post(
            name: .wexloCommentDidChange,
            object: post.id,
            userInfo: [
                "postID": post.id,
                "authorID": authorID
            ]
        )
        return WexloLocalComment(
            authorID: authorID,
            text: normalizedText,
            timeLabel: relativeTimestamp(for: createdAt)
        )
    }

    func count(for post: WexloLocalPost) -> Int {
        comments(for: post).count
    }

    func removeComments(for userID: String) {
        var state = loadState()
        state.comments.removeAll { $0.authorID == userID }
        _ = saveState(state)
        NotificationCenter.default.post(name: .wexloCommentDidChange, object: nil)
    }

    func removeComments(forPostIDs postIDs: Set<String>) {
        guard !postIDs.isEmpty else { return }
        var state = loadState()
        state.comments.removeAll { postIDs.contains($0.postID) }
        _ = saveState(state)
        NotificationCenter.default.post(name: .wexloCommentDidChange, object: nil)
    }

    private func relativeTimestamp(for date: Date) -> String {
        let elapsed = max(0, Date().timeIntervalSince(date))
        if elapsed < 60 {
            return "now"
        }
        if elapsed < 3_600 {
            return "\(Int(elapsed / 60))m"
        }
        if elapsed < 86_400 {
            return "\(Int(elapsed / 3_600))h"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func loadState() -> StoredState {
        guard let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return StoredState()
        }
        return state
    }

    private func saveState(_ state: StoredState) -> Bool {
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: stateKey)
        return true
    }
}

extension Notification.Name {
    static let wexloCommentDidChange = Notification.Name("wexlo.comment.didChange")
}
