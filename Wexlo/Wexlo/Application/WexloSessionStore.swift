import Foundation

enum WexloSession: Equatable {
    case absent
    case guest
    case authenticated(userID: String)
}

struct WexloAIMessage: Codable, Equatable {
    let text: String
    let isAI: Bool
    let createdAt: Date
}

@MainActor
final class WexloSessionStore {
    static let shared = WexloSessionStore()

    private enum Key {
        static let sessionKind = "wexlo.session.kind"
        static let userID = "wexlo.session.userID"
        static let acceptedEULA = "wexlo.eula.accepted"
        static let aiMessagesPrefix = "wexlo.ai.messages."
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var current: WexloSession {
        switch defaults.string(forKey: Key.sessionKind) {
        case "guest": return .guest
        case "authenticated":
            guard let userID = defaults.string(forKey: Key.userID), !userID.isEmpty else {
                clearStoredSession()
                return .absent
            }
            return .authenticated(userID: userID)
        default: return .absent
        }
    }

    var hasAcceptedEULA: Bool { defaults.bool(forKey: Key.acceptedEULA) }

    func enterGuestSession() {
        defaults.set("guest", forKey: Key.sessionKind)
        defaults.removeObject(forKey: Key.userID)
        postChange()
    }

    func saveAuthenticatedSession(userID: String, toastMessage: String? = nil) {
        defaults.set("authenticated", forKey: Key.sessionKind)
        defaults.set(userID, forKey: Key.userID)
        postChange(toastMessage: toastMessage)
    }

    func clearSession(toastMessage: String? = nil) {
        clearStoredSession()
        postChange(toastMessage: toastMessage)
    }

    func aiMessages(for accountID: String?) -> [WexloAIMessage] {
        let key = aiMessagesKey(for: accountID)
        guard let data = defaults.data(forKey: key),
              let messages = try? JSONDecoder().decode([WexloAIMessage].self, from: data) else {
            return []
        }
        return messages.sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func appendAIMessage(_ message: WexloAIMessage, for accountID: String?) -> Bool {
        let key = aiMessagesKey(for: accountID)
        var messages = aiMessages(for: accountID)
        messages.append(message)
        guard let data = try? JSONEncoder().encode(messages) else {
            return false
        }
        defaults.set(data, forKey: key)
        return true
    }

    func removeAIMessages(for accountID: String) {
        defaults.removeObject(forKey: aiMessagesKey(for: accountID))
    }

    private func clearStoredSession() {
        defaults.removeObject(forKey: Key.sessionKind)
        defaults.removeObject(forKey: Key.userID)
    }

    private func aiMessagesKey(for accountID: String?) -> String {
        let normalizedID = accountID?.isEmpty == false ? accountID! : "guest"
        return "\(Key.aiMessagesPrefix)\(normalizedID)"
    }

    func acceptEULA() { defaults.set(true, forKey: Key.acceptedEULA) }

    private func postChange(toastMessage: String? = nil) {
        let userInfo: [AnyHashable: Any]? = toastMessage.map { ["toastMessage": $0] }
        NotificationCenter.default.post(
            name: .wexloSessionDidChange,
            object: nil,
            userInfo: userInfo
        )
    }
}

extension Notification.Name {
    static let wexloBlockedUserDidChange = Notification.Name("wexlo.blockedUser.didChange")
    static let wexloSignInRequested = Notification.Name("wexlo.signIn.requested")
    static let wexloSessionDidChange = Notification.Name("wexlo.session.didChange")
}
