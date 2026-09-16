import Foundation

enum WexloCoinStoreError: Error {
    case invalidAmount
    case insufficientBalance
    case storageFailure
}

@MainActor
final class WexloCoinStore {
    static let shared = WexloCoinStore()

    private let keychain = WexloKeychainStore(service: "app.myfy.Wexlo.coin-balances")
    private let initialBalance = 900

    func balance(for accountID: String) -> Int {
        guard let stored = keychain.string(for: accountID),
              let balance = Int(stored),
              balance >= 0 else {
            return initialBalance
        }
        return balance
    }

    func addCoins(_ amount: Int, for accountID: String) throws {
        guard amount > 0 else { throw WexloCoinStoreError.invalidAmount }
        let updatedBalance = balance(for: accountID) + amount
        guard keychain.set(String(updatedBalance), for: accountID) else {
            throw WexloCoinStoreError.storageFailure
        }
    }

    func spendCoins(_ amount: Int, for accountID: String) throws {
        guard amount > 0 else { throw WexloCoinStoreError.invalidAmount }
        let currentBalance = balance(for: accountID)
        guard currentBalance >= amount else {
            throw WexloCoinStoreError.insufficientBalance
        }
        guard keychain.set(String(currentBalance - amount), for: accountID) else {
            throw WexloCoinStoreError.storageFailure
        }
        NotificationCenter.default.post(
            name: .wexloCoinsDidChange,
            object: nil,
            userInfo: ["userID": accountID]
        )
    }

    func deleteBalance(for accountID: String) {
        _ = keychain.delete(account: accountID)
    }
}

extension Notification.Name {
    static let wexloCoinsDidChange = Notification.Name("wexlo.coins.didChange")
}
