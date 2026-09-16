import Foundation

struct WexloUserProfile: Codable, Equatable {
    let nickname: String
    let dateOfBirth: String
    let location: String
    let gender: String
    let bio: String
    let avatarAssetName: String?
    let avatarData: Data?

    init(
        nickname: String,
        dateOfBirth: String,
        location: String,
        gender: String,
        bio: String = "",
        avatarAssetName: String? = nil,
        avatarData: Data? = nil
    ) {
        self.nickname = nickname
        self.dateOfBirth = dateOfBirth
        self.location = location
        self.gender = gender
        self.bio = bio
        self.avatarAssetName = avatarAssetName
        self.avatarData = avatarData
    }

    private enum CodingKeys: String, CodingKey {
        case nickname
        case dateOfBirth
        case location
        case gender
        case bio
        case avatarAssetName
        case avatarData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            nickname: try container.decode(String.self, forKey: .nickname),
            dateOfBirth: try container.decode(String.self, forKey: .dateOfBirth),
            location: try container.decode(String.self, forKey: .location),
            gender: try container.decode(String.self, forKey: .gender),
            bio: try container.decodeIfPresent(String.self, forKey: .bio) ?? "",
            avatarAssetName: try container.decodeIfPresent(String.self, forKey: .avatarAssetName),
            avatarData: try container.decodeIfPresent(Data.self, forKey: .avatarData)
        )
    }
}

enum WexloAccountError: Error {
    case accountAlreadyExists
    case accountNotFound
    case invalidCredentials
    case invalidPassword
    case storageFailure

    var userMessage: String {
        switch self {
        case .accountAlreadyExists:
            return "An account with this email already exists."
        case .accountNotFound:
            return "We could not find an account for this email."
        case .invalidCredentials:
            return "The email or password is incorrect."
        case .invalidPassword:
            return "Password must contain at least 6 characters."
        case .storageFailure:
            return "Your account could not be saved right now."
        }
    }
}

@MainActor
final class WexloAccountStore {
    static let shared = WexloAccountStore()

    private struct Account: Codable {
        let id: String
        let email: String
        var profile: WexloUserProfile?
    }

    private let defaults: UserDefaults
    private let keychain: WexloKeychainStore
    private let accountsKey = "wexlo.accounts"
    private let seedVersionKey = "wexlo.local.seed.version"
    private let currentSeedVersion = "csv-2026-09-11"

    init(
        defaults: UserDefaults = .standard,
        keychain: WexloKeychainStore = WexloKeychainStore(service: "app.myfy.Wexlo.credentials")
    ) {
        self.defaults = defaults
        self.keychain = keychain
    }

    func register(
        email: String,
        password: String,
        profile: WexloUserProfile
    ) throws -> String {
        let normalizedEmail = Self.normalize(email)
        guard password.count >= 6 else { throw WexloAccountError.invalidPassword }

        var accounts = loadAccounts()
        guard !accounts.contains(where: { $0.email == normalizedEmail }) else {
            throw WexloAccountError.accountAlreadyExists
        }

        let account = Account(id: UUID().uuidString, email: normalizedEmail, profile: profile)
        accounts.append(account)
        guard saveAccounts(accounts) else {
            throw WexloAccountError.storageFailure
        }
        guard keychain.set(password, for: normalizedEmail) else {
            _ = saveAccounts(Array(accounts.dropLast()))
            throw WexloAccountError.storageFailure
        }
        return account.id
    }

    func authenticate(email: String, password: String) throws -> String {
        let normalizedEmail = Self.normalize(email)
        guard let account = loadAccounts().first(where: { $0.email == normalizedEmail }) else {
            throw WexloAccountError.invalidCredentials
        }
        guard keychain.string(for: normalizedEmail) == password else {
            throw WexloAccountError.invalidCredentials
        }
        return account.id
    }

    func resetPassword(email: String, password: String) throws {
        let normalizedEmail = Self.normalize(email)
        guard loadAccounts().contains(where: { $0.email == normalizedEmail }) else {
            throw WexloAccountError.accountNotFound
        }
        guard password.count >= 6 else { throw WexloAccountError.invalidPassword }
        guard keychain.set(password, for: normalizedEmail) else {
            throw WexloAccountError.storageFailure
        }
    }

    func saveProfile(_ profile: WexloUserProfile, for userID: String) throws {
        var accounts = loadAccounts()
        guard let index = accounts.firstIndex(where: { $0.id == userID }) else {
            throw WexloAccountError.accountNotFound
        }
        accounts[index].profile = profile
        guard saveAccounts(accounts) else {
            throw WexloAccountError.storageFailure
        }
        NotificationCenter.default.post(
            name: .wexloProfileDidChange,
            object: userID
        )
    }

    func profile(for userID: String) -> WexloUserProfile? {
        loadAccounts().first(where: { $0.id == userID })?.profile
    }

    func seedInitialAccountsIfNeeded() {
        guard defaults.string(forKey: seedVersionKey) != currentSeedVersion else {
            return
        }

        let seedUsers = WexloLocalContentStore.shared.users
        var accounts = loadAccounts()
        var didChange = false

        for user in seedUsers {
            let email = Self.normalize(user.email)
            if let index = accounts.firstIndex(where: { $0.id == user.id || $0.email == email }) {
                if accounts[index].profile == nil {
                    accounts[index].profile = Self.seedProfile(for: user)
                    didChange = true
                }
                continue
            }

            accounts.append(
                Account(
                    id: user.id,
                    email: email,
                    profile: Self.seedProfile(for: user)
                )
            )
            _ = keychain.set(user.password, for: email)
            didChange = true
        }

        if didChange {
            guard saveAccounts(accounts) else { return }
        }
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
    }

    func deleteAccount(userID: String) throws {
        var accounts = loadAccounts()
        guard let index = accounts.firstIndex(where: { $0.id == userID }) else {
            throw WexloAccountError.accountNotFound
        }
        let email = accounts[index].email
        accounts.remove(at: index)
        let password = keychain.string(for: email)
        guard keychain.delete(account: email) else {
            throw WexloAccountError.storageFailure
        }
        guard saveAccounts(accounts) else {
            if let password {
                _ = keychain.set(password, for: email)
            }
            throw WexloAccountError.storageFailure
        }
        WexloRelationshipStore.shared.removeUser(userID)
        WexloChatStore.shared.removeMessages(for: userID)
        WexloSessionStore.shared.removeAIMessages(for: userID)
        WexloCoinStore.shared.deleteBalance(for: userID)
        WexloCommentStore.shared.removeComments(for: userID)
    }

    private func loadAccounts() -> [Account] {
        guard let data = defaults.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([Account].self, from: data) else {
            return []
        }
        return accounts
    }

    private func saveAccounts(_ accounts: [Account]) -> Bool {
        guard let data = try? JSONEncoder().encode(accounts) else { return false }
        defaults.set(data, forKey: accountsKey)
        return true
    }

    private static func seedProfile(for user: WexloSeedUser) -> WexloUserProfile {
        WexloUserProfile(
            nickname: user.name,
            dateOfBirth: "01 / 01 / 1990",
            location: "Outdoor community",
            gender: "Prefer not to say",
            bio: user.bio,
            avatarAssetName: user.avatarAssetName
        )
    }

    private static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension Notification.Name {
    static let wexloProfileDidChange = Notification.Name("wexlo.profile.didChange")
}
