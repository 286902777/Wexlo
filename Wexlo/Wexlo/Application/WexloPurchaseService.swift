import Foundation
import StoreKit

enum WexloPurchaseResult {
    case success(Int)
    case pending
    case cancelled
    case failed
}

@MainActor
final class WexloPurchaseService {
    static let shared = WexloPurchaseService()

    private let coinStore = WexloCoinStore.shared

    func purchase(
        package: WexloRechargePackage,
        for userID: String
    ) async -> WexloPurchaseResult {
        do {
            let products = try await Product.products(for: [package.productID])
            guard let product = products.first(where: { $0.id == package.productID }) else {
                return .failed
            }

            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification,
                      transaction.productID == package.productID else {
                    return .failed
                }

                do {
                    try coinStore.addCoins(package.coinAmount, for: userID)
                } catch {
                    return .failed
                }

                await transaction.finish()
                NotificationCenter.default.post(
                    name: .wexloCoinsDidChange,
                    object: nil,
                    userInfo: ["userID": userID]
                )
                return .success(package.coinAmount)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }
}
